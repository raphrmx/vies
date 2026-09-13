import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:vies/src/constants.dart';
import 'package:vies/src/enums.dart';
import 'package:vies/src/error_code.dart';
import 'package:vies/src/models/vies_error.dart';
import 'package:vies/src/models/vies_validation_response.dart';
import 'package:vies/src/soap_parser.dart';
import 'package:vies/src/vat_shape.dart';
import 'package:vies/src/xml_codec.dart';

/// Entry point of the package. All operations are static - the class is not
/// instantiable.
///
/// Example:
/// ```dart
/// final response = await ViesProvider.validateVat(
///   vatNumber: 'BE1000341796',
/// );
/// print('${response.name} - ${response.address}');
/// ```
///
/// Throws:
///   * [ViesClientError] when the input or the parsed response indicates an
///     invalid VAT number, a SOAP fault, or a parsing failure.
///   * [ViesServerError] on network failure, timeout, or any non-2xx HTTP
///     response from VIES.
abstract final class ViesProvider {
  ViesProvider._();

  /// Validate a VAT number against the VIES SOAP service.
  ///
  /// Parameters:
  ///   * [vatNumber] - the number, with or without its country prefix.
  ///     `BE1003546213`, `BE1003.546.213`, `1003546213` and `1003.546.213`
  ///     are all accepted: spaces, dots and hyphens are stripped, and a
  ///     prefix VIES knows is read as the country.
  ///   * [countryCode] - deprecated. Put the prefix in [vatNumber] instead.
  ///     A prefix found there wins over this parameter, and a French key of
  ///     two letters can read as a country code: `countryCode: 'FR'` with
  ///     `vatNumber: 'BE123456789'` reaches Belgium, where
  ///     `vatNumber: 'FRBE123456789'` reaches France. Leaving both without a
  ///     country throws [ViesErrorCode.invalidInput].
  ///   * [timeout] - applied to each HTTP attempt, not to the call as a whole.
  ///     With [retries] the total wall time reaches `(retries + 1) * timeout`
  ///     plus the backoff. Defaults to [defaultRequestTimeout].
  ///   * [validationLevel] - see [ValidationLevel].
  ///   * [regexType] - see [RegexType].
  ///   * [client] - an optional [http.Client] to reuse across calls. Useful
  ///     for connection pooling and for injecting a mock in tests. When
  ///     omitted, a one-shot client is created and closed.
  ///   * [retries] - how many extra attempts to make after a transient
  ///     failure (timeout, MS unavailable, rate limited...). Defaults to `0`,
  ///     and a negative value counts as `0`. Each retry waits
  ///     `200ms * 2^attempt`, capped at [maxRetryBackoff].
  ///   * [serviceUrl] - endpoint to call. Defaults to [viesServiceUrl]; pass
  ///     [viesTestServiceUrl] to exercise the deterministic test service.
  static Future<ViesValidationResponse> validateVat({
    required String vatNumber,
    @Deprecated('Put the prefix in vatNumber instead. Removed in 3.0.0.')
    String? countryCode,
    Duration timeout = defaultRequestTimeout,
    ValidationLevel validationLevel = ValidationLevel.all,
    RegexType regexType = RegexType.world,
    http.Client? client,
    int retries = 0,
    String serviceUrl = viesServiceUrl,
  }) async {
    final carried = VatShape.split(vatNumber);
    final cleanCountry =
        carried?.countryCode ?? (countryCode ?? '').trim().toUpperCase();
    final cleanVat = carried?.vatNumber ?? VatShape.normalize(vatNumber);

    if (cleanCountry.isEmpty) {
      throw const ViesClientError(code: ViesErrorCode.invalidInput);
    }

    if (validationLevel == ValidationLevel.regex ||
        validationLevel == ValidationLevel.all) {
      if (!VatShape.isValid('$cleanCountry$cleanVat', regexType)) {
        throw const ViesClientError(code: ViesErrorCode.invalidVatNumber);
      }
    }

    if (validationLevel == ValidationLevel.regex) {
      return ViesValidationResponse(
        countryCode: cleanCountry,
        vatNumber: cleanVat,
        requestDate: DateTime.now().toUtc().toIso8601String(),
        valid: true,
        source: ValidationSource.regex,
      );
    }

    final ownedClient = client == null;
    final httpClient = client ?? http.Client();
    try {
      return await _callWithRetries(
        client: httpClient,
        countryCode: cleanCountry,
        vatNumber: cleanVat,
        timeout: timeout,
        retries: retries < 0 ? 0 : retries,
        serviceUrl: serviceUrl,
      );
    } finally {
      if (ownedClient) httpClient.close();
    }
  }

  /// Parse a raw SOAP body without performing the HTTP call. Exposed for
  /// tests and tooling.
  static ViesValidationResponse debugParseSoapResponse(String soapMessage) =>
      SoapParser.parse(soapMessage);

  // --------------------------------------------------------------------------
  // HTTP layer
  // --------------------------------------------------------------------------

  static Future<ViesValidationResponse> _callWithRetries({
    required http.Client client,
    required String countryCode,
    required String vatNumber,
    required Duration timeout,
    required int retries,
    required String serviceUrl,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await _callOnce(
          client: client,
          countryCode: countryCode,
          vatNumber: vatNumber,
          timeout: timeout,
          serviceUrl: serviceUrl,
        );
      } on ViesServerError catch (error) {
        if (attempt >= retries || !error.code.isRetryable) rethrow;
        await Future<void>.delayed(_backoffFor(attempt));
        attempt++;
      }
    }
  }

  /// Exponential backoff for [attempt], capped so a large `retries` cannot
  /// turn into an unbounded wait.
  static Duration _backoffFor(int attempt) {
    if (attempt >= 16) return maxRetryBackoff;
    final milliseconds = 200 * (1 << attempt);
    return milliseconds >= maxRetryBackoff.inMilliseconds
        ? maxRetryBackoff
        : Duration(milliseconds: milliseconds);
  }

  static Future<ViesValidationResponse> _callOnce({
    required http.Client client,
    required String countryCode,
    required String vatNumber,
    required Duration timeout,
    required String serviceUrl,
  }) async {
    final body = soapBodyTemplate
        .replaceAll('{countryCode}', XmlCodec.escape(countryCode))
        .replaceAll('{vatNumber}', XmlCodec.escape(vatNumber));

    try {
      final response = await client
          .post(Uri.parse(serviceUrl), headers: viesHeaders, body: body)
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ViesServerError(
          code: ViesErrorCode.serverDisconnected,
          message: 'VIES returned HTTP ${response.statusCode} '
              '(${response.reasonPhrase ?? 'no reason'}).',
        );
      }

      return SoapParser.parse(response.body);
    } on TimeoutException {
      throw const ViesServerError(code: ViesErrorCode.timeout);
    } on http.ClientException catch (error) {
      // `package:http` wraps transport failures in [http.ClientException] on
      // every platform. On native, connectivity errors arrive as a subtype
      // that also implements `SocketException`; on web they are plain
      // `ClientException`. We avoid importing `dart:io` (which breaks Flutter
      // web) and classify connectivity failures heuristically instead.
      throw ViesServerError(
        code: _isConnectivityError(error.message)
            ? ViesErrorCode.socketException
            : ViesErrorCode.serverDisconnected,
        message: error.message,
      );
    }
  }

  /// Heuristic detection of a connectivity (offline) failure from an
  /// [http.ClientException] message, without depending on `dart:io`.
  static bool _isConnectivityError(String message) {
    final m = message.toLowerCase();
    return m.contains('socket') ||
        m.contains('failed host lookup') ||
        m.contains('connection refused') ||
        m.contains('connection closed') ||
        m.contains('connection reset') ||
        m.contains('connection failed') ||
        m.contains('connection terminated') ||
        m.contains('network is unreachable') ||
        m.contains('no address associated') ||
        m.contains('xmlhttprequest'); // browser: network/CORS failure
  }
}

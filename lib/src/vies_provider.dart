import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vies/src/constants.dart';
import 'package:vies/src/enums.dart';
import 'package:vies/src/error_code.dart';
import 'package:vies/src/models/vies_error.dart';
import 'package:vies/src/models/vies_validation_response.dart';
import 'package:vies/src/soap_parser.dart';
import 'package:vies/src/vat_shape.dart';
import 'package:vies/src/xml_codec.dart';

/// Entry point of the package. All operations are static — the class is not
/// instantiable.
///
/// Example:
/// ```dart
/// final response = await ViesProvider.validateVat(
///   countryCode: 'BE',
///   vatNumber: '1000341796',
/// );
/// print('${response.name} — ${response.address}');
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
  ///   * [countryCode] — two-letter country prefix. Use `EL` for Greece and
  ///     `XI` for Northern Ireland.
  ///   * [vatNumber] — the digits/letters that follow the country prefix.
  ///     Spaces and hyphens are tolerated and stripped before validation.
  ///   * [timeout] — applied to the HTTP call. Defaults to
  ///     [defaultRequestTimeout].
  ///   * [validationLevel] — see [ValidationLevel].
  ///   * [regexType] — see [RegexType].
  ///   * [client] — an optional [http.Client] to reuse across calls. Useful
  ///     for connection pooling and for injecting a mock in tests. When
  ///     omitted, a one-shot client is created and closed.
  ///   * [retries] — how many extra attempts to make after a transient
  ///     failure (timeout, MS unavailable, rate limited…). Defaults to `0`.
  ///     Each retry waits `200ms * 2^attempt` before re-issuing the call.
  static Future<ViesValidationResponse> validateVat({
    required String countryCode,
    required String vatNumber,
    Duration timeout = defaultRequestTimeout,
    ValidationLevel validationLevel = ValidationLevel.all,
    RegexType regexType = RegexType.world,
    http.Client? client,
    int retries = 0,
  }) async {
    final cleanCountry = countryCode.trim().toUpperCase();
    final cleanVat = VatShape.normalize(vatNumber);

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
        retries: retries,
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
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await _callOnce(
          client: client,
          countryCode: countryCode,
          vatNumber: vatNumber,
          timeout: timeout,
        );
      } on ViesServerError catch (error) {
        if (attempt >= retries || !error.code.isRetryable) rethrow;
        await Future<void>.delayed(
          Duration(milliseconds: 200 * (1 << attempt)),
        );
        attempt++;
      }
    }
  }

  static Future<ViesValidationResponse> _callOnce({
    required http.Client client,
    required String countryCode,
    required String vatNumber,
    required Duration timeout,
  }) async {
    final body = soapBodyTemplate
        .replaceAll('{countryCode}', XmlCodec.escape(countryCode))
        .replaceAll('{vatNumber}', XmlCodec.escape(vatNumber));

    try {
      final response = await client
          .post(Uri.parse(viesServiceUrl), headers: viesHeaders, body: body)
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
    } on SocketException {
      throw const ViesServerError(code: ViesErrorCode.socketException);
    } on http.ClientException catch (error) {
      throw ViesServerError(
        code: ViesErrorCode.serverDisconnected,
        message: error.message,
      );
    }
  }
}

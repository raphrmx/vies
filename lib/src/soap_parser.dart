import 'package:vies/src/error_code.dart';
import 'package:vies/src/models/vies_error.dart';
import 'package:vies/src/models/vies_validation_response.dart';
import 'package:vies/src/xml_codec.dart';

/// Decodes a raw VIES SOAP body into a [ViesValidationResponse] or throws
/// the appropriate [ViesError] subtype.
abstract final class SoapParser {
  SoapParser._();

  /// Parse [soapMessage] returned by the VIES `checkVat` endpoint.
  ///
  /// Throws:
  ///   * [ViesClientError] for `<soap:Fault>` elements that indicate a
  ///     caller-side problem (invalid input, parsing error, soap fault),
  ///     or when VIES reports `valid=false`.
  ///   * [ViesServerError] for transient faults (`MS_UNAVAILABLE`,
  ///     `SERVICE_UNAVAILABLE`, …) that the caller may want to retry.
  static ViesValidationResponse parse(String soapMessage) {
    if (XmlCodec.faultRegex.firstMatch(soapMessage) != null) {
      _throwForFault(soapMessage);
    }

    final countryCode = XmlCodec.parseField(soapMessage, 'countryCode');
    final vatNumber = XmlCodec.parseField(soapMessage, 'vatNumber');
    final name = XmlCodec.parseField(soapMessage, 'name');
    final requestDate = XmlCodec.parseField(soapMessage, 'requestDate');
    final valid =
        XmlCodec.parseField(soapMessage, 'valid')?.toLowerCase() == 'true';
    final address = XmlCodec.parseField(soapMessage, 'address');

    if (!valid) {
      throw const ViesClientError(code: ViesErrorCode.invalidVatNumber);
    }

    if (countryCode == null || vatNumber == null || requestDate == null) {
      throw const ViesClientError(code: ViesErrorCode.parsingError);
    }

    return ViesValidationResponse(
      countryCode: countryCode,
      vatNumber: vatNumber,
      requestDate: requestDate,
      valid: valid,
      name: _nullIfBlank(name),
      address: _nullIfBlank(address),
    );
  }

  static Never _throwForFault(String soapMessage) {
    final faultString = XmlCodec.parseField(soapMessage, 'faultstring');
    final code = ViesErrorCode.fromWireName(faultString);
    if (code.isRetryable) {
      throw ViesServerError(code: code, viesResponse: faultString);
    }
    throw ViesClientError(
      code: code == ViesErrorCode.unknown ? ViesErrorCode.soapFault : code,
      viesResponse: faultString,
    );
  }

  static String? _nullIfBlank(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

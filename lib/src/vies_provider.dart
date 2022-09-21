import 'dart:async';
import 'dart:io';

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:vies/src/constants.dart';
import 'package:vies/src/models/vies_client_error.dart';
import 'package:vies/src/models/vies_server_error.dart';
import 'package:vies/src/models/vies_validation_response.dart';

///
/// Static provider to easly use
///
class ViesProvider {
  final String classId = "ViesProvider";

  /// remove encoded html caracter
  static final _unescape = HtmlUnescape();

  /// Get an element value from xml Vies response
  static String? _parseField(String soapMessage, String tag) {
    final regex = RegExp("<$tag>\((\.|\\s)\*?\)</$tag>");
    final res = regex.firstMatch(soapMessage);
    return res?.group(1) != null ? _unescape.convert(res!.group(1)!) : null;
  }

  /// Get if Vies resmonse has a fault on xml
  static String? _hasFault(String soapMessage) =>
      _parseField(soapMessage, 'soap:Fault');

  /// Parse xml Vies response to ViesValidationResponse
  static ViesValidationResponse _parseSoapResponse(String soapMessage) {
    if (_hasFault(soapMessage) != null) {
      throw ViesClientError(
        message: 'Failed to parse vat validation info from VIES response',
        errorCode: _parseField(soapMessage, 'faultstring'),
        viesResponse: viesErrors[_parseField(soapMessage, 'faultstring')],
      );
    } else {
      final countryCode = _parseField(soapMessage, "ns2:countryCode");
      final vatNumber = _parseField(soapMessage, "ns2:vatNumber");
      final name = _parseField(soapMessage, "ns2:name");
      final requestDate = _parseField(soapMessage, "ns2:requestDate");
      final valid = _parseField(soapMessage, "ns2:valid")?.toLowerCase() == 'true';
      final address = _parseField(soapMessage, "ns2:address");

      /// XML response is valid but VAT number from response is set to invalid
      if (!valid) {
        throw ViesClientError(
          message: 'VAT number is invalid',
          errorCode: 'INVALID_VAT_NUMBER',
          viesResponse: viesErrors['INVALID_VAT_NUMBER'],
        );
      }

      // XML response is invalid
      if (countryCode == null ||
          vatNumber == null ||
          requestDate == null ||
          address == null) {
        throw ViesClientError(
          message: 'Failed to parse vat validation info from VIES response',
          errorCode: 'PARSING_ERROR',
          viesResponse: viesErrors['PARSING_ERROR'],
        );
      }

      return ViesValidationResponse(
        countryCode: countryCode,
        vatNumber: vatNumber,
        requestDate: requestDate,
        valid: valid,
        name: name,
        address: address,
      );
    }
  }

  ///
  /// Check VAT validity and get relative infos from Vies
  ///
  static Future<ViesValidationResponse> validateVat({
    required String countryCode,
    required String vatNumber,
    Duration? timeout,
  }) async {
    try {
      // build xml before send request
      final xml = soapBodyTemplate
          .replaceAll("_country_code_placeholder_", countryCode)
          .replaceAll("_vat_number_placeholder_", vatNumber)
          .replaceAll("\n", "")
          .trim();
      final response = await http
          .post(
            Uri.parse(viesServiceUrl),
            headers: viesHeaders,
            body: xml,
          )
          .timeout(
            timeout ?? const Duration(seconds: 30),
          );
      if (response.statusCode != 200) throw Exception(response.reasonPhrase);
      return _parseSoapResponse(response.body);
    } on TimeoutException catch (_) {
      throw ViesServerError(
        message: 'Failed to get VIES web service. (Offline)',
        errorCode: 'TIMEOUT',
        viesResponse: viesErrors['TIMEOUT'],
      );
    } on SocketException catch (_) {
      throw ViesServerError(
        message: 'Failed to get VIES web service. (No Internet Connection)',
        errorCode: 'SOCKET_EXCEPTION',
        viesResponse: viesErrors['SOCKET_EXCEPTION'],
      );
    } catch (e) {
      print(e.toString());
      if (e is ViesServerError) {
        rethrow;
      }
      throw ViesServerError(
        message: 'Failed to get VIES web service. (Offline)',
        errorCode: 'SERVER_DICONNECTED',
        viesResponse: viesErrors['SERVER_DICONNECTED'],
      );
    }
  }
}

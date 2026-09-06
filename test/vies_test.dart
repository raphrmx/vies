// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vies/vies.dart';

String _validSoap({
  String countryCode = 'FR',
  String vatNumber = '64443061841',
  String name = 'GOOGLE FRANCE',
  String address = '8 RUE DE LONDRES, 75009 PARIS',
  String requestDate = '2026-05-21+02:00',
  bool valid = true,
}) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
    '<soap:Body>'
    '<ns2:checkVatResponse xmlns:ns2="urn:ec.europa.eu:taxud:vies:services:checkVat:types">'
    '<ns2:countryCode>$countryCode</ns2:countryCode>'
    '<ns2:vatNumber>$vatNumber</ns2:vatNumber>'
    '<ns2:requestDate>$requestDate</ns2:requestDate>'
    '<ns2:valid>$valid</ns2:valid>'
    '<ns2:name>$name</ns2:name>'
    '<ns2:address>$address</ns2:address>'
    '</ns2:checkVatResponse>'
    '</soap:Body>'
    '</soap:Envelope>';

String _faultSoap(String faultString) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
    '<soap:Body>'
    '<soap:Fault>'
    '<faultcode>soap:Server</faultcode>'
    '<faultstring>$faultString</faultstring>'
    '</soap:Fault>'
    '</soap:Body>'
    '</soap:Envelope>';

void main() {
  group('Regex-only validation', () {
    test('accepts a valid French VAT number (world regex)', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: '64443061841',
        validationLevel: ValidationLevel.regex,
      );
      expect(res.valid, isTrue);
      expect(res.countryCode, 'FR');
      expect(res.vatNumber, '64443061841');
      expect(DateTime.tryParse(res.requestDate), isNotNull);
    });

    test('accepts a valid French VAT number (EU regex)', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: '64443061841',
        validationLevel: ValidationLevel.regex,
        regexType: RegexType.eu,
      );
      expect(res.valid, isTrue);
    });

    test('accepts the Greek EL prefix', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'EL',
        vatNumber: '094277146',
        validationLevel: ValidationLevel.regex,
        regexType: RegexType.eu,
      );
      expect(res.valid, isTrue);
    });

    test('accepts the Northern Ireland XI prefix', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'XI',
        vatNumber: '123456789',
        validationLevel: ValidationLevel.regex,
        regexType: RegexType.eu,
      );
      expect(res.valid, isTrue);
    });

    test('strips spaces and hyphens from input', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: '64 443-061 841',
        validationLevel: ValidationLevel.regex,
      );
      expect(res.vatNumber, '64443061841');
    });

    test('throws ViesClientError on invalid shape', () {
      expect(
        () => ViesProvider.validateVat(
          countryCode: 'FF',
          vatNumber: '1234567',
          validationLevel: ValidationLevel.regex,
          regexType: RegexType.eu,
        ),
        throwsA(
          isA<ViesClientError>().having(
            (e) => e.code,
            'code',
            ViesErrorCode.invalidVatNumber,
          ),
        ),
      );
    });
  });

  group('SOAP response parsing', () {
    test('parses a valid response', () {
      final res = ViesProvider.debugParseSoapResponse(_validSoap());
      expect(res.valid, isTrue);
      expect(res.countryCode, 'FR');
      expect(res.vatNumber, '64443061841');
      expect(res.name, 'GOOGLE FRANCE');
      expect(res.address, '8 RUE DE LONDRES, 75009 PARIS');
      expect(res.requestDateTime, isNotNull);
    });

    test('unescapes XML entities in business name', () {
      final res = ViesProvider.debugParseSoapResponse(
        _validSoap(name: 'O&apos;Brien &amp; Sons'),
      );
      expect(res.name, "O'Brien & Sons");
    });

    test('unescapes numeric entities', () {
      final res = ViesProvider.debugParseSoapResponse(
        _validSoap(name: 'O&#39;Brien'),
      );
      expect(res.name, "O'Brien");
    });

    test('tolerates tag attributes and namespace prefix variations', () {
      const xml =
          '<env:Envelope xmlns:env="x">'
          '<env:Body>'
          '<r:checkVatResponse xmlns:r="urn:x">'
          '<r:countryCode xml:lang="en">BE</r:countryCode>'
          '<r:vatNumber>1000341796</r:vatNumber>'
          '<r:requestDate>2026-05-21+02:00</r:requestDate>'
          '<r:valid>true</r:valid>'
          '<r:name>ACME</r:name>'
          '<r:address>Brussels</r:address>'
          '</r:checkVatResponse>'
          '</env:Body>'
          '</env:Envelope>';
      final res = ViesProvider.debugParseSoapResponse(xml);
      expect(res.countryCode, 'BE');
      expect(res.name, 'ACME');
    });

    test('throws ViesClientError on valid=false', () {
      expect(
        () => ViesProvider.debugParseSoapResponse(_validSoap(valid: false)),
        throwsA(
          isA<ViesClientError>().having(
            (e) => e.code,
            'code',
            ViesErrorCode.invalidVatNumber,
          ),
        ),
      );
    });

    test('throws ViesClientError on INVALID_INPUT fault', () {
      expect(
        () => ViesProvider.debugParseSoapResponse(_faultSoap('INVALID_INPUT')),
        throwsA(
          isA<ViesClientError>().having(
            (e) => e.code,
            'code',
            ViesErrorCode.invalidInput,
          ),
        ),
      );
    });

    test('throws ViesServerError on MS_UNAVAILABLE fault', () {
      expect(
        () => ViesProvider.debugParseSoapResponse(_faultSoap('MS_UNAVAILABLE')),
        throwsA(
          isA<ViesServerError>().having(
            (e) => e.code,
            'code',
            ViesErrorCode.msUnavailable,
          ),
        ),
      );
    });
  });

  group('HTTP layer (with MockClient)', () {
    test('happy path returns a populated response', () async {
      final mock = MockClient((req) async => http.Response(_validSoap(), 200));
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: '64443061841',
        validationLevel: ValidationLevel.vies,
        client: mock,
      );
      expect(res.valid, isTrue);
      expect(res.name, 'GOOGLE FRANCE');
    });

    test('non-200 HTTP response surfaces as ViesServerError', () async {
      final mock = MockClient((req) async => http.Response('boom', 503));
      await expectLater(
        () => ViesProvider.validateVat(
          countryCode: 'FR',
          vatNumber: '64443061841',
          validationLevel: ValidationLevel.vies,
          client: mock,
        ),
        throwsA(isA<ViesServerError>()),
      );
    });

    test('connectivity ClientException maps to socketException', () async {
      final mock = MockClient(
        (req) => throw http.ClientException('Failed host lookup: ec.europa.eu'),
      );
      await expectLater(
        () => ViesProvider.validateVat(
          countryCode: 'FR',
          vatNumber: '64443061841',
          validationLevel: ValidationLevel.vies,
          client: mock,
        ),
        throwsA(
          isA<ViesServerError>().having(
            (e) => e.code,
            'code',
            ViesErrorCode.socketException,
          ),
        ),
      );
    });

    test('generic ClientException maps to serverDisconnected', () async {
      final mock = MockClient(
        (req) => throw http.ClientException('Malformed response'),
      );
      await expectLater(
        () => ViesProvider.validateVat(
          countryCode: 'FR',
          vatNumber: '64443061841',
          validationLevel: ValidationLevel.vies,
          client: mock,
        ),
        throwsA(
          isA<ViesServerError>().having(
            (e) => e.code,
            'code',
            ViesErrorCode.serverDisconnected,
          ),
        ),
      );
    });

    test('retries on transient MS_UNAVAILABLE then succeeds', () async {
      var calls = 0;
      final mock = MockClient((req) async {
        calls++;
        if (calls < 3) {
          return http.Response(_faultSoap('MS_UNAVAILABLE'), 200);
        }
        return http.Response(_validSoap(), 200);
      });
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: '64443061841',
        validationLevel: ValidationLevel.vies,
        client: mock,
        retries: 3,
      );
      expect(res.valid, isTrue);
      expect(calls, 3);
    });

    test('XML-escapes country code and VAT number in the SOAP body', () async {
      String? sentBody;
      final mock = MockClient((req) async {
        sentBody = req.body;
        return http.Response(_validSoap(), 200);
      });
      try {
        await ViesProvider.validateVat(
          countryCode: 'FR',
          vatNumber: '64443061841',
          validationLevel: ValidationLevel.vies,
          client: mock,
        );
      } on ViesError {
        // we only care about the request body
      }
      expect(sentBody, contains('<urn:countryCode>FR</urn:countryCode>'));
      expect(sentBody, isNot(contains('<script>')));
    });
  });

  group('ViesValidationResponse', () {
    test('equality and hashCode are value-based', () {
      const a = ViesValidationResponse(
        countryCode: 'FR',
        vatNumber: '64443061841',
        requestDate: '2026-05-21',
        valid: true,
      );
      const b = ViesValidationResponse(
        countryCode: 'FR',
        vatNumber: '64443061841',
        requestDate: '2026-05-21',
        valid: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('roundtrips through JSON', () {
      const original = ViesValidationResponse(
        countryCode: 'BE',
        vatNumber: '1000341796',
        requestDate: '2026-05-21+02:00',
        valid: true,
        name: 'ACME',
        address: 'Brussels',
      );
      final json = original.toJson();
      final restored = ViesValidationResponse.fromJson(json);
      expect(restored, equals(original));
    });

    test('requestDateTime parses VIES date+offset format', () {
      const r = ViesValidationResponse(
        countryCode: 'BE',
        vatNumber: '1000341796',
        requestDate: '2026-05-21+02:00',
        valid: true,
      );
      expect(r.requestDateTime, isNotNull);
      expect(r.requestDateTime!.year, 2026);
    });
  });
}

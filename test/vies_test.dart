import 'package:test/test.dart';
import 'package:vies/vies.dart';

void main() {
  final viesProvider = ViesProvider();

  test('Get viesProvider instance class id', () {
    expect(viesProvider.classId.isNotEmpty, isTrue);
  });

  group('VAT Regex tests', () {
    test('Test Google France entity world regex validity', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: "64443061841",
        validationLevel: ValidationLevel.regex,
        regexType: RegexType.world,
      );
      expect(res.valid, isTrue);
    });
    test('Test Google France entity EU regex validity', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: "64443061841",
        validationLevel: ValidationLevel.regex,
        regexType: RegexType.eu,
      );
      expect(res.valid, isTrue);
    });
    test('Test an invalid VAT number World regex validity', () async {
      try {
        final res = await ViesProvider.validateVat(
          countryCode: 'FRG5',
          vatNumber: "12345",
          validationLevel: ValidationLevel.regex,
          regexType: RegexType.world,
        );
        expect(!res.valid, isTrue);
      } catch(e) {
        expect(e is ViesServerError, isTrue);
      }
    });
    test('Test an invalid VAT number EU regex validity', () async {
      try {
        final res = await ViesProvider.validateVat(
          countryCode: 'FF',
          vatNumber: "1234567",
          validationLevel: ValidationLevel.regex,
          regexType: RegexType.eu,
        );
        expect(!res.valid, isTrue);
      } catch(e) {
        expect(e is ViesServerError, isTrue);
      }
    });
  });

  group('Vies API tests', () {
    test('Get Google France entity infos from Vies', () async {
      try {
        final res = await ViesProvider.validateVat(
          countryCode: 'FR',
          vatNumber: "64443061841",
          validationLevel: ValidationLevel.vies,
        );
        print('''
        --------------------------\n
        Vies Response:\n
        --------------------------\n
        $res\n
        --------------------------\n
        ''');
        expect(res.valid, isTrue);
      } catch(e) {
        expect(e is! ViesServerError, isTrue);
      }
    });
    test('Get an invalid entity infos from Vies', () async {
      try {
        final res = await ViesProvider.validateVat(
          countryCode: 'FR',
          vatNumber: "123456789",
          validationLevel: ValidationLevel.vies,
        );
        print('''
        --------------------------\n
        Vies Response:\n
        --------------------------\n
        $res\n
        --------------------------\n
        ''');
        expect(!res.valid, isTrue);
      } catch(e) {
        expect(e is ViesServerError, isTrue);
      }
    });
  });

  group('All Regex and Vies tests', () {
    test('Get Google France entity infos from Vies', () async {
      try {
        final res = await ViesProvider.validateVat(
          countryCode: 'FR',
          vatNumber: "64443061841",
          validationLevel: ValidationLevel.all,
        );
        print('''
        --------------------------\n
        Vies Response:\n
        --------------------------\n
        $res\n
        --------------------------\n
        ''');
        expect(res.valid, isTrue);
      } catch(e) {
        expect(e is! ViesServerError, isTrue);
      }
    });
    test('Get an invalid entity infos from Vies', () async {
      try {
        final res = await ViesProvider.validateVat(
          countryCode: 'FRGF',
          vatNumber: "12345",
          validationLevel: ValidationLevel.all,
        );
        print('''
        --------------------------\n
        Vies Response:\n
        --------------------------\n
        $res\n
        --------------------------\n
        ''');
        expect(!res.valid, isTrue);
      } catch(e) {
        expect(e is ViesServerError, isTrue);
      }
    });
  });
}

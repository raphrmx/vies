import 'package:vies/vies.dart';

Future<void> main() async {
  // Check VAT Number validity and get relative informations
  try {
    final ViesValidationResponse res = await ViesProvider.validateVat(
      countryCode: 'BE',
      vatNumber: '1000341796',
      timeout: const Duration(seconds: 50),
      validationLevel: ValidationLevel.vies,
      // regexType: RegexType.world,
    );
    print('$res');
  } catch (e) {
    print('$e');
  }
}

import 'package:vies/vies.dart';

Future<void> main() async {
  // Check VAT Number validity and get relative informations
  try {
    final ViesValidationResponse res = await ViesProvider.validateVat(
      countryCode: 'BE',
      vatNumber: '0123456789',
      timeout: const Duration(seconds: 50),
    );
    print(res.toString());
  } catch (e) {
    print(e.toString());
  }
}

import 'dart:developer';

import 'package:vies/vies.dart';

Future<void> main() async {
  // Check VAT Number validity and get relative informations
  try {
    final ViesValidationResponse res = await ViesProvider.validateVat(
      countryCode: 'FR',
      vatNumber: '64443061841',
      timeout: const Duration(seconds: 50),
    );
    log('$res');
  } catch (e) {
    log('$e');
  }
}

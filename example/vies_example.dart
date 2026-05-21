// ignore_for_file: avoid_print

import 'package:vies/vies.dart';

Future<void> main() async {
  try {
    final response = await ViesProvider.validateVat(
      countryCode: 'BE',
      vatNumber: '1000341796',
      timeout: const Duration(seconds: 15),
      retries: 2,
    );
    print('Valid VAT for ${response.name}');
    print('Address: ${response.address}');
    print('Checked at: ${response.requestDateTime}');
  } on ViesClientError catch (e) {
    print('Client error [${e.code.wireName}]: ${e.message}');
  } on ViesServerError catch (e) {
    print('Server error [${e.code.wireName}]: ${e.message}');
  }
}

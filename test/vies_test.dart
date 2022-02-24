import 'package:test/test.dart';
import 'package:vies/vies.dart';

void main() {
  group('A group of Vies tests', () {
    final viesProvider = ViesProvider();
    test('First Test: Get viesProvider class id', () {
      expect(viesProvider.classId.isNotEmpty, isTrue);
    });

    test('Second Test: Get entity infos from Vies', () async {
      final res = await ViesProvider.validateVat(
          countryCode: 'BE', vatNumber: "0869703879");
      print(res.toString());
      expect(res.valid, isTrue);
    });
  });
}

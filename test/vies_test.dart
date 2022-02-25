import 'package:test/test.dart';
import 'package:vies/vies.dart';

void main() {
  group('A group of Vies tests', () {
    final viesProvider = ViesProvider();
    test('First Test: Get viesProvider class id', () {
      expect(viesProvider.classId.isNotEmpty, isTrue);
    });

    test('Second Test: Get Google France entity infos from Vies', () async {
      final res = await ViesProvider.validateVat(
        countryCode: 'FR',
        vatNumber: "64443061841",
      );
      print("--------------------------");
      print("Vies Response:");
      print("--------------------------");
      print(res.toString());
      print("--------------------------");
      expect(res.valid, isTrue);
    });
  });
}

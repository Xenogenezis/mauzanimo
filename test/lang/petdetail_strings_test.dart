import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/lang/strings_petdetail.dart';

void main() {
  test('petdetail strings have the same keys in en, fr and mfe', () {
    final en = petdetailStrings['en']!.keys.toSet();
    expect(en, isNotEmpty);
    for (final lang in ['fr', 'mfe']) {
      expect(petdetailStrings[lang]!.keys.toSet(), en, reason: lang);
      expect(petdetailStrings[lang]!.values.where((v) => v.trim().isEmpty),
          isEmpty);
    }
  });
}

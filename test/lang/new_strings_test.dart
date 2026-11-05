import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/screens/info/adoption_quiz_screen.dart';
import 'package:stray_pets_mu/screens/info/care_guide_screen.dart';

void main() {
  final keys = <String>[
    'quiz_title', 'quiz_subtitle', 'quiz_ready', 'quiz_almost', 'quiz_not_yet',
    for (var i = 1; i <= kQuizQuestionCount; i++) ...['quiz_q$i', 'quiz_tip$i'],
    'care_guide', 'care_intro', 'care_disclaimer',
    for (final (id, _, _) in kCareTopics) ...['care_${id}_title', 'care_${id}_body'],
    'filter_sort', 'sort_newest', 'age_young', 'male', 'female', 'no_pets_match',
  ];

  for (final lang in ['en', 'fr', 'mfe']) {
    test('quiz, guide and filter strings exist in $lang', () {
      final missing =
          keys.where((k) => AppStrings.translations[lang]![k] == null).toList();
      expect(missing, isEmpty);
    });
  }
}

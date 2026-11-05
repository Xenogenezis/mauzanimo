import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/lang/strings_adoption_tips.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/info/care_guide_screen.dart';
import 'package:stray_pets_mu/widgets/adoption_stage_tips.dart';

void main() {
  const langs = ['en', 'fr', 'mfe'];
  final widgetKeys = ['adopt_tips_title', 'adopt_tips_care_guide'];

  group('adoptionTipKeys', () {
    for (final stage in AdoptionStage.values) {
      test('${stage.name} has at least 2 unique tips', () {
        final keys = adoptionTipKeys(stage);
        expect(keys.length, greaterThanOrEqualTo(2));
        expect(keys.toSet().length, keys.length);
      });
    }

    for (final lang in langs) {
      test('every tip key exists in $lang', () {
        final allKeys = [
          ...widgetKeys,
          for (final stage in AdoptionStage.values) ...adoptionTipKeys(stage),
        ];
        final missing = allKeys
            .where((k) =>
                (adoptionTipsStrings[lang]?[k] ?? '').trim().isEmpty ||
                AppStrings.get(k, lang) == k)
            .toList();
        expect(missing, isEmpty);
      });
    }

    test('en, fr and mfe define the same keys', () {
      final en = adoptionTipsStrings['en']!.keys.toSet();
      expect(adoptionTipsStrings['fr']!.keys.toSet(), en);
      expect(adoptionTipsStrings['mfe']!.keys.toSet(), en);
    });
  });

  group('AdoptionStageTips widget', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget wrap(Widget child) => ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
              home: Scaffold(body: SingleChildScrollView(child: child))),
        );

    testWidgets('shows title and tips for the trial stage, expanded',
        (tester) async {
      await tester.pumpWidget(
          wrap(const AdoptionStageTips(stage: AdoptionStage.trial)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(
          find.text(AppStrings.get('adopt_tips_title', 'en')), findsOneWidget);
      for (final key in adoptionTipKeys(AdoptionStage.trial)) {
        expect(find.text(AppStrings.get(key, 'en')), findsOneWidget);
      }
      expect(find.text(AppStrings.get('adopt_tips_care_guide', 'en')),
          findsOneWidget);
    });

    testWidgets('collapses on tap and opens the care guide', (tester) async {
      await tester.pumpWidget(
          wrap(const AdoptionStageTips(stage: AdoptionStage.completed)));
      await tester.pumpAndSettle();

      final firstTip =
          AppStrings.get(adoptionTipKeys(AdoptionStage.completed).first, 'en');
      expect(find.text(firstTip), findsOneWidget);

      await tester.tap(find.text(AppStrings.get('adopt_tips_title', 'en')));
      await tester.pumpAndSettle();
      expect(find.text(firstTip), findsNothing);

      await tester.tap(find.text(AppStrings.get('adopt_tips_title', 'en')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.text(AppStrings.get('adopt_tips_care_guide', 'en')));
      await tester.pumpAndSettle();
      expect(find.byType(CareGuideScreen), findsOneWidget);
    });
  });
}

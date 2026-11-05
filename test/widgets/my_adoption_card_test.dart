import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/lang/strings_myadoptions.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/widgets/my_adoption_card.dart';

Adoption _a(String id, String name, DateTime createdAt,
        {AdoptionStage stage = AdoptionStage.application, String? reason}) =>
    Adoption(
      id: id,
      petId: 'pet_$id',
      petName: name,
      adopterId: 'u1',
      adopterName: 'A',
      adopterEmail: 'a@b.mu',
      adopterPhone: '123',
      currentStage: stage,
      createdAt: createdAt,
      rejectionReason: reason,
    );

void main() {
  group('myadoptionsStrings', () {
    test('en, fr and mfe define the same non-empty keys', () {
      final en = myadoptionsStrings['en']!.keys.toSet();
      expect(en, isNotEmpty);
      for (final lang in ['en', 'fr', 'mfe']) {
        expect(myadoptionsStrings[lang]!.keys.toSet(), en, reason: lang);
        for (final k in en) {
          expect(myadoptionsStrings[lang]![k]!.trim(), isNotEmpty,
              reason: '$lang/$k');
          expect(AppStrings.get(k, lang), myadoptionsStrings[lang]![k],
              reason: '$lang/$k');
        }
      }
    });
  });

  group('MyAdoptionsList', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget wrap(Widget child) => ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
          child: MaterialApp(home: Scaffold(body: child)),
        );

    String t(String k) => AppStrings.get(k, 'en');

    testWidgets('empty state shows a browse button', (tester) async {
      var browsed = 0;
      await tester.pumpWidget(wrap(MyAdoptionsList(
        adoptions: const [],
        onTap: (_) {},
        onBrowse: () => browsed++,
      )));
      await tester.pumpAndSettle();

      expect(find.text(t('my_adoptions_empty_title')), findsOneWidget);
      await tester.tap(find.text(t('my_adoptions_browse')));
      expect(browsed, 1);
    });

    testWidgets('groups, orders and shows stage chips; tap opens the item',
        (tester) async {
      Adoption? tapped;
      await tester.pumpWidget(wrap(MyAdoptionsList(
        adoptions: [
          _a('1', 'Rex', DateTime(2025, 1, 5), stage: AdoptionStage.completed),
          _a('2', 'Mimi', DateTime(2025, 3, 2), stage: AdoptionStage.screening),
          _a('3', 'Bobby', DateTime(2025, 4, 9),
              stage: AdoptionStage.rejected, reason: 'Moved abroad'),
        ],
        onTap: (a) => tapped = a,
        onBrowse: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text(t('my_adoptions_active')), findsOneWidget);
      expect(find.text(t('my_adoptions_closed')), findsOneWidget);
      expect(find.text(t('stage_screening')), findsOneWidget);
      expect(find.text(t('stage_completed')), findsOneWidget);
      expect(find.text(t('stage_rejected')), findsOneWidget);
      expect(find.text('Applied on 2/3/2025'), findsOneWidget);
      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('Reason: Moved abroad'), findsOneWidget);

      // Active first, then closed newest first: Mimi, Bobby, Rex.
      final mimiY = tester.getTopLeft(find.text('Mimi')).dy;
      final bobbyY = tester.getTopLeft(find.text('Bobby')).dy;
      final rexY = tester.getTopLeft(find.text('Rex')).dy;
      expect(mimiY < bobbyY && bobbyY < rexY, isTrue);

      await tester.tap(find.text('Mimi'));
      expect(tapped?.id, '2');
    });

    testWidgets('fits a narrow phone width without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrap(MyAdoptionsList(
        adoptions: [
          _a('1', 'A very long pet name that should be truncated nicely',
              DateTime(2025, 1, 5),
              stage: AdoptionStage.meet_greet),
        ],
        onTap: (_) {},
        onBrowse: () {},
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(t('stage_meet_greet')), findsOneWidget);
    });
  });
}

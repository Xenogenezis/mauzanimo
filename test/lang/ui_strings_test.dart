import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/lang/strings_ui.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/info/about_screen.dart';
import 'package:stray_pets_mu/utils/app_version.dart';

void main() {
  group('uiStrings', () {
    const langs = ['en', 'fr', 'mfe'];
    final allKeys = {for (final l in langs) ...uiStrings[l]!.keys};

    test('has en, fr and mfe maps', () {
      for (final l in langs) {
        expect(uiStrings[l], isNotNull, reason: 'missing $l');
      }
    });

    for (final lang in langs) {
      test('every key exists and is non-empty in $lang', () {
        final missing = allKeys
            .where((k) => (uiStrings[lang]![k] ?? '').trim().isEmpty)
            .toList();
        expect(missing, isEmpty);
      });
    }

    test('keys do not shadow or get shadowed by the main translations', () {
      for (final l in langs) {
        final clash = allKeys
            .where((k) => AppStrings.translations[l]!.containsKey(k))
            .toList();
        expect(clash, isEmpty, reason: 'clash in $l');
      }
    });

    test('placeholders are kept in every language', () {
      final placeholder = RegExp(r'\{\w+\}');
      for (final key in allKeys) {
        final expected = placeholder
            .allMatches(uiStrings['en']![key]!)
            .map((m) => m[0])
            .toSet();
        for (final l in langs) {
          final actual = placeholder
              .allMatches(uiStrings[l]![key]!)
              .map((m) => m[0])
              .toSet();
          expect(actual, expected, reason: '$key in $l');
        }
      }
    });
  });

  test('kAppVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pubspec);
    expect(match?.group(1), kAppVersion);
  });

  group('AboutScreen', () {
    Future<void> pumpAbout(WidgetTester tester, String lang,
        {ThemeData? theme}) async {
      SharedPreferences.setMockInitialValues({'language': lang});
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
          child: MaterialApp(theme: theme, home: const AboutScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders in French', (tester) async {
      await pumpAbout(tester, 'fr');

      expect(find.text(AppStrings.get('about_app', 'fr')), findsOneWidget);
      expect(find.text(AppStrings.get('our_mission', 'fr')), findsOneWidget);
      expect(find.text('Chaque animal compte'), findsOneWidget);
      expect(find.text('Communauté'), findsOneWidget);
      expect(find.textContaining('JCI'), findsNothing);
      expect(find.text('Version $kAppVersion'), findsOneWidget);
      expect(find.text('Our values'), findsNothing);
      expect(find.text('Every animal matters'), findsNothing);
    });

    testWidgets('renders in Kreol Morisien', (tester) async {
      await pumpAbout(tester, 'mfe');

      expect(find.text('Sak zanimo konte'), findsOneWidget);
      expect(find.text('Versyon $kAppVersion'), findsOneWidget);
    });

    testWidgets('defaults to English', (tester) async {
      await pumpAbout(tester, 'en');

      expect(find.text('About MauZanimo'), findsOneWidget);
      expect(find.text('Every animal matters'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('value tiles follow the dark colour scheme', (tester) async {
      final dark = ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal, brightness: Brightness.dark),
      );
      await pumpAbout(tester, 'en', theme: dark);

      final title = tester.widget<Text>(find.text('Compassion'));
      expect(title.style?.color, dark.colorScheme.onSurface);
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/lang/strings_report.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/utils/offline_write.dart';
import 'package:stray_pets_mu/widgets/report_button.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(Widget child) => ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(home: Scaffold(body: child)),
      );

  ButtonStyleButton submitButton(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('report-submit')));

  testWidgets('lists every reason and keeps submit disabled until one is chosen',
      (tester) async {
    final calls = <(String, String?)>[];
    await tester.pumpWidget(host(ReportSheet(onSubmit: (reason, details) async {
      calls.add((reason, details));
      return WriteOutcome.synced;
    })));
    await tester.pump();

    expect(find.text('Report this content'), findsOneWidget);
    for (final r in kReportReasons) {
      expect(find.byKey(ValueKey('report-reason-$r')), findsOneWidget);
    }
    expect(submitButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pump();
    expect(calls, isEmpty);

    await tester.tap(find.text('Scam or asking for money'));
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);

    await tester.enterText(
        find.byKey(const ValueKey('report-details')), '  wants a deposit  ');
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pump();
    expect(calls, [('scam', 'wants a deposit')]);
  });

  testWidgets('empty details are sent as null and the sheet pops with the outcome',
      (tester) async {
    WriteOutcome? result;
    String? sentDetails = 'unset';
    await tester.pumpWidget(host(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          result = await showModalBottomSheet<WriteOutcome>(
            context: context,
            isScrollControlled: true,
            builder: (_) => ReportSheet(onSubmit: (reason, details) async {
              sentDetails = details;
              return WriteOutcome.queued;
            }),
          );
        },
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-reason-animal_welfare')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pumpAndSettle();

    expect(sentDetails, isNull);
    expect(result, WriteOutcome.queued);
    expect(find.byType(ReportSheet), findsNothing);
  });

  testWidgets('a failed submit keeps the sheet open and shows an error',
      (tester) async {
    await tester.pumpWidget(host(ReportSheet(
        onSubmit: (_, __) async => throw Exception('permission-denied'))));
    await tester.tap(find.byKey(const ValueKey('report-reason-spam')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pump();

    expect(find.text('Could not send the report. Please try again.'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('uses the selected language', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'fr'});
    await tester.pumpWidget(
        host(ReportSheet(onSubmit: (_, __) async => WriteOutcome.synced)));
    await tester.pump();
    expect(find.text('Signaler ce contenu'), findsOneWidget);
  });

  group('buildReportData', () {
    test('has exactly the fields the rules allow', () {
      final data = buildReportData(
        reporterId: 'u1',
        targetCollection: 'pets',
        targetId: 'p1',
        reason: 'spam',
        details: ' hi ',
      );
      expect(data.keys.toSet(), {
        'reporterId', 'targetCollection', 'targetId', 'reason', 'details',
        'status', 'createdAt',
      });
      expect(data['status'], 'open');
      expect(data['details'], 'hi');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('omits empty details and truncates long ones', () {
      Map<String, dynamic> build(String? d) => buildReportData(
          reporterId: 'u1', targetCollection: 'stories', targetId: 's',
          reason: 'other', details: d);
      expect(build(null).containsKey('details'), isFalse);
      expect(build('   ').containsKey('details'), isFalse);
      expect((build('x' * 1500)['details'] as String).length,
          kReportDetailsMaxLength);
    });
  });

  test('ReportedTargets remembers per user and target', () {
    ReportedTargets.clear();
    ReportedTargets.add('u1', 'pets', 'p1');
    expect(ReportedTargets.contains('u1', 'pets', 'p1'), isTrue);
    expect(ReportedTargets.contains('u2', 'pets', 'p1'), isFalse);
    expect(ReportedTargets.contains('u1', 'stories', 'p1'), isFalse);
    ReportedTargets.clear();
  });

  test('report strings have the same non-empty keys in en, fr and mfe', () {
    final en = reportStrings['en']!.keys.toSet();
    for (final r in kReportReasons) {
      expect(en, contains('report_reason_$r'));
    }
    for (final lang in ['fr', 'mfe']) {
      expect(reportStrings[lang]!.keys.toSet(), en, reason: lang);
      expect(reportStrings[lang]!.values.where((v) => v.trim().isEmpty), isEmpty);
    }
  });
}

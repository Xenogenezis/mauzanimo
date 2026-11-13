import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/lang/strings_ui.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/admin/add_event_screen.dart';
import 'package:stray_pets_mu/utils/event_calendar.dart';

void main() {
  test('formatEventDate is zero-padded ISO so events sort by date', () {
    expect(formatEventDate(DateTime(2026, 3, 7)), '2026-03-07');
    expect(formatEventDate(DateTime(2026, 12, 12)), '2026-12-12');
    expect(formatEventDate(DateTime(2026, 3, 7)).compareTo(formatEventDate(DateTime(2026, 12, 1))), lessThan(0));
  });

  test('formatEventTime covers all-day, start only and a range', () {
    expect(formatEventTime(null, null), '');
    expect(formatEventTime(const TimeOfDay(hour: 9, minute: 0), null), '09:00');
    expect(
      formatEventTime(const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 13, minute: 30)),
      '09:00 - 13:30',
    );
  });

  test('the stored date and time are readable by the calendar export', () {
    final event = CalendarEvent.fromEventData({
      'title': 'Adoption day',
      'date': formatEventDate(DateTime(2026, 12, 12)),
      'time': formatEventTime(const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 13, minute: 0)),
    }, id: 'e1');
    expect(event, isNotNull);
    expect(event!.allDay, isFalse);
    expect(event.end.difference(event.start), const Duration(hours: 4));
  });

  testWidgets('shows the form and refuses to save without title, date and location', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(home: AddEventScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New event'), findsOneWidget);
    expect(find.text('Event title'), findsOneWidget);
    expect(find.byKey(const ValueKey('event-date')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-start')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-end')), findsOneWidget);

    final save = find.byKey(const ValueKey('event-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Please enter a title, a date and a location'), findsOneWidget);
  });

  testWidgets('the date field opens a date picker and shows the chosen day', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(home: AddEventScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('event-date')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final shown = MaterialLocalizations.of(tester.element(find.byType(AddEventScreen))).formatMediumDate(today);
    expect(find.text(shown), findsOneWidget);
  });

  test('add-event strings exist in en, fr and mfe', () {
    final keys = uiStrings['en']!.keys.where((k) => k.startsWith('ui_event_')).toSet();
    expect(keys, isNotEmpty);
    for (final lang in ['fr', 'mfe']) {
      for (final k in keys) {
        expect(uiStrings[lang]![k], isNotEmpty, reason: '$lang is missing $k');
      }
    }
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/event_calendar.dart';

void main() {
  group('escapeIcsText', () {
    test('escapes commas, semicolons, backslashes and newlines', () {
      expect(escapeIcsText(r'a,b;c\d'), r'a\,b\;c\\d');
      expect(escapeIcsText('line1\nline2\r\nline3\rline4'),
          r'line1\nline2\nline3\nline4');
    });
  });

  group('parseEventDate', () {
    test('ISO, day-first numeric and month names', () {
      expect(parseEventDate('2026-12-12'), DateTime.utc(2026, 12, 12));
      expect(parseEventDate('5/12/2026'), DateTime.utc(2026, 12, 5));
      expect(parseEventDate('05.12.2026'), DateTime.utc(2026, 12, 5));
      expect(parseEventDate('12 December 2026'), DateTime.utc(2026, 12, 12));
      expect(parseEventDate('Samedi 7 juillet 2026'), DateTime.utc(2026, 7, 7));
      expect(parseEventDate('3 juin 2026'), DateTime.utc(2026, 6, 3));
      expect(parseEventDate('14 février 2026'), DateTime.utc(2026, 2, 14));
      expect(parseEventDate('December 12, 2026'), DateTime.utc(2026, 12, 12));
    });

    test('rejects unreadable or impossible dates', () {
      expect(parseEventDate(''), isNull);
      expect(parseEventDate('soon'), isNull);
      expect(parseEventDate('2026-02-31'), isNull);
      expect(parseEventDate(null), isNull);
      expect(parseEventDate(42), isNull);
    });

    test('DateTime and Timestamp-like values', () {
      expect(parseEventDate(DateTime(2026, 3, 4, 15)), DateTime.utc(2026, 3, 4));
      // 22:00 UTC on 3 March is already 4 March in Mauritius.
      expect(parseEventDate(_FakeTimestamp(DateTime.utc(2026, 3, 3, 22))),
          DateTime.utc(2026, 3, 4));
    });
  });

  group('parseTimes', () {
    test('24h ranges, am/pm and French h notation', () {
      expect(parseTimes('09:00 - 13:00'),
          [const Duration(hours: 9), const Duration(hours: 13)]);
      expect(parseTimes('9am-1pm'),
          [const Duration(hours: 9), const Duration(hours: 13)]);
      expect(parseTimes('14h30'), [const Duration(hours: 14, minutes: 30)]);
      expect(parseTimes('12pm'), [const Duration(hours: 12)]);
      expect(parseTimes('12am'), [Duration.zero]);
    });
    test('ignores bare numbers and invalid times', () {
      expect(parseTimes('all day'), isEmpty);
      expect(parseTimes('Stand 12'), isEmpty);
      expect(parseTimes('25:00'), isEmpty);
    });
  });

  group('CalendarEvent.fromEventData', () {
    test('converts Mauritius local time to UTC', () {
      final e = CalendarEvent.fromEventData({
        'title': 'Adoption Day',
        'date': '2026-12-12',
        'time': '09:00 - 13:00',
        'location': 'Grand Baie',
      }, id: 'ev1')!;
      expect(e.allDay, isFalse);
      expect(e.start, DateTime.utc(2026, 12, 12, 5));
      expect(e.end, DateTime.utc(2026, 12, 12, 9));
      expect(e.uid, 'ev1@mauzanimo');
    });

    test('defaults to 2 hours without an end time', () {
      final e = CalendarEvent.fromEventData(
          {'title': 'x', 'date': '2026-12-12', 'time': '10:00'}, id: 'a')!;
      expect(e.end.difference(e.start), const Duration(hours: 2));
    });

    test('time inside the date text', () {
      final e = CalendarEvent.fromEventData(
          {'title': 'x', 'date': '2026-12-12 10:30'}, id: 'a')!;
      expect(e.start, DateTime.utc(2026, 12, 12, 6, 30));
    });

    test('ends after midnight', () {
      final e = CalendarEvent.fromEventData(
          {'title': 'x', 'date': '2026-12-12', 'time': '20:00 - 01:00'},
          id: 'a')!;
      expect(e.end.difference(e.start), const Duration(hours: 5));
    });

    test('no time gives an all-day event', () {
      final e = CalendarEvent.fromEventData(
          {'title': 'x', 'date': '12/12/2026', 'time': ''}, id: 'a')!;
      expect(e.allDay, isTrue);
      expect(e.start, DateTime.utc(2026, 12, 12));
      expect(e.end, DateTime.utc(2026, 12, 13));
    });

    test('unreadable date gives null', () {
      expect(CalendarEvent.fromEventData({'date': 'TBC'}, id: 'a'), isNull);
    });
  });

  group('buildIcs', () {
    final event = CalendarEvent(
      uid: 'ev1@mauzanimo',
      title: 'Adoption Day, Grand Baie; free',
      description: 'Bring a leash.\nMeet our dogs, cats & more!',
      location: 'Sunset Blvd, Grand Baie',
      start: DateTime.utc(2026, 12, 12, 5),
      end: DateTime.utc(2026, 12, 12, 9),
    );
    final ics = buildIcs(event, now: DateTime.utc(2026, 11, 5, 8, 30, 15));

    test('uses CRLF line endings everywhere', () {
      expect(ics.endsWith('\r\n'), isTrue);
      expect(ics.replaceAll('\r\n', '').contains('\n'), isFalse);
      expect(ics.replaceAll('\r\n', '').contains('\r'), isFalse);
    });

    test('has the required structure and UTC times', () {
      final lines = ics.split('\r\n');
      expect(lines.first, 'BEGIN:VCALENDAR');
      expect(lines, contains('VERSION:2.0'));
      expect(lines, contains('BEGIN:VEVENT'));
      expect(lines, contains('END:VEVENT'));
      expect(lines, contains('DTSTART:20261212T050000Z'));
      expect(lines, contains('DTEND:20261212T090000Z'));
      expect(lines, contains('DTSTAMP:20261105T083015Z'));
      expect(lines, contains('UID:ev1@mauzanimo'));
      expect(lines[lines.length - 2], 'END:VCALENDAR');
    });

    test('escapes text values', () {
      final unfolded = ics.replaceAll('\r\n ', '');
      expect(unfolded, contains(r'SUMMARY:Adoption Day\, Grand Baie\; free'));
      expect(unfolded,
          contains(r'DESCRIPTION:Bring a leash.\nMeet our dogs\, cats & more!'));
      expect(unfolded, contains(r'LOCATION:Sunset Blvd\, Grand Baie'));
    });

    test('all-day events use DATE values', () {
      final allDay = buildIcs(
          CalendarEvent(
            uid: 'u',
            title: 't',
            start: DateTime.utc(2026, 12, 12),
            end: DateTime.utc(2026, 12, 13),
            allDay: true,
          ),
          now: DateTime.utc(2026));
      expect(allDay, contains('DTSTART;VALUE=DATE:20261212\r\n'));
      expect(allDay, contains('DTEND;VALUE=DATE:20261213\r\n'));
      expect(allDay.contains('DESCRIPTION'), isFalse);
    });

    test('folds long lines at 75 octets without splitting characters', () {
      final long = buildIcs(
          CalendarEvent(
            uid: 'u',
            title: 'é' * 100,
            start: DateTime.utc(2026),
            end: DateTime.utc(2026, 1, 2),
          ),
          now: DateTime.utc(2026));
      for (final line in long.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
      expect(long.replaceAll('\r\n ', ''), contains('SUMMARY:${'é' * 100}'));
    });
  });

  test('googleCalendarUrl', () {
    final url = googleCalendarUrl(CalendarEvent(
      uid: 'u',
      title: 'Adoption Day & more',
      description: 'Line 1\nLine 2',
      location: 'Grand Baie',
      start: DateTime.utc(2026, 12, 12, 5),
      end: DateTime.utc(2026, 12, 12, 9),
    ));
    final s = url.toString();
    expect(s, startsWith('https://calendar.google.com/calendar/render?action=TEMPLATE'));
    expect(s, contains('dates=20261212T050000Z/20261212T090000Z'));
    expect(url.queryParameters['text'], 'Adoption Day & more');
    expect(url.queryParameters['details'], 'Line 1\nLine 2');
    expect(url.queryParameters['location'], 'Grand Baie');
  });

  test('icsFileName', () {
    expect(icsFileName('Adoption Day: Grand Baie!'), 'adoption-day-grand-baie.ics');
    expect(icsFileName('***'), 'event.ics');
  });
}

class _FakeTimestamp {
  final DateTime _d;
  _FakeTimestamp(this._d);
  DateTime toDate() => _d;
}

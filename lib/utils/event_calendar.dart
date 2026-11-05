import 'dart:convert';

/// Mauritius time is UTC+4 all year (no daylight saving). Event dates and
/// times in Firestore are free text in local time.
const Duration mauritiusUtcOffset = Duration(hours: 4);

/// Used when an event has a start time but no end time.
const Duration defaultEventDuration = Duration(hours: 2);

/// An event ready for a calendar. For timed events [start] and [end] are
/// UTC instants; for all-day events they are dates (end exclusive).
class CalendarEvent {
  final String uid;
  final String title;
  final String description;
  final String location;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  const CalendarEvent({
    required this.uid,
    required this.title,
    this.description = '',
    this.location = '',
    required this.start,
    required this.end,
    this.allDay = false,
  });

  /// Builds a calendar event from an `events` document. Reads `title`,
  /// `description`, `location`, `date` (text such as "2026-12-12",
  /// "12/12/2026", "12 December 2026", or a Timestamp/DateTime) and
  /// `time` (such as "09:00 - 13:00", "9am-1pm", "14h30"). No time gives
  /// an all-day event; no end time gives [defaultEventDuration].
  /// Returns null when the date cannot be read.
  static CalendarEvent? fromEventData(Map<String, dynamic> data,
      {required String id}) {
    final rawDate = data['date'];
    final date = parseEventDate(rawDate);
    if (date == null) return null;

    var timeText = (data['time'] ?? '').toString();
    if (timeText.trim().isEmpty && rawDate is String) {
      // e.g. "2026-12-12 10:00": look for a time after the date.
      timeText = rawDate.replaceFirst(_isoDate, '').replaceFirst(_dmyDate, '');
    }
    final times = parseTimes(timeText);

    final title = (data['title'] ?? '').toString().trim();
    final common = (
      uid: '$id@mauzanimo',
      title: title.isEmpty ? 'MauZanimo event' : title,
      description: (data['description'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
    );

    if (times.isEmpty) {
      return CalendarEvent(
        uid: common.uid,
        title: common.title,
        description: common.description,
        location: common.location,
        start: DateTime.utc(date.year, date.month, date.day),
        end: DateTime.utc(date.year, date.month, date.day + 1),
        allDay: true,
      );
    }

    DateTime toUtc(Duration t) =>
        DateTime.utc(date.year, date.month, date.day)
            .add(t)
            .subtract(mauritiusUtcOffset);
    final start = toUtc(times.first);
    var end = times.length > 1 ? toUtc(times[1]) : start.add(defaultEventDuration);
    if (!end.isAfter(start)) {
      // "20:00 - 01:00" ends after midnight; anything else odd gets 2h.
      final nextDay = end.add(const Duration(days: 1));
      end = times.length > 1 && nextDay.difference(start) <= const Duration(hours: 12)
          ? nextDay
          : start.add(defaultEventDuration);
    }
    return CalendarEvent(
      uid: common.uid,
      title: common.title,
      description: common.description,
      location: common.location,
      start: start,
      end: end,
    );
  }
}

final _isoDate = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
final _dmyDate = RegExp(r'(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})');
final _textDate =
    RegExp(r'(\d{1,2})(?:st|nd|rd|th|er)?\s+([a-zéû]+)\.?,?\s+(\d{4})');
final _textDateUs =
    RegExp(r'([a-zéû]+)\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})');

const _monthPrefixes = <String, int>{
  'jan': 1, 'janv': 1, 'feb': 2, 'fev': 2, 'fév': 2, 'mar': 3, 'apr': 4,
  'avr': 4, 'may': 5, 'mai': 5, 'jun': 6, 'juin': 6, 'jul': 7, 'juil': 7,
  'aug': 8, 'aou': 8, 'aoû': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  'déc': 12,
};

int? _monthOf(String word) {
  final w = word.toLowerCase();
  // Longest prefix first so "juil" (July) wins over "jui".
  for (final len in [4, 3]) {
    if (w.length >= len) {
      final m = _monthPrefixes[w.substring(0, len)];
      if (m != null) return m;
    }
  }
  return null;
}

DateTime? _validDate(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime.utc(y, m, d);
  return dt.month == m ? dt : null; // rejects 31 February etc.
}

/// Reads the event's calendar date (as a UTC midnight) from free text,
/// a [DateTime] or a Firestore Timestamp (anything with `toDate()`).
/// Numeric dates are read day-first, as written in Mauritius.
DateTime? parseEventDate(Object? raw) {
  if (raw == null) return null;
  DateTime? instant;
  if (raw is DateTime) {
    instant = raw;
  } else if (raw is! String) {
    try {
      final d = (raw as dynamic).toDate();
      if (d is DateTime) instant = d;
    } catch (_) {
      return null;
    }
  }
  if (instant != null) {
    final local = instant.isUtc ? instant.add(mauritiusUtcOffset) : instant;
    return DateTime.utc(local.year, local.month, local.day);
  }
  if (raw is! String) return null;
  final text = raw.toLowerCase().trim();
  var m = _isoDate.firstMatch(text);
  if (m != null) {
    return _validDate(
        int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }
  m = _dmyDate.firstMatch(text);
  if (m != null) {
    return _validDate(
        int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  }
  m = _textDate.firstMatch(text);
  if (m != null) {
    final month = _monthOf(m[2]!);
    if (month != null) {
      return _validDate(int.parse(m[3]!), month, int.parse(m[1]!));
    }
  }
  m = _textDateUs.firstMatch(text);
  if (m != null) {
    final month = _monthOf(m[1]!);
    if (month != null) {
      return _validDate(int.parse(m[3]!), month, int.parse(m[2]!));
    }
  }
  return null;
}

final _time = RegExp(
    r'(\d{1,2})\s*(?:([:hH.])\s*(\d{2})?)?\s*(a\.?m\.?|p\.?m\.?)?',
    caseSensitive: false);

/// Times of day found in [text] (for example "09:00 - 13:00", "9am-1pm",
/// "14h30"), as offsets from midnight. A bare number without minutes or
/// am/pm is ignored.
List<Duration> parseTimes(String text) {
  final out = <Duration>[];
  for (final m in _time.allMatches(text)) {
    final sep = m[2];
    final ampm = m[4]?.toLowerCase();
    if (sep == null && ampm == null) continue;
    if (sep == '.' && m[3] == null) continue;
    var h = int.parse(m[1]!);
    final min = int.tryParse(m[3] ?? '') ?? 0;
    if (ampm != null) {
      if (h < 1 || h > 12) continue;
      final pm = ampm.startsWith('p');
      if (h == 12) h = 0;
      if (pm) h += 12;
    }
    if (h > 23 || min > 59) continue;
    out.add(Duration(hours: h, minutes: min));
  }
  return out;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `YYYYMMDD` for a date.
String formatIcsDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';

/// `YYYYMMDDTHHMMSSZ` for an instant (converted to UTC).
String formatIcsUtc(DateTime t) {
  final u = t.toUtc();
  return '${formatIcsDate(u)}T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
}

/// Escapes a TEXT value (RFC 5545 §3.3.11): backslash, semicolon, comma
/// and line breaks.
String escapeIcsText(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\r\n', r'\n')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\n');

/// Folds a content line to at most 75 octets per line (RFC 5545 §3.1),
/// never splitting a UTF-8 character. Continuation lines start with a space.
String foldIcsLine(String line) {
  const limit = 75;
  if (utf8.encode(line).length <= limit) return line;
  final out = StringBuffer();
  var used = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final size = utf8.encode(ch).length;
    if (used + size > limit) {
      out.write('\r\n ');
      used = 1; // the leading space
    }
    out.write(ch);
    used += size;
  }
  return out.toString();
}

/// Builds an RFC 5545 VCALENDAR with one VEVENT, CRLF line endings.
/// [now] is the DTSTAMP (defaults to the current time).
String buildIcs(CalendarEvent e, {DateTime? now}) {
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//JCI Grand Baie//MauZanimo//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    'UID:${escapeIcsText(e.uid)}',
    'DTSTAMP:${formatIcsUtc(now ?? DateTime.now())}',
    if (e.allDay) ...[
      'DTSTART;VALUE=DATE:${formatIcsDate(e.start)}',
      'DTEND;VALUE=DATE:${formatIcsDate(e.end)}',
    ] else ...[
      'DTSTART:${formatIcsUtc(e.start)}',
      'DTEND:${formatIcsUtc(e.end)}',
    ],
    'SUMMARY:${escapeIcsText(e.title)}',
    if (e.description.trim().isNotEmpty)
      'DESCRIPTION:${escapeIcsText(e.description)}',
    if (e.location.trim().isNotEmpty) 'LOCATION:${escapeIcsText(e.location)}',
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  return '${lines.map(foldIcsLine).join('\r\n')}\r\n';
}

/// Google Calendar "add event" link for [e].
Uri googleCalendarUrl(CalendarEvent e) {
  final dates = e.allDay
      ? '${formatIcsDate(e.start)}/${formatIcsDate(e.end)}'
      : '${formatIcsUtc(e.start)}/${formatIcsUtc(e.end)}';
  String enc(String v) => Uri.encodeQueryComponent(v);
  return Uri.parse('https://calendar.google.com/calendar/render'
      '?action=TEMPLATE'
      '&text=${enc(e.title)}'
      '&dates=$dates'
      '&details=${enc(e.description)}'
      '&location=${enc(e.location)}');
}

/// A safe file name such as `adoption-day.ics`.
String icsFileName(String title) {
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final short = slug.length > 40 ? slug.substring(0, 40) : slug;
  return '${short.isEmpty ? 'event' : short}.ics';
}

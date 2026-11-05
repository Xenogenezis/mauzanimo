import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'event_calendar.dart';
import 'file_download.dart';

/// What [exportIcs] did with the file.
enum IcsExportResult { shared, downloaded }

/// Opens Google Calendar's "add event" page for [event].
Future<bool> openGoogleCalendar(CalendarEvent event) =>
    launchUrl(googleCalendarUrl(event), mode: LaunchMode.externalApplication);

/// Downloads (web) or shares (mobile/desktop) an .ics file for [event],
/// following the poster export pattern. Throws if sharing fails.
Future<IcsExportResult> exportIcs(CalendarEvent event,
    {Rect? shareOrigin}) async {
  final fileName = icsFileName(event.title);
  final bytes = Uint8List.fromList(utf8.encode(buildIcs(event)));
  const mime = 'text/calendar';
  if (kIsWeb) {
    await downloadBytes(fileName, bytes, mimeType: mime);
    return IcsExportResult.downloaded;
  }
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(bytes, mimeType: mime, name: fileName)],
    fileNameOverrides: [fileName],
    subject: event.title,
    sharePositionOrigin: shareOrigin,
  ));
  return IcsExportResult.shared;
}

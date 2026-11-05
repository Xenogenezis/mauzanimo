import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'file_download.dart';

/// What [shareJsonExport] did with the file.
enum DataExportResult { shared, downloaded }

/// Downloads [json] as [fileName] on the web, or opens the share sheet on
/// mobile/desktop (same pattern as `exportPoster`).
Future<DataExportResult> shareJsonExport({
  required String json,
  required String fileName,
  String? shareText,
  Rect? shareOrigin,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(json));
  if (kIsWeb) {
    await downloadBytes(fileName, bytes, mimeType: 'application/json');
    return DataExportResult.downloaded;
  }
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(bytes, mimeType: 'application/json', name: fileName)],
    fileNameOverrides: [fileName],
    text: shareText,
    sharePositionOrigin: shareOrigin,
  ));
  return DataExportResult.shared;
}

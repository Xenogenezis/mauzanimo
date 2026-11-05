import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'file_download.dart';

/// What [exportPoster] did with the image.
enum PosterExportResult { shared, downloaded }

/// Renders the [RepaintBoundary] behind [boundaryKey] to PNG bytes.
Future<Uint8List> capturePosterPng(GlobalKey boundaryKey,
    {double pixelRatio = 3}) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('PNG encoding failed');
    return byteData.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// The on-screen rect of [context], used to anchor iPad share sheets.
/// Read it before any `await`.
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box != null && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
}

/// Captures the poster behind [boundaryKey] and either downloads it (web) or
/// opens the platform share sheet with [shareText] (mobile/desktop).
/// Throws if capturing or sharing fails.
Future<PosterExportResult> exportPoster({
  required GlobalKey boundaryKey,
  required String fileName,
  required String shareText,
  Rect? shareOrigin,
}) async {
  final bytes = await capturePosterPng(boundaryKey);
  if (kIsWeb) {
    await downloadBytes(fileName, bytes, mimeType: 'image/png');
    return PosterExportResult.downloaded;
  }
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
    fileNameOverrides: [fileName],
    text: shareText,
    sharePositionOrigin: shareOrigin,
  ));
  return PosterExportResult.shared;
}

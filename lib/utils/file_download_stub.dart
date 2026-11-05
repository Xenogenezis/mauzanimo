import 'dart:typed_data';

/// Non-web fallback: mobile/desktop builds share files with share_plus instead.
Future<void> downloadBytes(
  String filename,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) async {
  throw UnsupportedError('File download is only available on the web.');
}

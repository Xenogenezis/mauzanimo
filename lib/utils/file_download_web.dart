import 'dart:js_interop';
import 'dart:typed_data';

// `web` comes in transitively via Flutter's web plugins (as in admin_web).
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

/// Triggers a browser download of [bytes] as [filename].
Future<void> downloadBytes(
  String filename,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}

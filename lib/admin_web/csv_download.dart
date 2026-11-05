export 'csv_download_stub.dart' if (dart.library.js_interop) 'csv_download_web.dart';

/// Escape a value for CSV (RFC 4180).
String csvCell(Object? v) {
  final s = v?.toString() ?? '';
  if (s.contains(RegExp(r'[",\n\r]'))) return '"${s.replaceAll('"', '""')}"';
  return s;
}

String toCsv(List<String> header, Iterable<List<Object?>> rows) {
  final b = StringBuffer()..writeln(header.map(csvCell).join(','));
  for (final r in rows) {
    b.writeln(r.map(csvCell).join(','));
  }
  return b.toString();
}

/// Non-web fallback: the admin panel is a web build, so this is unused.
Future<void> downloadTextFile(String filename, String content) async {
  throw UnsupportedError('CSV download is only available in the web admin.');
}

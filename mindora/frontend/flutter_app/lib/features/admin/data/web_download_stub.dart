/// Non-web stub for browser file downloads.
void triggerWebDownload(List<int> bytes, String fileName, String mimeType) {
  throw UnsupportedError('Web download is only supported on Flutter Web.');
}

abstract interface class ClipboardRepository {
  Future<void> copyText(String text);
}

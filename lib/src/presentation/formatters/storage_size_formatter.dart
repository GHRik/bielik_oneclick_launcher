class StorageSizeFormatter {
  static String format(int bytes) {
    if (bytes < 1000) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1000;
    var unit = 0;
    while (value >= 999.95 && unit < units.length - 1) {
      value /= 1000;
      unit++;
    }
    return '${value.toStringAsFixed(1).replaceAll('.', ',')} ${units[unit]}';
  }
}

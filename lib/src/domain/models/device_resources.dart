class DeviceResources {
  const DeviceResources({
    this.totalRamBytes,
    this.availableRamBytes,
    this.freeStorageBytes,
  });

  final int? totalRamBytes;
  final int? availableRamBytes;
  final int? freeStorageBytes;

  double? get totalRamGb => _gb(totalRamBytes);
  double? get availableRamGb => _gb(availableRamBytes);
  double? get freeStorageGb => _gb(freeStorageBytes);

  static double? _gb(int? bytes) =>
      bytes == null || bytes < 0 ? null : bytes / 1000000000;
}

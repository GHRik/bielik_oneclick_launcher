class AppExitReport {
  const AppExitReport({
    required this.id,
    required this.lowMemory,
    required this.code,
  });

  final String id;
  final bool lowMemory;
  final String code;
}

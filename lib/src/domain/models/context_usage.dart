class ContextUsage {
  const ContextUsage({
    required this.promptTokens,
    required this.contextSize,
    this.responseTokens = 0,
    this.omittedMessageIds = const [],
    this.omittedAttachmentNames = const [],
  });

  final int promptTokens;
  final int responseTokens;
  final int contextSize;
  final List<String> omittedMessageIds;
  final List<String> omittedAttachmentNames;

  bool get hasOmittedHistory => omittedMessageIds.isNotEmpty;

  int get usedTokens => promptTokens + responseTokens;
  double get fraction =>
      contextSize > 0 ? (usedTokens / contextSize).clamp(0.0, 1.0) : 0;
  int get percent => (fraction * 100).round();
}

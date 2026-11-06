class LlmConfiguration {
  const LlmConfiguration({
    required this.contextSize,
    required this.responseTokens,
    required this.safetyTokens,
    required this.numberOfThreads,
    required this.batchSize,
    required this.useGpu,
    required this.gpuLayers,
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.minP,
    required this.repeatPenalty,
    this.seed,
  }) : assert(contextSize > responseTokens + safetyTokens),
       assert(responseTokens > 0),
       assert(safetyTokens >= 0),
       assert(numberOfThreads > 0),
       assert(batchSize > 0),
       assert(!useGpu || gpuLayers > 0),
       assert(temperature >= 0),
       assert(topK >= 0),
       assert(topP > 0 && topP <= 1),
       assert(minP >= 0 && minP <= 1),
       assert(repeatPenalty > 0);

  final int contextSize;
  final int responseTokens;
  final int safetyTokens;
  final int numberOfThreads;
  final int batchSize;
  final bool useGpu;
  final int gpuLayers;
  final double temperature;
  final int topK;
  final double topP;
  final double minP;
  final double repeatPenalty;
  final int? seed;

  LlmConfiguration copyWith({
    int? contextSize,
    int? responseTokens,
    int? safetyTokens,
    int? numberOfThreads,
    int? batchSize,
    bool? useGpu,
    int? gpuLayers,
    double? temperature,
    int? topK,
    double? topP,
    double? minP,
    double? repeatPenalty,
    int? seed,
  }) => LlmConfiguration(
    contextSize: contextSize ?? this.contextSize,
    responseTokens: responseTokens ?? this.responseTokens,
    safetyTokens: safetyTokens ?? this.safetyTokens,
    numberOfThreads: numberOfThreads ?? this.numberOfThreads,
    batchSize: batchSize ?? this.batchSize,
    useGpu: useGpu ?? this.useGpu,
    gpuLayers: gpuLayers ?? this.gpuLayers,
    temperature: temperature ?? this.temperature,
    topK: topK ?? this.topK,
    topP: topP ?? this.topP,
    minP: minP ?? this.minP,
    repeatPenalty: repeatPenalty ?? this.repeatPenalty,
    seed: seed ?? this.seed,
  );
}

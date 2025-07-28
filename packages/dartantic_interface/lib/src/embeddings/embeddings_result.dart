import '../model/model.dart';

/// Result returned by embeddings providers.
class EmbeddingsResult extends LanguageModelResult<List<double>> {
  /// Creates a new embeddings result instance.
  EmbeddingsResult({
    required super.output,
    required super.finishReason,
    required super.metadata,
    required super.usage,
    super.id,
  });

  /// The embedding vectors.
  List<double> get embeddings => output;

  @override
  String toString() =>
      '''
EmbeddingsResult{
  id: $id, 
  embeddings: ${output.length} dimensions,
  finishReason: $finishReason,
  metadata: $metadata,
  usage: $usage,
}''';
}

/// Result for batch embeddings operations.
class BatchEmbeddingsResult extends LanguageModelResult<List<List<double>>> {
  /// Creates a new batch embeddings result instance.
  BatchEmbeddingsResult({
    required super.output,
    required super.finishReason,
    required super.metadata,
    required super.usage,
    super.id,
  });

  /// The batch of embedding vectors.
  List<List<double>> get embeddings => output;

  /// Number of embeddings in the batch.
  int get count => output.length;

  /// Dimensions of each embedding vector.
  int get dimensions => output.isNotEmpty ? output.first.length : 0;

  @override
  String toString() =>
      '''
BatchEmbeddingsResult{
  id: $id, 
  embeddings: ${output.length} vectors x $dimensions dimensions,
  finishReason: $finishReason,
  metadata: $metadata,
  usage: $usage,
}''';
}

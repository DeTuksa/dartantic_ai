import 'dart:math';

import 'embeddings_model_options.dart';
import 'embeddings_result.dart';

/// Embeddings model base class.
abstract class EmbeddingsModel<TOptions extends EmbeddingsModelOptions> {
  /// Creates a new embeddings model instance.
  EmbeddingsModel({
    required this.name,
    required this.defaultOptions,
    this.dimensions,
    this.batchSize,
  });

  /// The default options for the embeddings model.
  final TOptions defaultOptions;

  /// The model name to use.
  final String name;

  /// The number of dimensions the resulting output embeddings should have.
  final int? dimensions;

  /// The maximum number of texts to embed in a single request.
  final int? batchSize;

  /// Embed query text and return result with usage data.
  Future<EmbeddingsResult> embedQuery(String query, {TOptions? options});

  /// Embed texts and return results with usage data.
  Future<BatchEmbeddingsResult> embedDocuments(
    List<String> texts, {
    TOptions? options,
  });

  /// Disposes the embeddings model.
  void dispose();

  /// Measures the cosine of the angle between two vectors in a vector space.
  /// It ranges from -1 to 1, where 1 represents identical vectors, 0 represents
  /// orthogonal vectors, and -1 represents vectors that are diametrically
  /// opposed.
  static double cosineSimilarity(List<double> a, List<double> b) {
    double p = 0;
    double p2 = 0;
    double q2 = 0;
    for (var i = 0; i < a.length; i++) {
      p += a[i] * b[i];
      p2 += a[i] * a[i];
      q2 += b[i] * b[i];
    }
    return p / sqrt(p2 * q2);
  }

  /// Calculates the similarity between an embedding and a list of embeddings.
  ///
  /// The similarity is calculated using the provided [similarityFunction].
  /// The default similarity function is [cosineSimilarity].
  static List<double> calculateSimilarity(
    List<double> embedding,
    List<List<double>> embeddings, {
    double Function(List<double> a, List<double> b) similarityFunction =
        cosineSimilarity,
  }) => embeddings
      .map((vector) => similarityFunction(vector, embedding))
      .toList(growable: false);

  /// Returns a sorted list of indexes of [embeddings] that are most similar to
  /// the provided [embedding] (in descending order, most similar first).
  ///
  /// The similarity is calculated using the provided [similarityFunction].
  /// The default similarity function is [cosineSimilarity].
  List<int> getIndexesMostSimilarEmbeddings(
    List<double> embedding,
    List<List<double>> embeddings, {
    double Function(List<double> a, List<double> b) similarityFunction =
        cosineSimilarity,
  }) {
    final similarities = calculateSimilarity(
      embedding,
      embeddings,
      similarityFunction: similarityFunction,
    );
    return List<int>.generate(embeddings.length, (i) => i)
      ..sort((a, b) => similarities[b].compareTo(similarities[a]));
  }
}

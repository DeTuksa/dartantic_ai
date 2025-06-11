/// The type of embedding to generate.
///
/// This enum defines different types of embeddings that can be generated
/// for text, optimized for different use cases.
enum EmbeddingType {
  /// Embedding optimized for documents/content that will be stored
  /// and searched against.
  document,

  /// Embedding optimized for queries that will be used to search
  /// against document embeddings.
  query,
}

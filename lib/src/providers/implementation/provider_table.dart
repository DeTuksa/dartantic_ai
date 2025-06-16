import '../providers.dart';

/// Manages the mapping between provider family names and provider factories.
///
/// Provides a registry of available AI model providers and methods to create
/// provider instances based on settings.
class ProviderTable {
  /// Map of provider family names to provider factory functions.
  ///
  /// Used to look up the appropriate provider factory when creating providers.
  static final primaryProviders = <String, ProviderFactory>{
    'openai':
        (settings) => OpenAiProvider(
          modelName: settings.modelName,
          embeddingModelName: settings.embeddingModelName,
          apiKey: settings.apiKey,
        ),
    'google':
        (settings) => GeminiProvider(
          modelName: settings.modelName,
          embeddingModelName: settings.embeddingModelName,
          apiKey: settings.apiKey,
        ),
  };

  /// Aliases for provider names to support different naming conventions.
  static const providerAliases = {
    'googleai': 'google',
    'google-gla': 'google',
    'gemini': 'google',
  };

  /// Creates a provider instance for the given settings.
  ///
  /// Uses the [settings providerName] to look up the appropriate provider
  /// factory in the [primaryProviders] map and creates a provider with the
  /// specified settings. Throws an [ArgumentError] if the provider family is
  /// not supported.
  static Provider providerFor(ProviderSettings settings) {
    final providerName =
        providerAliases[settings.providerName] ?? settings.providerName;
    final providerFactory = primaryProviders[providerName];
    if (providerFactory != null) return providerFactory(settings);
    throw ArgumentError('Unsupported provider: $settings.providerName');
  }
}

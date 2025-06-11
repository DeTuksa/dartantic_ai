import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dartantic_ai/src/providers/implementation/provider_table.dart';

Iterable<Provider> allProvidersByType() {
  // get all providers from the provider table
  final providers = [
    for (final providerName in ProviderTable.providers.keys)
      ProviderTable.providerFor(
        ProviderSettings(
          providerName: providerName,
          modelName: null,
          apiKey: null,
        ),
      ),
  ];

  // grab a set of providers unique by runtime type, i.e. GeminiProvider,
  // OpenAiProvider, etc., letting the map default to only unique provider
  // types
  final typeToProvider = <String, Provider>{};
  for (final provider in providers) {
    typeToProvider[provider.runtimeType.toString()] = provider;
  }

  return typeToProvider.values;
}

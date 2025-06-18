import 'package:dartantic_ai/dartantic_ai.dart';

final allProviders = [
  for (final providerName in ProviderTable.providers.keys)
    Agent.providerFor(providerName),
];

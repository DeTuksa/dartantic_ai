// ignore_for_file: avoid_print

import 'package:dartantic_ai/dartantic_ai.dart';

void main() async {
  for (final providerName in ProviderTable.providers.keys) {
    final provider = Agent.providerFor(providerName);
    print('\n# Provider: ${provider.name}');
    try {
      final models = await provider.listModels();
      for (final model in models) {
        print('- Model: ${model.providerName}:${model.name} => ${model.kinds}');
      }
    } on Exception catch (e) {
      print('Exception: $e');
      // waiting on https://github.com/davidmigloz/langchain_dart/issues/734
      // ignore: avoid_catching_errors
    } on Error catch (e) {
      print('Error: $e');
    }
  }
}

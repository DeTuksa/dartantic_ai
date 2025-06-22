// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart';

/// An example of how to add and use a custom provider.
void main() async {
  print('Adding the "echo" provider...');
  Agent.providers['echo'] = (_) => EchoProvider();
  print('Added! Available providers: ${Agent.providers.keys.join(', ')}');

  print('');
  print('Using the echo provider...');
  final agent = Agent('echo:mock');
  const prompt = 'Hello, world!';
  final response = await agent.run(prompt);

  print('Prompt: "$prompt"');
  print('Response: "${response.output}"');

  assert(response.output == prompt);
  print('');
  print('Successfully echoed the prompt!');
}

/// A mock model that echos back the prompt.
class EchoModel implements Model {
  @override
  Set<ProviderCaps> get caps => {ProviderCaps.textGeneration};

  @override
  String get generativeModelName => 'echo';

  @override
  String get embeddingModelName => '';

  @override
  Stream<AgentResponse> runStream({
    required String prompt,
    Iterable<Message> messages = const [],
    Iterable<Part> attachments = const [],
  }) async* {
    final requestMessages = [
      ...messages,
      Message(
        role: MessageRole.user,
        parts: [TextPart(prompt), ...attachments],
      ),
    ];

    final responseMessages = [
      ...requestMessages,
      Message(role: MessageRole.model, parts: [TextPart(prompt)]),
    ];

    yield AgentResponse(output: prompt, messages: responseMessages);
  }

  @override
  Future<Float64List> createEmbedding(
    String text, {
    EmbeddingType type = EmbeddingType.document,
  }) {
    throw UnsupportedError('EchoModel does not support embeddings.');
  }
}

/// A mock provider that provides an [EchoModel].
class EchoProvider implements Provider {
  @override
  String get name => 'echo';

  @override
  Set<ProviderCaps> get caps => {ProviderCaps.textGeneration};

  @override
  Model createModel(ModelSettings settings) => EchoModel();

  @override
  Future<Iterable<ModelInfo>> listModels() async => [
    ModelInfo(
      providerName: name,
      name: 'echo',
      kinds: const {ModelKind.chat},
      stable: true,
    ),
  ];
}

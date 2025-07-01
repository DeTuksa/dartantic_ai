import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart';

/// A mock model that mocks back the prompt.
class MockModel implements Model {
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
    if (attachments.isNotEmpty && !caps.contains(ProviderCaps.fileUploads)) {
      throw UnsupportedError('This model does not support attachments.');
    }

    yield AgentResponse(
      output: prompt,
      messages: [
        ...messages,
        Message.user([TextPart(prompt)]),
        Message.model([TextPart(prompt)]),
      ],
    );
  }

  @override
  Future<Float64List> createEmbedding(
    String text, {
    EmbeddingType type = EmbeddingType.document,
    int? dimensions,
  }) {
    throw UnsupportedError('MockModel does not support embeddings.');
  }
}

/// A mock provider that provides an [MockModel].
class MockProvider implements Provider {
  MockProvider([this.name = 'mock']);

  @override
  String name;

  @override
  Set<ProviderCaps> get caps => {ProviderCaps.textGeneration};

  @override
  Model createModel(ModelSettings settings) =>
      settings.tools?.isEmpty ?? true
          ? MockModel()
          : throw UnsupportedError('MockModel does not support tools.');

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

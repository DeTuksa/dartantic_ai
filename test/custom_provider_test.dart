import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:test/test.dart';

import 'mock_provider.dart';

void main() {
  test('MockProvider handles multi-turn chat history', () async {
    final agent = Agent.provider(MockProvider());
    var messages = <Message>[];

    // Turn 1
    const prompt1 = 'Hello there!';
    final response1 = await agent.run(prompt1, messages: messages);
    messages = response1.messages.toList();

    expect(response1.output, prompt1);
    expect(messages, hasLength(2));
    expect(messages[0].role, MessageRole.user);
    expect(messages[0].text, prompt1);
    expect(messages[1].role, MessageRole.model);
    expect(messages[1].text, prompt1);

    // Turn 2
    const prompt2 = 'How are you doing?';
    final response2 = await agent.run(prompt2, messages: messages);
    messages = response2.messages.toList();

    expect(response2.output, prompt2);
    expect(messages, hasLength(4));
    expect(messages[2].role, MessageRole.user);
    expect(messages[2].text, prompt2);
    expect(messages[3].role, MessageRole.model);
    expect(messages[3].text, prompt2);
  });

  test('can extend the provider table and use a custom provider', () async {
    // Register the custom provider
    Agent.providers['mock'] = (settings) => MockProvider();

    // The agent will automatically find the MockProvider via the table
    // by just providing the provider name. The model name will be inferred.
    final agent = Agent('mock');
    const prompt = 'This is a test';
    final response = await agent.run(prompt);

    expect(response.output, prompt);
    expect(agent.model, 'mock:echo');
  });

  test('the provider table grows when a new provider is added', () {
    final initialCount = Agent.providers.length;

    // Register the custom provider
    Agent.providers['another_mock'] = (_) => MockProvider();

    expect(Agent.providers.length, initialCount + 1);
    expect(Agent.providers.containsKey('another_mock'), isTrue);
  });

  test('throws for unsupported features', () {
    final provider = MockProvider();

    // Test embedding creation
    expect(
      () => Agent.provider(provider).createEmbedding('test'),
      throwsUnsupportedError,
    );

    // Test tool usage
    expect(
      () => Agent.provider(
        provider,
        tools: [Tool(name: 'test_tool', onCall: (args) async => {})],
      ),
      throwsUnsupportedError,
    );

    // Test file attachments
    final agent = Agent.provider(provider);
    expect(
      () => agent.run(
        'test',
        attachments: [LinkPart(Uri.parse('https://example.com'))],
      ),
      throwsUnsupportedError,
    );
  });
}

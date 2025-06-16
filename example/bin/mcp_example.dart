// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dartantic_ai/dartantic_ai.dart';

void main() async {
  final localTime = Tool(
    name: 'local_time',
    description: 'Returns the current local time in ISO 8601 format.',
    onCall: (args) async => {'result': DateTime.now().toIso8601String()},
  );

  final location = Tool(
    name: 'location',
    description: 'Returns the current location.',
    onCall: (args) async => {'result': 'Portland, OR'},
  );

  final deepwiki = McpServer.remote(
    'deepwiki',
    url: 'https://mcp.deepwiki.com/mcp',
  );

  final huggingFace = McpServer.remote(
    'huggingface',
    url: 'https://huggingface.co/mcp',
  );

  final agent = Agent(
    'google',
    systemPrompt:
        'You are a helpful assistant with access to various tools; '
        'use the right one for the right job!',
    tools: [
      localTime,
      location,
      ...await deepwiki.getTools(),
      ...await huggingFace.getTools(),
    ],
  );

  try {
    const query =
        'Where am I and what time is it and '
        'who is hugging face and '
        'what model providers does csells/dartantic_ai currently support?';
    await agent.runStream(query).map((r) => print(r.output)).drain();
  } finally {
    await Future.wait([deepwiki.disconnect(), huggingFace.disconnect()]);
  }

  exit(0);
}

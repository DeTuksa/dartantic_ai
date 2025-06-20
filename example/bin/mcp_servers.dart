// ignore_for_file: avoid_print, unreachable_from_main, unused_element

import 'dart:convert';
import 'dart:io';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(
    (record) => print('\n[${record.level.name}]: ${record.message}\n'),
  );

  await singleMcpServer();
  await multipleToolsAndMcpServers();
  exit(0);
}

Future<void> singleMcpServer() async {
  print('\nSingle MCP Server');

  final huggingFace = McpClient.remote(
    'huggingface',
    url: Uri.parse('https://huggingface.co/mcp'),
  );

  final hgTools = await huggingFace.listTools();
  // _dumpTools('huggingface', hgTools);

  final agent = Agent(
    'google',
    systemPrompt:
        'You are a helpful assistant with access to various tools; '
        'use the right one for the right job!',
    tools: [...hgTools],
  );

  try {
    const query = 'Who is hugging face?';
    await agent.runStream(query).map((r) => stdout.write(r.output)).drain();
  } finally {
    await huggingFace.disconnect();
  }

  print('');
}

Future<void> multipleToolsAndMcpServers() async {
  print('\nMultiple Tools and MCP Servers');

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

  final deepwiki = McpClient.remote(
    'deepwiki',
    url: Uri.parse('https://mcp.deepwiki.com/mcp'),
  );

  final dwTools = await deepwiki.listTools();
  // _dumpTools('deepwiki', dwTools);

  final huggingFace = McpClient.remote(
    'huggingface',
    url: Uri.parse('https://huggingface.co/mcp'),
  );

  final hgTools = await huggingFace.listTools();

  final agent = Agent(
    'google',
    systemPrompt:
        'You are a helpful assistant with access to various tools; '
        'use the right one for the right job!',
    tools: [localTime, location, ...dwTools, ...hgTools],
  );

  try {
    const query =
        'Where am I and what time is it and '
        'who is hugging face and '
        'what model providers does csells/dartantic_ai currently support?';
    await agent.runStream(query).map((r) => stdout.write(r.output)).drain();
  } finally {
    await Future.wait([deepwiki.disconnect(), huggingFace.disconnect()]);
  }

  print('');
}

void _dumpTools(String name, Iterable<Tool> tools) {
  print('\n# $name');
  for (final tool in tools) {
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(jsonDecode(tool.inputSchema!.toJson()));
    print('\n## Tool');
    print('- name: ${tool.name}');
    print('- description: ${tool.description}');
    print('- inputSchema: $json');
  }
}

void _dumpMessages(List<Message> messages) {
  print('Messages:');
  for (final message in messages) {
    print('  ${message.role}: ${message.parts}');
  }
}

// ignore_for_file: avoid_print, unreachable_from_main, unused_element

import 'dart:convert';
import 'dart:io';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen(
    (record) => print('\n[${record.level.name}]: ${record.message}\n'),
  );

  await zapierGoogleCalendar();
  // await singleMcpServer();
  // await multipleToolsAndMcpServers();
  exit(0);
}

Future<void> zapierGoogleCalendar() async {
  print('\nZapier Google Calendar');
  final zapierServer = McpClient.remote(
    'google-calendar',
    url: Uri.parse(Platform.environment['ZAPIER_MCP_URL']!),
  );

  final zapierTools = await zapierServer.listTools();
  _dumpTools('zapier google calendar', zapierTools);

  final agent = Agent(
    'openai',
    systemPrompt: '''
You are a helpful calendar assistant.
You have access to tools to interact with Google Calendar.
You already have permission to call any Google Calendar tool.
Never ask the user for additional access or confirmation.
''',
    tools: [
      Tool(
        name: 'get-current-date-time',
        description: 'Get the current local date and time in ISO-8601 format',
        onCall: (_) async => {'datetime': DateTime.now().toIso8601String()},
      ),
      ...zapierTools,
    ],
  );

  final result = await agent.run("What's on my schedule today?");
  print(result.output);
  _dumpMessages(result.messages);
  // final result2 = await agent.run('continue', messages: result.messages);
  // print(result2.output);
}

void _dumpMessages(List<Message> messages) {
  print('Messages:');
  for (final message in messages) {
    print('  ${message.role}: ${message.parts}');
  }
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

import 'package:mcp_dart/mcp_dart.dart';

void main() async {
  print('Starting test_mcp_server...');
  McpServer server = McpServer(
    Implementation(name: "mcp-example-server", version: "1.0.0"),
    options: ServerOptions(
      capabilities: ServerCapabilities(
        resources: ServerCapabilitiesResources(),
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  server.tool(
    "calculate",
    description: 'Perform basic arithmetic operations',
    inputSchemaProperties: {
      'operation': {
        'type': 'string',
        'enum': ['add', 'subtract', 'multiply', 'divide'],
      },
      'a': {'type': 'number'},
      'b': {'type': 'number'},
    },
    callback: ({args, extra}) async {
      final operation = args!['operation'];
      final a = args['a'];
      final b = args['b'];
      return CallToolResult.fromContent(
        content: [
          TextContent(
            text: switch (operation) {
              'add' => 'Result: ${a + b}',
              'subtract' => 'Result: ${a - b}',
              'multiply' => 'Result: ${a * b}',
              'divide' => 'Result: ${a / b}',
              _ => throw Exception('Invalid operation'),
            },
          ),
        ],
      );
    },
  );

  print('Connecting test_mcp_server...');
  await server.connect(StdioServerTransport());
  print('test_mcp_server connected and running.');
}

import 'package:mcp_dart/mcp_dart.dart' as mcp;

import '../agent/agent.dart';
import '../agent/mcp_client.dart';

/// Gets the value of an environment variable.
///
/// For web, this function only checks the `Agent.environment` map.
/// Throws an exception if the variable is not set or is empty.
String getEnv(String key) {
  final value = Agent.environment[key];
  if (value == null) {
    throw Exception(
      'Environment variable $key not found. Set it in Agent.environment, or '
      'pass it to the Agent/Provider manually.',
    );
  }
  return value;
}

/// Gets the transport for the MCP server.
///
/// For web, this function only returns a [mcp.StreamableHttpClientTransport].
/// Throws an exception if the transport is not supported.
mcp.Transport getTransport({
  required McpServerKind kind,
  required String? command,
  required List<String> args,
  required Map<String, String> environment,
  required String? workingDirectory,
  required Uri? url,
  Map<String, String>? headers,
  Map<String, String>? requestInit,
}) => switch (kind) {
  McpServerKind.local =>
    throw Exception('Local MCP servers are not supported on web.'),
  McpServerKind.remote => mcp.StreamableHttpClientTransport(
    url!,
    opts:
        headers == null
            ? null
            : mcp.StreamableHttpClientTransportOptions(
              requestInit: {'headers': headers},
            ),
  ),
};

import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart' as mcp;

import '../agent/agent.dart';
import '../agent/mcp_client.dart';

/// Gets the value of an environment variable.
///
/// Retrieves the value of the environment variable with the given [key].
/// It first checks the `Agent.environment` map, then falls back to
/// `Platform.environment`.
///
/// Throws an exception if the variable is not set or is empty in either
/// location.
String getEnv(String key) {
  final value = Agent.environment[key] ?? Platform.environment[key];
  if (value == null) {
    throw Exception(
      'Environment variable $key not found. Set it in Agent.environment, '
      'the platform environment, or pass it to the Agent/Provider manually.',
    );
  }
  return value;
}

/// Gets the transport for the MCP server.
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
  McpServerKind.local => mcp.StdioClientTransport(
    mcp.StdioServerParameters(
      command: command!,
      args: args,
      environment: environment,
      workingDirectory: workingDirectory,
      // Fix mcp_dart bug: must use normal mode to access stdout/stdin
      // pipes
      stderrMode: ProcessStartMode.normal,
    ),
  ),
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

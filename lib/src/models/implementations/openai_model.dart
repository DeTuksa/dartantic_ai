import 'dart:convert';
import 'dart:developer' as dev;

import 'package:json_schema/json_schema.dart';
import 'package:openai_dart/openai_dart.dart' as openai;

import '../../../dartantic_ai.dart';
import '../interface/model.dart';

/// Implementation of [Model] that uses OpenAI's API.
///
/// This model handles interaction with OpenAI models, supporting both
/// standard text responses and structured JSON schema responses.
class OpenAiModel extends Model {
  /// Creates a new [OpenAiModel] with the given parameters.
  ///
  /// The [apiKey] is the API key to use for authentication.
  /// The [modelName] is the name of the OpenAI model to use.
  /// The [outputType] is an optional JSON schema for structured outputs.
  /// The [systemPrompt] is an optional system prompt to use.
  OpenAiModel({
    required String apiKey,
    required String modelName,
    JsonSchema? outputType,
    String? systemPrompt,
    Iterable<Tool>? tools,
  }) : _tools = tools,
       _systemPrompt = systemPrompt,
       _modelName = modelName,
       _client = openai.OpenAIClient(apiKey: apiKey),
       _responseFormat =
           outputType != null
               ? openai.ResponseFormat.jsonSchema(
                 jsonSchema: _schemaObjectFrom(outputType),
               )
               : null;

  final openai.OpenAIClient _client;
  final String _modelName;
  final openai.ResponseFormat? _responseFormat;
  final String? _systemPrompt;
  final Iterable<Tool>? _tools;

  @override
  Stream<AgentResponse> run(String prompt) async* {
    final messages = <openai.ChatCompletionMessage>[
      if (_systemPrompt != null)
        openai.ChatCompletionMessage.system(content: _systemPrompt),
      openai.ChatCompletionMessage.user(
        content: openai.ChatCompletionUserMessageContent.string(prompt),
      ),
    ];

    while (true) {
      final stream = _client.createChatCompletionStream(
        request: openai.CreateChatCompletionRequest(
          model: openai.ChatCompletionModel.modelId(_modelName),
          responseFormat: _responseFormat,
          messages: messages,
          tools:
              _tools
                  ?.map(
                    (tool) => openai.ChatCompletionTool(
                      type: openai.ChatCompletionToolType.function,
                      function: openai.FunctionObject(
                        name: tool.name,
                        description: tool.description,
                        parameters: tool.inputType?.toMap(),
                      ),
                    ),
                  )
                  .toList(),
        ),
      );

      var toolCallName = '';
      var toolCallArgs = '';
      var toolCallId = '';

      await for (final chunk in stream) {
        final delta = chunk.choices.first.delta;

        // Handle content streaming
        if (delta.content != null) {
          yield AgentResponse(output: delta.content!);
        }

        // Handle tool calls
        if (delta.toolCalls != null && delta.toolCalls!.isNotEmpty) {
          final toolCall = delta.toolCalls!.first;
          if (toolCall.function?.name != null) {
            toolCallName = toolCall.function!.name!;
          }
          if (toolCall.function?.arguments != null) {
            toolCallArgs += toolCall.function!.arguments!;
          }
          if (toolCall.id != null) {
            toolCallId = toolCall.id!;
          }
        }
      }

      // If no tool calls, we're done
      if (toolCallName.isEmpty) {
        break;
      }

      // Handle tool calls
      final args = jsonDecode(toolCallArgs) as Map<String, dynamic>;
      final result = await _callTool(toolCallName, args);

      // Add the tool response to the messages
      messages.add(
        openai.ChatCompletionMessage.tool(
          toolCallId: toolCallId,
          content: jsonEncode(result),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _callTool(
    String name,
    Map<String, dynamic> args,
  ) async {
    Map<String, dynamic>? result;
    try {
      // if the tool isn't found, return an error
      final tool = _tools?.where((t) => t.name == name).singleOrNull;
      result =
          tool == null
              ? {'error': 'Tool $name not found'}
              : await tool.onCall.call(args);
    } on Exception catch (ex) {
      // if the tool call throws an error, return the exception message
      result = {'error': ex.toString()};
    }

    dev.log('Tool: $name($args)= $result');
    return result;
  }

  static openai.JsonSchemaObject _schemaObjectFrom(
    JsonSchema rawJsonSchema, {
    String name = 'response',
    bool strict = true,
  }) {
    // Ensure additionalProperties: false is set at every object level
    final jsonSchema = rawJsonSchema.toMap();
    final schema = _ensureAdditionalPropertiesFalse(jsonSchema);

    return openai.JsonSchemaObject(
      name: name,
      description: schema['description'] as String?,
      schema: schema,
      strict: strict,
    );
  }

  static Map<String, Object> _ensureAdditionalPropertiesFalse(
    Map<String, dynamic> schema,
  ) {
    final result = Map<String, Object>.from(schema);

    // Skip adding additionalProperties if $ref is present
    if (!result.containsKey(r'$ref')) {
      // Set additionalProperties: false for this object
      result['additionalProperties'] = false;
    }

    // Remove format field if it exists
    result.remove('format');

    // Handle properties of objects
    if (result['properties'] is Map) {
      final properties = Map<String, Object>.from(result['properties']! as Map);
      for (final entry in properties.entries) {
        if (entry.value is Map) {
          properties[entry.key] = _ensureAdditionalPropertiesFalse(
            entry.value as Map<String, dynamic>,
          );
        }
      }
      result['properties'] = properties;
    }

    // Handle items of arrays
    if (result['items'] is Map) {
      result['items'] = _ensureAdditionalPropertiesFalse(
        result['items']! as Map<String, dynamic>,
      );
    }

    // Handle definitions
    if (result[r'$defs'] is Map) {
      final definitions = Map<String, Object>.from(result[r'$defs']! as Map);
      for (final entry in definitions.entries) {
        if (entry.value is Map) {
          definitions[entry.key] = _ensureAdditionalPropertiesFalse(
            entry.value as Map<String, dynamic>,
          );
        }
      }
      result[r'$defs'] = definitions;
    }

    return result;
  }
}

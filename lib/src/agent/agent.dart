import 'dart:convert';

import 'package:dotprompt_dart/dotprompt_dart.dart';
import 'package:json_schema/json_schema.dart';

import '../models/interface/model.dart';
import '../models/interface/model_settings.dart';
import '../providers/implementation/provider_table.dart';
import '../providers/interface/provider.dart';
import '../providers/interface/provider_settings.dart';
import 'agent_response.dart';
import 'tool.dart';

export 'agent_response.dart';
export 'tool.dart';

/// An agent that can run prompts through an AI model and return responses.
///
/// This class provides a unified interface for interacting with different
/// AI model providers and handling both string and typed responses.
class Agent {
  /// Factory constructor to create an [Agent] for a specific model.
  ///
  /// Creates an [Agent] by specifying the model in the format "providerName",
  /// "providerName:modelName", or "providerName/modelName". Automatically
  /// resolves the appropriate provider for the given model.
  ///
  /// - [model]: The model identifier in "providerName",
  ///   "providerName:modelName", or "providerName/modelName" format.
  /// - [systemPrompt]: (Optional) A system prompt to guide the agent's
  ///   behavior.
  /// - [outputType]: (Optional) A [JsonSchema] defining the expected output
  ///   type.
  /// - [outputFromJson]: (Optional) A function to convert JSON output to a
  ///   typed object.
  /// - [tools]: (Optional) A collection of [Tool]s the agent can use.
  factory Agent(
    String model, {
    String? systemPrompt,
    JsonSchema? outputType,
    dynamic Function(Map<String, dynamic> json)? outputFromJson,
    Iterable<Tool>? tools,
  }) => Agent.provider(
    providerFor(model),
    systemPrompt: systemPrompt,
    outputType: outputType,
    outputFromJson: outputFromJson,
    tools: tools,
  );

  /// Creates a new [Agent] with the given [provider].
  ///
  /// - [provider]: The [Provider] to use for the agent.
  /// - [systemPrompt]: (Optional) The system prompt to use for the agent.
  /// - [outputType]: (Optional) The [JsonSchema] for the expected output type.
  /// - [outputFromJson]: (Optional) A function to convert JSON output to a
  ///   typed object.
  /// - [tools]: (Optional) A collection of [Tool]s the agent can use.
  Agent.provider(
    Provider provider, {
    String? systemPrompt,
    JsonSchema? outputType,
    this.outputFromJson,
    Iterable<Tool>? tools,
  }) : _model = provider.createModel(
         ModelSettings(
           systemPrompt: systemPrompt,
           outputType: outputType,
           tools: tools,
         ),
       );

  final Model _model;

  /// Function to convert JSON output to a typed object.
  ///
  /// When provided, this function is used to convert the JSON response from the
  /// model into a strongly-typed object when using [runFor].
  final dynamic Function(Map<String, dynamic> json)? outputFromJson;

  /// Runs the given [prompt] through the model and returns the response as a
  /// stream.
  ///
  /// Returns a [Stream] of [AgentResponse] containing the raw string output.
  Stream<AgentResponse> run(String prompt) => _model.run(prompt);

  /// Runs the given [prompt] through the model and returns a typed response.
  ///
  /// Returns an [AgentResponseFor<T>] containing the output converted to type
  /// [T]. Uses [outputFromJson] to convert the JSON response if provided,
  /// otherwise returns the decoded JSON.
  Future<AgentResponseFor<T>> runFor<T>(String prompt) async {
    // dev.log('schema: [1m${_modelSettings.outputType}[0m');
    final stream = run(prompt);
    final output = StringBuffer();
    await for (final chunk in stream) {
      output.write(chunk.output);
    }
    final outputJson = jsonDecode(output.toString());
    final outputTyped = outputFromJson?.call(outputJson) ?? outputJson;
    return AgentResponseFor(output: outputTyped);
  }

  /// Executes a given [DotPrompt] using the specified parameters and returns
  /// the response as a [Stream] of [AgentResponse].
  ///
  /// - [prompt]: The [DotPrompt] to be executed.
  /// - [systemPrompt]: (Optional) A system prompt to guide the agent's
  ///   behavior.
  /// - [outputType]: (Optional) A [JsonSchema] defining the expected output
  ///   type.
  /// - [outputFromJson]: (Optional) A function to convert JSON output to a
  ///   typed object.
  /// - [tools]: (Optional) A collection of [Tool]s the agent can use.
  /// - [input]: (Optional) A map of input values to render the prompt with.
  ///   Defaults to an empty map.
  ///
  /// Returns a [Stream] of [AgentResponse] containing the raw string output
  /// from the agent.
  static Stream<AgentResponse> runPrompt(
    DotPrompt prompt, {
    String? systemPrompt,
    JsonSchema? outputType,
    dynamic Function(Map<String, dynamic> json)? outputFromJson,
    Iterable<Tool>? tools,
    Map<String, dynamic> input = const {},
  }) {
    final agent = Agent(
      prompt.frontMatter.model ?? 'google',
      systemPrompt: systemPrompt,
      outputType: outputType,
      outputFromJson: outputFromJson,
      tools: tools,
    );

    return agent.run(prompt.render(input));
  }

  /// Resolves the [Provider] for the given [model] string.
  ///
  /// [model] should be in the format "providerName", "providerName:modelName",
  /// or "providerName/modelName".
  ///
  /// Throws [ArgumentError] if [model] is empty.
  static Provider providerFor(String model) {
    if (model.isEmpty) throw ArgumentError('Model must be provided');

    final modelParts = model.split(RegExp('[:/]'));
    final providerName = modelParts[0];
    final modelName = modelParts.length != 1 ? modelParts[1] : null;

    return ProviderTable.providerFor(
      ProviderSettings(
        providerName: providerName,
        modelName: modelName,
        apiKey: null,
      ),
    );
  }
}

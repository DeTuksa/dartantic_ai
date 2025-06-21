import 'package:json_schema/json_schema.dart';

import '../../agent/tool.dart';
import '../../providers/interface/provider_caps.dart';

/// The mode in which the model will call tools.
enum ToolCallingMode {
  /// The model will use the single-step mode. This is the intuitive
  /// request=>response mode. It's meant as an optimization and not the default.
  singleStep,

  /// The model will use the multi-step mode. This is the mode that allows the
  /// model to call tools multiple times in a single request. Because it
  /// sometimes results in multiple tool calls, it is going to result in
  /// multiple round-trips to the LLM. However, it's more correct as it allows
  /// the LLM to complete their work in a single request.
  multiStep,
}

/// Settings used to configure a model.
///
/// Contains configuration options that are common across different model
/// implementations.
class ModelSettings {
  /// Creates a new [ModelSettings] instance.
  ///
  /// The [systemPrompt] is the system prompt to use for the model.
  /// The [outputSchema] is an optional JSON schema for structured outputs.
  ModelSettings({
    required this.systemPrompt,
    required this.outputSchema,
    required Iterable<Tool>? tools,
    required this.toolCallingMode,
    required this.caps,
    required this.temperature,
  }) : tools = tools?.toList();

  /// The system prompt to use for the model.
  ///
  /// Provides context and instructions to guide the model's responses.
  final String? systemPrompt;

  /// The output type for structured responses.
  ///
  /// When provided, configures the model to return responses in JSON format
  /// that match this schema.
  final JsonSchema? outputSchema;

  /// The tools to use for the model.
  final List<Tool>? tools;

  /// The mode in which the agent will run.
  final ToolCallingMode? toolCallingMode;

  /// The temperature to use for the model.
  final double? temperature;

  /// The capabilities of the model.
  final Set<ProviderCaps> caps;
}

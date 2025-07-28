import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:meta/meta.dart';

/// Options to pass into MistralAI.
@immutable
class MistralChatModelOptions extends ChatModelOptions {
  /// Creates a new mistral ai options instance.
  const MistralChatModelOptions({
    this.topP,
    this.maxTokens,
    this.safePrompt,
    this.randomSeed,
  });

  /// Nucleus sampling, where the model considers the results of the tokens
  /// with `top_p` probability mass. So 0.1 means only the tokens comprising
  /// the top 10% probability mass are considered.
  ///
  /// We generally recommend altering this or `temperature` but not both.
  final double? topP;

  /// The maximum number of tokens to generate in the completion.
  ///
  /// The token count of your prompt plus `max_tokens` cannot exceed the
  /// model's context length.
  final int? maxTokens;

  /// Whether to inject a safety prompt before all conversations.
  final bool? safePrompt;

  /// The seed to use for random sampling.
  /// If set, different calls will generate deterministic results.
  final int? randomSeed;
}

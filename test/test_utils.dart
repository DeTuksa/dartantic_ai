// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dotprompt_dart/dotprompt_dart.dart';
import 'package:openai_dart/openai_dart.dart' as openai;

final allProviders = [
  for (final providerName in ProviderTable.providers.keys)
    Agent.providerFor(providerName),
];

Stream<T> rateLimitRetryStream<T>(
  Stream<T> Function() fn, {
  required int retries,
}) async* {
  var attempts = 0;
  while (true) {
    attempts++;
    try {
      yield* fn();
      // If we get here without an exception, we're done
      break;
    } on openai.OpenAIClientException catch (ex) {
      final waitTimeMs = _retryWait(ex, attempts);
      if (waitTimeMs > 0 && attempts < retries) {
        print(
          'Retrying stream after rate limit (attempt $attempts of $retries)',
        );
        await Future.delayed(Duration(milliseconds: waitTimeMs));
        // Continue to retry
      } else {
        // Not a rate limit error or retries exhausted, rethrow
        rethrow;
      }
    }
  }
}

Future<T> rateLimitRetry<T>(
  Future<T> Function() fn, {
  required int retries,
}) async {
  var attempts = 0;
  while (true) {
    attempts++;
    try {
      return await fn();
      // If we get here without an exception, we're done
    } on openai.OpenAIClientException catch (e) {
      final waitTimeMs = _retryWait(e, attempts);
      if (waitTimeMs > 0 && attempts < retries) {
        print('Retrying after rate limit (attempt $attempts of $retries)');
        await Future.delayed(Duration(milliseconds: waitTimeMs));
        // Continue to retry
      } else {
        // Not a rate limit error or retries exhausted, rethrow
        rethrow;
      }
    }
  }
}

int _retryWait(openai.OpenAIClientException ex, int attempts) {
  // Check if it's a rate limit error (code 429)
  if (ex.code != 429) return 0;

  // Try to parse the wait time from the error message
  print('OpenAIClientException.body: ${ex.body}');

  try {
    // Parse the error body as JSON if it's a String
    final Map<String, dynamic> parsedBody;
    if (ex.body is String) {
      parsedBody = jsonDecode(ex.body! as String) as Map<String, dynamic>;
    } else if (ex.body is Map<String, dynamic>) {
      parsedBody = ex.body! as Map<String, dynamic>;
    } else {
      // Unknown format, use exponential backoff
      return _calculateBackoff(attempts);
    }

    if (parsedBody['error'] is Map<String, dynamic>) {
      final errorMap = parsedBody['error'] as Map<String, dynamic>;
      final errorMessage = errorMap['message'] as String?;

      if (errorMessage != null) {
        // Extract wait time using regex
        final regex = RegExp(r'Please try again in (\d+)ms');
        final match = regex.firstMatch(errorMessage);

        if (match != null && match.groupCount >= 1) {
          final waitTimeMs = int.tryParse(match.group(1)!) ?? 1000;
          print(
            'Rate limit hit. Waiting ${waitTimeMs}ms before retry. '
            'Attempt: $attempts',
          );
          return waitTimeMs;
        }
      }
    }
  } on Exception catch (e) {
    print('Error parsing rate limit response: $e');
    // Fall through to default backoff
  }

  // If we couldn't parse the wait time, use exponential backoff
  return _calculateBackoff(attempts);
}

int _calculateBackoff(int attempts) {
  final backoffMs = 200 * (1 << (attempts - 1)); // 200ms, 400ms, 800ms, etc.

  print(
    'Using exponential backoff: ${backoffMs}ms. '
    'Attempt: $attempts',
  );

  return backoffMs;
}

extension AgentRetryExtension on Agent {
  Future<AgentResponse> runWithRetries(
    String prompt, {
    Iterable<Message> messages = const [],
    Iterable<Part> attachments = const [],
    int retries = 1,
  }) => rateLimitRetry(
    () => run(prompt, messages: messages, attachments: attachments),
    retries: retries,
  );

  Future<AgentResponseFor<T>> runForWithRetries<T>(
    String prompt, {
    Iterable<Message> messages = const [],
    Iterable<Part> attachments = const [],
    int retries = 3,
  }) => rateLimitRetry<AgentResponseFor<T>>(
    () => runFor<T>(prompt, messages: messages, attachments: attachments),
    retries: retries,
  );

  Stream<AgentResponse> runStreamWithRetries(
    String prompt, {
    Iterable<Message> messages = const [],
    Iterable<Part> attachments = const [],
    int retries = 3,
  }) => rateLimitRetryStream<AgentResponse>(
    () => runStream(prompt, messages: messages, attachments: attachments),
    retries: retries,
  );
}

Stream<AgentResponse> runPromptStreamWithRetries(
  DotPrompt prompt, {
  Iterable<Message> messages = const [],
  Iterable<Part> attachments = const [],
  int retries = 3,
}) => rateLimitRetryStream<AgentResponse>(
  () => Agent.runPromptStream(
    prompt,
    messages: messages,
    attachments: attachments,
  ),
  retries: retries,
);

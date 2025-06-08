import 'dart:convert';

import 'package:dartantic_ai/src/models/message.dart';
import 'package:test/test.dart';

void main() {
  group('Message serialization', () {
    test('deserializes and reserializes to the same JSON structure', () {
      const jsonString = '''
[
        {
          "role": "system",
          "content": [
            {"text": "You are a helpful AI assistant."}
          ]
        },
        {
          "role": "user",
          "content": [
            {"text": "Hello, can you help me with a task?"}
          ]
        },
        {
          "role": "model",
          "content": [
            {"text": "Of course! I'd be happy to help you with a task. What kind of task do you need assistance with? Please provide me with more details, and I'll do my best to help you."}
          ]
        },
        {
          "role": "user",
          "content": [
            {"text": "Can you analyze this image and tell me what you see?"},
            {
              "media": {
                "contentType": "image/jpeg",
                "url": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAg..."
              }
            }
          ]
        }
      ]''';

      final inputJson = jsonDecode(jsonString);
      final messages =
          (inputJson as List).map((e) => Message.fromJson(e)).toList();
      final outputJson = messages.map((m) => m.toJson()).toList();

      // Deep equality check
      expect(outputJson, equals(inputJson));
    });
  });
}

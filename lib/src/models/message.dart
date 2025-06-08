// ignore_for_file: public_member_api_docs // TODO: remove this
// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

enum MessageRole { system, user, model }

class Message {
  Message({required this.role, required this.content});

  factory Message.fromRawJson(String str) => Message.fromJson(json.decode(str));

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    role: MessageRole.values.byName(json['role']),
    content:
        json['content'] == null
            ? []
            : List<Part>.from(json['content']!.map((x) => Part.fromJson(x))),
  );

  final MessageRole role;
  final List<Part> content;

  Message copyWith({MessageRole? role, List<Part>? content}) =>
      Message(role: role ?? this.role, content: content ?? this.content);

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': List<dynamic>.from(content.map((x) => x.toJson())),
  };
}

abstract class Part {
  const Part();

  factory Part.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('text')) {
      return TextPart.fromJson(json);
    } else if (json.containsKey('media')) {
      return MediaPart.fromJson(json);
    } else if (json.containsKey('tool')) {
      return ToolPart.fromJson(json);
    } else {
      throw Exception('Unknown part type: $json');
    }
  }

  Map<String, dynamic> toJson();
}

class TextPart extends Part {
  const TextPart({this.text});

  factory TextPart.fromJson(Map<String, dynamic> json) =>
      TextPart(text: json['text']);

  final String? text;

  @override
  Map<String, dynamic> toJson() => {'text': text};
}

class MediaPart extends Part {
  const MediaPart({this.contentType, this.url});

  factory MediaPart.fromJson(Map<String, dynamic> json) {
    final media = json['media'] as Map<String, dynamic>?;
    return MediaPart(contentType: media?['contentType'], url: media?['url']);
  }

  final String? contentType;
  final String? url;

  @override
  Map<String, dynamic> toJson() => {
    'media': {'contentType': contentType, 'url': url},
  };
}

class ToolPart extends Part {
  const ToolPart({this.id, this.name, this.arguments, this.result});

  factory ToolPart.fromJson(Map<String, dynamic> json) {
    final tool = json['tool'] as Map<String, dynamic>?;
    return ToolPart(
      id: tool?['id'],
      name: tool?['name'],
      arguments: tool?['arguments'],
      result: tool?['result'],
    );
  }

  final String? id;
  final String? name;
  final dynamic arguments;
  final dynamic result;

  @override
  Map<String, dynamic> toJson() => {
    'tool': {'id': id, 'name': name, 'arguments': arguments, 'result': result},
  };
}

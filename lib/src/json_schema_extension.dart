import 'dart:convert';

import 'package:json_schema/json_schema.dart';

/// Extension methods for [JsonSchema]
extension JsonSchemaExtension on JsonSchema {
  /// Converts this [JsonSchema] to a [Map<String, dynamic>]
  Map<String, dynamic> toMap() => jsonDecode(toJson()) as Map<String, dynamic>;
}

/// Extension methods for [Map<String, dynamic>]
extension MapExtension on Map<String, dynamic> {
  /// Converts a [Map<String, dynamic>] to a [JsonSchema]
  JsonSchema toSchema() => JsonSchema.create(this);
}

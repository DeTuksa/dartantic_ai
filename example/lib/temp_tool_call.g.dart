// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temp_tool_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TempFunctionInput _$TempFunctionInputFromJson(Map<String, dynamic> json) =>
    TempFunctionInput(location: json['location'] as String);

Map<String, dynamic> _$TempFunctionInputToJson(TempFunctionInput instance) =>
    <String, dynamic>{'location': instance.location};

// **************************************************************************
// SotiSchemaGenerator
// **************************************************************************

const _$TempFunctionInputSchemaMap = <String, dynamic>{
  r'$schema': r'https://json-schema.org/draft/2020-12/schema',
  r'type': r'object',
  r'properties': {
    r'location': {
      r'type': r'string',
      r'description':
          r'/// The location to get the temperature in (e.g. "New York, NY")',
    },
  },
  r'required': [r'location'],
  r'$defs': {},
};

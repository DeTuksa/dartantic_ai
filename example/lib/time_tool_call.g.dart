// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_tool_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeFunctionInput _$TimeFunctionInputFromJson(Map<String, dynamic> json) =>
    TimeFunctionInput(timeZoneName: json['timeZoneName'] as String);

Map<String, dynamic> _$TimeFunctionInputToJson(TimeFunctionInput instance) =>
    <String, dynamic>{'timeZoneName': instance.timeZoneName};

TimeFunctionOutput _$TimeFunctionOutputFromJson(Map<String, dynamic> json) =>
    TimeFunctionOutput(time: DateTime.parse(json['time'] as String));

Map<String, dynamic> _$TimeFunctionOutputToJson(TimeFunctionOutput instance) =>
    <String, dynamic>{'time': instance.time.toIso8601String()};

// **************************************************************************
// SotiSchemaGenerator
// **************************************************************************

const _$TimeFunctionInputSchemaMap = <String, dynamic>{
  r'$schema': r'https://json-schema.org/draft/2020-12/schema',
  r'type': r'object',
  r'properties': {
    r'timeZoneName': {
      r'type': r'string',
      r'description':
          r'/// The name of the time zone to get the time in (e.g. "America/New_York")',
    },
  },
  r'required': [r'timeZoneName'],
  r'$defs': {},
};

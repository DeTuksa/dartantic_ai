// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loc_time_temp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocTimeTemp _$LocTimeTempFromJson(Map<String, dynamic> json) => LocTimeTemp(
  location: json['location'] as String,
  time: DateTime.parse(json['time'] as String),
  temp: (json['temp'] as num).toDouble(),
);

Map<String, dynamic> _$LocTimeTempToJson(LocTimeTemp instance) =>
    <String, dynamic>{
      'location': instance.location,
      'time': instance.time.toIso8601String(),
      'temp': instance.temp,
    };

ListOfLocTimeTemps _$ListOfLocTimeTempsFromJson(Map<String, dynamic> json) =>
    ListOfLocTimeTemps(
      locations:
          (json['locations'] as List<dynamic>)
              .map((e) => LocTimeTemp.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$ListOfLocTimeTempsToJson(ListOfLocTimeTemps instance) =>
    <String, dynamic>{
      'locations': instance.locations.map((e) => e.toJson()).toList(),
    };

// **************************************************************************
// SotiSchemaGenerator
// **************************************************************************

const _$LocTimeTempSchemaMap = <String, dynamic>{
  r'$schema': r'https://json-schema.org/draft/2020-12/schema',
  r'type': r'object',
  r'properties': {
    r'location': {
      r'type': r'string',
      r'description':
          r'/// The location to get the temperature in (e.g. "New York, NY")',
    },
    r'time': {
      r'type': r'string',
      r'format': r'date-time',
      r'description': r'/// The time in the given time zone',
    },
    r'temp': {
      r'type': r'number',
      r'description': r'/// The temperature in degrees Fahrenheit',
    },
  },
  r'required': [r'location', r'time', r'temp'],
  r'$defs': {},
};

const _$ListOfLocTimeTempsSchemaMap = <String, dynamic>{
  r'$schema': r'https://json-schema.org/draft/2020-12/schema',
  r'type': r'object',
  r'properties': {
    r'locations': {
      r'type': r'array',
      r'items': {r'$ref': r'#/$defs/LocTimeTemp'},
      r'description':
          r'/// A list of locations with their current time and temperature',
    },
  },
  r'required': [r'locations'],
  r'$defs': {},
};

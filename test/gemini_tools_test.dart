// ignore_for_file: lines_longer_than_80_chars, avoid_print

import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:test/test.dart';

void main() {
  group('GeminiModel.toolsFrom', () {
    test('converts simple string parameter tool', () {
      final tools = [
        Tool(
          name: 'search_web',
          description: 'Search the web for information',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'query': {
                    'type': 'string',
                    'description': 'The search query to execute',
                  },
                },
                'required': ['query'],
              }.toSchema(),
          onCall: (input) async => {'result': 'mock search result'},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();

      expect(geminiTools, hasLength(1));
      final tool = geminiTools[0];
      expect(tool.functionDeclarations, isNotNull);
      expect(tool.functionDeclarations, hasLength(1));

      final functionDecl = tool.functionDeclarations![0];
      expect(functionDecl.name, equals('search_web'));
      expect(
        functionDecl.description,
        equals('Search the web for information'),
      );

      final params = functionDecl.parameters;
      expect(params, isNotNull);
      expect(params!.type, equals(gemini.SchemaType.object));
      expect(params.properties, isNotNull);
      expect(params.properties, hasLength(1));
      expect(
        params.properties!['query']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        params.properties!['query']?.description,
        equals('The search query to execute'),
      );
      expect(params.requiredProperties, equals(['query']));
    });

    test('converts complex nested object tool', () {
      final tools = [
        Tool(
          name: 'create_user',
          description: 'Create a new user account',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'user': {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string', 'description': 'Full name'},
                      'email': {
                        'type': 'string',
                        'description': 'Email address',
                      },
                      'age': {'type': 'integer', 'description': 'Age in years'},
                      'active': {
                        'type': 'boolean',
                        'description': 'Account status',
                      },
                    },
                    'required': ['name', 'email'],
                  },
                  'settings': {
                    'type': 'object',
                    'properties': {
                      'theme': {
                        'type': 'string',
                        'enum': ['light', 'dark', 'auto'],
                        'description': 'UI theme preference',
                      },
                      'notifications': {'type': 'boolean'},
                    },
                  },
                },
                'required': ['user'],
              }.toSchema(),
          onCall: (input) async => {'userId': '12345'},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();
      final functionDecl = geminiTools[0].functionDeclarations![0];

      expect(functionDecl.name, equals('create_user'));
      final params = functionDecl.parameters!;
      expect(params.type, equals(gemini.SchemaType.object));
      expect(params.requiredProperties, equals(['user']));

      // Check user object
      final userProperty = params.properties!['user'];
      expect(userProperty, isNotNull);
      expect(userProperty!.type, equals(gemini.SchemaType.object));
      expect(userProperty.properties, hasLength(4));
      expect(
        userProperty.properties!['name']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        userProperty.properties!['email']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        userProperty.properties!['age']?.type,
        equals(gemini.SchemaType.integer),
      );
      expect(
        userProperty.properties!['active']?.type,
        equals(gemini.SchemaType.boolean),
      );
      expect(userProperty.requiredProperties, equals(['name', 'email']));

      // Check settings object
      final settingsProperty = params.properties!['settings'];
      expect(settingsProperty, isNotNull);
      expect(settingsProperty!.type, equals(gemini.SchemaType.object));
      final themeProperty = settingsProperty.properties!['theme'];
      expect(themeProperty, isNotNull);
      expect(themeProperty!.type, equals(gemini.SchemaType.string));
    });

    test('converts array parameter tool', () {
      final tools = [
        Tool(
          name: 'batch_process',
          description: 'Process multiple items',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'items': {
                    'type': 'array',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'id': {'type': 'string'},
                        'value': {'type': 'number'},
                      },
                      'required': ['id'],
                    },
                    'description': 'Array of items to process',
                  },
                  'options': {
                    'type': 'array',
                    'items': {'type': 'string'},
                    'description': 'Processing options',
                  },
                },
                'required': ['items'],
              }.toSchema(),
          onCall: (input) async => {'processed': true},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();
      final functionDecl = geminiTools[0].functionDeclarations![0];

      expect(functionDecl.name, equals('batch_process'));
      final params = functionDecl.parameters!;

      // Check items array
      final itemsProperty = params.properties!['items'];
      expect(itemsProperty, isNotNull);
      expect(itemsProperty!.type, equals(gemini.SchemaType.array));
      expect(itemsProperty.items, isNotNull);
      expect(itemsProperty.items!.type, equals(gemini.SchemaType.object));
      expect(itemsProperty.items!.properties, isNotNull);
      expect(itemsProperty.items!.properties, hasLength(2));
      expect(
        itemsProperty.items!.properties!['id']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        itemsProperty.items!.properties!['value']?.type,
        equals(gemini.SchemaType.number),
      );

      // Check options array
      final optionsProperty = params.properties!['options'];
      expect(optionsProperty, isNotNull);
      expect(optionsProperty!.type, equals(gemini.SchemaType.array));
      expect(optionsProperty.items!.type, equals(gemini.SchemaType.string));
    });

    test('converts HuggingFace-style text generation tool', () {
      final tools = [
        Tool(
          name: 'text_generation',
          description: 'Generate text using a language model',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'inputs': {
                    'type': 'string',
                    'description': 'The input text to generate from',
                  },
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'max_new_tokens': {
                        'type': 'integer',
                        'description': 'Maximum number of tokens to generate',
                        'minimum': 1,
                        'maximum': 4096,
                      },
                      'temperature': {
                        'type': 'number',
                        'description': 'Sampling temperature',
                        'minimum': 0.0,
                        'maximum': 2.0,
                      },
                      'top_p': {
                        'type': 'number',
                        'description': 'Nucleus sampling parameter',
                        'minimum': 0.0,
                        'maximum': 1.0,
                      },
                      'do_sample': {
                        'type': 'boolean',
                        'description': 'Whether to use sampling',
                      },
                      'stop_sequences': {
                        'type': 'array',
                        'items': {'type': 'string'},
                        'description': 'List of sequences to stop generation',
                      },
                    },
                  },
                },
                'required': ['inputs'],
              }.toSchema(),
          onCall: (input) async => {'generated_text': 'Mock generated text'},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();
      final textGenTool = geminiTools[0].functionDeclarations![0];

      expect(textGenTool.name, equals('text_generation'));
      final params = textGenTool.parameters!;
      expect(params.requiredProperties, equals(['inputs']));

      final parametersProperty = params.properties!['parameters'];
      expect(parametersProperty, isNotNull);
      expect(parametersProperty!.type, equals(gemini.SchemaType.object));
      expect(
        parametersProperty.properties!['max_new_tokens']?.type,
        equals(gemini.SchemaType.integer),
      );
      expect(
        parametersProperty.properties!['temperature']?.type,
        equals(gemini.SchemaType.number),
      );
      expect(
        parametersProperty.properties!['do_sample']?.type,
        equals(gemini.SchemaType.boolean),
      );

      final stopSequencesProperty =
          parametersProperty.properties!['stop_sequences'];
      expect(stopSequencesProperty, isNotNull);
      expect(stopSequencesProperty!.type, equals(gemini.SchemaType.array));
      expect(
        stopSequencesProperty.items!.type,
        equals(gemini.SchemaType.string),
      );
    });

    test('converts tool with enum values', () {
      final tools = [
        Tool(
          name: 'set_status',
          description: 'Set user status',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'status': {
                    'type': 'string',
                    'enum': ['online', 'away', 'busy', 'offline'],
                    'description': 'User status',
                  },
                  'priority': {
                    'type': 'string',
                    'enum': ['low', 'medium', 'high'],
                    'description': 'Priority level',
                  },
                },
                'required': ['status'],
              }.toSchema(),
          onCall: (input) async => {'success': true},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();
      final functionDecl = geminiTools[0].functionDeclarations![0];

      expect(functionDecl.name, equals('set_status'));
      final params = functionDecl.parameters!;

      final statusProperty = params.properties!['status'];
      expect(statusProperty, isNotNull);
      expect(statusProperty!.type, equals(gemini.SchemaType.string));

      final priorityProperty = params.properties!['priority'];
      expect(priorityProperty, isNotNull);
      expect(priorityProperty!.type, equals(gemini.SchemaType.string));
    });

    test('converts tool with no input schema', () {
      final tools = [
        Tool(
          name: 'get_time',
          description: 'Get current time',
          onCall: (input) async => {'time': DateTime.now().toIso8601String()},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();
      final functionDecl = geminiTools[0].functionDeclarations![0];

      expect(functionDecl.name, equals('get_time'));
      expect(functionDecl.description, equals('Get current time'));
      final params = functionDecl.parameters!;
      expect(params.type, equals(gemini.SchemaType.object));
      expect(params.properties, isEmpty);
    });

    test('converts multiple tools', () {
      final tools = [
        Tool(
          name: 'tool1',
          description: 'First tool',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'param1': {'type': 'string'},
                },
              }.toSchema(),
          onCall: (input) async => {'result': 'tool1'},
        ),
        Tool(
          name: 'tool2',
          description: 'Second tool',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'param2': {'type': 'integer'},
                },
              }.toSchema(),
          onCall: (input) async => {'result': 'tool2'},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();

      expect(geminiTools, hasLength(2));
      expect(geminiTools[0].functionDeclarations![0].name, equals('tool1'));
      expect(geminiTools[1].functionDeclarations![0].name, equals('tool2'));
    });

    test('handles empty tools list', () {
      final geminiTools = GeminiModel.toolsFrom([]).toList();
      expect(geminiTools, isEmpty);
    });

    test('converts HuggingFace image classification tool', () {
      final tools = [
        Tool(
          name: 'image_classification',
          description: 'Classify images using a vision model',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'inputs': {
                    'type': 'string',
                    'description': 'Base64 encoded image or image URL',
                  },
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'top_k': {
                        'type': 'integer',
                        'description': 'Number of top predictions to return',
                        'minimum': 1,
                        'maximum': 10,
                      },
                    },
                  },
                },
                'required': ['inputs'],
              }.toSchema(),
          onCall:
              (input) async => {
                'predictions': [
                  {'label': 'cat', 'score': 0.95},
                  {'label': 'dog', 'score': 0.03},
                ],
              },
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();
      final imageClassTool = geminiTools[0].functionDeclarations![0];

      expect(imageClassTool.name, equals('image_classification'));
      expect(
        imageClassTool.description,
        equals('Classify images using a vision model'),
      );
      final params = imageClassTool.parameters!;
      expect(params.requiredProperties, equals(['inputs']));

      // Verify inputs parameter
      final inputsProperty = params.properties!['inputs'];
      expect(inputsProperty, isNotNull);
      expect(inputsProperty!.type, equals(gemini.SchemaType.string));

      // Verify parameters object
      final parametersProperty = params.properties!['parameters'];
      expect(parametersProperty, isNotNull);
      expect(parametersProperty!.type, equals(gemini.SchemaType.object));

      final topKProperty = parametersProperty.properties!['top_k'];
      expect(topKProperty, isNotNull);
      expect(topKProperty!.type, equals(gemini.SchemaType.integer));
    });

    test('converts complex real-world tool with nested arrays and objects', () {
      final tools = [
        Tool(
          name: 'create_workflow',
          description: 'Create a complex workflow with multiple steps',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'workflow': {
                    'type': 'object',
                    'properties': {
                      'name': {
                        'type': 'string',
                        'description': 'Workflow name',
                      },
                      'description': {'type': 'string'},
                      'steps': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'id': {'type': 'string'},
                            'type': {
                              'type': 'string',
                              'enum': [
                                'action',
                                'condition',
                                'loop',
                                'parallel',
                              ],
                            },
                            'config': {
                              'type': 'object',
                              'properties': {
                                'timeout': {'type': 'integer'},
                                'retry_count': {'type': 'integer'},
                                'parameters': {
                                  'type': 'array',
                                  'items': {
                                    'type': 'object',
                                    'properties': {
                                      'key': {'type': 'string'},
                                      'value': {'type': 'string'},
                                      'encrypted': {'type': 'boolean'},
                                    },
                                    'required': ['key', 'value'],
                                  },
                                },
                              },
                            },
                          },
                          'required': ['id', 'type'],
                        },
                      },
                    },
                    'required': ['name', 'steps'],
                  },
                  'metadata': {
                    'type': 'object',
                    'properties': {
                      'tags': {
                        'type': 'array',
                        'items': {'type': 'string'},
                      },
                      'priority': {
                        'type': 'string',
                        'enum': ['low', 'medium', 'high', 'critical'],
                      },
                    },
                  },
                },
                'required': ['workflow'],
              }.toSchema(),
          onCall: (input) async => {'workflowId': 'wf-12345'},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();
      final functionDecl = geminiTools[0].functionDeclarations![0];

      expect(functionDecl.name, equals('create_workflow'));
      final params = functionDecl.parameters!;
      expect(params.requiredProperties, equals(['workflow']));

      // Verify workflow object structure
      final workflowProperty = params.properties!['workflow'];
      expect(workflowProperty, isNotNull);
      expect(workflowProperty!.type, equals(gemini.SchemaType.object));
      expect(workflowProperty.requiredProperties, equals(['name', 'steps']));

      // Verify steps array
      final stepsProperty = workflowProperty.properties!['steps'];
      expect(stepsProperty, isNotNull);
      expect(stepsProperty!.type, equals(gemini.SchemaType.array));
      expect(stepsProperty.items!.type, equals(gemini.SchemaType.object));

      // Verify step object structure
      final stepItems = stepsProperty.items!;
      expect(stepItems.requiredProperties, equals(['id', 'type']));
      expect(
        stepItems.properties!['id']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        stepItems.properties!['type']?.type,
        equals(gemini.SchemaType.string),
      );

      // Verify config object in steps
      final configProperty = stepItems.properties!['config'];
      expect(configProperty, isNotNull);
      expect(configProperty!.type, equals(gemini.SchemaType.object));

      // Verify parameters array in config
      final parametersProperty = configProperty.properties!['parameters'];
      expect(parametersProperty, isNotNull);
      expect(parametersProperty!.type, equals(gemini.SchemaType.array));
      expect(parametersProperty.items!.type, equals(gemini.SchemaType.object));
      expect(
        parametersProperty.items!.requiredProperties,
        equals(['key', 'value']),
      );

      // Verify metadata object
      final metadataProperty = params.properties!['metadata'];
      expect(metadataProperty, isNotNull);
      expect(metadataProperty!.type, equals(gemini.SchemaType.object));

      final tagsProperty = metadataProperty.properties!['tags'];
      expect(tagsProperty, isNotNull);
      expect(tagsProperty!.type, equals(gemini.SchemaType.array));
      expect(tagsProperty.items!.type, equals(gemini.SchemaType.string));
    });

    test('converts Zapier Google Calendar tools', () {
      final tools = [
        // Tools with empty schema
        Tool(
          name: 'add_tools',
          description: 'Add new actions to your MCP provider',
          inputSchema: {'type': 'object', 'properties': {}}.toSchema(),
          onCall: (input) async => {'success': true},
        ),
        Tool(
          name: 'edit_tools',
          description: 'Edit your existing MCP provider actions',
          inputSchema: {'type': 'object', 'properties': {}}.toSchema(),
          onCall: (input) async => {'success': true},
        ),
        // Event retrieval tool
        Tool(
          name: 'google_calendar_retrieve_event_by_id',
          description: 'Finds a specific event by its ID in your calendar.',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'instructions': {
                    'type': 'string',
                    'description':
                        'Instructions for running this tool. Any '
                        'parameters that are not given a value will be guessed '
                        'based on the instructions.',
                  },
                  'event_id': {'type': 'string', 'description': 'Event ID'},
                  'calendarid': {'type': 'string', 'description': 'Calendar'},
                },
                'required': ['instructions'],
              }.toSchema(),
          onCall: (input) async => {'event': 'mock_event'},
        ),
        // Event search tool with complex parameters
        Tool(
          name: 'google_calendar_find_event',
          description:
              'Finds an event in your calendar. (Fixed parameters: '
              'calendarid: csells@sellsbrothers.com)',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'instructions': {
                    'type': 'string',
                    'description':
                        'Instructions for running this tool. Any '
                        'parameters that are not given a value will be guessed '
                        'based on the instructions.',
                  },
                  'end_time': {
                    'type': 'string',
                    'description':
                        'This field sets the EARLIEST timestamp '
                        "(lower boundary) to find events. So the events' "
                        'start_time will be greater than this timestamp: e.g. '
                        'To find events scheduled for today, the end_time should '
                        'be set to the earliest of today e.g. To find events '
                        'scheduled for this week, the end_time should be set to '
                        'earliest of this week e.g. To find events scheduled for '
                        'yesterday, the end_time should be set to earliest of '
                        'yesterday e.g. To find events scheduled for tomorrow, '
                        'the end_time should be set to earliest of tomorrow',
                  },
                  'ordering': {'type': 'string', 'description': 'Sort Order'},
                  'eventTypes': {'type': 'string', 'description': 'Event Type'},
                  'start_time': {
                    'type': 'string',
                    'description':
                        'This field sets the LATEST timestamp '
                        "(upper boundary) to find events. So the events' "
                        'end_time will be less than this timestamp: e.g. To find '
                        'events scheduled for today, the start_time should be set '
                        "to 'today at 11:59pm' e.g. To find events scheduled "
                        "for this week, the start_time should be set to 'this "
                        "week last day at 11:59pm' e.g. To find events scheduled "
                        'for yesterday, the start_time should be set to '
                        "'yesterday 11:59pm' e.g. To find events scheduled for "
                        "tomorrow, the start_time should be set to 'tomorrow  "
                        "11:59pm'",
                  },
                  'search_term': {
                    'type': 'string',
                    'description':
                        'ONLY generate a value for this field if '
                        'explicitly asked to filter events. Will search across '
                        'the event name and description. Does not include '
                        'canceled events. **Note**: Search operators such as '
                        '`AND` or `OR` do not work here. If you search for more '
                        'than one word (e.g. `apple banana`) we will only find '
                        'events with both `apple` *AND* `banana` in them, rather '
                        'than events that contains `apple` *OR* `banana`. You can '
                        'also use a negative modifier to exclude terms (example: '
                        '"-apple")',
                  },
                  'expand_recurring': {
                    'type': 'string',
                    'description': 'Expand Recurring Events',
                  },
                },
                'required': ['instructions'],
              }.toSchema(),
          onCall: (input) async => {'events': []},
        ),
        // Busy periods tool
        Tool(
          name: 'google_calendar_find_busy_periods_in_calendar',
          description:
              'Finds busy time periods in your calendar for a specific '
              'timeframe.',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'instructions': {
                    'type': 'string',
                    'description':
                        'Instructions for running this tool. Any '
                        'parameters that are not given a value will be guessed '
                        'based on the instructions.',
                  },
                  'end_time': {'type': 'string', 'description': 'End Time'},
                  'calendarid': {'type': 'string', 'description': 'Calendar'},
                  'start_time': {'type': 'string', 'description': 'Start Time'},
                },
                'required': ['instructions'],
              }.toSchema(),
          onCall: (input) async => {'busy_periods': []},
        ),
        // Quick add event tool
        Tool(
          name: 'google_calendar_quick_add_event',
          description:
              'Create an event from a piece of text. Google parses '
              'the text for date, time, and description info.',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'instructions': {
                    'type': 'string',
                    'description':
                        'Instructions for running this tool. Any '
                        'parameters that are not given a value will be guessed '
                        'based on the instructions.',
                  },
                  'text': {'type': 'string', 'description': 'Describe Event'},
                  'attendees': {'type': 'string', 'description': 'Attendees'},
                  'calendarid': {'type': 'string', 'description': 'Calendar'},
                },
                'required': ['instructions'],
              }.toSchema(),
          onCall: (input) async => {'event_created': true},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();

      expect(geminiTools, hasLength(6));

      // Test empty schema tools
      final addToolsDecl = geminiTools[0].functionDeclarations![0];
      expect(addToolsDecl.name, equals('add_tools'));
      expect(
        addToolsDecl.description,
        equals('Add new actions to your MCP provider'),
      );
      final addToolsParams = addToolsDecl.parameters!;
      expect(addToolsParams.type, equals(gemini.SchemaType.object));
      expect(addToolsParams.properties, isEmpty);

      final editToolsDecl = geminiTools[1].functionDeclarations![0];
      expect(editToolsDecl.name, equals('edit_tools'));

      // Test event retrieval tool
      final retrieveEventDecl = geminiTools[2].functionDeclarations![0];
      expect(
        retrieveEventDecl.name,
        equals('google_calendar_retrieve_event_by_id'),
      );
      expect(
        retrieveEventDecl.description,
        equals('Finds a specific event by its ID in your calendar.'),
      );
      final retrieveParams = retrieveEventDecl.parameters!;

      // Debug: Print complete tool comparison
      final retrieveEventTool =
          tools[2]; // google_calendar_retrieve_event_by_id
      print('\n=== COMPLETE TOOL COMPARISON ===');
      print('Tool: ${retrieveEventTool.name}');

      print('\n--- INPUT TOOL OBJECT ---');
      print('Name: ${retrieveEventTool.name}');
      print('Description: ${retrieveEventTool.description}');
      print('Input Schema:');
      final inputSchemaMap = retrieveEventTool.inputSchema?.toMap();
      if (inputSchemaMap != null) {
        final prettyJson = const JsonEncoder.withIndent(
          '  ',
        ).convert(inputSchemaMap);
        print(prettyJson);
      } else {
        print('  null');
      }

      print('\n--- OUTPUT GEMINI FUNCTION DECLARATION ---');
      print('Name: ${retrieveEventDecl.name}');
      print('Description: ${retrieveEventDecl.description}');
      print('Parameters:');
      print('  Type: ${retrieveParams.type}');
      print('  Properties count: ${retrieveParams.properties?.length}');
      print('  Required properties: ${retrieveParams.requiredProperties}');
      print('  All Properties:');
      retrieveParams.properties?.forEach((key, value) {
        print('    $key:');
        print('      type: ${value.type}');
        print('      description: ${value.description}');
        print('      nullable: ${value.nullable}');
        print('      format: ${value.format}');
      });
      print('=== End Tool Comparison ===\n');

      expect(retrieveParams.properties, hasLength(3));
      expect(
        retrieveParams.properties!['instructions']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        retrieveParams.properties!['event_id']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        retrieveParams.properties!['calendarid']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        retrieveParams.properties!['instructions']?.description,
        contains('Instructions for running'),
      );

      // Test complex find event tool
      final findEventDecl = geminiTools[3].functionDeclarations![0];
      expect(findEventDecl.name, equals('google_calendar_find_event'));
      expect(
        findEventDecl.description,
        contains('Finds an event in your calendar'),
      );
      final findParams = findEventDecl.parameters!;
      expect(findParams.properties, hasLength(7));
      expect(
        findParams.properties!['end_time']?.description,
        contains('EARLIEST timestamp'),
      );
      expect(
        findParams.properties!['start_time']?.description,
        contains('LATEST timestamp'),
      );
      expect(
        findParams.properties!['search_term']?.description,
        contains('Search operators'),
      );
      expect(
        findParams.properties!['expand_recurring']?.type,
        equals(gemini.SchemaType.string),
      );

      // Test busy periods tool
      final busyPeriodsDecl = geminiTools[4].functionDeclarations![0];
      expect(
        busyPeriodsDecl.name,
        equals('google_calendar_find_busy_periods_in_calendar'),
      );
      expect(
        busyPeriodsDecl.description,
        equals(
          'Finds busy time periods in your calendar for a specific timeframe.',
        ),
      );
      final busyParams = busyPeriodsDecl.parameters!;
      expect(busyParams.properties, hasLength(4));

      // Test quick add event tool
      final quickAddDecl = geminiTools[5].functionDeclarations![0];
      expect(quickAddDecl.name, equals('google_calendar_quick_add_event'));
      expect(
        quickAddDecl.description,
        contains('Create an event from a piece of text'),
      );
      final quickAddParams = quickAddDecl.parameters!;
      expect(quickAddParams.properties, hasLength(4));
      expect(
        quickAddParams.properties!['text']?.description,
        equals('Describe Event'),
      );
      expect(
        quickAddParams.properties!['attendees']?.description,
        equals('Attendees'),
      );
    });

    test('converts HuggingFace tools with constraints and defaults', () {
      final tools = [
        // Tool with empty schema
        Tool(
          name: 'hf_whoami',
          description:
              'Hugging Face tools are being used anonymously and '
              'may be rate limited. Call this tool for instructions on '
              'joining and authenticating.',
          inputSchema: {'type': 'object', 'properties': {}}.toSchema(),
          onCall: (input) async => {'user': 'anonymous'},
        ),
        // Space search with constraints
        Tool(
          name: 'space_search',
          description:
              'Find Hugging Face Spaces using semantic search. '
              'Include links to the Space when presenting the results.',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'query': {
                    'type': 'string',
                    'minLength': 1,
                    'maxLength': 100,
                    'description': 'Semantic Search Query',
                  },
                  'limit': {
                    'type': 'number',
                    'default': 10,
                    'description': 'Number of results to return',
                  },
                  'mcp': {
                    'type': 'boolean',
                    'default': false,
                    'description': 'Only return MCP Server enabled Spaces',
                  },
                },
                'required': ['query'],
              }.toSchema(),
          onCall: (input) async => {'spaces': []},
        ),
        // Model search with enums and constraints
        Tool(
          name: 'model_search',
          description:
              'Find Machine Learning models hosted on Hugging Face. '
              'Returns comprehensive information about matching models '
              'including downloads, likes, tags, and direct links. Include '
              'links to the models in your response',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'query': {
                    'type': 'string',
                    'description':
                        'Search term. Leave blank and specify "sort" '
                        'and "limit" to get e.g. "Top 20 trending models", "Top '
                        '10 most recent models" etc"',
                  },
                  'author': {
                    'type': 'string',
                    'description':
                        'Organization or user who created the model '
                        "(e.g., 'google', 'meta-llama', 'microsoft')",
                  },
                  'task': {
                    'type': 'string',
                    'description':
                        "Model task type (e.g., 'text-generation', "
                        "'image-classification', 'translation')",
                  },
                  'library': {
                    'type': 'string',
                    'description':
                        'Framework the model uses (e.g., '
                        "'transformers', 'diffusers', 'timm')",
                  },
                  'sort': {
                    'type': 'string',
                    'enum': [
                      'trendingScore',
                      'downloads',
                      'likes',
                      'createdAt',
                      'lastModified',
                    ],
                    'description':
                        'Sort order: trendingScore, downloads , likes, '
                        'createdAt, lastModified',
                  },
                  'limit': {
                    'type': 'number',
                    'minimum': 1,
                    'maximum': 100,
                    'default': 20,
                    'description': 'Maximum number of results to return',
                  },
                },
              }.toSchema(),
          onCall: (input) async => {'models': []},
        ),
        // Dataset search with array properties
        Tool(
          name: 'dataset_search',
          description:
              'Find Datasets hosted on the Hugging Face hub. '
              'Returns comprehensive information about matching datasets '
              'including downloads, likes, tags, and direct links. Include '
              'links to the datasets in your response',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'query': {
                    'type': 'string',
                    'description':
                        'Search term. Leave blank and specify "sort" '
                        'and "limit" to get e.g. "Top 20 trending datasets", '
                        '"Top 10 most recent datasets" etc"',
                  },
                  'author': {
                    'type': 'string',
                    'description':
                        'Organization or user who created the dataset '
                        "(e.g., 'google', 'facebook', 'allenai')",
                  },
                  'tags': {
                    'type': 'array',
                    'items': {'type': 'string'},
                    'description':
                        'Tags to filter datasets (e.g., '
                        "['language:en', 'size_categories:1M<n<10M', "
                        "'task_categories:text-classification'])",
                  },
                  'sort': {
                    'type': 'string',
                    'enum': [
                      'trendingScore',
                      'downloads',
                      'likes',
                      'createdAt',
                      'lastModified',
                    ],
                    'description':
                        'Sort order: trendingScore, downloads, likes, '
                        'createdAt, lastModified',
                  },
                  'limit': {
                    'type': 'number',
                    'minimum': 1,
                    'maximum': 100,
                    'default': 20,
                    'description': 'Maximum number of results to return',
                  },
                },
              }.toSchema(),
          onCall: (input) async => {'datasets': []},
        ),
        // Model details tool
        Tool(
          name: 'model_details',
          description:
              'Get detailed information about a specific model from the Hugging Face Hub.',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'model_id': {
                    'type': 'string',
                    'minLength': 1,
                    'description': 'Model ID (e.g., microsoft/DialoGPT-large)',
                  },
                },
                'required': ['model_id'],
              }.toSchema(),
          onCall: (input) async => {'model_info': {}},
        ),
        // Paper search tool
        Tool(
          name: 'paper_search',
          description:
              "Find Machine Learning research papers on the Hugging Face hub. Include 'Link to paper' When presenting the results. Consider whether tabulating results matches user intent.",
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'query': {
                    'type': 'string',
                    'minLength': 3,
                    'maxLength': 200,
                    'description': 'Semantic Search query',
                  },
                  'results_limit': {
                    'type': 'number',
                    'default': 12,
                    'description': 'Number of results to return',
                  },
                  'concise_only': {
                    'type': 'boolean',
                    'default': false,
                    'description':
                        'Return a 2 sentence summary of the abstract. Use for broad search terms which may return a lot of results. Check with User if unsure.',
                  },
                },
                'required': ['query'],
              }.toSchema(),
          onCall: (input) async => {'papers': []},
        ),
        // Dataset details tool
        Tool(
          name: 'dataset_details',
          description:
              'Get detailed information about a specific dataset on Hugging Face Hub.',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'dataset_id': {
                    'type': 'string',
                    'minLength': 1,
                    'description': 'Dataset ID (e.g., squad, glue, imdb)',
                  },
                },
                'required': ['dataset_id'],
              }.toSchema(),
          onCall: (input) async => {'dataset_info': {}},
        ),
        // Image generation with numeric ranges
        Tool(
          name: 'gr1_evalstate_flux1_schnell',
          description:
              'Generate an image using the Flux 1 Schnell Image '
              'Generator. (from evalstate/flux1_schnell)',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'prompt': {'type': 'string'},
                  'seed': {
                    'type': 'number',
                    'description': 'numeric value between 0 and 2147483647',
                  },
                  'randomize_seed': {'type': 'boolean', 'default': true},
                  'width': {
                    'type': 'number',
                    'description': 'numeric value between 256 and 2048',
                    'default': 1024,
                  },
                  'height': {
                    'type': 'number',
                    'description': 'numeric value between 256 and 2048',
                    'default': 1024,
                  },
                  'num_inference_steps': {
                    'type': 'number',
                    'description': 'numeric value between 1 and 50',
                    'default': 4,
                  },
                },
              }.toSchema(),
          onCall:
              (input) async => {'image_url': 'https://example.com/image.png'},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();

      expect(geminiTools, hasLength(8));

      // Test empty schema tool
      final whoamiDecl = geminiTools[0].functionDeclarations![0];
      expect(whoamiDecl.name, equals('hf_whoami'));
      expect(
        whoamiDecl.description,
        contains('Hugging Face tools are being used anonymously'),
      );
      final whoamiParams = whoamiDecl.parameters!;
      expect(whoamiParams.type, equals(gemini.SchemaType.object));
      expect(whoamiParams.properties, isEmpty);

      // Test space search with constraints
      final spaceSearchDecl = geminiTools[1].functionDeclarations![0];
      expect(spaceSearchDecl.name, equals('space_search'));
      expect(spaceSearchDecl.description, contains('Find Hugging Face Spaces'));
      final spaceParams = spaceSearchDecl.parameters!;
      expect(spaceParams.properties, hasLength(3));
      expect(
        spaceParams.properties!['query']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        spaceParams.properties!['limit']?.type,
        equals(gemini.SchemaType.number),
      );
      expect(
        spaceParams.properties!['mcp']?.type,
        equals(gemini.SchemaType.boolean),
      );
      // Verify required field is properly converted
      expect(spaceParams.requiredProperties, equals(['query']));

      // Test model search with enums
      final modelSearchDecl = geminiTools[2].functionDeclarations![0];
      expect(modelSearchDecl.name, equals('model_search'));
      expect(
        modelSearchDecl.description,
        contains('Find Machine Learning models'),
      );
      final modelParams = modelSearchDecl.parameters!;
      expect(modelParams.properties, hasLength(6));
      expect(
        modelParams.properties!['sort']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        modelParams.properties!['limit']?.type,
        equals(gemini.SchemaType.number),
      );
      expect(
        modelParams.properties!['query']?.description,
        contains('Search term'),
      );

      // Test dataset search with arrays
      final datasetSearchDecl = geminiTools[3].functionDeclarations![0];
      expect(datasetSearchDecl.name, equals('dataset_search'));
      expect(datasetSearchDecl.description, contains('Find Datasets hosted'));
      final datasetParams = datasetSearchDecl.parameters!;
      expect(datasetParams.properties, hasLength(5));
      final tagsProperty = datasetParams.properties!['tags'];
      expect(tagsProperty, isNotNull);
      expect(tagsProperty!.type, equals(gemini.SchemaType.array));
      expect(tagsProperty.items!.type, equals(gemini.SchemaType.string));
      expect(tagsProperty.description, contains('Tags to filter datasets'));

      // Test model details with required field
      final modelDetailsDecl = geminiTools[4].functionDeclarations![0];
      expect(modelDetailsDecl.name, equals('model_details'));
      expect(
        modelDetailsDecl.description,
        contains('Get detailed information about a specific model'),
      );
      final modelDetailsParams = modelDetailsDecl.parameters!;
      expect(modelDetailsParams.properties, hasLength(1));
      expect(
        modelDetailsParams.properties!['model_id']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(modelDetailsParams.requiredProperties, equals(['model_id']));

      // Test paper search with required field
      final paperSearchDecl = geminiTools[5].functionDeclarations![0];
      expect(paperSearchDecl.name, equals('paper_search'));
      expect(
        paperSearchDecl.description,
        contains('Find Machine Learning research papers'),
      );
      final paperSearchParams = paperSearchDecl.parameters!;
      expect(paperSearchParams.properties, hasLength(3));
      expect(
        paperSearchParams.properties!['query']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(paperSearchParams.requiredProperties, equals(['query']));

      // Test dataset details with required field
      final datasetDetailsDecl = geminiTools[6].functionDeclarations![0];
      expect(datasetDetailsDecl.name, equals('dataset_details'));
      expect(
        datasetDetailsDecl.description,
        contains('Get detailed information about a specific dataset'),
      );
      final datasetDetailsParams = datasetDetailsDecl.parameters!;
      expect(datasetDetailsParams.properties, hasLength(1));
      expect(
        datasetDetailsParams.properties!['dataset_id']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(datasetDetailsParams.requiredProperties, equals(['dataset_id']));

      // Test image generation with numeric ranges
      final imageGenDecl = geminiTools[7].functionDeclarations![0];
      expect(imageGenDecl.name, equals('gr1_evalstate_flux1_schnell'));
      expect(imageGenDecl.description, contains('Generate an image using'));
      final imageParams = imageGenDecl.parameters!;
      expect(imageParams.properties, hasLength(6));
      expect(
        imageParams.properties!['prompt']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        imageParams.properties!['seed']?.type,
        equals(gemini.SchemaType.number),
      );
      expect(
        imageParams.properties!['randomize_seed']?.type,
        equals(gemini.SchemaType.boolean),
      );
      expect(
        imageParams.properties!['width']?.type,
        equals(gemini.SchemaType.number),
      );
      expect(
        imageParams.properties!['height']?.type,
        equals(gemini.SchemaType.number),
      );
      expect(
        imageParams.properties!['num_inference_steps']?.type,
        equals(gemini.SchemaType.number),
      );
      expect(
        imageParams.properties!['width']?.description,
        contains('numeric value between 256 and 2048'),
      );
    });

    test('converts deepwiki GitHub repository tools', () {
      final tools = [
        Tool(
          name: 'read_wiki_structure',
          description:
              'Get a list of documentation topics for a GitHub repository',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'repoName': {
                    'type': 'string',
                    'description':
                        'GitHub repository: owner/repo (e.g. "facebook/react")',
                  },
                },
                'required': ['repoName'],
              }.toSchema(),
          onCall: (input) async => {'topics': []},
        ),
        Tool(
          name: 'read_wiki_contents',
          description: 'View documentation about a GitHub repository',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'repoName': {
                    'type': 'string',
                    'description':
                        'GitHub repository: owner/repo (e.g. "facebook/react")',
                  },
                },
                'required': ['repoName'],
              }.toSchema(),
          onCall: (input) async => {'content': 'wiki content'},
        ),
        Tool(
          name: 'ask_question',
          description: 'Ask any question about a GitHub repository',
          inputSchema:
              {
                'type': 'object',
                'properties': {
                  'repoName': {
                    'type': 'string',
                    'description':
                        'GitHub repository: owner/repo (e.g. "facebook/react")',
                  },
                  'question': {
                    'type': 'string',
                    'description': 'The question to ask about the repository',
                  },
                },
                'required': ['repoName', 'question'],
              }.toSchema(),
          onCall: (input) async => {'answer': 'repository answer'},
        ),
      ];

      final geminiTools = GeminiModel.toolsFrom(tools).toList();

      expect(geminiTools, hasLength(3));

      // Test wiki structure tool
      final wikiStructureDecl = geminiTools[0].functionDeclarations![0];
      expect(wikiStructureDecl.name, equals('read_wiki_structure'));
      expect(
        wikiStructureDecl.description,
        equals('Get a list of documentation topics for a GitHub repository'),
      );
      final structureParams = wikiStructureDecl.parameters!;
      expect(structureParams.type, equals(gemini.SchemaType.object));
      expect(structureParams.properties, hasLength(1));
      expect(
        structureParams.properties!['repoName']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        structureParams.properties!['repoName']?.description,
        equals('GitHub repository: owner/repo (e.g. "facebook/react")'),
      );
      expect(structureParams.requiredProperties, equals(['repoName']));

      // Test wiki contents tool
      final wikiContentsDecl = geminiTools[1].functionDeclarations![0];
      expect(wikiContentsDecl.name, equals('read_wiki_contents'));
      expect(
        wikiContentsDecl.description,
        equals('View documentation about a GitHub repository'),
      );
      final contentsParams = wikiContentsDecl.parameters!;
      expect(contentsParams.type, equals(gemini.SchemaType.object));
      expect(contentsParams.properties, hasLength(1));
      expect(
        contentsParams.properties!['repoName']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(contentsParams.requiredProperties, equals(['repoName']));

      // Test ask question tool
      final askQuestionDecl = geminiTools[2].functionDeclarations![0];
      expect(askQuestionDecl.name, equals('ask_question'));
      expect(
        askQuestionDecl.description,
        equals('Ask any question about a GitHub repository'),
      );
      final questionParams = askQuestionDecl.parameters!;
      expect(questionParams.type, equals(gemini.SchemaType.object));
      expect(questionParams.properties, hasLength(2));
      expect(
        questionParams.properties!['repoName']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        questionParams.properties!['question']?.type,
        equals(gemini.SchemaType.string),
      );
      expect(
        questionParams.properties!['question']?.description,
        equals('The question to ask about the repository'),
      );
      expect(
        questionParams.requiredProperties,
        equals(['repoName', 'question']),
      );
    });
  });
}

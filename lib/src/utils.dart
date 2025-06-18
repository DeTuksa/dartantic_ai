import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

// ignore: public_member_api_docs
final log = Logger('dartantic_ai');

const _uuid = Uuid();

/// Generates a unique tool call ID.
String generateToolCallId() => _uuid.v4();

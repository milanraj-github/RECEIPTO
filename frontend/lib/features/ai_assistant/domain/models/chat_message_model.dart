import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AIStructuredResponse? structuredResponse;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.structuredResponse,
  });
}

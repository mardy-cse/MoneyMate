/// Chat Message Model for Chatbot functionality
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.general,
  });
}

/// Message Types for styling and categorization
enum MessageType {
  greeting,
  expense,
  category,
  advice,
  tips,
  analysis,
  comparison,
  help,
  info,
  fallback,
  general,
}

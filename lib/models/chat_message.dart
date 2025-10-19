enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String conversationId;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  // For updating content during streaming
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
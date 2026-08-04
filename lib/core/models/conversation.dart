import 'package:uuid/uuid.dart';

enum ConversationMode {
  daily('Daily Conversation', '💬'),
  interview('Job Interview', '💼'),
  travel('Travel', '✈️'),
  college('College', '🎓'),
  business('Business', '📊'),
  restaurant('Restaurant', '🍽️'),
  hospital('Hospital', '🏥'),
  airport('Airport', '🛫'),
  debate('Debate', '⚖️'),
  publicSpeaking('Public Speaking', '🎤');

  final String label;
  final String emoji;
  const ConversationMode(this.label, this.emoji);
}

class Conversation {
  final String id;
  final String title;
  final ConversationMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final int durationSeconds;

  Conversation({
    String? id,
    required this.title,
    required this.mode,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.messageCount = 0,
    this.durationSeconds = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'mode': mode.name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'message_count': messageCount,
        'duration_seconds': durationSeconds,
      };

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
        id: map['id'],
        title: map['title'],
        mode: ConversationMode.values.firstWhere(
          (m) => m.name == map['mode'],
          orElse: () => ConversationMode.daily,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
        messageCount: map['message_count'] ?? 0,
        durationSeconds: map['duration_seconds'] ?? 0,
      );
}

class Message {
  final String id;
  final String conversationId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    String? id,
    required this.conversationId,
    required this.role,
    required this.content,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'],
        conversationId: map['conversation_id'],
        role: map['role'],
        content: map['content'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      );
}

// lib/models/ai_chat_log.dart
class AiChatLog {
  final int id;
  final int userId;
  final String userQuery;
  final String aiResponse;
  final DateTime createdAt;

  AiChatLog({
    required this.id,
    required this.userId,
    required this.userQuery,
    required this.aiResponse,
    required this.createdAt,
  });

  factory AiChatLog.fromJson(Map<String, dynamic> json) => AiChatLog(
        id: json['id'],
        userId: json['user_id'],
        userQuery: json['user_query'],
        aiResponse: json['ai_response'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_query': userQuery,
        'ai_response': aiResponse,
        'created_at': createdAt.toIso8601String(),
      };
}
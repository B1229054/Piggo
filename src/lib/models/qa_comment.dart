// lib/models/qa_comment.dart
class QaComment {
  final int id;
  final int qaId;
  final int userId;
  final String content;
  final DateTime createdAt;

  QaComment({
    required this.id,
    required this.qaId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory QaComment.fromJson(Map<String, dynamic> json) => QaComment(
        id: json['id'],
        qaId: json['qa_id'],
        userId: json['user_id'],
        content: json['content'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'qa_id': qaId,
        'user_id': userId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
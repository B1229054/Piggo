// lib/models/qa_like.dart
class QaLike {
  final int userId;
  final int qaId;
  final DateTime createdAt;

  QaLike({required this.userId, required this.qaId, required this.createdAt});

  factory QaLike.fromJson(Map<String, dynamic> json) => QaLike(
        userId: json['user_id'],
        qaId: json['qa_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'qa_id': qaId,
        'created_at': createdAt.toIso8601String(),
      };
}
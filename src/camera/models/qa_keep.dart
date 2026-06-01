// lib/models/qa_keep.dart
class QaKeep {
  final int id;
  final int userId;
  final int qaId;
  final DateTime createdAt;

  QaKeep({
    required this.id,
    required this.userId,
    required this.qaId,
    required this.createdAt,
  });

  factory QaKeep.fromJson(Map<String, dynamic> json) => QaKeep(
        id: json['id'],
        userId: json['user_id'],
        qaId: json['qa_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'qa_id': qaId,
        'created_at': createdAt.toIso8601String(),
      };
}
// lib/models/post_keep.dart
class PostKeep {
  final int id;
  final int userId;
  final int postId;
  final DateTime createdAt;

  PostKeep({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  factory PostKeep.fromJson(Map<String, dynamic> json) => PostKeep(
        id: json['id'],
        userId: json['user_id'],
        postId: json['post_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'post_id': postId,
        'created_at': createdAt.toIso8601String(),
      };
}
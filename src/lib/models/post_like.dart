// lib/models/post_like.dart
class PostLike {
  final int userId;
  final int postId;
  final DateTime createdAt;

  PostLike({required this.userId, required this.postId, required this.createdAt});

  factory PostLike.fromJson(Map<String, dynamic> json) => PostLike(
        userId: json['user_id'],
        postId: json['post_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'post_id': postId,
        'created_at': createdAt.toIso8601String(),
      };
}
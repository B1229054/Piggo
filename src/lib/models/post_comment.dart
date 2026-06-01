// lib/models/post_comment.dart
class PostComment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'],
        postId: json['post_id'],
        userId: json['user_id'],
        content: json['content'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
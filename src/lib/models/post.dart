// lib/models/post.dart
class Post {
  final int id;
  final int userId;
  final String content;
  final String locationTag;
  final DateTime createdAt;
  final int? tripId;
  final Map<String, dynamic> tags;
  final bool isPublic;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.locationTag,
    required this.createdAt,
    this.tripId,
    required this.tags,
    required this.isPublic,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      locationTag: json['location_tag'],
      createdAt: DateTime.parse(json['created_at']),
      tripId: json['trip_id'],
      tags: json['tags'] ?? {},
      isPublic: json['is_public'] == 1 || json['is_public'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'location_tag': locationTag,
      'created_at': createdAt.toIso8601String(),
      'trip_id': tripId,
      'tags': tags,
      'is_public': isPublic,
    };
  }
}
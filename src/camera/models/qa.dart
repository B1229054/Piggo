// lib/models/qa.dart
class Qa {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String category;
  final String locationTag;
  final DateTime createdAt;

  Qa({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.locationTag,
    required this.createdAt,
  });

  factory Qa.fromJson(Map<String, dynamic> json) => Qa(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        content: json['content'],
        category: json['category'],
        locationTag: json['location_tag'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category,
        'location_tag': locationTag,
        'created_at': createdAt.toIso8601String(),
      };
}
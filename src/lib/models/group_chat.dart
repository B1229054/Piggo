// lib/models/group_chat.dart
class GroupChat {
  final int id;
  final int tripId;
  final int userId;
  final String content;
  final String type;
  final DateTime time;

  GroupChat({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.content,
    required this.type,
    required this.time,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json) => GroupChat(
        id: json['id'],
        tripId: json['trip_id'],
        userId: json['user_id'],
        content: json['content'],
        type: json['type'],
        time: DateTime.parse(json['time']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'user_id': userId,
        'content': content,
        'type': type,
        'time': time.toIso8601String(),
      };
}
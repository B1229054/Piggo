// lib/models/vote.dart
class Vote {
  final int id;
  final int tripId;
  final int creatorId;
  final String title;
  final DateTime createdAt;
  final String state;
  final DateTime startTime;
  final DateTime endTime;

  Vote({
    required this.id,
    required this.tripId,
    required this.creatorId,
    required this.title,
    required this.createdAt,
    required this.state,
    required this.startTime,
    required this.endTime,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      tripId: json['trip_id'],
      creatorId: json['creator_id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      state: json['state'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'creator_id': creatorId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'state': state,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }
}
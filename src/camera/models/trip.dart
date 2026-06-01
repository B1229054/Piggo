// lib/models/trip.dart
class Trip {
  final int id;
  final int creatorId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String coverImage;
  final String status;
  final String inviteCode;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.coverImage,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      creatorId: json['creator_id'],
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      coverImage: json['cover_image'],
      status: json['status'],
      inviteCode: json['invite_code'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'cover_image': coverImage,
      'status': status,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
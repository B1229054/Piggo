// lib/models/trip_member.dart
class TripMember {
  final int id;
  final int tripId;
  final int userId;
  final String role;

  TripMember({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.role,
  });

  factory TripMember.fromJson(Map<String, dynamic> json) {
    return TripMember(
      id: json['id'],
      tripId: json['trip_id'],
      userId: json['user_id'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'role': role,
    };
  }
}
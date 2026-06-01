// lib/models/place_keep.dart
class PlaceKeep {
  final int id;
  final int userId;
  final String googlePlaceId;
  final String placeName;
  final String address;
  final double lat;
  final double lng;
  final DateTime createdAt;

  PlaceKeep({
    required this.id,
    required this.userId,
    required this.googlePlaceId,
    required this.placeName,
    required this.address,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  factory PlaceKeep.fromJson(Map<String, dynamic> json) => PlaceKeep(
        id: json['id'],
        userId: json['user_id'],
        googlePlaceId: json['google_place_id'],
        placeName: json['place_name'],
        address: json['address'],
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'google_place_id': googlePlaceId,
        'place_name': placeName,
        'address': address,
        'lat': lat,
        'lng': lng,
        'created_at': createdAt.toIso8601String(),
      };
}
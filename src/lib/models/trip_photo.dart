class TripPhoto {
  final int id;
  final int tripId;
  final int userId;
  final String imageUrl;
  final String userName;
  final DateTime takenAt;
  final double? lat;
  final double? lng;
  final bool isShared;

  final String locationName;

  TripPhoto({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    required this.takenAt,
    this.lat, // 因為可以為空，所以拔掉 required
    this.lng,
    required this.locationName,
    required this.isShared,
  });

  factory TripPhoto.fromJson(Map<String, dynamic> json) {
    return TripPhoto(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      tripId: json['trip_id'] != null
          ? int.tryParse(json['trip_id'].toString()) ?? 0
          : 0,
      userId: json['user_id'] != null
          ? int.tryParse(json['user_id'].toString()) ?? 0
          : 0,
      imageUrl: json['image_url'] ?? '',
      userName: json['username'] ?? '匿名成員',
      isShared: json['is_shared'] == 1,
      takenAt: json['taken_at'] != null
          ? DateTime.tryParse(json['taken_at'].toString()) ?? DateTime.now()
          : DateTime.now(),

      lat: double.tryParse(json['lat']?.toString() ?? ''),
      lng: double.tryParse(json['lng']?.toString() ?? ''),

      locationName: json['location_name'] ?? '未知地點',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trip_id': tripId,
    'user_id': userId,
    'image_url': imageUrl,
    'taken_at': takenAt.toIso8601String(),
    'lat': lat,
    'lng': lng,
    'location_name': locationName,
  };
}

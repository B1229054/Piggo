// lib/models/trip_detail.dart
class TripDetail {
  final int id;
  final int tripId;
  final int dayNumber;
  final int sortOrder;
  final String placeName;
  final String googlePlaceId;
  final String address;
  final double lat;
  final double lng;
  final String startTime; // Using String for time, can be parsed to TimeOfDay later
  final int stayDuration;
  final String transportMode;
  final int transportTime;
  final String note;

  TripDetail({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    required this.sortOrder,
    required this.placeName,
    required this.googlePlaceId,
    required this.address,
    required this.lat,
    required this.lng,
    required this.startTime,
    required this.stayDuration,
    required this.transportMode,
    required this.transportTime,
    required this.note,
  });

  factory TripDetail.fromJson(Map<String, dynamic> json) {
    return TripDetail(
      id: json['id'],
      tripId: json['trip_id'],
      dayNumber: json['day_number'],
      sortOrder: json['sort_order'],
      placeName: json['place_name'],
      googlePlaceId: json['google_place_id'],
      address: json['address'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      startTime: json['start_time'],
      stayDuration: json['stay_duration'],
      transportMode: json['transport_mode'],
      transportTime: json['transport_time'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'day_number': dayNumber,
      'sort_order': sortOrder,
      'place_name': placeName,
      'google_place_id': googlePlaceId,
      'address': address,
      'lat': lat,
      'lng': lng,
      'start_time': startTime,
      'stay_duration': stayDuration,
      'transport_mode': transportMode,
      'transport_time': transportTime,
      'note': note,
    };
  }
}
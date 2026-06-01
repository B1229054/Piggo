// lib/models/packing_item.dart
class TripPackingItem {
  final int id;
  final int tripId;
  final int userId;
  final String category;
  final String itemName;
  final bool isChecked;
  final String itemType;

  TripPackingItem({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.category,
    required this.itemName,
    required this.isChecked,
    required this.itemType,
  });

  factory TripPackingItem.fromJson(Map<String, dynamic> json) => TripPackingItem(
        id: json['id'],
        tripId: json['trip_id'],
        userId: json['user_id'],
        category: json['category'],
        itemName: json['item_name'],
        isChecked: json['is_checked'] == 1 || json['is_checked'] == true,
        itemType: json['item_type'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'user_id': userId,
        'category': category,
        'item_name': itemName,
        'is_checked': isChecked,
        'item_type': itemType,
      };
}
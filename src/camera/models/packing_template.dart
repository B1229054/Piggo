// lib/models/packing_template.dart
class UserPackingTemplate {
  final int id;
  final int userId;
  final String category;
  final String itemName;

  UserPackingTemplate({
    required this.id,
    required this.userId,
    required this.category,
    required this.itemName,
  });

  factory UserPackingTemplate.fromJson(Map<String, dynamic> json) =>
      UserPackingTemplate(
        id: json['id'],
        userId: json['user_id'],
        category: json['category'],
        itemName: json['item_name'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category': category,
    'item_name': itemName,
  };
}

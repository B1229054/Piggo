// lib/models/pose_reference.dart
class PoseReference {
  final int id;
  final String imageUrl;
  final String poseName;
  final String category;

  PoseReference({
    required this.id,
    required this.imageUrl,
    required this.poseName,
    required this.category,
  });

  factory PoseReference.fromJson(Map<String, dynamic> json) => PoseReference(
        id: json['id'],
        imageUrl: json['image_url'],
        poseName: json['pose_name'],
        category: json['category'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'pose_name': poseName,
        'category': category,
      };
}
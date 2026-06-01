// lib/models/post_attachment.dart
class PostAttachment {
  final int id;
  final int postId;
  final int? tripPhotoId;
  final String? uploadPhotoUrl;
  final int sortOrder;

  PostAttachment({
    required this.id,
    required this.postId,
    this.tripPhotoId,
    this.uploadPhotoUrl,
    required this.sortOrder,
  });

  factory PostAttachment.fromJson(Map<String, dynamic> json) => PostAttachment(
        id: json['id'],
        postId: json['post_id'],
        tripPhotoId: json['trip_photo_id'],
        uploadPhotoUrl: json['upload_photo_url'],
        sortOrder: json['sort_order'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'trip_photo_id': tripPhotoId,
        'upload_photo_url': uploadPhotoUrl,
        'sort_order': sortOrder,
      };
}
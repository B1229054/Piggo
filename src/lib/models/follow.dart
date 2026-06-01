// lib/models/follow.dart
class Follow {
  final int followerId;
  final int followingId;

  Follow({required this.followerId, required this.followingId});

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      followerId: json['follower_id'],
      followingId: json['following_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'follower_id': followerId,
      'following_id': followingId,
    };
  }
}
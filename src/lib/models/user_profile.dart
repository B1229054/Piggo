// lib/models/user_profile.dart
class UserProfile {
  final int userId;
  final String bio;
  final String personalityType;
  final Map<String, dynamic> personalityTags;

  UserProfile({
    required this.userId,
    required this.bio,
    required this.personalityType,
    required this.personalityTags,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'],
      bio: json['bio'],
      personalityType: json['personality_type'],
      personalityTags: json['personality_tags'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'bio': bio,
      'personality_type': personalityType,
      'personality_tags': personalityTags,
    };
  }
}
// lib/models/user.dart
class User {
  final int id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String provider;
  final String? providerId;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    required this.provider,
    this.providerId,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      provider: json['provider'] ?? 'local',
      providerId: json['provider_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'provider': provider,
      'provider_id': providerId,
    };
  }
}

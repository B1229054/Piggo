// lib/models/vote_response.dart
class VoteResponse {
  final int id;
  final int voteOptionId;
  final int userId;

  VoteResponse({required this.id, required this.voteOptionId, required this.userId});

  factory VoteResponse.fromJson(Map<String, dynamic> json) => VoteResponse(
        id: json['id'],
        voteOptionId: json['vote_option_id'],
        userId: json['user_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vote_option_id': voteOptionId,
        'user_id': userId,
      };
}
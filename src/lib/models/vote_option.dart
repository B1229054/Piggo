// lib/models/vote_option.dart
class VoteOption {
  final int id;
  final int voteId;
  final String optionContent;

  VoteOption({required this.id, required this.voteId, required this.optionContent});

  factory VoteOption.fromJson(Map<String, dynamic> json) => VoteOption(
        id: json['id'],
        voteId: json['vote_id'],
        optionContent: json['option_content'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vote_id': voteId,
        'option_content': optionContent,
      };
}
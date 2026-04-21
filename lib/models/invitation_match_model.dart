class InvitationMatchModel {
  final int id;
  final int match;
  final int invite;
  final String statut;

  const InvitationMatchModel({
    required this.id,
    required this.match,
    required this.invite,
    required this.statut,
  });

  factory InvitationMatchModel.fromJson(Map<String, dynamic> json) =>
      InvitationMatchModel(
        id: json['id'] as int,
        match: json['Match'] as int,
        invite: json['Invite'] as int,
        statut: json['Statut'] as String? ?? '',
      );
}

class InvitationModel {
  final int id;
  final DateTime? createdAt;
  final String reservation; // uuid -> Réservation.id
  final int invite; // Member.id
  final int inviteur; // Member.id
  final String statut;

  const InvitationModel({
    required this.id,
    this.createdAt,
    required this.reservation,
    required this.invite,
    required this.inviteur,
    required this.statut,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) =>
      InvitationModel(
        id: json['id'] as int,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        reservation: json['Réservation'] as String,
        invite: json['Invité'] as int,
        inviteur: json['Inviteur'] as int,
        statut: json['Statut'] as String? ?? 'en attente',
      );
}

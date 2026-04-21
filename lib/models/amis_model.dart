class AmisModel {
  final int id;
  final String statut;
  final int demandeur;
  final int destinataire;
  final int? amiId; // from MesAmis view — always the OTHER person's Member.id

  const AmisModel({
    required this.id,
    required this.statut,
    required this.demandeur,
    required this.destinataire,
    this.amiId,
  });

  factory AmisModel.fromJson(Map<String, dynamic> json) => AmisModel(
        id: json['id'] as int,
        statut: json['Statut'] as String? ?? '',
        demandeur: json['Demandeur'] as int,
        destinataire: json['Destinataire'] as int,
        amiId: json['AmiId'] as int?,
      );
}

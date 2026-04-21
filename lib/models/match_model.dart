class MatchModel {
  final int id;
  final int terrain;
  final String? date;
  final String? heure;
  final int organisateur;
  final String? statut;
  final String? sport;
  final int nombreJoueurs;
  final int nombreJoueursActuel;

  const MatchModel({
    required this.id,
    required this.terrain,
    this.date,
    this.heure,
    required this.organisateur,
    this.statut,
    this.sport,
    required this.nombreJoueurs,
    required this.nombreJoueursActuel,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
        id: json['id'] as int,
        terrain: json['Terrain'] as int,
        date: json['Date'] as String?,
        heure: json['Heure'] as String?,
        organisateur: json['Organisateur'] as int,
        statut: json['Statut'] as String?,
        sport: json['Sport'] as String?,
        nombreJoueurs: json['NombreJoueurs'] as int? ?? 0,
        nombreJoueursActuel: json['NombreJoueursActuel'] as int? ?? 0,
      );
}

class ProduitModel {
  final int id;
  final String? categorie;
  final String? nom;
  final double? prixUnitaire;
  final String? sport;
  final String? terrain; // uuid FK -> Terrain
  final String? type;
  final double? startAt;
  final double? endAt;
  final String? days;
  final String? souCategorie;

  const ProduitModel({
    required this.id,
    this.categorie,
    this.nom,
    this.prixUnitaire,
    this.sport,
    this.terrain,
    this.type,
    this.startAt,
    this.endAt,
    this.days,
    this.souCategorie,
  });

  factory ProduitModel.fromJson(Map<String, dynamic> json) => ProduitModel(
        id: json['id'] as int,
        categorie: json['Catégorie'] as String?,
        nom: json['Nom'] as String?,
        prixUnitaire: json['Prix unitaire'] != null
            ? (json['Prix unitaire'] as num).toDouble()
            : null,
        sport: json['Sport'] as String?,
        terrain: json['Terrain'] as String?,
        type: json['Type'] as String?,
        startAt: json['Start_at'] != null
            ? (json['Start_at'] as num).toDouble()
            : null,
        endAt: json['End_at'] != null
            ? (json['End_at'] as num).toDouble()
            : null,
        days: json['days'] as String?,
        souCategorie: json['Sous-catégorie'] as String?,
      );
}

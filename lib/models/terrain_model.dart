class TerrainModel {
  final String id; // uuid
  final String? nom;
  final String? adresse;
  final String? sport;
  final String? img;
  final double? prix;
  final String? description;
  final String? format;

  const TerrainModel({
    required this.id,
    this.nom,
    this.adresse,
    this.sport,
    this.img,
    this.prix,
    this.description,
    this.format,
  });

  factory TerrainModel.fromJson(Map<String, dynamic> json) => TerrainModel(
        id: json['id'] as String,
        nom: json['Nom'] as String?,
        adresse: null,
        sport: json['Type de sport'] as String?,
        img: json['image'] as String?,
        prix: null,
        description: null,
        format: json['Format'] as String?,
      );
}

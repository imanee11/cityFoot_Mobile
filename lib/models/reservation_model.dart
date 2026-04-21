class ReservationModel {
  final String id; // uuid
  final DateTime? createdAt;
  final String? titre;
  final String? typeDeReservation;
  final String? terrain; // uuid
  final String? sport;
  final String? presence;
  final String? prenom;
  final String? nom;
  final int? produit;
  final String? privePublic;
  final String? niveau;
  final String? format;
  final double? duree;
  final DateTime? dateDeResa;
  final String? categorie;
  final int? client; // Member.id
  final int? joueurs; // Member.id
  final int? capitaine; // Member.id
  final bool payeNonPaye;
  final int? numeroDeReservation;
  final double? heureDebut;
  final double? heureFin;
  final String? agent;
  final DateTime? matchDatetime;

  const ReservationModel({
    required this.id,
    this.createdAt,
    this.titre,
    this.typeDeReservation,
    this.terrain,
    this.sport,
    this.presence,
    this.prenom,
    this.nom,
    this.produit,
    this.privePublic,
    this.niveau,
    this.format,
    this.duree,
    this.dateDeResa,
    this.categorie,
    this.client,
    this.joueurs,
    this.capitaine,
    this.payeNonPaye = false,
    this.numeroDeReservation,
    this.heureDebut,
    this.heureFin,
    this.agent,
    this.matchDatetime,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) =>
      ReservationModel(
        id: json['id'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        titre: json['Titre'] as String?,
        typeDeReservation: json['Type de réservation'] as String?,
        terrain: json['Terrain'] as String?,
        sport: json['Sport'] as String?,
        presence: json['Présence'] as String?,
        prenom: json['Prénom'] as String?,
        nom: json['Nom'] as String?,
        produit: json['Produit'] as int?,
        privePublic: json['Privé_Public'] as String?,
        niveau: json['Niveau'] as String?,
        format: json['Format'] as String?,
        duree: json['Durée'] != null
            ? (json['Durée'] as num).toDouble()
            : null,
        dateDeResa: json['Date de résa'] != null
            ? DateTime.tryParse(json['Date de résa'].toString())
            : null,
        categorie: json['catégorie'] as String?,
        client: json['Client'] as int?,
        joueurs: json['Joueurs'] as int?,
        capitaine: json['Capitaine'] as int?,
        payeNonPaye: json['Payé / Non payé'] as bool? ?? false,
        numeroDeReservation: json['N° de réservation'] as int?,
        heureDebut: json['Heure_début'] != null
            ? (json['Heure_début'] as num).toDouble()
            : null,
        heureFin: json['Heure_fin'] != null
            ? (json['Heure_fin'] as num).toDouble()
            : null,
        agent: json['Agent'] as String?,
        matchDatetime: json['match_datetime'] != null
            ? DateTime.tryParse(json['match_datetime'].toString())
            : null,
      );
}

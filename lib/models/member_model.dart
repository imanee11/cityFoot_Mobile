class MemberModel {
  final int id;
  final String? prenom;
  final String? nom;
  final String? email;
  final String? telephone;
  final String? img;
  final String? type;
  final String? sportPrincipal;
  final String? categorie;
  final String? civilite;
  final String? user;

  const MemberModel({
    required this.id,
    this.prenom,
    this.nom,
    this.email,
    this.telephone,
    this.img,
    this.type,
    this.sportPrincipal,
    this.categorie,
    this.civilite,
    this.user,
  });

  String get fullName => '${prenom ?? ''} ${nom ?? ''}'.trim();

  String get initials {
    final p = prenom?.isNotEmpty == true ? prenom![0].toUpperCase() : '';
    final n = nom?.isNotEmpty == true ? nom![0].toUpperCase() : '';
    return '$p$n';
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'] as int,
        prenom: json['Prénom'] as String?,
        nom: json['Nom'] as String?,
        email: json['Email'] as String?,
        telephone: json['Téléphone'] as String?,
        img: json['Img'] as String?,
        type: json['Type'] as String?,
        sportPrincipal: json['Sport principal'] as String?,
        categorie: json['Catégorie'] as String?,
        civilite: json['civilité'] as String?,
        user: json['User'] as String?,
      );

  MemberModel copyWith({
    int? id,
    String? prenom,
    String? nom,
    String? email,
    String? telephone,
    String? img,
    String? type,
    String? sportPrincipal,
    String? categorie,
    String? civilite,
    String? user,
  }) {
    return MemberModel(
      id: id ?? this.id,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      img: img ?? this.img,
      type: type ?? this.type,
      sportPrincipal: sportPrincipal ?? this.sportPrincipal,
      categorie: categorie ?? this.categorie,
      civilite: civilite ?? this.civilite,
      user: user ?? this.user,
    );
  }
}

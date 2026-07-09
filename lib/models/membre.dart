class Membre {
  final int? id;
  final String nom;
  final String telephone;
  final String dateAdhesion; // format yyyy-MM-dd
  final String statut; // 'Actif' ou 'Inactif'
  final double montantCotisationMensuelle;

  Membre({
    this.id,
    required this.nom,
    this.telephone = '',
    required this.dateAdhesion,
    this.statut = 'Actif',
    required this.montantCotisationMensuelle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'date_adhesion': dateAdhesion,
      'statut': statut,
      'montant_cotisation_mensuelle': montantCotisationMensuelle,
    };
  }

  factory Membre.fromMap(Map<String, dynamic> map) {
    return Membre(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      telephone: map['telephone'] as String? ?? '',
      dateAdhesion: map['date_adhesion'] as String,
      statut: map['statut'] as String? ?? 'Actif',
      montantCotisationMensuelle:
          (map['montant_cotisation_mensuelle'] as num).toDouble(),
    );
  }

  Membre copyWith({
    int? id,
    String? nom,
    String? telephone,
    String? dateAdhesion,
    String? statut,
    double? montantCotisationMensuelle,
  }) {
    return Membre(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      dateAdhesion: dateAdhesion ?? this.dateAdhesion,
      statut: statut ?? this.statut,
      montantCotisationMensuelle:
          montantCotisationMensuelle ?? this.montantCotisationMensuelle,
    );
  }
}

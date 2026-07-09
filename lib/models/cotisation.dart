/// Types de cotisation possibles.
class TypeCotisation {
  static const String mensuelle = 'Mensuelle';
  static const String adhesionAnnuelle = 'Adhésion annuelle';
  static const String evenement = 'Événement';
  static const String autre = 'Autre';

  static const List<String> toutes = [
    mensuelle,
    adhesionAnnuelle,
    evenement,
    autre,
  ];
}

class Cotisation {
  final int? id;
  final int membreId;
  final String mois; // format yyyy-MM (mois concerné par le paiement)
  final double montant;
  final String datePaiement; // format yyyy-MM-dd
  final String modePaiement; // Espèces / Mobile Money / Virement
  final String typeCotisation; // Mensuelle / Adhésion annuelle / Événement / Autre
  final String libelle; // précision optionnelle (ex: nom de l'événement)

  Cotisation({
    this.id,
    required this.membreId,
    required this.mois,
    required this.montant,
    required this.datePaiement,
    this.modePaiement = 'Espèces',
    this.typeCotisation = TypeCotisation.mensuelle,
    this.libelle = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'membre_id': membreId,
      'mois': mois,
      'montant': montant,
      'date_paiement': datePaiement,
      'mode_paiement': modePaiement,
      'type_cotisation': typeCotisation,
      'libelle': libelle,
    };
  }

  factory Cotisation.fromMap(Map<String, dynamic> map) {
    return Cotisation(
      id: map['id'] as int?,
      membreId: map['membre_id'] as int,
      mois: map['mois'] as String,
      montant: (map['montant'] as num).toDouble(),
      datePaiement: map['date_paiement'] as String,
      modePaiement: map['mode_paiement'] as String? ?? 'Espèces',
      typeCotisation:
          map['type_cotisation'] as String? ?? TypeCotisation.mensuelle,
      libelle: map['libelle'] as String? ?? '',
    );
  }
}

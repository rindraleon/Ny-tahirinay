class Sortie {
  final int? id;
  final String date; // format yyyy-MM-dd
  final double montant;
  final String motif;
  final String beneficiaire;
  final String justificatif; // chemin d'une photo (optionnel)
  final int forcee; // 0 = normal, 1 = validée malgré balance insuffisante

  Sortie({
    this.id,
    required this.date,
    required this.montant,
    required this.motif,
    this.beneficiaire = '',
    this.justificatif = '',
    this.forcee = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'montant': montant,
      'motif': motif,
      'beneficiaire': beneficiaire,
      'justificatif': justificatif,
      'forcee': forcee,
    };
  }

  factory Sortie.fromMap(Map<String, dynamic> map) {
    return Sortie(
      id: map['id'] as int?,
      date: map['date'] as String,
      montant: (map['montant'] as num).toDouble(),
      motif: map['motif'] as String,
      beneficiaire: map['beneficiaire'] as String? ?? '',
      justificatif: map['justificatif'] as String? ?? '',
      forcee: map['forcee'] as int? ?? 0,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/membre.dart';
import '../models/cotisation.dart';
import '../providers/cotisation_provider.dart';
import '../utils/formatters.dart';

class MembreDetailScreen extends StatelessWidget {
  final Membre membre;

  const MembreDetailScreen({super.key, required this.membre});

  Color _couleurType(String type) {
    switch (type) {
      case TypeCotisation.mensuelle:
        return Colors.green;
      case TypeCotisation.adhesionAnnuelle:
        return Colors.blue;
      case TypeCotisation.evenement:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cotisationProvider = context.watch<CotisationProvider>();
    final cotisations = cotisationProvider.parMembre(membre.id!);
    final totalPaye = cotisations.fold(0.0, (s, c) => s + c.montant);

    // Le retard ne concerne que les cotisations mensuelles
    final cotisationsMensuelles =
        cotisations.where((c) => c.typeCotisation == TypeCotisation.mensuelle).toList();
    final totalMensuelPaye = cotisationsMensuelles.fold(0.0, (s, c) => s + c.montant);

    // Calculer les mois écoulés depuis l'adhésion
    final dateAdhesion = DateTime.parse(membre.dateAdhesion);
    final maintenant = DateTime.now();
    final moisEcoules = (maintenant.year - dateAdhesion.year) * 12 +
        (maintenant.month - dateAdhesion.month) +
        1;
    final moisAttendu = moisEcoules > 0 ? moisEcoules : 1;
    final montantAttendu = moisAttendu * membre.montantCotisationMensuelle;
    final retard = montantAttendu - totalMensuelPaye;

    return Scaffold(
      appBar: AppBar(title: Text(membre.nom)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ligneInfo(Icons.phone, membre.telephone.isNotEmpty ? membre.telephone : 'Non renseigné'),
                  _ligneInfo(Icons.calendar_today, 'Adhésion: ${Formatters.dateLisible(membre.dateAdhesion)}'),
                  _ligneInfo(Icons.savings, 'Cotisation mensuelle: ${Formatters.montant(membre.montantCotisationMensuelle)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CarteStat(
                  titre: 'Total payé',
                  valeur: Formatters.montant(totalPaye),
                  couleur: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CarteStat(
                  titre: retard > 0 ? 'Montant en retard' : 'À jour',
                  valeur: retard > 0 ? Formatters.montant(retard) : '✓',
                  couleur: retard > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Historique des paiements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (cotisations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Aucun paiement enregistré')),
            )
          else
            ...cotisations.map((c) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _couleurType(c.typeCotisation),
                      child: const Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                    title: Text('${c.typeCotisation} • ${Formatters.moisLisible(c.mois)}'),
                    subtitle: Text(
                      'Payé le ${Formatters.dateLisible(c.datePaiement)} • ${c.modePaiement}'
                      '${c.libelle.isNotEmpty ? " • ${c.libelle}" : ""}',
                    ),
                    trailing: Text(
                      Formatters.montant(c.montant),
                      style: TextStyle(fontWeight: FontWeight.bold, color: _couleurType(c.typeCotisation)),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _ligneInfo(IconData icon, String texte) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(texte),
        ],
      ),
    );
  }
}

class _CarteStat extends StatelessWidget {
  final String titre;
  final String valeur;
  final Color couleur;

  const _CarteStat({required this.titre, required this.valeur, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: couleur.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(valeur,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: couleur)),
            const SizedBox(height: 4),
            Text(titre, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

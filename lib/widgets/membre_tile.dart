import 'package:flutter/material.dart';
import '../models/membre.dart';
import '../utils/formatters.dart';

enum StatutPaiement { aJour, enRetard, partiel }

class MembreTile extends StatelessWidget {
  final Membre membre;
  final StatutPaiement? statutPaiement;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MembreTile({
    super.key,
    required this.membre,
    this.statutPaiement,
    this.onTap,
    this.onDelete,
  });

  Color _couleurStatut() {
    switch (statutPaiement) {
      case StatutPaiement.aJour:
        return Colors.green;
      case StatutPaiement.enRetard:
        return Colors.red;
      case StatutPaiement.partiel:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _texteStatut() {
    switch (statutPaiement) {
      case StatutPaiement.aJour:
        return 'À jour';
      case StatutPaiement.enRetard:
        return 'En retard';
      case StatutPaiement.partiel:
        return 'Partiel';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            membre.nom.isNotEmpty ? membre.nom[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(membre.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${membre.telephone.isNotEmpty ? membre.telephone : "Pas de contact"}\n'
          'Cotisation: ${Formatters.montant(membre.montantCotisationMensuelle)}/mois',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statutPaiement != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _couleurStatut().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _texteStatut(),
                  style: TextStyle(
                    color: _couleurStatut(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

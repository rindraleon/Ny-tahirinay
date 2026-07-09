import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double totalCotisations;
  final double totalSorties;
  final double balance;

  const BalanceCard({
    super.key,
    required this.totalCotisations,
    required this.totalSorties,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final estPositive = balance >= 0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Balance actuelle',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.montant(balance),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: estPositive ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  label: 'Total cotisations',
                  valeur: totalCotisations,
                  couleur: Colors.green,
                  icone: Icons.arrow_downward,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _StatColumn(
                  label: 'Total sorties',
                  valeur: totalSorties,
                  couleur: Colors.red,
                  icone: Icons.arrow_upward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double valeur;
  final Color couleur;
  final IconData icone;

  const _StatColumn({
    required this.label,
    required this.valeur,
    required this.couleur,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, color: couleur, size: 20),
        const SizedBox(height: 4),
        Text(
          Formatters.montant(valeur),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: couleur,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

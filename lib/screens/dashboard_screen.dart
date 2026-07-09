import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/cotisation_provider.dart';
import '../providers/sortie_provider.dart';
import '../providers/membre_provider.dart';
import '../widgets/balance_card.dart';
import '../utils/formatters.dart';
import '../db/database_helper.dart';
import '../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onAjouterCotisation;
  final VoidCallback onAjouterSortie;
  final VoidCallback onAjouterMembre;

  const DashboardScreen({
    super.key,
    required this.onAjouterCotisation,
    required this.onAjouterSortie,
    required this.onAjouterMembre,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _nomAssociation = 'Ny Tahiriko';
  bool _verificationEnCours = false;

  @override
  void initState() {
    super.initState();
    _chargerNomAssociation();
  }

  Future<void> _chargerNomAssociation() async {
    final nom = await DatabaseHelper.instance.getParametre('nom_association');
    if (mounted) {
      setState(() {
        _nomAssociation = (nom != null && nom.isNotEmpty) ? nom : 'Ny Tahiriko';
      });
    }
  }

  Future<void> _verifierRetardsMaintenant() async {
    setState(() => _verificationEnCours = true);
    try {
      await NotificationService.instance.notifierMembresEnRetardMaintenant();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vérification effectuée, voir la notification.')),
        );
      }
    } finally {
      if (mounted) setState(() => _verificationEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cotisationProvider = context.watch<CotisationProvider>();
    final sortieProvider = context.watch<SortieProvider>();
    final membreProvider = context.watch<MembreProvider>();

    final totalCotisations = cotisationProvider.totalCotisations;
    final totalSorties = sortieProvider.totalSorties;
    final balance = totalCotisations - totalSorties;

    // Préparer données pour graphique (6 derniers mois)
    final maintenant = DateTime.now();
    final moisListe = List.generate(6, (i) {
      final d = DateTime(maintenant.year, maintenant.month - (5 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });

    return RefreshIndicator(
      onRefresh: () async {
        await cotisationProvider.chargerCotisations();
        await sortieProvider.chargerSorties();
        await membreProvider.chargerMembres();
        await _chargerNomAssociation();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.savings, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nomAssociation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Gestion des cotisations',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.people, size: 18, color: Colors.blue),
                  label: Text('${membreProvider.membres.length} membres'),
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BalanceCard(
            totalCotisations: totalCotisations,
            totalSorties: totalSorties,
            balance: balance,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.savings,
                  label: 'Cotisation',
                  color: Colors.green,
                  onTap: widget.onAjouterCotisation,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.money_off,
                  label: 'Sortie',
                  color: Colors.red,
                  onTap: widget.onAjouterSortie,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.person_add,
                  label: 'Membre',
                  color: Colors.blue,
                  onTap: widget.onAjouterMembre,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _verificationEnCours ? null : _verifierRetardsMaintenant,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    _verificationEnCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Vérifier les membres en retard maintenant',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.orange),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Évolution des 6 derniers mois',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: List.generate(moisListe.length, (i) {
                      final mois = moisListe[i];
                      final totalMois = cotisationProvider.totalParMois(mois);
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: totalMois,
                            color: Colors.green,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= moisListe.length) {
                              return const SizedBox();
                            }
                            final parts = moisListe[idx].split('-');
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${parts[1]}/${parts[0].substring(2)}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ce mois-ci',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.blue),
              title: Text(Formatters.moisLisible(Formatters.moisActuel())),
              subtitle: Text(
                'Collecté: ${Formatters.montant(cotisationProvider.totalParMois(Formatters.moisActuel()))}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

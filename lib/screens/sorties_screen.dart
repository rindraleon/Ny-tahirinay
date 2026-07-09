import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sortie.dart';
import '../providers/sortie_provider.dart';
import '../utils/formatters.dart';

class SortiesScreen extends StatefulWidget {
  const SortiesScreen({super.key});

  @override
  State<SortiesScreen> createState() => SortiesScreenState();
}

class SortiesScreenState extends State<SortiesScreen> {
  void ouvrirFormulaireAjout() {
    _afficherFormulaireSortie(context);
  }

  void _afficherFormulaireSortie(BuildContext context) {
    final montantController = TextEditingController();
    final motifController = TextEditingController();
    final beneficiaireController = TextEditingController();
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Ajouter une sortie',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant (Ar) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: motifController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Motif / Raison de la sortie *',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Achat de matériel, frais de réunion...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: beneficiaireController,
                      decoration: const InputDecoration(
                        labelText: 'Bénéficiaire (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(Formatters.dateLisible(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => date = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final montant = double.tryParse(montantController.text.trim());
                        final motif = motifController.text.trim();

                        if (montant == null || montant <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Montant invalide')),
                          );
                          return;
                        }
                        if (motif.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Le motif de la sortie est obligatoire')),
                          );
                          return;
                        }

                        final dateStr =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                        final sortie = Sortie(
                          date: dateStr,
                          montant: montant,
                          motif: motif,
                          beneficiaire: beneficiaireController.text.trim(),
                        );

                        final provider = context.read<SortieProvider>();
                        final resultat = await provider.tenterAjouterSortie(sortie);

                        if (!ctx.mounted) return;

                        if (resultat.balanceInsuffisante && !resultat.succes) {
                          // Restriction : balance insuffisante -> demander confirmation
                          final forcer = await showDialog<bool>(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Fonds insuffisants'),
                                ],
                              ),
                              content: Text(
                                'La balance actuelle est de ${Formatters.montant(resultat.balanceActuelle)}.\n\n'
                                'Cette sortie de ${Formatters.montant(montant)} ferait passer la balance en négatif '
                                '(${Formatters.montant(resultat.balanceActuelle - montant)}).\n\n'
                                'Voulez-vous quand même valider cette sortie (avance de trésorerie) ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  child: const Text('Forcer quand même',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (forcer == true) {
                            await provider.tenterAjouterSortie(sortie, forcer: true);
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        } else if (resultat.succes) {
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortieProvider = context.watch<SortieProvider>();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Column(
              children: [
                const Text('Total des sorties', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  Formatters.montant(sortieProvider.totalSorties),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance restante: ${Formatters.montant(sortieProvider.balance)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sortieProvider.balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sortieProvider.sorties.isEmpty
                ? const Center(child: Text('Aucune sortie enregistrée.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortieProvider.sorties.length,
                    itemBuilder: (ctx, i) {
                      final sortie = sortieProvider.sorties[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: sortie.forcee == 1 ? Colors.orange : Colors.red,
                            child: const Icon(Icons.arrow_upward, color: Colors.white),
                          ),
                          title: Text(sortie.motif),
                          subtitle: Text(
                            '${Formatters.dateLisible(sortie.date)}'
                            '${sortie.beneficiaire.isNotEmpty ? " • ${sortie.beneficiaire}" : ""}'
                            '${sortie.forcee == 1 ? "\n⚠️ Validée malgré balance insuffisante" : ""}',
                          ),
                          isThreeLine: sortie.forcee == 1,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '-${Formatters.montant(sortie.montant)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () async {
                                  await sortieProvider.supprimerSortie(sortie.id!);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ouvrirFormulaireAjout,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}

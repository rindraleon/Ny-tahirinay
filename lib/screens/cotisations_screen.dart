import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cotisation.dart';
import '../providers/cotisation_provider.dart';
import '../providers/membre_provider.dart';
import '../utils/formatters.dart';

class CotisationsScreen extends StatefulWidget {
  const CotisationsScreen({super.key});

  @override
  State<CotisationsScreen> createState() => CotisationsScreenState();
}

class CotisationsScreenState extends State<CotisationsScreen> {
  String _moisSelectionne = Formatters.moisActuel();

  void ouvrirFormulaireAjout() {
    _afficherFormulaireCotisation(context);
  }

  void _changerMois(int delta) {
    final parts = _moisSelectionne.split('-');
    var annee = int.parse(parts[0]);
    var mois = int.parse(parts[1]) + delta;
    if (mois > 12) {
      mois = 1;
      annee++;
    } else if (mois < 1) {
      mois = 12;
      annee--;
    }
    setState(() {
      _moisSelectionne = '$annee-${mois.toString().padLeft(2, '0')}';
    });
  }

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

  void _afficherFormulaireCotisation(BuildContext context) {
    final membreProvider = context.read<MembreProvider>();
    if (membreProvider.membres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d\'abord un membre avant d\'enregistrer une cotisation.')),
      );
      return;
    }

    int? membreSelectionneId = membreProvider.membres.first.id;
    String moisChoisi = _moisSelectionne;
    String typeChoisi = TypeCotisation.mensuelle;
    final montantController = TextEditingController(
      text: membreProvider.membres.first.montantCotisationMensuelle.toString(),
    );
    final libelleController = TextEditingController();
    DateTime datePaiement = DateTime.now();
    String modePaiement = 'Espèces';

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
                    const Text('Ajouter une cotisation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: membreSelectionneId,
                      decoration: const InputDecoration(
                        labelText: 'Membre *',
                        border: OutlineInputBorder(),
                      ),
                      items: membreProvider.membres
                          .map((m) => DropdownMenuItem(value: m.id, child: Text(m.nom)))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          membreSelectionneId = val;
                          final m = membreProvider.membres.firstWhere((mb) => mb.id == val);
                          if (typeChoisi == TypeCotisation.mensuelle) {
                            montantController.text = m.montantCotisationMensuelle.toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: typeChoisi,
                      decoration: const InputDecoration(
                        labelText: 'Type de cotisation *',
                        border: OutlineInputBorder(),
                      ),
                      items: TypeCotisation.toutes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            typeChoisi = val;
                            if (val == TypeCotisation.mensuelle && membreSelectionneId != null) {
                              final m = membreProvider.membres
                                  .firstWhere((mb) => mb.id == membreSelectionneId);
                              montantController.text = m.montantCotisationMensuelle.toString();
                            }
                          });
                        }
                      },
                    ),
                    if (typeChoisi != TypeCotisation.mensuelle) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: libelleController,
                        decoration: InputDecoration(
                          labelText: typeChoisi == TypeCotisation.evenement
                              ? 'Nom de l\'événement'
                              : 'Précision (optionnel)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mois concerné'),
                      subtitle: Text(Formatters.moisLisible(moisChoisi)),
                      trailing: const Icon(Icons.calendar_view_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          helpText: 'Choisir un mois',
                        );
                        if (picked != null) {
                          setModalState(() {
                            moisChoisi = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant (Ar) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date de paiement'),
                      subtitle: Text(Formatters.dateLisible(
                          '${datePaiement.year}-${datePaiement.month.toString().padLeft(2, '0')}-${datePaiement.day.toString().padLeft(2, '0')}')),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: datePaiement,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => datePaiement = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: modePaiement,
                      decoration: const InputDecoration(
                        labelText: 'Mode de paiement',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Espèces', 'Mobile Money', 'Virement']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => modePaiement = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final montant = double.tryParse(montantController.text.trim());
                        if (membreSelectionneId == null || montant == null || montant <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Veuillez remplir correctement le formulaire')),
                          );
                          return;
                        }

                        final dateStr =
                            '${datePaiement.year}-${datePaiement.month.toString().padLeft(2, '0')}-${datePaiement.day.toString().padLeft(2, '0')}';

                        await context.read<CotisationProvider>().ajouterCotisation(
                              Cotisation(
                                membreId: membreSelectionneId!,
                                mois: moisChoisi,
                                montant: montant,
                                datePaiement: dateStr,
                                modePaiement: modePaiement,
                                typeCotisation: typeChoisi,
                                libelle: libelleController.text.trim(),
                              ),
                            );

                        if (ctx.mounted) Navigator.pop(ctx);
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
    final cotisationProvider = context.watch<CotisationProvider>();
    final membreProvider = context.watch<MembreProvider>();

    final cotisationsDuMois = cotisationProvider.parMois(_moisSelectionne);
    final totalMois = cotisationProvider.totalParMois(_moisSelectionne);

    // Seules les cotisations "Mensuelle" comptent pour déterminer qui a payé ce mois-ci
    final cotisationsMensuellesDuMois =
        cotisationsDuMois.where((c) => c.typeCotisation == TypeCotisation.mensuelle).toList();
    final membresPayes = cotisationsMensuellesDuMois.map((c) => c.membreId).toSet();
    final membresNonPayes =
        membreProvider.membres.where((m) => !membresPayes.contains(m.id)).toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changerMois(-1),
                    ),
                    Text(
                      Formatters.moisLisible(_moisSelectionne),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changerMois(1),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Total collecté: ${Formatters.montant(totalMois)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (cotisationsDuMois.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Paiements enregistrés', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...cotisationsDuMois.map((c) {
                    final membre = membreProvider.membres.firstWhere(
                      (m) => m.id == c.membreId,
                      orElse: () => membreProvider.membres.first,
                    );
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _couleurType(c.typeCotisation),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(membre.nom),
                        subtitle: Text(
                          '${Formatters.dateLisible(c.datePaiement)} • ${c.modePaiement}'
                          '${c.libelle.isNotEmpty ? " • ${c.libelle}" : ""}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Formatters.montant(c.montant),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: _couleurType(c.typeCotisation)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  onPressed: () async {
                                    await cotisationProvider.supprimerCotisation(c.id!);
                                  },
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _couleurType(c.typeCotisation).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.typeCotisation,
                                style: TextStyle(
                                    fontSize: 10, color: _couleurType(c.typeCotisation), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (membresNonPayes.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('N\'ont pas encore payé la cotisation mensuelle',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...membresNonPayes.map((m) => Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        color: Colors.red[50],
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, color: Colors.white),
                          ),
                          title: Text(m.nom),
                          subtitle: Text('Attendu: ${Formatters.montant(m.montantCotisationMensuelle)}'),
                        ),
                      )),
                ],
                if (membreProvider.membres.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Aucun membre enregistré.')),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ouvrirFormulaireAjout,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}

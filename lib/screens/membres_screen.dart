import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/membre.dart';
import '../models/cotisation.dart';
import '../providers/membre_provider.dart';
import '../providers/cotisation_provider.dart';
import '../widgets/membre_tile.dart';
import '../utils/formatters.dart';
import 'membre_detail_screen.dart';

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => MembresScreenState();
}

class MembresScreenState extends State<MembresScreen> {
  String _recherche = '';

  StatutPaiement _calculerStatut(Membre membre, CotisationProvider provider) {
    final moisActuel = Formatters.moisActuel();
    final cotisationsMembre = provider.parMembre(membre.id!);
    final cotisationDuMois = cotisationsMembre
        .where((c) => c.mois == moisActuel && c.typeCotisation == TypeCotisation.mensuelle)
        .toList();

    if (cotisationDuMois.isEmpty) {
      return StatutPaiement.enRetard;
    }
    final totalPaye = cotisationDuMois.fold(0.0, (s, c) => s + c.montant);
    if (totalPaye >= membre.montantCotisationMensuelle) {
      return StatutPaiement.aJour;
    }
    return StatutPaiement.partiel;
  }

  void ouvrirFormulaireAjout() {
    _afficherFormulaireMembre(context);
  }

  void _afficherFormulaireMembre(BuildContext context, {Membre? membre}) {
    final nomController = TextEditingController(text: membre?.nom ?? '');
    final telController = TextEditingController(text: membre?.telephone ?? '');
    final montantController = TextEditingController(
      text: membre != null ? membre.montantCotisationMensuelle.toString() : '',
    );
    DateTime dateAdhesion =
        membre != null ? DateTime.parse(membre.dateAdhesion) : DateTime.now();

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
                    Text(
                      membre == null ? 'Ajouter un membre' : 'Modifier le membre',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: telController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cotisation mensuelle (Ar) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Date d'adhésion"),
                      subtitle: Text(Formatters.dateLisible(
                          '${dateAdhesion.year}-${dateAdhesion.month.toString().padLeft(2, '0')}-${dateAdhesion.day.toString().padLeft(2, '0')}')),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dateAdhesion,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dateAdhesion = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final nom = nomController.text.trim();
                        final montantTxt = montantController.text.trim();
                        if (nom.isEmpty || montantTxt.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Veuillez remplir les champs obligatoires (*)')),
                          );
                          return;
                        }
                        final montant = double.tryParse(montantTxt);
                        if (montant == null || montant < 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Montant invalide')),
                          );
                          return;
                        }

                        final dateStr =
                            '${dateAdhesion.year}-${dateAdhesion.month.toString().padLeft(2, '0')}-${dateAdhesion.day.toString().padLeft(2, '0')}';

                        final provider = context.read<MembreProvider>();
                        if (membre == null) {
                          await provider.ajouterMembre(Membre(
                            nom: nom,
                            telephone: telController.text.trim(),
                            dateAdhesion: dateStr,
                            montantCotisationMensuelle: montant,
                          ));
                        } else {
                          await provider.modifierMembre(membre.copyWith(
                            nom: nom,
                            telephone: telController.text.trim(),
                            dateAdhesion: dateStr,
                            montantCotisationMensuelle: montant,
                          ));
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(membre == null ? 'Ajouter' : 'Enregistrer'),
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
    final membreProvider = context.watch<MembreProvider>();
    final cotisationProvider = context.watch<CotisationProvider>();

    final membresFiltres = membreProvider.rechercherParNom(_recherche);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (val) => setState(() => _recherche = val),
            ),
          ),
          Expanded(
            child: membresFiltres.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun membre. Appuyez sur + pour en ajouter.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: membresFiltres.length,
                    itemBuilder: (ctx, i) {
                      final membre = membresFiltres[i];
                      final statut = _calculerStatut(membre, cotisationProvider);
                      return MembreTile(
                        membre: membre,
                        statutPaiement: statut,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MembreDetailScreen(membre: membre),
                            ),
                          );
                        },
                        onDelete: () async {
                          final confirmer = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Supprimer le membre ?'),
                              content: Text(
                                  'Voulez-vous vraiment supprimer ${membre.nom} ? Toutes ses cotisations enregistrées seront aussi supprimées.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Supprimer',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirmer == true) {
                            await membreProvider.supprimerMembre(membre.id!);
                            await cotisationProvider.chargerCotisations();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ouvrirFormulaireAjout,
        child: const Icon(Icons.add),
      ),
    );
  }
}

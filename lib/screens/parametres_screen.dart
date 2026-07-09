import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../db/database_helper.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _nomAssociationController = TextEditingController();
  final _montantDefautController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerParametres();
  }

  Future<void> _chargerParametres() async {
    final nom = await DatabaseHelper.instance.getParametre('nom_association');
    final montant = await DatabaseHelper.instance.getParametre('montant_defaut');
    setState(() {
      _nomAssociationController.text = nom ?? 'Ny Tahiriko';
      _montantDefautController.text = montant ?? '';
    });
  }

  Future<void> _enregistrerParametres() async {
    await DatabaseHelper.instance
        .setParametre('nom_association', _nomAssociationController.text.trim());
    await DatabaseHelper.instance
        .setParametre('montant_defaut', _montantDefautController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres enregistrés')),
      );
    }
  }

  Future<void> _exporterSauvegarde() async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Base de données introuvable')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/sauvegarde_cotisation_app.db');
      await dbFile.copy(backupFile.path);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'Sauvegarde de la base de données - Cotisation App',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export : $e')),
        );
      }
    }
  }

  Future<void> _restaurerSauvegarde() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer une sauvegarde'),
        content: const Text(
          'Attention : cette action remplacera toutes les données actuelles par celles du fichier sélectionné. Continuer ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmer != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;

      final sourceFile = File(result.files.single.path!);
      await DatabaseHelper.instance.closeDatabase();

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      await sourceFile.copy(dbPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sauvegarde restaurée. Redémarrez l\'application pour appliquer les changements.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la restauration : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Paramètres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("Informations de l'association",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nomAssociationController,
            decoration: const InputDecoration(
              labelText: "Nom de l'association",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montantDefautController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant de cotisation par défaut (Ar)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _enregistrerParametres,
            child: const Text('Enregistrer'),
          ),
          const SizedBox(height: 30),
          const Text('Sauvegarde des données',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toutes les données sont stockées uniquement sur cet appareil. '
                      'Pensez à faire des sauvegardes régulières pour ne pas perdre vos données.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _exporterSauvegarde,
            icon: const Icon(Icons.upload_file),
            label: const Text('Exporter une sauvegarde'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _restaurerSauvegarde,
            icon: const Icon(Icons.download),
            label: const Text('Restaurer une sauvegarde'),
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              'Ny Tahiriko v1.0.0',
              style: TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../providers/membre_provider.dart';
import '../providers/cotisation_provider.dart';
import '../providers/sortie_provider.dart';
import '../utils/pdf_generator.dart';
import '../utils/formatters.dart';
import '../db/database_helper.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  bool _generationEnCours = false;
  String _nomAssociation = '';
  String _moisBilanSelectionne = Formatters.moisActuel();

  @override
  void initState() {
    super.initState();
    _chargerNomAssociation();
  }

  Future<void> _chargerNomAssociation() async {
    final nom = await DatabaseHelper.instance.getParametre('nom_association');
    setState(() {
      _nomAssociation = nom ?? '';
    });
  }

  void _changerMoisBilan(int delta) {
    final parts = _moisBilanSelectionne.split('-');
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
      _moisBilanSelectionne = '$annee-${mois.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _exporterPdf() async {
    setState(() => _generationEnCours = true);
    try {
      final membreProvider = context.read<MembreProvider>();
      final cotisationProvider = context.read<CotisationProvider>();
      final sortieProvider = context.read<SortieProvider>();

      final pdfBytes = await PdfGenerator.genererRapportGlobal(
        nomAssociation: _nomAssociation,
        membres: membreProvider.membres,
        cotisations: cotisationProvider.cotisations,
        sorties: sortieProvider.sorties,
        totalCotisations: cotisationProvider.totalCotisations,
        totalSorties: sortieProvider.totalSorties,
        balance: cotisationProvider.totalCotisations - sortieProvider.totalSorties,
      );

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } finally {
      if (mounted) setState(() => _generationEnCours = false);
    }
  }

  Future<void> _partagerPdf() async {
    setState(() => _generationEnCours = true);
    try {
      final membreProvider = context.read<MembreProvider>();
      final cotisationProvider = context.read<CotisationProvider>();
      final sortieProvider = context.read<SortieProvider>();

      final pdfBytes = await PdfGenerator.genererRapportGlobal(
        nomAssociation: _nomAssociation,
        membres: membreProvider.membres,
        cotisations: cotisationProvider.cotisations,
        sorties: sortieProvider.sorties,
        totalCotisations: cotisationProvider.totalCotisations,
        totalSorties: sortieProvider.totalSorties,
        balance: cotisationProvider.totalCotisations - sortieProvider.totalSorties,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/rapport_cotisations.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Rapport financier de l\'association');
    } finally {
      if (mounted) setState(() => _generationEnCours = false);
    }
  }

  Future<void> _apercuBilanMensuel() async {
    setState(() => _generationEnCours = true);
    try {
      final membreProvider = context.read<MembreProvider>();
      final cotisationProvider = context.read<CotisationProvider>();
      final sortieProvider = context.read<SortieProvider>();

      final cotisationsDuMois = cotisationProvider.parMois(_moisBilanSelectionne);
      final sortiesDuMois = sortieProvider.sorties
          .where((s) => s.date.startsWith(_moisBilanSelectionne))
          .toList();

      final pdfBytes = await PdfGenerator.genererBilanMensuel(
        nomAssociation: _nomAssociation,
        mois: _moisBilanSelectionne,
        membres: membreProvider.membres,
        cotisationsDuMois: cotisationsDuMois,
        sortiesDuMois: sortiesDuMois,
        balanceGlobaleActuelle:
            cotisationProvider.totalCotisations - sortieProvider.totalSorties,
      );

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } finally {
      if (mounted) setState(() => _generationEnCours = false);
    }
  }

  Future<void> _partagerBilanMensuel() async {
    setState(() => _generationEnCours = true);
    try {
      final membreProvider = context.read<MembreProvider>();
      final cotisationProvider = context.read<CotisationProvider>();
      final sortieProvider = context.read<SortieProvider>();

      final cotisationsDuMois = cotisationProvider.parMois(_moisBilanSelectionne);
      final sortiesDuMois = sortieProvider.sorties
          .where((s) => s.date.startsWith(_moisBilanSelectionne))
          .toList();

      final pdfBytes = await PdfGenerator.genererBilanMensuel(
        nomAssociation: _nomAssociation,
        mois: _moisBilanSelectionne,
        membres: membreProvider.membres,
        cotisationsDuMois: cotisationsDuMois,
        sortiesDuMois: sortiesDuMois,
        balanceGlobaleActuelle:
            cotisationProvider.totalCotisations - sortieProvider.totalSorties,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bilan_${_moisBilanSelectionne}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Bilan mensuel — ${Formatters.moisLisible(_moisBilanSelectionne)}',
      );
    } finally {
      if (mounted) setState(() => _generationEnCours = false);
    }
  }

  Future<void> _exporterExcel() async {
    setState(() => _generationEnCours = true);
    try {
      final membreProvider = context.read<MembreProvider>();
      final cotisationProvider = context.read<CotisationProvider>();
      final sortieProvider = context.read<SortieProvider>();

      final nomsParId = <int, String>{
        for (final m in membreProvider.membres)
          if (m.id != null) m.id!: m.nom,
      };

      final workbook = excel_lib.Excel.createExcel();

      // Feuille Membres
      final sheetMembres = workbook['Membres'];
      sheetMembres.appendRow([
        excel_lib.TextCellValue('Nom'),
        excel_lib.TextCellValue('Téléphone'),
        excel_lib.TextCellValue('Cotisation mensuelle'),
        excel_lib.TextCellValue('Date adhésion'),
      ]);
      for (final m in membreProvider.membres) {
        sheetMembres.appendRow([
          excel_lib.TextCellValue(m.nom),
          excel_lib.TextCellValue(m.telephone),
          excel_lib.DoubleCellValue(m.montantCotisationMensuelle),
          excel_lib.TextCellValue(m.dateAdhesion),
        ]);
      }

      // Feuille Cotisations
      final sheetCotisations = workbook['Cotisations'];
      sheetCotisations.appendRow([
        excel_lib.TextCellValue('Membre'),
        excel_lib.TextCellValue('Type'),
        excel_lib.TextCellValue('Mois'),
        excel_lib.TextCellValue('Montant'),
        excel_lib.TextCellValue('Date paiement'),
        excel_lib.TextCellValue('Mode'),
      ]);
      for (final c in cotisationProvider.cotisations) {
        sheetCotisations.appendRow([
          excel_lib.TextCellValue(nomsParId[c.membreId] ?? 'Membre supprimé (#${c.membreId})'),
          excel_lib.TextCellValue(c.typeCotisation),
          excel_lib.TextCellValue(c.mois),
          excel_lib.DoubleCellValue(c.montant),
          excel_lib.TextCellValue(c.datePaiement),
          excel_lib.TextCellValue(c.modePaiement),
        ]);
      }

      // Feuille Sorties
      final sheetSorties = workbook['Sorties'];
      sheetSorties.appendRow([
        excel_lib.TextCellValue('Date'),
        excel_lib.TextCellValue('Motif'),
        excel_lib.TextCellValue('Bénéficiaire'),
        excel_lib.TextCellValue('Montant'),
      ]);
      for (final s in sortieProvider.sorties) {
        sheetSorties.appendRow([
          excel_lib.TextCellValue(s.date),
          excel_lib.TextCellValue(s.motif),
          excel_lib.TextCellValue(s.beneficiaire),
          excel_lib.DoubleCellValue(s.montant),
        ]);
      }

      workbook.delete('Sheet1');

      final bytes = workbook.save();
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/grand_livre_cotisations.xlsx');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Grand livre des cotisations');
      }
    } finally {
      if (mounted) setState(() => _generationEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cotisationProvider = context.watch<CotisationProvider>();
    final sortieProvider = context.watch<SortieProvider>();
    final balance = cotisationProvider.totalCotisations - sortieProvider.totalSorties;

    return Scaffold(
      body: _generationEnCours
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Rapports & export',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ligne('Total cotisations', Formatters.montant(cotisationProvider.totalCotisations), Colors.green),
                        _ligne('Total sorties', Formatters.montant(sortieProvider.totalSorties), Colors.red),
                        const Divider(),
                        _ligne('Balance', Formatters.montant(balance), balance >= 0 ? Colors.green : Colors.red, gras: true),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Bilan mensuel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _changerMoisBilan(-1),
                        ),
                        Text(
                          Formatters.moisLisible(_moisBilanSelectionne),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _changerMoisBilan(1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _boutonExport(
                  icon: Icons.fact_check,
                  label: 'Aperçu / Imprimer le bilan du mois',
                  couleur: Colors.indigo,
                  onTap: _apercuBilanMensuel,
                ),
                const SizedBox(height: 10),
                _boutonExport(
                  icon: Icons.share,
                  label: 'Partager le bilan du mois',
                  couleur: Colors.teal,
                  onTap: _partagerBilanMensuel,
                ),

                const SizedBox(height: 24),
                const Text('Rapport complet (toutes périodes)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _boutonExport(
                  icon: Icons.picture_as_pdf,
                  label: 'Aperçu / Imprimer le rapport PDF',
                  couleur: Colors.red,
                  onTap: _exporterPdf,
                ),
                const SizedBox(height: 10),
                _boutonExport(
                  icon: Icons.share,
                  label: 'Partager le rapport PDF',
                  couleur: Colors.blue,
                  onTap: _partagerPdf,
                ),
                const SizedBox(height: 10),
                _boutonExport(
                  icon: Icons.table_chart,
                  label: 'Exporter le grand livre en Excel',
                  couleur: Colors.green,
                  onTap: _exporterExcel,
                ),
              ],
            ),
    );
  }

  Widget _ligne(String label, String valeur, Color couleur, {bool gras = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: gras ? FontWeight.bold : FontWeight.normal)),
          Text(valeur,
              style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
                  fontSize: gras ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _boutonExport({
    required IconData icon,
    required String label,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return Material(
      color: couleur.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: couleur),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(color: couleur, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.chevron_right, color: couleur),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cotisation.dart';
import '../models/sortie.dart';
import '../models/membre.dart';
import 'formatters.dart';

class PdfGenerator {
  /// Construit un dictionnaire id -> nom pour retrouver rapidement
  /// le nom d'un membre à partir de son identifiant.
  static Map<int, String> _nomsParId(List<Membre> membres) {
    final map = <int, String>{};
    for (final m in membres) {
      if (m.id != null) map[m.id!] = m.nom;
    }
    return map;
  }

  static String _nomMembre(Map<int, String> noms, int membreId) {
    return noms[membreId] ?? 'Membre supprimé (#$membreId)';
  }

  static Future<Uint8List> genererRapportGlobal({
    required String nomAssociation,
    required List<Membre> membres,
    required List<Cotisation> cotisations,
    required List<Sortie> sorties,
    required double totalCotisations,
    required double totalSorties,
    required double balance,
  }) async {
    final pdf = pw.Document();
    final noms = _nomsParId(membres);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(nomAssociation.isNotEmpty ? nomAssociation : 'Association',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Rapport financier - généré le ${Formatters.dateLisible(Formatters.dateActuelle())}'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Total cotisations'),
                  pw.Text(Formatters.montant(totalCotisations),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Total sorties'),
                  pw.Text(Formatters.montant(totalSorties),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Balance'),
                  pw.Text(Formatters.montant(balance),
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: balance >= 0 ? PdfColors.green700 : PdfColors.red700)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Liste des membres (${membres.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Nom', 'Téléphone', 'Cotisation/mois', 'Adhésion'],
            data: membres
                .map((m) => [
                      m.nom,
                      m.telephone,
                      Formatters.montant(m.montantCotisationMensuelle),
                      Formatters.dateLisible(m.dateAdhesion),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Cotisations enregistrées (${cotisations.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Membre', 'Type', 'Mois', 'Montant', 'Date', 'Mode'],
            data: cotisations
                .map((c) => [
                      _nomMembre(noms, c.membreId),
                      c.typeCotisation,
                      Formatters.moisLisible(c.mois),
                      Formatters.montant(c.montant),
                      Formatters.dateLisible(c.datePaiement),
                      c.modePaiement,
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Sorties enregistrées (${sorties.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Motif', 'Bénéficiaire', 'Montant'],
            data: sorties
                .map((s) => [
                      Formatters.dateLisible(s.date),
                      s.motif,
                      s.beneficiaire,
                      Formatters.montant(s.montant),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Génère un bilan complet pour un mois donné (format yyyy-MM) :
  /// cotisations du mois (avec noms des membres), qui a payé / qui n'a pas
  /// payé, sorties du mois, total du mois et balance globale de l'association
  /// après ce mois.
  static Future<Uint8List> genererBilanMensuel({
    required String nomAssociation,
    required String mois,
    required List<Membre> membres,
    required List<Cotisation> cotisationsDuMois,
    required List<Sortie> sortiesDuMois,
    required double balanceGlobaleActuelle,
  }) async {
    final pdf = pw.Document();
    final noms = _nomsParId(membres);

    final totalCotisationsMois =
        cotisationsDuMois.fold(0.0, (s, c) => s + c.montant);
    final totalSortiesMois = sortiesDuMois.fold(0.0, (s, sOut) => s + sOut.montant);
    final soldeDuMois = totalCotisationsMois - totalSortiesMois;

    // Membres actifs qui n'ont pas payé leur cotisation mensuelle ce mois-ci
    final idsAyantPayeMensuel = cotisationsDuMois
        .where((c) => c.typeCotisation == TypeCotisation.mensuelle)
        .map((c) => c.membreId)
        .toSet();
    final membresActifs = membres.where((m) => m.statut == 'Actif').toList();
    final membresEnRetard =
        membresActifs.where((m) => !idsAyantPayeMensuel.contains(m.id)).toList();
    final membresAJour =
        membresActifs.where((m) => idsAyantPayeMensuel.contains(m.id)).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(nomAssociation.isNotEmpty ? nomAssociation : 'Association',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('BILAN MENSUEL — ${Formatters.moisLisible(mois)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.Text('Généré le ${Formatters.dateLisible(Formatters.dateActuelle())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),

          // Résumé du mois
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Cotisations du mois'),
                  pw.Text(Formatters.montant(totalCotisationsMois),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Sorties du mois'),
                  pw.Text(Formatters.montant(totalSortiesMois),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Solde du mois'),
                  pw.Text(Formatters.montant(soldeDuMois),
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: soldeDuMois >= 0 ? PdfColors.green700 : PdfColors.red700)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: balanceGlobaleActuelle >= 0 ? PdfColors.green50 : PdfColors.red50,
              border: pw.Border.all(
                  color: balanceGlobaleActuelle >= 0 ? PdfColors.green300 : PdfColors.red300),
            ),
            child: pw.Text(
              'Balance globale de l\'association (à ce jour) : ${Formatters.montant(balanceGlobaleActuelle)}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: balanceGlobaleActuelle >= 0 ? PdfColors.green800 : PdfColors.red800,
              ),
            ),
          ),

          pw.SizedBox(height: 20),
          pw.Text('Cotisations encaissées (${cotisationsDuMois.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (cotisationsDuMois.isEmpty)
            pw.Text('Aucune cotisation enregistrée pour ce mois.',
                style: const pw.TextStyle(color: PdfColors.grey700))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Membre', 'Type', 'Montant', 'Date', 'Mode'],
              data: cotisationsDuMois
                  .map((c) => [
                        _nomMembre(noms, c.membreId),
                        c.typeCotisation,
                        Formatters.montant(c.montant),
                        Formatters.dateLisible(c.datePaiement),
                        c.modePaiement,
                      ])
                  .toList(),
            ),

          pw.SizedBox(height: 20),
          pw.Text('Membres à jour ce mois-ci (${membresAJour.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
          pw.SizedBox(height: 6),
          pw.Text(
            membresAJour.isEmpty ? 'Aucun' : membresAJour.map((m) => m.nom).join(', '),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Membres en retard ce mois-ci (${membresEnRetard.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
          pw.SizedBox(height: 6),
          pw.Text(
            membresEnRetard.isEmpty ? 'Aucun — tout le monde est à jour !' : membresEnRetard.map((m) => m.nom).join(', '),
          ),

          pw.SizedBox(height: 20),
          pw.Text('Sorties du mois (${sortiesDuMois.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (sortiesDuMois.isEmpty)
            pw.Text('Aucune sortie enregistrée pour ce mois.',
                style: const pw.TextStyle(color: PdfColors.grey700))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Motif', 'Bénéficiaire', 'Montant'],
              data: sortiesDuMois
                  .map((s) => [
                        Formatters.dateLisible(s.date),
                        s.motif,
                        s.beneficiaire,
                        Formatters.montant(s.montant),
                      ])
                  .toList(),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> genererRecuMembre({
    required String nomAssociation,
    required Membre membre,
    required Cotisation cotisation,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(nomAssociation.isNotEmpty ? nomAssociation : 'Association',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('REÇU DE COTISATION',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text('Membre : ${membre.nom}'),
                pw.SizedBox(height: 6),
                pw.Text('Type : ${cotisation.typeCotisation}'),
                pw.SizedBox(height: 6),
                pw.Text('Mois : ${Formatters.moisLisible(cotisation.mois)}'),
                pw.SizedBox(height: 6),
                pw.Text('Date de paiement : ${Formatters.dateLisible(cotisation.datePaiement)}'),
                pw.SizedBox(height: 6),
                pw.Text('Mode de paiement : ${cotisation.modePaiement}'),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text(
                    'Montant payé : ${Formatters.montant(cotisation.montant)}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text('Merci pour votre contribution.'),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}

import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/sortie.dart';

/// Résultat retourné lors de la tentative d'ajout d'une sortie,
/// permet de gérer la restriction de balance.
class ResultatAjoutSortie {
  final bool succes;
  final bool balanceInsuffisante;
  final double balanceActuelle;

  ResultatAjoutSortie({
    required this.succes,
    required this.balanceInsuffisante,
    required this.balanceActuelle,
  });
}

class SortieProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Sortie> _sorties = [];
  double _totalSorties = 0.0;
  double _balance = 0.0;

  List<Sortie> get sorties => _sorties;
  double get totalSorties => _totalSorties;
  double get balance => _balance;

  Future<void> chargerSorties() async {
    _sorties = await _db.getSorties();
    _totalSorties = await _db.getTotalSorties();
    _balance = await _db.getBalance();
    notifyListeners();
  }

  /// Vérifie la balance avant d'ajouter une sortie.
  /// Si [forcer] est false et que la balance deviendrait négative,
  /// l'opération est bloquée et on retourne l'information pour
  /// que l'interface affiche une alerte de confirmation.
  Future<ResultatAjoutSortie> tenterAjouterSortie(
    Sortie sortie, {
    bool forcer = false,
  }) async {
    final balanceActuelle = await _db.getBalance();
    final nouvelleBalance = balanceActuelle - sortie.montant;

    if (nouvelleBalance < 0 && !forcer) {
      return ResultatAjoutSortie(
        succes: false,
        balanceInsuffisante: true,
        balanceActuelle: balanceActuelle,
      );
    }

    final sortieFinale = Sortie(
      date: sortie.date,
      montant: sortie.montant,
      motif: sortie.motif,
      beneficiaire: sortie.beneficiaire,
      justificatif: sortie.justificatif,
      forcee: nouvelleBalance < 0 ? 1 : 0,
    );

    await _db.insertSortie(sortieFinale);
    await chargerSorties();

    return ResultatAjoutSortie(
      succes: true,
      balanceInsuffisante: nouvelleBalance < 0,
      balanceActuelle: balanceActuelle,
    );
  }

  Future<void> supprimerSortie(int id) async {
    await _db.deleteSortie(id);
    await chargerSorties();
  }
}

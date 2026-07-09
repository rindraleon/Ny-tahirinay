import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/cotisation.dart';

class CotisationProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Cotisation> _cotisations = [];
  double _totalCotisations = 0.0;

  List<Cotisation> get cotisations => _cotisations;
  double get totalCotisations => _totalCotisations;

  Future<void> chargerCotisations() async {
    _cotisations = await _db.getCotisations();
    _totalCotisations = await _db.getTotalCotisations();
    notifyListeners();
  }

  Future<void> ajouterCotisation(Cotisation cotisation) async {
    await _db.insertCotisation(cotisation);
    await chargerCotisations();
  }

  Future<void> modifierCotisation(Cotisation cotisation) async {
    await _db.updateCotisation(cotisation);
    await chargerCotisations();
  }

  Future<void> supprimerCotisation(int id) async {
    await _db.deleteCotisation(id);
    await chargerCotisations();
  }

  List<Cotisation> parMois(String mois) {
    return _cotisations.where((c) => c.mois == mois).toList();
  }

  List<Cotisation> parMembre(int membreId) {
    return _cotisations.where((c) => c.membreId == membreId).toList();
  }

  double totalParMois(String mois) {
    return parMois(mois).fold(0.0, (sum, c) => sum + c.montant);
  }
}

import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/membre.dart';

class MembreProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Membre> _membres = [];

  List<Membre> get membres => _membres;

  Future<void> chargerMembres() async {
    _membres = await _db.getMembres();
    notifyListeners();
  }

  Future<void> ajouterMembre(Membre membre) async {
    await _db.insertMembre(membre);
    await chargerMembres();
  }

  Future<void> modifierMembre(Membre membre) async {
    await _db.updateMembre(membre);
    await chargerMembres();
  }

  Future<void> supprimerMembre(int id) async {
    await _db.deleteMembre(id);
    await chargerMembres();
  }

  List<Membre> rechercherParNom(String query) {
    if (query.isEmpty) return _membres;
    return _membres
        .where((m) => m.nom.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

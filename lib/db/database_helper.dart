import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/membre.dart';
import '../models/cotisation.dart';
import '../models/sortie.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'cotisation_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE cotisations ADD COLUMN type_cotisation TEXT NOT NULL DEFAULT 'Mensuelle'");
      await db.execute(
          "ALTER TABLE cotisations ADD COLUMN libelle TEXT NOT NULL DEFAULT ''");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE membres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        telephone TEXT,
        date_adhesion TEXT NOT NULL,
        statut TEXT NOT NULL DEFAULT 'Actif',
        montant_cotisation_mensuelle REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cotisations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        membre_id INTEGER NOT NULL,
        mois TEXT NOT NULL,
        montant REAL NOT NULL,
        date_paiement TEXT NOT NULL,
        mode_paiement TEXT DEFAULT 'Espèces',
        type_cotisation TEXT NOT NULL DEFAULT 'Mensuelle',
        libelle TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (membre_id) REFERENCES membres (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sorties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        montant REAL NOT NULL,
        motif TEXT NOT NULL,
        beneficiaire TEXT,
        justificatif TEXT,
        forcee INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE parametres (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      )
    ''');

    // Valeurs par défaut
    await db.insert('parametres', {'cle': 'nom_association', 'valeur': 'Ny Tahiriko'});
  }

  // ---------------- MEMBRES ----------------

  Future<int> insertMembre(Membre membre) async {
    final db = await database;
    return await db.insert('membres', membre.toMap()..remove('id'));
  }

  Future<int> updateMembre(Membre membre) async {
    final db = await database;
    return await db.update(
      'membres',
      membre.toMap(),
      where: 'id = ?',
      whereArgs: [membre.id],
    );
  }

  Future<int> deleteMembre(int id) async {
    final db = await database;
    // Supprime aussi les cotisations liées
    await db.delete('cotisations', where: 'membre_id = ?', whereArgs: [id]);
    return await db.delete('membres', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Membre>> getMembres() async {
    final db = await database;
    final result = await db.query('membres', orderBy: 'nom ASC');
    return result.map((m) => Membre.fromMap(m)).toList();
  }

  Future<Membre?> getMembreById(int id) async {
    final db = await database;
    final result = await db.query('membres', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Membre.fromMap(result.first);
  }

  // ---------------- COTISATIONS ----------------

  Future<int> insertCotisation(Cotisation cotisation) async {
    final db = await database;
    return await db.insert('cotisations', cotisation.toMap()..remove('id'));
  }

  Future<int> updateCotisation(Cotisation cotisation) async {
    final db = await database;
    return await db.update(
      'cotisations',
      cotisation.toMap(),
      where: 'id = ?',
      whereArgs: [cotisation.id],
    );
  }

  Future<int> deleteCotisation(int id) async {
    final db = await database;
    return await db.delete('cotisations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Cotisation>> getCotisations() async {
    final db = await database;
    final result = await db.query('cotisations', orderBy: 'date_paiement DESC');
    return result.map((c) => Cotisation.fromMap(c)).toList();
  }

  Future<List<Cotisation>> getCotisationsParMois(String mois) async {
    final db = await database;
    final result = await db.query(
      'cotisations',
      where: 'mois = ?',
      whereArgs: [mois],
    );
    return result.map((c) => Cotisation.fromMap(c)).toList();
  }

  Future<List<Cotisation>> getCotisationsParMembre(int membreId) async {
    final db = await database;
    final result = await db.query(
      'cotisations',
      where: 'membre_id = ?',
      whereArgs: [membreId],
      orderBy: 'mois DESC',
    );
    return result.map((c) => Cotisation.fromMap(c)).toList();
  }

  Future<double> getTotalCotisations() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(montant) as total FROM cotisations');
    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  Future<double> getTotalCotisationsParMois(String mois) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(montant) as total FROM cotisations WHERE mois = ?',
      [mois],
    );
    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  /// Retourne la liste des membres actifs qui n'ont pas encore payé
  /// leur cotisation mensuelle pour le mois donné.
  Future<List<Membre>> getMembresEnRetard(String mois) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT m.* FROM membres m
      WHERE m.statut = 'Actif'
      AND m.id NOT IN (
        SELECT membre_id FROM cotisations
        WHERE mois = ? AND type_cotisation = 'Mensuelle'
      )
    ''', [mois]);
    return result.map((m) => Membre.fromMap(m)).toList();
  }

  // ---------------- SORTIES ----------------

  Future<int> insertSortie(Sortie sortie) async {
    final db = await database;
    return await db.insert('sorties', sortie.toMap()..remove('id'));
  }

  Future<int> updateSortie(Sortie sortie) async {
    final db = await database;
    return await db.update(
      'sorties',
      sortie.toMap(),
      where: 'id = ?',
      whereArgs: [sortie.id],
    );
  }

  Future<int> deleteSortie(int id) async {
    final db = await database;
    return await db.delete('sorties', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Sortie>> getSorties() async {
    final db = await database;
    final result = await db.query('sorties', orderBy: 'date DESC');
    return result.map((s) => Sortie.fromMap(s)).toList();
  }

  Future<double> getTotalSorties() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(montant) as total FROM sorties');
    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  // ---------------- BALANCE ----------------

  Future<double> getBalance() async {
    final totalCotisations = await getTotalCotisations();
    final totalSorties = await getTotalSorties();
    return totalCotisations - totalSorties;
  }

  // ---------------- PARAMETRES ----------------

  Future<void> setParametre(String cle, String valeur) async {
    final db = await database;
    await db.insert(
      'parametres',
      {'cle': cle, 'valeur': valeur},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getParametre(String cle) async {
    final db = await database;
    final result =
        await db.query('parametres', where: 'cle = ?', whereArgs: [cle]);
    if (result.isEmpty) return null;
    return result.first['valeur'] as String?;
  }

  Future<String> getDatabasePath() async {
    final documentsDirectory = await getDatabasesPath();
    return join(documentsDirectory, 'cotisation_app.db');
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

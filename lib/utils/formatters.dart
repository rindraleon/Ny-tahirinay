import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _montantFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'Ar',
    decimalDigits: 0,
    customPattern: '#,##0 \u00a4',
  );

  static String montant(double valeur) {
    return _montantFormat.format(valeur);
  }

  static String moisLisible(String mois) {
    // mois au format yyyy-MM
    try {
      final parts = mois.split('-');
      final annee = int.parse(parts[0]);
      final moisNum = int.parse(parts[1]);
      final date = DateTime(annee, moisNum);
      final formatteur = DateFormat.yMMMM('fr_FR');
      return formatteur.format(date);
    } catch (e) {
      return mois;
    }
  }

  static String dateLisible(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(d);
    } catch (e) {
      return date;
    }
  }

  static String moisActuel() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String dateActuelle() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

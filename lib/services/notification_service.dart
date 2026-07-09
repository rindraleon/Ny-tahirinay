import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../db/database_helper.dart';
import '../utils/formatters.dart';

/// Service centralisant la gestion des notifications locales :
/// - Rappel de début de mois pour lancer la collecte des cotisations
/// - Alerte listant les membres en retard (envoyée le 15 et le 25 du mois)
class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialise = false;

  Future<void> initialiser() async {
    if (_initialise) return;

    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Demande de permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialise = true;

    await _planifierRappelsRecurrents();
  }

  Future<void> _planifierRappelsRecurrents() async {
    // Annule les anciennes planifications avant de les recréer
    await _plugin.cancel(_idRappelDebutMois);
    await _plugin.cancel(_idAlerteRetard15);
    await _plugin.cancel(_idAlerteRetard25);

    // 1) Rappel de début de mois : le 1er de chaque mois à 8h00
    await _planifierNotificationMensuelle(
      id: _idRappelDebutMois,
      jour: 1,
      heure: 8,
      titre: '📅 Nouveau mois, nouvelle collecte !',
      corps:
          'Il est temps de commencer la collecte des cotisations pour ${Formatters.moisLisible(Formatters.moisActuel())}.',
    );

    // 2) Alerte membres en retard : le 15 de chaque mois à 9h00
    await _planifierNotificationMensuelle(
      id: _idAlerteRetard15,
      jour: 15,
      heure: 9,
      titre: '⚠️ Suivi des cotisations',
      corps: 'Vérifiez les membres qui n\'ont pas encore payé ce mois-ci.',
    );

    // 3) Alerte membres en retard : le 25 de chaque mois à 9h00
    await _planifierNotificationMensuelle(
      id: _idAlerteRetard25,
      jour: 25,
      heure: 9,
      titre: '⏰ Dernière relance du mois',
      corps: 'Il reste quelques jours pour collecter les cotisations en retard.',
    );
  }

  static const int _idRappelDebutMois = 1001;
  static const int _idAlerteRetard15 = 1002;
  static const int _idAlerteRetard25 = 1003;

  Future<void> _planifierNotificationMensuelle({
    required int id,
    required int jour,
    required int heure,
    required String titre,
    required String corps,
  }) async {
    final maintenant = tz.TZDateTime.now(tz.local);
    var prochaine = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      jour,
      heure,
    );

    if (prochaine.isBefore(maintenant)) {
      // Passe au mois suivant si la date est déjà passée ce mois-ci
      prochaine = tz.TZDateTime(
        tz.local,
        maintenant.month == 12 ? maintenant.year + 1 : maintenant.year,
        maintenant.month == 12 ? 1 : maintenant.month + 1,
        jour,
        heure,
      );
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ny_tahiriko_rappels',
        'Rappels de cotisation',
        channelDescription:
            'Notifications de rappel pour la collecte des cotisations',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      prochaine,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// Affiche immédiatement une notification listant les membres en retard
  /// pour le mois en cours (peut être appelée manuellement depuis l'app).
  Future<void> notifierMembresEnRetardMaintenant() async {
    final moisActuel = Formatters.moisActuel();
    final membresEnRetard =
        await DatabaseHelper.instance.getMembresEnRetard(moisActuel);

    if (membresEnRetard.isEmpty) {
      await _plugin.show(
        2001,
        '✅ Tout le monde est à jour',
        'Tous les membres actifs ont payé leur cotisation de ${Formatters.moisLisible(moisActuel)}.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ny_tahiriko_rappels',
            'Rappels de cotisation',
            importance: Importance.defaultImportance,
          ),
        ),
      );
      return;
    }

    final noms = membresEnRetard.map((m) => m.nom).join(', ');
    await _plugin.show(
      2002,
      '⚠️ ${membresEnRetard.length} membre(s) en retard',
      'N\'ont pas encore payé pour ${Formatters.moisLisible(moisActuel)} : $noms',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ny_tahiriko_rappels',
          'Rappels de cotisation',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

# Ny Tahiriko — Application de gestion des cotisations pour association

Application Flutter développée pour permettre à un trésorier d'association de :
- Gérer la liste des membres
- Enregistrer les cotisations mensuelles (calcul automatique du total)
- Gérer plusieurs **types de cotisation** : Mensuelle, Adhésion annuelle, Événement, Autre
- Enregistrer les sorties/dépenses avec un motif obligatoire
- Calculer automatiquement la balance (Total cotisations − Total sorties)
- Bloquer/avertir en cas de fonds insuffisants avant une sortie (restriction)
- Recevoir des **notifications/rappels** :
  - Rappel automatique le 1er de chaque mois pour lancer la collecte
  - Alertes automatiques le 15 et le 25 du mois sur les membres en retard
  - Bouton "Vérifier les membres en retard maintenant" sur le tableau de bord
- Exporter un **rapport global** en PDF/Excel (avec les noms des membres, pas juste leurs identifiants)
- Générer un **bilan mensuel PDF** pour un mois donné (cotisations encaissées, membres à jour/en retard, sorties, balance)

## 🚀 Générer l'APK automatiquement avec GitHub Actions (recommandé)

Ce projet contient un workflow prêt à l'emploi dans
`.github/workflows/build_apk.yml` qui compile l'APK automatiquement à chaque
`push`, à chaque pull request, ou manuellement.

### Étapes pour l'utiliser :

1. **Créez un dépôt sur GitHub** (public ou privé), par exemple `ny-tahiriko-app`.
2. **Poussez ce projet** vers le dépôt :
   ```bash
   cd app
   git remote add origin https://github.com/VOTRE_UTILISATEUR/ny-tahiriko-app.git
   git push -u origin main
   ```
   (le dépôt local est déjà initialisé avec un premier commit)
3. Allez dans l'onglet **Actions** de votre dépôt GitHub : le workflow
   "Build Android APK" se lance automatiquement.
4. Une fois terminé (environ 5-10 minutes), ouvrez le run terminé et
   téléchargez l'APK dans la section **Artifacts** :
   - `ny-tahiriko-apk-universal` : un seul APK qui fonctionne sur tous les téléphones
   - `ny-tahiriko-apk-par-architecture` : APK plus légers, séparés par architecture de processeur
5. Si le push est fait sur la branche `main`, une **Release GitHub** est
   aussi créée automatiquement avec l'APK attaché en pièce jointe,
   directement téléchargeable depuis l'onglet **Releases** du dépôt.

Vous pouvez aussi déclencher le workflow manuellement : onglet **Actions** →
"Build Android APK" → bouton **Run workflow**.

## 🛠️ Recompiler le projet en local (alternative)

### Pré-requis
- Flutter SDK (3.24.x recommandé)
- Java JDK **17** (important : la version 21 pose des problèmes avec certains plugins Android)
- Android SDK (command-line tools + platform 34/35 + build-tools)

### Étapes
```bash
cd app
flutter pub get
dart run flutter_launcher_icons   # génère l'icône de l'app à partir du logo
flutter build apk --release
```
L'APK généré se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

Pour lancer en mode développement sur un appareil/émulateur connecté :
```bash
flutter run
```

## 📂 Structure du projet
```
lib/
 ├── main.dart                     # Point d'entrée, navigation par onglets
 ├── models/                       # Membre, Cotisation (avec types), Sortie
 ├── db/database_helper.dart       # Base SQLite (CRUD + calculs de sommes + migrations)
 ├── providers/                    # Gestion d'état (Provider)
 ├── services/notification_service.dart  # Rappels et alertes locales
 ├── screens/                      # Tableau de bord, Membres, Cotisations, Sorties, Rapports, Paramètres
 ├── widgets/                      # Composants réutilisables (carte balance, tuile membre)
 └── utils/                        # Formatage (Ariary, dates), génération PDF (rapport global + bilan mensuel)
assets/icon/app_icon.png           # Logo de l'application
.github/workflows/build_apk.yml    # Workflow CI de compilation automatique
```

## 💰 Devise
Les montants sont affichés en Ariary malgache (Ar).

## 🔒 Stockage des données
Toutes les données sont stockées **localement** sur l'appareil via SQLite.
Aucune connexion internet n'est nécessaire pour utiliser l'application.
Pensez à faire des sauvegardes régulières via l'écran "Paramètres"
(export du fichier de base de données, à conserver en lieu sûr).

## ⚠️ Restriction de balance
Avant toute sortie, l'application vérifie si le solde restant serait négatif.
Si c'est le cas, une alerte s'affiche et le trésorier doit confirmer explicitement
("Forcer quand même") pour enregistrer la dépense malgré tout. Ces sorties
forcées sont marquées visuellement dans l'historique.

## 🏷️ Types de cotisation
Chaque cotisation enregistrée peut être classée par type :
- **Mensuelle** — la cotisation régulière prise en compte pour déterminer si un membre est à jour
- **Adhésion annuelle** — cotisation d'entrée/renouvellement annuel
- **Événement** — cotisation liée à un événement ponctuel (avec un libellé, ex: nom de l'événement)
- **Autre** — tout autre type de contribution

Seules les cotisations de type "Mensuelle" comptent dans le calcul du statut
"à jour / en retard" des membres.

## 🔔 Notifications
- Rappel automatique le **1er du mois** à 8h00 pour lancer la collecte
- Alerte automatique le **15 du mois** à 9h00 sur les membres en retard
- Alerte automatique le **25 du mois** à 9h00 (dernière relance)
- Bouton manuel "Vérifier les membres en retard maintenant" sur le tableau de bord

## 📄 Rapports PDF
- **Rapport global** : historique complet, avec les noms des membres (pas les identifiants), exportable en PDF ou Excel
- **Bilan mensuel** : sélectionnez un mois et générez un PDF récapitulatif
  (cotisations encaissées avec noms, membres à jour, membres en retard,
  sorties du mois, balance globale à jour)

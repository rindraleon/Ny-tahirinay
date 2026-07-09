# Cotisation App — Application de gestion des cotisations pour association

Application Flutter développée pour permettre à un trésorier d'association de :
- Gérer la liste des membres
- Enregistrer les cotisations mensuelles (calcul automatique du total)
- Enregistrer les sorties/dépenses avec un motif obligatoire
- Calculer automatiquement la balance (Total cotisations − Total sorties)
- Bloquer/avertir en cas de fonds insuffisants avant une sortie (restriction demandée)
- Exporter des rapports PDF et Excel

## 📦 APK prêt à installer
Un fichier `cotisation_app.apk` (déjà compilé) est disponible à la racine du workspace.
Il suffit de le transférer sur un téléphone Android et de l'installer
(autoriser "Sources inconnues" dans les paramètres Android si demandé).

## 🛠️ Recompiler le projet soi-même

### Pré-requis
- Flutter SDK (3.24.x recommandé)
- Java JDK **17** (important : la version 21 pose des problèmes avec certains plugins Android)
- Android SDK (command-line tools + platform 34/35 + build-tools)

### Étapes
```bash
cd app
flutter pub get
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
 ├── main.dart                  # Point d'entrée, navigation par onglets
 ├── models/                    # Membre, Cotisation, Sortie
 ├── db/database_helper.dart    # Base SQLite (CRUD + calculs de sommes)
 ├── providers/                 # Gestion d'état (Provider)
 ├── screens/                   # Tableau de bord, Membres, Cotisations, Sorties, Rapports, Paramètres
 ├── widgets/                   # Composants réutilisables (carte balance, tuile membre)
 └── utils/                     # Formatage (Ariary, dates), génération PDF
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

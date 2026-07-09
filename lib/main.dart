import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/membre_provider.dart';
import 'providers/cotisation_provider.dart';
import 'providers/sortie_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/membres_screen.dart';
import 'screens/cotisations_screen.dart';
import 'screens/sorties_screen.dart';
import 'screens/rapports_screen.dart';
import 'screens/parametres_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await NotificationService.instance.initialiser();
  runApp(const CotisationApp());
}

class CotisationApp extends StatelessWidget {
  const CotisationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MembreProvider()),
        ChangeNotifierProvider(create: (_) => CotisationProvider()),
        ChangeNotifierProvider(create: (_) => SortieProvider()),
      ],
      child: MaterialApp(
        title: 'Ny Tahiriko',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _indexActuel = 0;

  final GlobalKey<MembresScreenState> _membresKey = GlobalKey<MembresScreenState>();
  final GlobalKey<CotisationsScreenState> _cotisationsKey = GlobalKey<CotisationsScreenState>();
  final GlobalKey<SortiesScreenState> _sortiesKey = GlobalKey<SortiesScreenState>();

  late final List<Widget> _ecrans;

  final List<String> _titres = [
    'Tableau de bord',
    'Membres',
    'Cotisations',
    'Sorties',
    'Rapports',
  ];

  @override
  void initState() {
    super.initState();
    _ecrans = [
      DashboardScreen(
        onAjouterCotisation: () {
          setState(() => _indexActuel = 2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _cotisationsKey.currentState?.ouvrirFormulaireAjout();
          });
        },
        onAjouterSortie: () {
          setState(() => _indexActuel = 3);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sortiesKey.currentState?.ouvrirFormulaireAjout();
          });
        },
        onAjouterMembre: () {
          setState(() => _indexActuel = 1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _membresKey.currentState?.ouvrirFormulaireAjout();
          });
        },
      ),
      MembresScreen(key: _membresKey),
      CotisationsScreen(key: _cotisationsKey),
      SortiesScreen(key: _sortiesKey),
      const RapportsScreen(),
    ];

    _chargerToutesLesDonnees();
  }

  Future<void> _chargerToutesLesDonnees() async {
    await context.read<MembreProvider>().chargerMembres();
    await context.read<CotisationProvider>().chargerCotisations();
    await context.read<SortieProvider>().chargerSorties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titres[_indexActuel]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParametresScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _indexActuel,
        children: _ecrans,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexActuel,
        onDestinationSelected: (index) {
          setState(() => _indexActuel = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Membres'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Cotisations'),
          NavigationDestination(icon: Icon(Icons.money_off_outlined), selectedIcon: Icon(Icons.money_off), label: 'Sorties'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Rapports'),
        ],
      ),
    );
  }
}

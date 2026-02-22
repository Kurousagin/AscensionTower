import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/title_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/npc_list_screen.dart';
import 'screens/citadel_screen.dart';
import 'screens/tower_screen.dart';
import 'screens/event_log_screen.dart';
import 'screens/codex_screen.dart';
import 'screens/groups_screen.dart';
import 'widgets/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TowerApp());
}

class TowerApp extends StatelessWidget {
  const TowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider()..init(),
      child: MaterialApp(
        title: 'Tower Ascension',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _inGame = false;
  int _currentTab = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TowerScreen(),
    CitadelScreen(),
    NpcListScreen(),
    GroupsScreen(),
    EventLogScreen(),
    CodexScreen(),
  ];

  final List<String> _titles = [
    'OBSERVATORIO',
    'A TORRE',
    'CIDADELA',
    'HABITANTES',
    'ESQUADROES',
    'REGISTROS',
    'CODEX',
  ];

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GameProvider>(context);

    if (gp.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2),
              ),
              SizedBox(height: 16),
              Text('INICIALIZANDO...', style: TextStyle(fontFamily: 'FiraCode', color: AppTheme.cyan, fontSize: 11, letterSpacing: 2)),
            ],
          ),
        ),
      );
    }

    if (!_inGame) {
      return TitleScreen(onStartGame: () => setState(() => _inGame = true));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18),
          onPressed: () {
            gp.stopSimulation();
            setState(() => _inGame = false);
          },
        ),
        title: Row(
          children: [
            Text(_titles[_currentTab]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${gp.timeDisplay} | Andar ${gp.state.highestFloorCleared} | ${gp.population} hab.',
                style: const TextStyle(fontFamily: 'FiraCode', fontSize: 8, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(child: _screens[_currentTab]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye_outlined, size: 18), label: 'Observar'),
            BottomNavigationBarItem(icon: Icon(Icons.cell_tower, size: 18), label: 'Torre'),
            BottomNavigationBarItem(icon: Icon(Icons.castle_outlined, size: 18), label: 'Cidadela'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 18), label: 'Habitantes'),
            BottomNavigationBarItem(icon: Icon(Icons.groups_outlined, size: 18), label: 'Grupos'),
            BottomNavigationBarItem(icon: Icon(Icons.article_outlined, size: 18), label: 'Registros'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined, size: 18), label: 'Codex'),
          ],
        ),
      ),
    );
  }
}

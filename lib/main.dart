import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/title_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/npc_list_screen.dart';
import 'screens/citadel_screen.dart';
import 'screens/tower_screen.dart';
import 'screens/citadel_ledger_screen.dart';
import 'screens/codex_screen.dart';
import 'screens/groups_screen.dart';
import 'widgets/theme.dart';
import 'widgets/event_toast.dart';
import 'screens/prison_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tower_saves');
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
        home: EventToastOverlay(child: const AppShell()),
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
  int _currentScreen = 0;
  int? _expandedGroup; // qual grupo está expandido

  // ── Definição de grupos ──────────────────────
  static const _groups = [
    _NavGroup(
      icon: Icons.remove_red_eye_outlined,
      label: 'Base',
      screens: [_NavItem(0, 'OBSERVATORIO', Icons.remove_red_eye_outlined)],
    ),
    _NavGroup(
      icon: Icons.cell_tower,
      label: 'Torre',
      screens: [
        _NavItem(1, 'A TORRE', Icons.cell_tower),
        _NavItem(4, 'ESQUADROES', Icons.groups_outlined),
      ],
    ),
    _NavGroup(
      icon: Icons.castle_outlined,
      label: 'Cidadela',
      screens: [
        _NavItem(2, 'CIDADELA', Icons.castle_outlined),
        _NavItem(5, 'REGISTROS', Icons.article_outlined),
      ],
    ),
    _NavGroup(
      icon: Icons.people_outline,
      label: 'Povo',
      screens: [
        _NavItem(3, 'HABITANTES', Icons.people_outline),
        _NavItem(6, 'JUSTICA', Icons.gavel),
      ],
    ),
    _NavGroup(
      icon: Icons.menu_book_outlined,
      label: 'Codex',
      screens: [_NavItem(7, 'CODEX', Icons.menu_book_outlined)],
    ),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    TowerScreen(),
    CitadelScreen(),
    NpcListScreen(),
    GroupsScreen(),
    CitadelLedgerScreen(),
    PrisonScreen(),
    CodexScreen(),
  ];

  static const _titles = [
    'OBSERVATORIO',
    'A TORRE',
    'CIDADELA',
    'HABITANTES',
    'ESQUADROES',
    'REGISTROS',
    'JUSTICA',
    'CODEX',
  ];

  // Qual grupo contém a tela atual
  int _groupOf(int screenIndex) {
    for (int i = 0; i < _groups.length; i++) {
      if (_groups[i].screens.any((s) => s.index == screenIndex)) return i;
    }
    return 0;
  }

  void _onGroupTap(int groupIdx) {
    final group = _groups[groupIdx];
    if (group.screens.length == 1) {
      // Grupo sem sub-itens: navega direto
      setState(() {
        _currentScreen = group.screens.first.index;
        _expandedGroup = null;
      });
    } else if (_expandedGroup == groupIdx) {
      // Já expandido: fecha
      setState(() => _expandedGroup = null);
    } else {
      // Expande
      setState(() => _expandedGroup = groupIdx);
    }
  }

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
                child: CircularProgressIndicator(
                  color: AppTheme.cyan,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'INICIALIZANDO...',
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  color: AppTheme.cyan,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
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
            Text(_titles[_currentScreen]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${gp.timeDisplay} | Andar ${gp.state.highestFloorCleared} | ${gp.population} hab.',
                style: const TextStyle(
                  fontFamily: 'FiraCode',
                  fontSize: 8,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        // Toque no body fecha o menu expandido
        onTap: () {
          if (_expandedGroup != null) setState(() => _expandedGroup = null);
        },
        behavior: HitTestBehavior.translucent,
        child: SafeArea(child: _screens[_currentScreen]),
      ),
      bottomNavigationBar: _ExpandableNavBar(
        groups: _groups,
        currentScreen: _currentScreen,
        expandedGroup: _expandedGroup,
        onGroupTap: _onGroupTap,
        onSubItemTap: (screenIdx) {
          setState(() {
            _currentScreen = screenIdx;
            _expandedGroup = null;
          });
        },
        groupOf: _groupOf,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────

class _NavItem {
  final int index;
  final String label;
  final IconData icon;
  const _NavItem(this.index, this.label, this.icon);
}

class _NavGroup {
  final IconData icon;
  final String label;
  final List<_NavItem> screens;
  const _NavGroup({
    required this.icon,
    required this.label,
    required this.screens,
  });
}

// ─────────────────────────────────────────────
// WIDGET DA NAV BAR
// ─────────────────────────────────────────────

class _ExpandableNavBar extends StatelessWidget {
  final List<_NavGroup> groups;
  final int currentScreen;
  final int? expandedGroup;
  final void Function(int) onGroupTap;
  final void Function(int) onSubItemTap;
  final int Function(int) groupOf;

  const _ExpandableNavBar({
    required this.groups,
    required this.currentScreen,
    required this.expandedGroup,
    required this.onGroupTap,
    required this.onSubItemTap,
    required this.groupOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
        color: AppTheme.bgCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sub-menu expansível
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: expandedGroup != null
                ? _buildSubMenu(groups[expandedGroup!])
                : const SizedBox.shrink(),
          ),
          // Barra principal
          SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: List.generate(groups.length, (i) {
                  final group = groups[i];
                  final isActive = groupOf(currentScreen) == i;
                  final isExpanded = expandedGroup == i;
                  final hasSubItems = group.screens.length > 1;

                  return Expanded(
                    child: InkWell(
                      onTap: () => onGroupTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                group.icon,
                                size: 22,
                                color: isActive || isExpanded
                                    ? AppTheme.cyan
                                    : AppTheme.textDim,
                              ),
                              // Indicador de sub-itens
                              if (hasSubItems)
                                Positioned(
                                  top: -3,
                                  right: -6,
                                  child: AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.arrow_drop_up,
                                      size: 12,
                                      color: isActive || isExpanded
                                          ? AppTheme.cyan
                                          : AppTheme.textDim,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            group.label,
                            style: TextStyle(
                              fontFamily: 'FiraCode',
                              fontSize: 9,
                              color: isActive || isExpanded
                                  ? AppTheme.cyan
                                  : AppTheme.textDim,
                            ),
                          ),
                          // Dot indicador de tela ativa
                          if (isActive)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: AppTheme.cyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMenu(_NavGroup group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.cyan.withValues(alpha: 0.3)),
          bottom: BorderSide(color: AppTheme.border),
        ),
        color: AppTheme.bgElevated,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: group.screens.map((item) {
          final isActive = currentScreen == item.index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () => onSubItemTap(item.index),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isActive ? AppTheme.cyan : AppTheme.border,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: isActive ? AppTheme.cyan.withValues(alpha: 0.1) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isActive ? AppTheme.cyan : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: 'FiraCode',
                        fontSize: 9,
                        color: isActive
                            ? AppTheme.cyan
                            : AppTheme.textSecondary,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

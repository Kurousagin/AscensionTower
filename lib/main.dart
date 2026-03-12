import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/services/events/notification_service.dart';
import 'package:tower_ascension/widgets/ambient_appbar.dart';
import 'package:tower_ascension/widgets/ambient_overlay.dart';
import 'package:workmanager/workmanager.dart';
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
import 'screens/arena_screen.dart';
import 'screens/faction_screen.dart';
import 'background/notification_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tower_saves');
  await Hive.openBox('settings');

  // ── Notificações ──────────────────────────────────────────
  await NotificationService.instance.init();

  // Workmanager só existe em Android/iOS
  if (Platform.isAndroid || Platform.isIOS) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    Workmanager().registerPeriodicTask(
      'crisis_check',
      'crisis_check_task',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

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
        home: const EventToastOverlay(child: AppShell()),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP SHELL
// ─────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _inGame = false;
  int _currentScreen = 0;
  int? _expandedGroup;

  Box get _settings => Hive.box('settings');
  bool get _effectsEnabled =>
      _settings.get('effectsEnabled', defaultValue: true) as bool;
  void _toggleEffects() {
    _settings.put('effectsEnabled', !_effectsEnabled);
    setState(() {});
  }

  // ── Grupos da nav bar ────────────────────────────────────────
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
        _NavItem(8, 'FACCOES', Icons.account_balance_outlined),
      ],
    ),
    _NavGroup(
      icon: Icons.castle_outlined,
      label: 'Cidadela',
      screens: [
        _NavItem(2, 'CIDADELA', Icons.castle_outlined),
        _NavItem(9, 'ARENA', Icons.sports_mma_outlined),
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
    DashboardScreen(), // 0
    TowerScreen(), // 1
    CitadelScreen(), // 2
    NpcListScreen(), // 3
    GroupsScreen(), // 4
    CitadelLedgerScreen(), // 5
    PrisonScreen(), // 6
    CodexScreen(), // 7
    FactionScreen(), // 8
    ArenaScreen(), // 9 — substituir por ArenaScreen()
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
    'FACCOES',
    'ARENA',
  ];

  int _groupOf(int screenIndex) {
    for (int i = 0; i < _groups.length; i++) {
      if (_groups[i].screens.any((s) => s.index == screenIndex)) return i;
    }
    return 0;
  }

  void _onGroupTap(int groupIdx) {
    final group = _groups[groupIdx];
    if (group.screens.length == 1) {
      setState(() {
        _currentScreen = group.screens.first.index;
        _expandedGroup = null;
      });
    } else if (_expandedGroup == groupIdx) {
      setState(() => _expandedGroup = null);
    } else {
      setState(() => _expandedGroup = groupIdx);
    }
  }

  // ── Confirm dialog de saída ──────────────────────────────────
  void _confirmExit(BuildContext context, GameProvider gp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'SAIR DO JOGO',
          style: TextStyle(
            fontFamily: 'FiraCode',
            color: AppTheme.textPrimary,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        content: const Text(
          'O progresso foi salvo automaticamente.\nDeseja voltar ao menu principal?',
          style: TextStyle(
            fontFamily: 'FiraCode',
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                fontFamily: 'FiraCode',
                color: AppTheme.textDim,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              gp.stopSimulation();
              setState(() => _inGame = false);
            },
            child: const Text(
              'SAIR',
              style: TextStyle(
                fontFamily: 'FiraCode',
                color: AppTheme.red,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer lateral (hamburguer) ──────────────────────────────
  Widget _buildDrawer(BuildContext context, GameProvider gp) {
    return Drawer(
      backgroundColor: AppTheme.bgCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'TOWER ASCENSION',
                style: const TextStyle(
                  fontFamily: 'FiraCode',
                  color: AppTheme.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Dia ${gp.state.currentDay} · ${gp.population} hab. · Andar ${gp.state.highestFloorCleared}',
                style: const TextStyle(
                  fontFamily: 'FiraCode',
                  color: AppTheme.textDim,
                  fontSize: 12,
                ),
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 8),

            // Configurações (placeholder por enquanto)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: const Text(
                'CONFIGURAÇÕES',
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  color: AppTheme.textDim,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SwitchListTile(
              dense: true,
              activeColor: AppTheme.cyan,
              secondary: Icon(
                _effectsEnabled
                    ? Icons.auto_awesome
                    : Icons.auto_awesome_outlined,
                color: _effectsEnabled ? AppTheme.cyan : AppTheme.textDim,
                size: 18,
              ),
              title: Text(
                'EFEITOS VISUAIS',
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  color: _effectsEnabled
                      ? AppTheme.textPrimary
                      : AppTheme.textDim,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              subtitle: Text(
                _effectsEnabled ? 'Partículas e tint ativos' : 'Desativados',
                style: const TextStyle(
                  fontFamily: 'FiraCode',
                  color: AppTheme.textDim,
                  fontSize: 10,
                ),
              ),
              value: _effectsEnabled,
              onChanged: (_) {
                Navigator.pop(context);
                _toggleEffects();
              },
            ),

            const Spacer(),
            const Divider(color: AppTheme.border, height: 1),

            // Sair
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, color: AppTheme.red, size: 18),
              title: const Text(
                'SAIR PARA O MENU',
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  color: AppTheme.red,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmExit(context, gp);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_inGame) {
      return AmbientOverlay(
        effectsEnabled: _effectsEnabled,
        child: TitleScreen(onStartGame: () => setState(() => _inGame = true)),
      );
    }

    return AmbientOverlay(
      effectsEnabled: _effectsEnabled,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        endDrawer: _buildDrawer(context, gp),
        appBar: AmbientAppBar(
          title: _titles[_currentScreen],
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, size: 20),
                color: AppTheme.textSecondary,
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          ],
        ),
        body: GestureDetector(
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
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: expandedGroup != null
                ? _buildSubMenu(groups[expandedGroup!])
                : const SizedBox.shrink(),
          ),
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
                              fontSize: 11,
                              color: isActive || isExpanded
                                  ? AppTheme.cyan
                                  : AppTheme.textDim,
                            ),
                          ),
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
                        fontSize: 11,
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

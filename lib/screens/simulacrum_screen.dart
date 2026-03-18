// lib/screens/simulacrum_screen.dart
//
// SimulacrumScreen — Mapa holográfico tático.
// Master aloca monstros direto no mapa → NPC responde automaticamente → Resolução.

import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/citadel.dart';
import 'package:tower_ascension/models/floor_faction.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../models/tower.dart';
import '../models/simulacrum_battle.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

// ── Paleta Holográfica ───────────────────────────────────────────────────────
const _holoBase    = Color(0xFF000D0D);
const _holoCyan    = Color(0xFF00FFE5);
const _holoBlue    = Color(0xFF0088FF);
const _holoGreen   = Color(0xFF00FF88);
const _holoRed     = Color(0xFFFF3344);
const _holoGold    = Color(0xFFFFCC00);
const _holoPurple  = Color(0xFFAA44FF);
const _holoGrid    = Color(0xFF003322);
const _arcaneColor = Color(0xFF9966EE);
// ────────────────────────────────────────────────────────────────────────────

class SimulacrumScreen extends StatefulWidget {
  const SimulacrumScreen({super.key});

  @override
  State<SimulacrumScreen> createState() => _SimulacrumScreenState();
}

class _SimulacrumScreenState extends State<SimulacrumScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  late Animation<double> _pulse;
  late Animation<double> _scan;

  SimulacrumBattle? _battle;
  Npc? _selectedNpc;
  TowerFloor? _selectedFloor;
  String? _activeZoneId;
  bool _masterDone = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat();
    _pulse = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scan = Tween(begin: 0.0, end: 1.0).animate(_scanCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        if (!gp.citadel.hasBuilding(BuildingType.simulacrum)) {
          return _buildNoBuilding();
        }
        if (_battle == null) return _buildSetup(context, gp);
        if (_battle!.phase == BattlePhase.completed) return _buildResult(context, gp);
        return _buildBattle(context, gp);
      },
    );
  }

  // ─────────────────────────────────────────────
  // SEM EDIFÍCIO
  // ─────────────────────────────────────────────

  Widget _buildNoBuilding() {
    return ScanlineOverlay(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Icon(Icons.psychology_outlined,
                    size: 56, color: _arcaneColor.withValues(alpha: _pulse.value)),
              ),
              const SizedBox(height: 16),
              const TerminalText('SIMULACRO', fontSize: 20, color: _arcaneColor,
                  fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              const TerminalText(
                'Construa o Simulacro na Cidadela\npara treinar estratégia com seus NPCs.',
                fontSize: 11, color: AppTheme.textSecondary, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const TerminalText(
                'Tier 3 · 30 Madeira · 25 Tijolos · 15 Ferro · 40 Conhecimento',
                fontSize: 9, color: AppTheme.textDim, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SETUP
  // ─────────────────────────────────────────────

  Widget _buildSetup(BuildContext context, GameProvider gp) {
    final floors = gp.strategicClearedFloors;
    final npcs = [...gp.aliveNpcs]
      ..sort((a, b) => b.attributes.intelligence.compareTo(a.attributes.intelligence));

    return ScanlineOverlay(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _holoBase,
              border: Border(bottom: BorderSide(color: _holoCyan.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Icon(Icons.psychology,
                      color: _holoCyan.withValues(alpha: _pulse.value), size: 22),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalText('SIMULACRO', fontSize: 16, color: _holoCyan,
                        fontWeight: FontWeight.bold),
                    TerminalText('Batalha tática simulada nos andares conquistados',
                        fontSize: 9, color: AppTheme.textDim),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CyanDivider(label: 'COMANDANTE'),
                  ...npcs.take(6).map((npc) {
                    final err = gp.canStartSimulacrum(npc.id);
                    final ok = err == null;
                    final sel = _selectedNpc?.id == npc.id;
                    return GestureDetector(
                      onTap: ok ? () => setState(() => _selectedNpc = npc) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sel ? _holoCyan.withValues(alpha: 0.08) : AppTheme.bgCard,
                          border: Border.all(
                            color: sel ? _holoCyan : ok ? AppTheme.border
                                : AppTheme.border.withValues(alpha: 0.3),
                            width: sel ? 1.5 : 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            _rankBadge(npc.rank),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TerminalText(npc.name, fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ok ? AppTheme.textPrimary : AppTheme.textDim),
                                  TerminalText(
                                    'INT ${npc.attributes.intelligence.toStringAsFixed(1)} · '
                                    '${npc.stars}★ · ${npc.profession.label}',
                                    fontSize: 8, color: AppTheme.textDim),
                                ],
                              ),
                            ),
                            if (!ok) TerminalText(err!, fontSize: 8, color: AppTheme.textDim)
                            else if (sel) const Icon(Icons.check_circle, size: 16, color: _holoCyan),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const CyanDivider(label: 'CENÁRIO ESTRATÉGICO'),
                  if (floors.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: TerminalText(
                        'Nenhum andar estratégico conquistado.\nExplore andares do tipo ESTRATÉGICO na Torre.',
                        fontSize: 10, color: AppTheme.textDim, textAlign: TextAlign.center),
                    )
                  else
                    ...floors.map((floor) {
                      final sel = _selectedFloor?.number == floor.number;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFloor = floor),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: sel ? _holoGold.withValues(alpha: 0.07) : AppTheme.bgCard,
                            border: Border.all(
                                color: sel ? _holoGold : AppTheme.border,
                                width: sel ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _holoGold.withValues(alpha: 0.1),
                                  border: Border.all(color: _holoGold.withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: TerminalText('${floor.number}',
                                      fontSize: 14, color: _holoGold,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TerminalText(floor.description, fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                    TerminalText(
                                      'Tier ${floor.tier}${floor.specialCondition.isNotEmpty ? " · ${floor.specialCondition}" : ""}',
                                      fontSize: 8, color: AppTheme.textDim, maxLines: 1),
                                    if (floor.controllingFaction != FloorFaction.none)
                                      TerminalText('Facção: ${floor.controllingFaction.label}',
                                          fontSize: 8, color: _holoPurple),
                                  ],
                                ),
                              ),
                              if (sel) const Icon(Icons.check_circle, size: 16, color: _holoGold),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: TerminalButton(
              label: _selectedNpc == null || _selectedFloor == null
                  ? 'SELECIONE COMANDANTE E CENÁRIO'
                  : 'INICIAR SIMULACRO — ${_selectedFloor!.description}',
              icon: Icons.play_arrow,
              color: _selectedNpc != null && _selectedFloor != null
                  ? _holoCyan : AppTheme.textDim,
              expanded: true,
              onPressed: _selectedNpc != null && _selectedFloor != null
                  ? () => _startBattle(gp) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _startBattle(GameProvider gp) {
    final b = gp.startSimulacrumBattle(_selectedNpc!.id, _selectedFloor!.number);
    if (b != null) setState(() { _battle = b; _masterDone = false; });
  }

  // ─────────────────────────────────────────────
  // BATALHA
  // ─────────────────────────────────────────────

  Widget _buildBattle(BuildContext context, GameProvider gp) {
    final battle = _battle!;
    final npc = gp.aliveNpcs.firstWhereOrNull((n) => n.id == battle.npcId);

    return Scaffold(
      backgroundColor: _holoBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildBattleHeader(battle, npc),
            Expanded(
              flex: 6,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulse, _scan]),
                builder: (_, __) => _buildHoloMap(context, battle),
              ),
            ),
            if (!_masterDone) _buildMonsterPanel(context, battle),
            if (_masterDone) _buildNpcStatusBar(battle, npc),
            _buildActionButton(context, battle, gp),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleHeader(SimulacrumBattle battle, Npc? npc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _holoBase,
        border: Border(bottom: BorderSide(color: _holoCyan.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(battle.floorName, fontSize: 13,
                    color: _holoGold, fontWeight: FontWeight.bold),
                TerminalText(
                  'Tier ${battle.tier} · ${battle.layout.layoutName}',
                  fontSize: 8, color: AppTheme.textDim),
              ],
            ),
          ),
          if (npc != null)
            Row(
              children: [
                _rankBadge(npc.rank),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TerminalText(npc.name, fontSize: 11,
                        color: _holoCyan, fontWeight: FontWeight.bold),
                    TerminalText('INT ${npc.attributes.intelligence.toStringAsFixed(1)} · ${npc.stars}★',
                        fontSize: 8, color: AppTheme.textDim),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHoloMap(BuildContext context, SimulacrumBattle battle) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _holoBase,
        border: Border.all(color: _holoCyan.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: _holoCyan.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return GestureDetector(
              onTapUp: (d) => _handleMapTap(context, d.localPosition, battle, w, h),
              child: CustomPaint(
                size: Size(w, h),
                painter: _HoloMapPainter(
                  zones: battle.zones,
                  monsters: battle.masterMonsters,
                  troops: battle.npcTroops,
                  strategies: battle.npcStrategies,
                  activeZoneId: _activeZoneId,
                  masterDone: _masterDone,
                  pulse: _pulse.value,
                  scan: _scan.value,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleMapTap(BuildContext context, Offset pos,
      SimulacrumBattle battle, double w, double h) {
    BattleZone? nearest;
    double minDist = double.infinity;
    for (final zone in battle.zones) {
      final dist = (pos - Offset(zone.x * w, zone.y * h)).distance;
      if (dist < minDist && dist < 60) { minDist = dist; nearest = zone; }
    }
    if (nearest == null) return;
    final z = nearest;
    setState(() => _activeZoneId = _activeZoneId == z.id ? null : z.id);
    if (_activeZoneId != null && !_masterDone) {
      _showZoneSheet(context, battle, z);
    }
  }

  Widget _buildMonsterPanel(BuildContext context, SimulacrumBattle battle) {
    final available = battle.masterMonsters.where((m) => m.assignedZoneId == null).toList();
    final allocated = battle.masterMonsters.where((m) => m.assignedZoneId != null).toList();

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: _holoBase,
        border: Border(top: BorderSide(color: _holoRed.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.shield, size: 12, color: _holoRed),
                const SizedBox(width: 6),
                const TerminalText('SUAS FORÇAS — toque no mapa para posicionar',
                    fontSize: 9, color: _holoRed, fontWeight: FontWeight.bold),
                const Spacer(),
                TerminalText('${allocated.length}/${battle.masterMonsters.length}',
                    fontSize: 8, color: AppTheme.textDim),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              children: [
                ...available.map((m) => _monsterChip(m, false, () =>
                    _showMonsterZonePicker(context, battle, m))),
                if (allocated.isNotEmpty)
                  Container(margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 1, color: AppTheme.border),
                ...allocated.map((m) => _monsterChip(m, true, () =>
                    setState(() { m.assignedZoneId = null; }))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monsterChip(SimulacrumMonster m, bool allocated, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: allocated ? _holoRed.withValues(alpha: 0.05) : _holoRed.withValues(alpha: 0.15),
          border: Border.all(
              color: allocated ? _holoRed.withValues(alpha: 0.25) : _holoRed.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TerminalText(m.type.icon, fontSize: 18,
                color: allocated ? AppTheme.textDim : _holoRed),
            TerminalText(m.name.split(' ').first, fontSize: 7,
                color: allocated ? AppTheme.textDim : AppTheme.textSecondary),
            if (allocated) TerminalText('✓', fontSize: 6, color: _holoRed.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildNpcStatusBar(SimulacrumBattle battle, Npc? npc) {
    final cnt = battle.npcTroops.where((t) => t.assignedZoneId != null).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _holoBase,
        border: Border(top: BorderSide(color: _holoCyan.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, size: 12, color: _holoCyan),
          const SizedBox(width: 6),
          TerminalText(
            '${npc?.name ?? "Comandante"} respondeu: $cnt/${battle.npcTroops.length} tropas posicionadas',
            fontSize: 9, color: _holoCyan),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, SimulacrumBattle battle, GameProvider gp) {
    final anyAllocated = battle.masterMonsters.any((m) => m.assignedZoneId != null);

    String label;
    Color color;
    VoidCallback? onPress;

    if (!_masterDone) {
      if (!anyAllocated) {
        label = 'POSICIONE SUAS FORÇAS NO MAPA';
        color = AppTheme.textDim;
        onPress = null;
      } else {
        label = 'CONFIRMAR POSICIONAMENTO — NPC RESPONDE';
        color = _holoRed;
        onPress = () => _confirmMasterAllocation(gp, battle);
      }
    } else {
      label = 'INICIAR SIMULAÇÃO';
      color = _holoCyan;
      onPress = () {
        battle.phase = BattlePhase.resolution;
        gp.resolveSimulacrumBattle(battle);
        setState(() {});
      };
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: TerminalButton(
        label: label,
        icon: _masterDone ? Icons.play_arrow : Icons.check,
        color: color, expanded: true, onPressed: onPress,
      ),
    );
  }

  void _confirmMasterAllocation(GameProvider gp, SimulacrumBattle battle) {
    final npc = gp.aliveNpcs.firstWhereOrNull((n) => n.id == battle.npcId);
    if (npc != null) _autoAllocateNpc(battle, npc, gp);
    setState(() { _masterDone = true; _activeZoneId = null; });
  }

  void _autoAllocateNpc(SimulacrumBattle battle, Npc npc, GameProvider gp) {
    final intel = npc.attributes.intelligence;
    final zones = battle.zones;
    final available = gp.getAvailableStrategies(npc.id);

    // Ordena zonas por ameaça
    final threat = <String, double>{};
    for (final z in zones) {
      threat[z.id] = battle.monstersInZone(z.id).fold(0.0, (s, m) => s + m.power);
    }
    final sorted = [...zones]..sort((a, b) => (threat[b.id] ?? 0).compareTo(threat[a.id] ?? 0));

    for (final troop in battle.npcTroops) {
      BattleZone? target;
      switch (troop.type) {
        case TroopType.warrior:
          target = sorted.first;
        case TroopType.archer:
          target = zones.firstWhereOrNull((z) => z.advantage == ZoneAdvantage.elevated)
              ?? sorted.last;
        case TroopType.strategist:
          target = intel >= 6
              ? zones.firstWhereOrNull((z) => battle.monstersInZone(z.id)
                  .any((m) => m.type == MonsterType.monsterCommander))
              : null;
          target ??= zones.firstWhereOrNull((z) => z.advantage == ZoneAdvantage.neutral)
              ?? zones.first;
        case TroopType.healer:
          target = zones.reduce((a, b) =>
              battle.troopsInZone(a.id).length >= battle.troopsInZone(b.id).length ? a : b);
        case TroopType.diplomat:
          target = sorted.last;
      }
      troop.assignedZoneId = target?.id ?? zones.first.id;
    }

    // Estratégias por zona
    for (final zone in zones) {
      if (battle.troopsInZone(zone.id).isEmpty) continue;
      final monsters = battle.monstersInZone(zone.id);
      ZoneStrategy chosen = ZoneStrategy.directAssault;

      if (intel >= 7 && monsters.any((m) => m.type == MonsterType.trap)
          && available.contains(ZoneStrategy.tacticalAnalysis)) {
        chosen = ZoneStrategy.tacticalAnalysis;
      } else if (intel >= 5 && monsters.any((m) => m.type == MonsterType.ambusher)
          && available.contains(ZoneStrategy.infiltration)) {
        chosen = ZoneStrategy.infiltration;
      } else if (intel >= 6 && available.contains(ZoneStrategy.siege)) {
        final adjWithTroops = zone.adjacentZoneIds
            .where((id) => battle.troopsInZone(id).isNotEmpty).length;
        if (adjWithTroops >= 1) chosen = ZoneStrategy.siege;
      } else if (intel >= 5 && npc.attributes.charisma >= 6
          && available.contains(ZoneStrategy.negotiation)
          && monsters.any((m) => m.type != MonsterType.brute)) {
        chosen = ZoneStrategy.negotiation;
      }
      battle.npcStrategies[zone.id] = chosen;
    }
  }

  void _showZoneSheet(BuildContext context, SimulacrumBattle battle, BattleZone zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _holoBase,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: _holoRed.withValues(alpha: 0.4)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final here = battle.monstersInZone(zone.id);
          final avail = battle.masterMonsters.where((m) => m.assignedZoneId == null).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.55, minChildSize: 0.35, maxChildSize: 0.75,
            expand: false,
            builder: (ctx, scroll) => Column(
              children: [
                Center(child: Container(width: 36, height: 3,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(color: _holoRed.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: _zoneHoloColor(zone.advantage),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: _zoneHoloColor(zone.advantage), blurRadius: 6)])),
                        const SizedBox(width: 8),
                        TerminalText(zone.name, fontSize: 15, color: _holoGold,
                            fontWeight: FontWeight.bold),
                        const Spacer(),
                        TerminalText(_zoneAdvLabel(zone.advantage), fontSize: 9,
                            color: _zoneHoloColor(zone.advantage)),
                      ]),
                      const SizedBox(height: 4),
                      TerminalText(zone.flavorText, fontSize: 9, color: AppTheme.textSecondary),
                      if (here.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TerminalText('Aqui: ${here.map((m) => '${m.type.icon} ${m.name}').join(' · ')}',
                            fontSize: 8, color: _holoRed),
                      ],
                    ],
                  ),
                ),
                Container(height: 1, color: _holoRed.withValues(alpha: 0.2)),
                if (avail.isEmpty)
                  const Padding(padding: EdgeInsets.all(20),
                      child: TerminalText('Todos os monstros foram alocados.',
                          fontSize: 10, color: AppTheme.textDim, textAlign: TextAlign.center))
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.all(8),
                      itemCount: avail.length,
                      itemBuilder: (ctx, i) {
                        final m = avail[i];
                        return GestureDetector(
                          onTap: () {
                            setState(() { m.assignedZoneId = zone.id; });
                            setSheet(() {});
                            if (battle.masterMonsters.every((m) => m.assignedZoneId != null)) {
                              Navigator.pop(ctx);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _holoRed.withValues(alpha: 0.08),
                              border: Border.all(color: _holoRed.withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(children: [
                              TerminalText(m.type.icon, fontSize: 20, color: _holoRed),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TerminalText(m.name, fontSize: 11, fontWeight: FontWeight.bold),
                                  TerminalText('${m.type.label} · POD ${m.power.toStringAsFixed(1)}',
                                      fontSize: 8, color: AppTheme.textDim),
                                ],
                              )),
                              const Icon(Icons.add_circle_outline, size: 18, color: _holoRed),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMonsterZonePicker(BuildContext context, SimulacrumBattle battle, SimulacrumMonster monster) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _holoBase,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: _holoRed.withValues(alpha: 0.4)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('${monster.type.icon} ${monster.name}',
                fontSize: 14, color: _holoRed, fontWeight: FontWeight.bold),
            const SizedBox(height: 4),
            const TerminalText('Escolha a zona para posicionar',
                fontSize: 9, color: AppTheme.textDim),
            const SizedBox(height: 12),
            ...battle.zones.map((zone) => GestureDetector(
              onTap: () { setState(() { monster.assignedZoneId = zone.id; }); Navigator.pop(ctx); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: _zoneHoloColor(zone.advantage).withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: _zoneHoloColor(zone.advantage),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  TerminalText(zone.name, fontSize: 11),
                  const Spacer(),
                  TerminalText('${battle.monstersInZone(zone.id).length} aqui',
                      fontSize: 8, color: AppTheme.textDim),
                ]),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTADO
  // ─────────────────────────────────────────────

  Widget _buildResult(BuildContext context, GameProvider gp) {
    final battle = _battle!;
    final npc = gp.aliveNpcs.firstWhereOrNull((n) => n.id == battle.npcId);

    return ScanlineOverlay(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: battle.npcVictory
                      ? _holoCyan.withValues(alpha: 0.06)
                      : _holoRed.withValues(alpha: 0.06),
                  border: Border.all(
                    color: (battle.npcVictory ? _holoCyan : _holoRed)
                        .withValues(alpha: _pulse.value * 0.8),
                    width: 2),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(
                    color: (battle.npcVictory ? _holoCyan : _holoRed)
                        .withValues(alpha: _pulse.value * 0.15),
                    blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(battle.npcVictory ? Icons.emoji_events : Icons.shield_outlined,
                          color: battle.npcVictory ? _holoCyan : _holoRed, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TerminalText(
                            battle.npcVictory ? 'VITÓRIA DO COMANDANTE'
                                : battle.npcZoneWins == battle.masterZoneWins
                                ? 'EMPATE TÁTICO' : 'DERROTA DO COMANDANTE',
                            fontSize: 16,
                            color: battle.npcVictory ? _holoCyan : _holoRed,
                            fontWeight: FontWeight.bold),
                          TerminalText(
                            '${battle.npcZoneWins} vitórias · ${battle.masterZoneWins} derrotas',
                            fontSize: 9, color: AppTheme.textSecondary),
                        ],
                      ),
                    ]),
                    if (npc != null) ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        const Icon(Icons.psychology, size: 16, color: _holoGold),
                        const SizedBox(width: 8),
                        TerminalText('+${battle.intGained.toStringAsFixed(2)} INT → ${npc.name}',
                            fontSize: 14, color: _holoGold, fontWeight: FontWeight.bold),
                      ]),
                      if (battle.bonusDecisions > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TerminalText(
                            '★ ${battle.bonusDecisions} decisão(ões) estratégica(s) acertada(s)',
                            fontSize: 9, color: _holoCyan)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const CyanDivider(label: 'RELATÓRIO DE ZONAS'),
            ...battle.zoneResults.map((result) {
              final zone = battle.zones.firstWhereOrNull((z) => z.id == result.zoneId);
              final color = result.outcome == ZoneOutcome.npcWin ? _holoCyan
                  : result.outcome == ZoneOutcome.masterWin ? _holoRed : AppTheme.textDim;
              final icon = result.outcome == ZoneOutcome.npcWin ? '✓'
                  : result.outcome == ZoneOutcome.masterWin ? '✗' : '~';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      TerminalText(icon, fontSize: 14, color: color),
                      const SizedBox(width: 8),
                      TerminalText(zone?.name ?? result.zoneId,
                          fontSize: 11, fontWeight: FontWeight.bold),
                      const Spacer(),
                      TerminalText(
                        '${result.npcPower.toStringAsFixed(1)} vs ${result.masterPower.toStringAsFixed(1)}',
                        fontSize: 8, color: AppTheme.textDim),
                      if (result.bonusDecision) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star, size: 11, color: _holoGold),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    TerminalText(result.narrative, fontSize: 9, color: AppTheme.textSecondary),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            TerminalButton(
              label: 'NOVA SIMULAÇÃO',
              icon: Icons.refresh, color: _holoCyan, expanded: true,
              onPressed: () => setState(() {
                _battle = null; _masterDone = false;
                _activeZoneId = null; _selectedNpc = null; _selectedFloor = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  Widget _rankBadge(NpcRank rank) {
    final c = _rankColor(rank);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          border: Border.all(color: c.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(2)),
      child: TerminalText(rank.label, fontSize: 8, color: c, fontWeight: FontWeight.bold),
    );
  }

  Color _rankColor(NpcRank rank) => switch (rank) {
    NpcRank.ssr => const Color(0xFFECC94B),
    NpcRank.sr  => const Color(0xFF00B4D8),
    NpcRank.r   => const Color(0xFF48BB78),
    NpcRank.n   => const Color(0xFF718096),
  };

  Color _zoneHoloColor(ZoneAdvantage adv) => switch (adv) {
    ZoneAdvantage.open     => _holoGreen,
    ZoneAdvantage.closed   => const Color(0xFFFF6644),
    ZoneAdvantage.elevated => _holoBlue,
    ZoneAdvantage.neutral  => _holoCyan,
  };

  String _zoneAdvLabel(ZoneAdvantage adv) => switch (adv) {
    ZoneAdvantage.open     => 'Terreno Aberto',
    ZoneAdvantage.closed   => 'Terreno Fechado',
    ZoneAdvantage.elevated => 'Terreno Elevado',
    ZoneAdvantage.neutral  => 'Terreno Neutro',
  };
}

// ─────────────────────────────────────────────
// CUSTOM PAINTER — MAPA HOLOGRÁFICO
// ─────────────────────────────────────────────

class _HoloMapPainter extends CustomPainter {
  final List<BattleZone> zones;
  final List<SimulacrumMonster> monsters;
  final List<SimulacrumTroop> troops;
  final Map<String, ZoneStrategy> strategies;
  final String? activeZoneId;
  final bool masterDone;
  final double pulse;
  final double scan;

  const _HoloMapPainter({
    required this.zones, required this.monsters, required this.troops,
    required this.strategies, this.activeZoneId, required this.masterDone,
    required this.pulse, required this.scan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawScanLine(canvas, size);
    _drawConnections(canvas, size.width, size.height);
    _drawZones(canvas, size.width, size.height);
    _drawCorners(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()..color = _holoGrid..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final y = scan * size.height;
    final p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [_holoCyan.withValues(alpha: 0.0), _holoCyan.withValues(alpha: 0.08),
            _holoCyan.withValues(alpha: 0.0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 30, size.width, 60));
    canvas.drawRect(Rect.fromLTWH(0, y - 30, size.width, 60), p);
  }

  void _drawCorners(Canvas canvas, Size size) {
    final p = Paint()..color = _holoCyan.withValues(alpha: 0.6)
        ..strokeWidth = 2..style = PaintingStyle.stroke;
    const len = 14.0;
    void corner(Offset o, Offset h, Offset v) {
      canvas.drawLine(o, h, p); canvas.drawLine(o, v, p);
    }
    corner(Offset.zero, const Offset(len, 0), const Offset(0, len));
    corner(Offset(size.width, 0), Offset(size.width - len, 0), Offset(size.width, len));
    corner(Offset(0, size.height), Offset(len, size.height), Offset(0, size.height - len));
    corner(size.bottomRight(Offset.zero),
        Offset(size.width - len, size.height), Offset(size.width, size.height - len));
  }

  void _drawConnections(Canvas canvas, double w, double h) {
    final drawn = <String>{};
    for (final zone in zones) {
      for (final adjId in zone.adjacentZoneIds) {
        final key = ([zone.id, adjId]..sort()).join('-');
        if (drawn.contains(key)) continue;
        drawn.add(key);
        final adj = zones.firstWhere((z) => z.id == adjId, orElse: () => zone);
        final p1 = Offset(zone.x * w, zone.y * h);
        final p2 = Offset(adj.x * w, adj.y * h);

        canvas.drawLine(p1, p2, Paint()
            ..color = _holoCyan.withValues(alpha: 0.12 + pulse * 0.06)
            ..strokeWidth = 1.0);

        // Partícula animada
        final t = (scan * 2 + zones.indexOf(zone) * 0.3) % 1.0;
        final pp = Offset(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
        canvas.drawCircle(pp, 2.5, Paint()
            ..color = _holoCyan.withValues(alpha: pulse * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }
  }

  void _drawZones(Canvas canvas, double w, double h) {
    for (final zone in zones) {
      final cx = zone.x * w;
      final cy = zone.y * h;
      final isActive = activeZoneId == zone.id;
      final zc = _zoneColor(zone.advantage);
      final monstersHere = monsters.where((m) => m.assignedZoneId == zone.id).toList();
      final troopsHere = troops.where((t) => t.assignedZoneId == zone.id).toList();
      final hasM = monstersHere.isNotEmpty;
      final hasT = troopsHere.isNotEmpty;

      final outerR = isActive ? 38.0 + pulse * 6 : 30.0 + pulse * 3;

      // Glow de conteúdo
      if (hasM || hasT) {
        canvas.drawCircle(Offset(cx, cy), outerR + 6, Paint()
            ..color = (hasM ? _holoRed : _holoCyan).withValues(alpha: pulse * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      }

      // Anel externo
      canvas.drawCircle(Offset(cx, cy), outerR, Paint()
          ..color = zc.withValues(alpha: (isActive ? 0.1 : 0.05) + pulse * 0.05)
          ..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(cx, cy), outerR, Paint()
          ..color = zc.withValues(alpha: isActive ? 0.8 : 0.3)
          ..strokeWidth = isActive ? 2.0 : 1.0
          ..style = PaintingStyle.stroke);

      // Núcleo
      canvas.drawCircle(Offset(cx, cy), 18.0, Paint()
          ..color = zc.withValues(alpha: 0.2 + pulse * 0.1)
          ..style = PaintingStyle.fill);

      // Ponto central
      canvas.drawCircle(Offset(cx, cy), 4.0, Paint()
          ..color = zc.withValues(alpha: 0.6 + pulse * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

      // Ícones de monstros (esquerda)
      if (hasM) _drawArcIcons(canvas, cx, cy, monstersHere.take(3).toList(),
          _holoRed, true, (m) => (m as SimulacrumMonster).type.icon, outerR);

      // Ícones de tropas (direita) — só após master confirmar
      if (masterDone && hasT) _drawArcIcons(canvas, cx, cy, troopsHere.take(3).toList(),
          _holoCyan, false, (t) => (t as SimulacrumTroop).type.icon, outerR);

      // Ícone de estratégia (topo)
      if (masterDone && strategies.containsKey(zone.id)) {
        _drawText(canvas, strategies[zone.id]!.icon, cx - 5, cy - outerR - 18, 11,
            _holoGold.withValues(alpha: 0.9));
      }

      // Nome da zona
      _drawText(canvas, zone.name, cx, cy + outerR + 5,
          isActive ? 9.5 : 8.5,
          isActive ? _holoGold : zc.withValues(alpha: 0.85),
          centered: true, maxWidth: 90);
    }
  }

  void _drawArcIcons(Canvas canvas, double cx, double cy,
      List<dynamic> items, Color color, bool leftSide,
      String Function(dynamic) iconOf, double r) {
    final startAngle = leftSide ? math.pi * 0.55 : math.pi * 1.55;
    final count = items.length;
    for (int i = 0; i < count; i++) {
      final angle = startAngle + (i - (count - 1) / 2) * (math.pi * 0.45 / math.max(count - 1, 1));
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      canvas.drawCircle(Offset(px, py), 8, Paint()
          ..color = color.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      _drawText(canvas, iconOf(items[i]), px - 4, py - 5, 8, Colors.white);
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      double fontSize, Color color, {bool centered = false, double maxWidth = double.infinity}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(
        fontFamily: 'FiraCode', fontSize: fontSize, color: color,
        shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
      )),
      textDirection: TextDirection.ltr,
      textAlign: centered ? TextAlign.center : TextAlign.left,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, Offset(centered ? x - tp.width / 2 : x, y));
  }

  Color _zoneColor(ZoneAdvantage adv) => switch (adv) {
    ZoneAdvantage.open     => _holoGreen,
    ZoneAdvantage.closed   => const Color(0xFFFF6644),
    ZoneAdvantage.elevated => _holoBlue,
    ZoneAdvantage.neutral  => _holoCyan,
  };

  @override
  bool shouldRepaint(covariant _HoloMapPainter old) =>
      old.pulse != pulse || old.scan != scan ||
      old.activeZoneId != activeZoneId || old.masterDone != masterDone;
}
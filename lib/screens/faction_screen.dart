// lib/screens/faction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/tower.dart';
import '../providers/game_provider.dart';
import '../models/floor_faction.dart';
import '../models/game_event.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import '../widgets/pending_recruits_badge.dart';
// FactionWar is from floor_faction.dart (already imported)

class FactionScreen extends StatefulWidget {
  const FactionScreen({super.key});

  @override
  State<FactionScreen> createState() => _FactionScreenState();
}

class _FactionScreenState extends State<FactionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 4, vsync: this);
  int? _expandedIdx;

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final relations = gp.state.factionRelations.values.toList()
          ..sort((a, b) => b.standing.compareTo(a.standing));
        return ScanlineOverlay(
          child: Column(
            children: [
              _buildHeader(context, gp, relations),
              Container(
                color: AppTheme.bgCard,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppTheme.cyan,
                  indicatorWeight: 1.5,
                  labelColor: AppTheme.cyan,
                  unselectedLabelColor: AppTheme.textDim,
                  labelStyle: const TextStyle(
                    fontFamily: 'FiraCode',
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                  tabs: const [
                    Tab(text: 'RELACOES'),
                    Tab(text: 'DIPLOMACIA'),
                    Tab(text: 'TERRITORIOS'),
                    Tab(text: 'HISTORICO'),
                  ],
                ),
              ),
              Container(height: 1, color: AppTheme.border),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _RelationsTab(
                      relations: relations,
                      expandedIdx: _expandedIdx,
                      onExpand: (i) => setState(
                        () => _expandedIdx = _expandedIdx == i ? null : i,
                      ),
                    ),
                    _DiplomacyTab(relations: relations),
                    const _TerritoryTab(),
                    const _WarHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GameProvider gp,
    List<FactionRelation> relations,
  ) {
    final allies = relations
        .where(
          (r) => r.tier == FactionTier.ally || r.tier == FactionTier.friendly,
        )
        .length;
    final hostile = relations
        .where(
          (r) =>
              r.tier == FactionTier.hostile ||
              r.tier == FactionTier.atWar ||
              r.tier == FactionTier.bloodFeud,
        )
        .length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _hStat('${relations.length}/5', 'ENCONTRADAS', AppTheme.cyan),
          _hStat('$allies', 'ALIADAS', AppTheme.green),
          _hStat('$hostile', 'HOSTIS', AppTheme.red),
          const Spacer(),
          if (gp.pendingRecruits.isNotEmpty)
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => RecruitListSheet(engine: gp.engine),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.green.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add_outlined,
                      size: 11,
                      color: AppTheme.green,
                    ),
                    const SizedBox(width: 4),
                    TerminalText(
                      '${gp.pendingRecruits.length} recruit',
                      fontSize: 8,
                      color: AppTheme.green,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hStat(String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TerminalText(
            value,
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(width: 4),
          TerminalText(label, fontSize: 7, color: AppTheme.textDim),
        ],
      ),
    );
  }
}

class _RelationsTab extends StatelessWidget {
  final List<FactionRelation> relations;
  final int? expandedIdx;
  final void Function(int) onExpand;
  const _RelationsTab({
    required this.relations,
    required this.expandedIdx,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GameProvider>(context);
    final knownNames = gp.state.factionRelations.keys.toSet();
    final unknown = FloorFaction.values
        .where((f) => f != FloorFaction.none && !knownNames.contains(f.name))
        .toList();
    final warFactions = relations
        .where(
          (r) => r.tier == FactionTier.atWar || r.tier == FactionTier.bloodFeud,
        )
        .toList();
    final activeWars = gp.activeWars;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warFactions.isNotEmpty) ...[
            _buildWarAlert(warFactions),
            const SizedBox(height: 10),
          ],
          if (activeWars.isNotEmpty) ...[
            _buildActiveWarsSection(context, gp, activeWars),
            const SizedBox(height: 10),
          ],
          if (relations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: TerminalText(
                  'Nenhuma faccao encontrada.\nContinue explorando a Torre.',
                  fontSize: 9,
                  color: AppTheme.textDim,
                ),
              ),
            )
          else
            ...List.generate(relations.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _FactionRow(
                  relation: relations[i],
                  engine: gp.engine,
                  isExpanded: expandedIdx == i,
                  onTap: () => onExpand(i),
                  onHistoryTap: () => _showHistory(context, gp, relations[i]),
                ),
              );
            }),
          if (unknown.isNotEmpty) ...[
            const SizedBox(height: 10),
            TerminalCard(
              title: 'NAO ENCONTRADAS (${unknown.length})',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: unknown.map(_unknownChip).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveWarsSection(
    BuildContext context,
    GameProvider gp,
    List<FactionWar> wars,
  ) {
    return TerminalCard(
      title: 'GUERRAS ATIVAS (${wars.length})',
      borderColor: AppTheme.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: wars.map((war) {
          final aggressorColor = _factionColor(war.aggressor);
          final defenderColor = _factionColor(war.defender);
          final playerSided = war.playerSidedWith;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _factionIcon(war.aggressor),
                      size: 11,
                      color: aggressorColor,
                    ),
                    const SizedBox(width: 4),
                    TerminalText(
                      war.aggressor.shortLabel,
                      fontSize: 9,
                      color: aggressorColor,
                      fontWeight: FontWeight.bold,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: TerminalText(
                        'vs',
                        fontSize: 8,
                        color: AppTheme.textDim,
                      ),
                    ),
                    Icon(
                      _factionIcon(war.defender),
                      size: 11,
                      color: defenderColor,
                    ),
                    const SizedBox(width: 4),
                    TerminalText(
                      war.defender.shortLabel,
                      fontSize: 9,
                      color: defenderColor,
                      fontWeight: FontWeight.bold,
                    ),
                    const Spacer(),
                  ],
                ),
                if (playerSided != null) ...[
                  const SizedBox(height: 6),
                  _buildAllianceStatusPanel(war, playerSided),
                ],
                if (war.contestedFloors.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  TerminalText(
                    'Andares contestados: ${war.contestedFloors.join(", ")}',
                    fontSize: 7,
                    color: AppTheme.textDim,
                  ),
                ],
                const SizedBox(height: 4),
                _buildWarProgressBar(war, gp.state.currentDay),
                if (playerSided == null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _WarInterventionButton(
                        label: 'Apoiar ${war.aggressor.shortLabel}',
                        color: aggressorColor,
                        onTap: () {
                          final result = gp.sideWithFaction(
                            war.id,
                            war.aggressor,
                          );
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(result)));
                        },
                      ),
                      const SizedBox(width: 6),
                      _WarInterventionButton(
                        label: 'Apoiar ${war.defender.shortLabel}',
                        color: defenderColor,
                        onTap: () {
                          final result = gp.sideWithFaction(
                            war.id,
                            war.defender,
                          );
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(result)));
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWarAlert(List<FactionRelation> warFactions) {
    return TerminalCard(
      title: 'ALERTA DE GUERRA',
      borderColor: AppTheme.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: warFactions
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 12,
                      color: AppTheme.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TerminalText(
                        '${r.faction.label} — ${r.tier.label} (${r.standing.toStringAsFixed(0)}) · ${r.incursionsCaused} incursoes',
                        fontSize: 9,
                        color: AppTheme.red,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _unknownChip(FloorFaction f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(3),
      ),
      child: TerminalText('? ${f.label}', fontSize: 9, color: AppTheme.textDim),
    );
  }

  void _showHistory(
    BuildContext context,
    GameProvider gp,
    FactionRelation relation,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HistorySheet(relation: relation, gp: gp),
    );
  }
}

class _DiplomacyTab extends StatelessWidget {
  final List<FactionRelation> relations;
  const _DiplomacyTab({required this.relations});

  @override
  Widget build(BuildContext context) {
    if (relations.isEmpty) {
      return const Center(
        child: TerminalText(
          'Encontre facções explorando a Torre\npara desbloquear negociações.',
          fontSize: 9,
          color: AppTheme.textDim,
        ),
      );
    }
    final gp = Provider.of<GameProvider>(context, listen: false);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: relations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _DiplomacyCard(relation: relations[i], gp: gp),
    );
  }
}

class _DiplomacyCard extends StatefulWidget {
  final FactionRelation relation;
  final GameProvider gp;
  const _DiplomacyCard({required this.relation, required this.gp});

  @override
  State<_DiplomacyCard> createState() => _DiplomacyCardState();
}

class _DiplomacyCardState extends State<_DiplomacyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final faction = widget.relation.faction;
    final color = _factionColor(faction);
    final isAlly = widget.relation.tier == FactionTier.ally;
    final cooldown = widget.gp.diplomacyCooldownDays(faction);
    final offers = widget.gp.getDiplomacyOffers(faction);
    final hasOffers = !isAlly && cooldown == 0 && offers.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(_factionIcon(faction), size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TerminalText(
                          faction.label,
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 2),
                        TerminalText(
                          isAlly
                              ? '✓ Já aliado — nenhuma negociação necessária'
                              : cooldown > 0
                              ? 'Cooldown: $cooldown dias restantes'
                              : offers.isEmpty
                              ? 'Sem ofertas disponíveis para este tier'
                              : '${offers.length} oferta(s) disponível(is)',
                          fontSize: 8,
                          color: isAlly
                              ? AppTheme.green
                              : cooldown > 0
                              ? AppTheme.textDim
                              : hasOffers
                              ? AppTheme.cyan
                              : AppTheme.textDim,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _tierColor(
                          widget.relation.tier,
                        ).withValues(alpha: 0.45),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: TerminalText(
                      widget.relation.standing.toStringAsFixed(0),
                      fontSize: 10,
                      color: _tierColor(widget.relation.tier),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: color.withValues(alpha: 0.15)),
            if (hasOffers)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: offers
                      .map(
                        (o) => _OfferTile(
                          offer: o,
                          faction: faction,
                          gp: widget.gp,
                          onExecuted: () => setState(() => _expanded = false),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: TerminalText(
                  isAlly
                      ? 'Esta facção já é sua aliada. Mantenha a relação explorando seus andares.'
                      : cooldown > 0
                      ? 'A facção precisa de $cooldown dias antes de aceitar nova proposta.'
                      : 'Nenhuma oferta disponível. Melhore o standing explorando os andares desta facção.',
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final DiplomacyOffer offer;
  final FloorFaction faction;
  final GameProvider gp;
  final VoidCallback onExecuted;
  const _OfferTile({
    required this.offer,
    required this.faction,
    required this.gp,
    required this.onExecuted,
  });

  @override
  Widget build(BuildContext context) {
    final color = _factionColor(faction);
    final canAfford = _canAffordAll();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TerminalText(
                  _typeLabel(offer.type),
                  fontSize: 7,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TerminalText(
                '${(offer.successChance * 100).toStringAsFixed(0)}% chance',
                fontSize: 8,
                color: offer.successChance >= 0.75
                    ? AppTheme.green
                    : offer.successChance >= 0.50
                    ? AppTheme.yellow
                    : AppTheme.orange,
              ),
              const SizedBox(width: 8),
              TerminalText(
                '+${offer.standingGain.toStringAsFixed(0)} standing',
                fontSize: 8,
                color: AppTheme.cyan,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 6),
          TerminalText(
            offer.description,
            fontSize: 8,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: offer.resourceCost.entries.map((e) {
                    final ok = _canAffordRes(e.key, e.value);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _resIcon(e.key),
                          size: 10,
                          color: ok ? AppTheme.textDim : AppTheme.red,
                        ),
                        const SizedBox(width: 3),
                        TerminalText(
                          '${e.value.toStringAsFixed(0)} ${_resLabel(e.key)}',
                          fontSize: 8,
                          color: ok ? AppTheme.textDim : AppTheme.red,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              GestureDetector(
                onTap: canAfford ? () => _execute(context) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: canAfford ? color.withValues(alpha: 0.12) : null,
                    border: Border.all(
                      color: canAfford
                          ? color.withValues(alpha: 0.6)
                          : AppTheme.border,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: TerminalText(
                    'NEGOCIAR',
                    fontSize: 8,
                    color: canAfford ? color : AppTheme.textDim,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canAffordRes(String key, double amt) {
    final r = gp.citadel.resources;
    return switch (key) {
      'food' => r.food >= amt,
      'knowledge' => r.knowledge >= amt,
      'woodLog' => r.woodLog >= amt,
      'stoneRaw' => r.stoneRaw >= amt,
      'ironOre' => r.ironOre >= amt,
      'lumber' => r.lumber >= amt,
      'stoneBrick' => r.stoneBrick >= amt,
      'ironBar' => r.ironBar >= amt,
      _ => false,
    };
  }

  bool _canAffordAll() =>
      offer.resourceCost.entries.every((e) => _canAffordRes(e.key, e.value));

  void _execute(BuildContext context) {
    final result = gp.executeDiplomacy(faction, offer.type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result,
          style: const TextStyle(
            fontFamily: 'FiraCode',
            fontSize: 10,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.bgElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.border),
        ),
      ),
    );
    onExecuted();
  }

  String _typeLabel(DiplomacyOfferType t) => switch (t) {
    DiplomacyOfferType.payTribute => 'TRIBUTO',
    DiplomacyOfferType.sendGoodwillMission => 'MISSAO',
    DiplomacyOfferType.donateKnowledge => 'CONHECIMENTO',
    DiplomacyOfferType.proposeNonAggression => 'NAO-AGRESSAO',
    DiplomacyOfferType.challengeToTrial => 'JULGAMENTO',
  };

  IconData _resIcon(String r) => switch (r) {
    'food' => Icons.restaurant,
    'knowledge' => Icons.auto_stories,
    'woodLog' => Icons.forest,
    'stoneRaw' => Icons.terrain,
    'ironOre' => Icons.hardware,
    'lumber' => Icons.carpenter,
    'stoneBrick' => Icons.view_module,
    'ironBar' => Icons.settings,
    _ => Icons.circle_outlined,
  };

  String _resLabel(String r) => switch (r) {
    'food' => 'comida',
    'knowledge' => 'conhecimento',
    'woodLog' => 'troncos',
    'stoneRaw' => 'pedra bruta',
    'ironOre' => 'minério',
    'lumber' => 'madeira',
    'stoneBrick' => 'tijolos',
    'ironBar' => 'ferro',
    _ => r,
  };
}

class _TerritoryTab extends StatelessWidget {
  const _TerritoryTab();

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GameProvider>(context);
    final floorMap = {for (final f in gp.floors) f.number: f};
    final countByFaction = <FloorFaction, int>{};
    for (final f in gp.floors) {
      if (f.controllingFaction != FloorFaction.none) {
        countByFaction[f.controllingFaction] =
            (countByFaction[f.controllingFaction] ?? 0) + 1;
      }
    }
    // Andares contestados pelas guerras ativas
    final contestedFloors = <int>{};
    for (final war in gp.activeWars) {
      contestedFloors.addAll(war.contestedFloors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalCard(
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 11,
                  color: AppTheme.textDim,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: TerminalText(
                    'Grade 10×10 — cada célula = 1 andar (1–100). Cor = facção controladora. Brilho = standing.',
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (contestedFloors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.orange.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.orange.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 11,
                    color: AppTheme.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TerminalText(
                      'Andares contestados (−40% recursos, +30% mortalidade): ${(contestedFloors.toList()..sort()).join(", ")}',
                      fontSize: 8,
                      color: AppTheme.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          TerminalCard(
            child: _buildGrid(context, gp, floorMap, contestedFloors),
          ),
          const SizedBox(height: 10),
          TerminalCard(
            title: 'LEGENDA',
            child: _buildLegend(gp, countByFaction),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    GameProvider gp,
    Map<int, dynamic> floorMap,
    Set<int> contestedFloors,
  ) {
    final nextFloorNum = gp.state.highestFloorCleared + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 100,
      itemBuilder: (context, idx) {
        final floorNum = idx + 1;
        final floor = floorMap[floorNum];
        final faction = floor?.controllingFaction ?? FloorFaction.none;
        final isCleared = floor?.cleared == true;
        final isNext = floorNum == nextFloorNum;
        final isBoss = floorNum % 10 == 0;
        final isContested = contestedFloors.contains(floorNum);
        final color = _factionColor(faction);
        final rel = gp.state.factionRelations[faction.key];

        final standing = rel?.standing ?? 0.0;
        final fillOpacity = faction == FloorFaction.none
            ? 0.0
            : (0.15 + (standing + 100) / 200 * 0.45).clamp(0.10, 0.60);
        final cellColor = isContested
            ? AppTheme.orange.withValues(alpha: 0.25)
            : isCleared
            ? color.withValues(alpha: fillOpacity)
            : AppTheme.bgElevated.withValues(alpha: 0.85);
        final borderColor = isContested
            ? AppTheme.orange.withValues(alpha: 0.8)
            : isNext
            ? AppTheme.cyan.withValues(alpha: 0.9)
            : isBoss && isCleared
            ? AppTheme.yellow.withValues(alpha: 0.55)
            : isCleared
            ? color.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.05);
        return GestureDetector(
          onTap: (isCleared || isNext) && floor != null
              ? () => _showFloorPopup(context, gp, floor as TowerFloor, rel)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: cellColor,
              border: Border.all(
                color: borderColor,
                width: isNext || isContested ? 1.5 : 0.5,
              ),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Center(
              child: Text(
                isBoss ? '★' : '$floorNum',
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  fontSize: isBoss ? 7 : 5.5,
                  fontWeight: isBoss ? FontWeight.bold : FontWeight.normal,
                  color: isNext
                      ? AppTheme.cyan
                      : isContested
                      ? AppTheme.orange
                      : isCleared
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFloorPopup(
    BuildContext context,
    GameProvider gp,
    TowerFloor floor,
    FactionRelation? rel,
  ) {
    final faction = floor.controllingFaction;
    final color = _factionColor(faction);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        title: TerminalText(
          'Andar ${floor.number} — ${floor.type.label}',
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(
              floor.description,
              fontSize: 8,
              color: AppTheme.textSecondary,
            ),
            if (faction != FloorFaction.none) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(_factionIcon(faction), size: 12, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TerminalText(
                      '${faction.label}${rel != null ? ' · Standing: ${rel.standing.toStringAsFixed(0)}' : ''}',
                      fontSize: 9,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.loop, size: 10, color: AppTheme.textDim),
                const SizedBox(width: 4),
                TerminalText(
                  'Re-explorado ${floor.timesReexplored}x',
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.emoji_events,
                  size: 10,
                  color: AppTheme.textDim,
                ),
                const SizedBox(width: 4),
                TerminalText(
                  'Conquistado ${floor.timesCleared}x',
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TerminalText(
              'FECHAR',
              fontSize: 9,
              color: AppTheme.cyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(GameProvider gp, Map<FloorFaction, int> countByFaction) {
    final factions = [
      FloorFaction.ironPact,
      FloorFaction.silentOrder,
      FloorFaction.bloodMarket,
      FloorFaction.voidChildren,
      FloorFaction.towerServants,
      FloorFaction.none,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _legendSwatch(
              child: Center(
                child: Text(
                  'N',
                  style: const TextStyle(
                    fontSize: 6,
                    color: AppTheme.cyan,
                    fontFamily: 'FiraCode',
                  ),
                ),
              ),
              borderColor: AppTheme.cyan,
              fill: Colors.transparent,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: TerminalText(
                'Próximo andar a conquistar',
                fontSize: 8,
                color: AppTheme.cyan,
              ),
            ),
            _legendSwatch(
              child: const Center(
                child: Text(
                  '★',
                  style: TextStyle(
                    fontSize: 7,
                    color: AppTheme.yellow,
                    fontFamily: 'FiraCode',
                  ),
                ),
              ),
              borderColor: AppTheme.yellow.withValues(alpha: 0.55),
              fill: Colors.transparent,
            ),
            const SizedBox(width: 8),
            const TerminalText(
              'Boss (×10)',
              fontSize: 8,
              color: AppTheme.yellow,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppTheme.border, height: 1),
        ),
        ...factions.map((faction) {
          final color = _factionColor(faction);
          final count = countByFaction[faction] ?? 0;
          final rel = gp.state.factionRelations[faction.key];

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                _legendSwatch(
                  child: null,
                  borderColor: color.withValues(alpha: 0.4),
                  fill: faction == FloorFaction.none
                      ? AppTheme.bgElevated
                      : color.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TerminalText(
                    faction.label,
                    fontSize: 8,
                    color: faction == FloorFaction.none
                        ? AppTheme.textDim
                        : AppTheme.textSecondary,
                  ),
                ),
                if (count > 0)
                  TerminalText(
                    '$count andares',
                    fontSize: 7,
                    color: AppTheme.textDim,
                  ),
                if (rel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: TerminalText(
                      rel.standing.toStringAsFixed(0),
                      fontSize: 7,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _legendSwatch({
    required Widget? child,
    required Color borderColor,
    required Color fill,
  }) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(1),
      ),
      child: child,
    );
  }
}

class _HistorySheet extends StatelessWidget {
  final FactionRelation relation;
  final GameProvider gp;
  const _HistorySheet({required this.relation, required this.gp});

  @override
  Widget build(BuildContext context) {
    final faction = relation.faction;
    final color = _factionColor(faction);
    final events = gp.eventsForFaction(faction);
    final controlledCount = gp.engine.clearedFloors
        .where((f) => f.controllingFaction == faction)
        .length;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: color.withValues(alpha: 0.4)),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Icon(_factionIcon(faction), size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TerminalText(
                            faction.label.toUpperCase(),
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                          TerminalText(
                            '${relation.tier.label} · Standing: ${relation.standing.toStringAsFixed(0)} · $controlledCount andares',
                            fontSize: 8,
                            color: AppTheme.textDim,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: ((relation.standing + 100) / 200)
                                  .clamp(0.0, 1.0),
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _tierColor(
                                relation.tier,
                              ).withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: TerminalText(
                            relation.tier.label.toUpperCase(),
                            fontSize: 7,
                            color: _tierColor(relation.tier),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    _qStat(
                      'Interacoes',
                      '${relation.totalInteractions}',
                      color,
                    ),
                    _qStat(
                      'Incursoes',
                      '${relation.incursionsCaused}',
                      relation.incursionsCaused > 0
                          ? AppTheme.red
                          : AppTheme.textDim,
                    ),
                    _qStat(
                      'Ult. contato',
                      relation.lastInteractionDay > 0
                          ? 'Dia ${relation.lastInteractionDay}'
                          : '—',
                      AppTheme.textDim,
                    ),
                    _qStat(
                      'No historico',
                      '${events.length}',
                      AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppTheme.border),
              Expanded(
                child: events.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: TerminalText(
                            'Nenhuma interação registrada ainda.\nAs interações aparecem após expedições\naos andares desta facção.',
                            fontSize: 9,
                            color: AppTheme.textDim,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        itemCount: events.length,
                        itemBuilder: (_, i) => _TimelineItem(event: events[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _qStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          TerminalText(
            value,
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(label, fontSize: 7, color: AppTheme.textDim),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final GameEvent event;
  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final typeColor = _eventColor(event.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 3, right: 10),
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: typeColor.withValues(alpha: 0.4),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TerminalText(
                        event.type.tag,
                        fontSize: 6,
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TerminalText(
                      'Dia ${event.day}',
                      fontSize: 7,
                      color: AppTheme.textDim,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                TerminalText(
                  event.title,
                  fontSize: 9,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                if (event.description.isNotEmpty)
                  TerminalText(
                    event.description.split('\n').first,
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(GameEventType t) => switch (t) {
    GameEventType.politicalEvent => const Color(0xFFDDAA66),
    GameEventType.crisis => AppTheme.orange,
    GameEventType.discovery => AppTheme.cyan,
    GameEventType.recruitment => AppTheme.green,
    GameEventType.combat => const Color(0xFFFF6B6B),
    GameEventType.exploration => const Color(0xFF44FFDD),
    _ => AppTheme.textDim,
  };
}

class _FactionRow extends StatelessWidget {
  final FactionRelation relation;
  final dynamic engine;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onHistoryTap;
  const _FactionRow({
    required this.relation,
    required this.engine,
    required this.isExpanded,
    required this.onTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final faction = relation.faction;
    final color = _factionColor(faction);
    final normalized = ((relation.standing + 100) / 200).clamp(0.0, 1.0);
    final controlledCleared = (engine.clearedFloors as List)
        .where((f) => f.controllingFaction == faction)
        .length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isExpanded ? 0.06 : 0.03),
          border: Border.all(
            color: color.withValues(alpha: isExpanded ? 0.50 : 0.20),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_factionIcon(faction), size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: TerminalText(
                    faction.label,
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _tierColor(relation.tier).withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TerminalText(
                    relation.tier.label.toUpperCase(),
                    fontSize: 7,
                    color: _tierColor(relation.tier),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TerminalText(
                      relation.standing.toStringAsFixed(0),
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(
                      width: 55,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.bgElevated,
                          borderRadius: BorderRadius.circular(1),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: normalized,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: AppTheme.textDim,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Container(height: 1, color: color.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              TerminalText(
                faction.description,
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statCell(
                    'Interacoes',
                    '${relation.totalInteractions}',
                    color,
                  ),
                  _statCell('Andares', '$controlledCleared', color),
                  _statCell(
                    'Incursoes',
                    '${relation.incursionsCaused}',
                    relation.incursionsCaused > 0 ? AppTheme.red : color,
                  ),
                  _statCell(
                    'Ult. dia',
                    relation.lastInteractionDay > 0
                        ? '${relation.lastInteractionDay}'
                        : '—',
                    color,
                  ),
                ],
              ),
              if (relation.hasTreaty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.green.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: AppTheme.green.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.handshake,
                        size: 11,
                        color: AppTheme.green,
                      ),
                      const SizedBox(width: 5),
                      // Precisa de currentDay — passar via engine ou Consumer interno
                      TerminalText(
                        'TRATADO ATIVO',
                        fontSize: 8,
                        color: AppTheme.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ],
              if (faction.primaryAttribute.isNotEmpty) ...[
                const SizedBox(height: 8),
                TerminalText(
                  'Respeita: ${_attrLabel(faction.primaryAttribute)}',
                  fontSize: 8,
                  color: color,
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onHistoryTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 11, color: color),
                        const SizedBox(width: 5),
                        TerminalText(
                          'VER HISTORICO',
                          fontSize: 8,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          TerminalText(
            value,
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(label, fontSize: 7, color: AppTheme.textDim),
        ],
      ),
    );
  }

  String _attrLabel(String attr) => switch (attr) {
    'combatPower' => 'Poder de Combate',
    'intelligence' => 'Inteligencia',
    'resources' => 'Recursos',
    'luck' => 'Sorte',
    'fame' => 'Fama',
    _ => attr,
  };
}

class _WarHistoryTab extends StatelessWidget {
  const _WarHistoryTab();

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GameProvider>(context);
    final history = gp.engine.warService.warHistory;

    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: TerminalText(
            'Nenhuma guerra resolvida ainda.\nAs guerras aparecem quando duas facções\ndisputam territórios na Torre.',
            fontSize: 9,
            color: AppTheme.textDim,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final war = history[history.length - 1 - i]; // mais recente primeiro
        final winner = war.winner;
        final loser = winner == null
            ? null
            : (winner == war.aggressor ? war.defender : war.aggressor);
        final winnerColor = winner != null
            ? _factionColor(winner)
            : AppTheme.textDim;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(4),
            color: AppTheme.bgElevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 12, color: winnerColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TerminalText(
                      winner != null
                          ? '${winner.label} venceu'
                          : 'Guerra sem resultado',
                      fontSize: 10,
                      color: winnerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TerminalText(
                    'Dia ${war.startDay}–${war.startDay + war.duration}',
                    fontSize: 7,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TerminalText(
                '${war.aggressor.label}  vs  ${war.defender.label}',
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
              if (loser != null)
                TerminalText(
                  'Derrotado: ${loser.label}',
                  fontSize: 8,
                  color: AppTheme.red,
                ),
              if (war.contestedFloors.isNotEmpty)
                TerminalText(
                  'Andares disputados: ${war.contestedFloors.join(", ")}',
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
              if (war.playerSidedWith != null)
                TerminalText(
                  'Você apoiou: ${war.playerSidedWith!.label}',
                  fontSize: 8,
                  color: AppTheme.cyan,
                ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildAllianceStatusPanel(FactionWar war, FloorFaction playerSided) {
  final alliedStrength = playerSided == war.aggressor
      ? war.aggressorStrength
      : war.defenderStrength;
  final enemyStrength = playerSided == war.aggressor
      ? war.defenderStrength
      : war.aggressorStrength;

  final statusMessage = () {
    if (alliedStrength >= enemyStrength * 1.3) {
      return '"Vocês estão dominando."';
    } else if (alliedStrength >= enemyStrength) {
      return '"A situação está equilibrada."';
    } else if (alliedStrength >= enemyStrength * 0.7) {
      return '"O inimigo está avançando."';
    } else {
      return '"A situação é crítica. Reforce o apoio."';
    }
  }();

  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield, size: 10, color: AppTheme.cyan),
            const SizedBox(width: 4),
            TerminalText(
              'SUA ALIANÇA — ${playerSided.shortLabel}',
              fontSize: 8,
              color: AppTheme.cyan,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText(
                    'Força aliada:',
                    fontSize: 7,
                    color: AppTheme.textDim,
                  ),
                  const SizedBox(height: 2),
                  _buildStrengthBar(alliedStrength, AppTheme.green),
                  const SizedBox(height: 2),
                  TerminalText(
                    alliedStrength.toStringAsFixed(0),
                    fontSize: 7,
                    color: AppTheme.green,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText(
                    'Força inimiga:',
                    fontSize: 7,
                    color: AppTheme.textDim,
                  ),
                  const SizedBox(height: 2),
                  _buildStrengthBar(enemyStrength, AppTheme.red),
                  const SizedBox(height: 2),
                  TerminalText(
                    enemyStrength.toStringAsFixed(0),
                    fontSize: 7,
                    color: AppTheme.red,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TerminalText(statusMessage, fontSize: 7, color: AppTheme.yellow),
      ],
    ),
  );
}

Widget _buildStrengthBar(double strength, Color color) {
  final clamped = (strength / 100).clamp(0.0, 1.0);
  return SizedBox(
    height: 4,
    child: LinearProgressIndicator(
      value: clamped,
      backgroundColor: AppTheme.bgCard,
      valueColor: AlwaysStoppedAnimation<Color>(color),
      minHeight: 4,
    ),
  );
}

Widget _buildWarProgressBar(FactionWar war, int currentDay) {
  final daysElapsed = currentDay - war.startDay;
  final fraction = (daysElapsed / war.duration).clamp(0.0, 1.0);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TerminalText(
        'Duração: $daysElapsed / ${war.duration} dias',
        fontSize: 7,
        color: AppTheme.textDim,
      ),
      const SizedBox(height: 2),
      SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: fraction,
          backgroundColor: AppTheme.bgCard,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.orange),
          minHeight: 3,
        ),
      ),
    ],
  );
}

// UI helpers — delegam para as extensões em floor_faction.dart
Color _factionColor(FloorFaction faction) => faction.color;
IconData _factionIcon(FloorFaction faction) => faction.icon;
Color _tierColor(FactionTier tier) => tier.color;

class _WarInterventionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _WarInterventionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: TerminalText(label, fontSize: 8, color: color),
      ),
    );
  }
}

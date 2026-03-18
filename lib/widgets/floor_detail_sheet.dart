// lib/widgets/floor_detail_sheet.dart
//
// Widget: FloorDetailSheet
// Exibido como bottom sheet ao tocar em um andar conquistado.
// Mostra: info do andar, facção controladora, habitantes ativos e survivors.
//
// USO:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => FloorDetailSheet(floor: floor, engine: engine),
//   );
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/group_model.dart';
import 'package:tower_ascension/models/npc.dart';
import 'package:tower_ascension/providers/game_provider.dart';
import 'package:flutter/material.dart';
import 'package:tower_ascension/models/citadel.dart';
import 'package:tower_ascension/models/tower.dart';
import 'package:tower_ascension/models/floor_faction.dart';
import 'package:tower_ascension/models/floor_inhabitant.dart';
import 'package:tower_ascension/services/game_engine.dart';
import 'package:tower_ascension/widgets/theme.dart';
import 'package:tower_ascension/widgets/terminal_widgets.dart'
    show TerminalButton, TerminalText;

class FloorDetailSheet extends StatelessWidget {
  final TowerFloor floor;
  final GameEngine engine;

  const FloorDetailSheet({
    super.key,
    required this.floor,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F14),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: _factionColor(floor.controllingFaction).withOpacity(0.5),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            children: [
              _Handle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    _FloorHeader(floor: floor),
                    const SizedBox(height: 16),
                    if (floor.controllingFaction != FloorFaction.none)
                      _FactionBadge(
                        faction: floor.controllingFaction,
                        relation: engine
                            .state
                            .factionRelations[floor.controllingFaction.key],
                      ),
                    const SizedBox(height: 20),
                    // ── Banner de guerra ──
                    if (engine.warService.isFloorContested(floor.number)) ...[
                      const SizedBox(height: 8),
                      _WarPenaltyBanner(
                        floorNumber: floor.number,
                        engine: engine,
                      ),
                    ],
                    _SectionLabel(
                      label: 'HABITANTES',
                      count: floor.inhabitants.where((i) => i.isActive).length,
                    ),
                    const SizedBox(height: 8),
                    if (floor.inhabitants.isEmpty ||
                        floor.inhabitants.every((i) => !i.isActive))
                      _EmptyInhabitants()
                    else
                      ...floor.inhabitants
                          .where((i) => i.isActive)
                          .map(
                            (i) =>
                                _InhabitantCard(inhabitant: i, engine: engine),
                          ),
                    const SizedBox(height: 20),
                    _QuestSection(floorNumber: floor.number, engine: engine),
                    const SizedBox(height: 16),
                    _TradeSection(floorNumber: floor.number, engine: engine),
                    // Tags temporárias (anomalias ativas)
                    if (floor.temporaryTags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _AnomalyTagsRow(tags: floor.temporaryTags),
                    ],
                    const SizedBox(height: 20),
                    _FloorStats(floor: floor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Handle ────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Floor Header ──────────────────────────────────────────────────────────

class _FloorHeader extends StatelessWidget {
  final TowerFloor floor;
  const _FloorHeader({required this.floor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Center(
            child: Text(floor.type.icon, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'ANDAR ${floor.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TierChip(tier: floor.tier),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                floor.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (floor.specialCondition.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: Color(0xFFFFB74D),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        floor.specialCondition,
                        style: const TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TierChip extends StatelessWidget {
  final int tier;
  const _TierChip({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        'T$tier',
        style: const TextStyle(
          color: Color(0xFF64B5F6),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Faction Badge ─────────────────────────────────────────────────────────

class _FactionBadge extends StatelessWidget {
  final FloorFaction faction;
  final FactionRelation? relation;
  const _FactionBadge({required this.faction, this.relation});

  @override
  Widget build(BuildContext context) {
    final color = _factionColor(faction);
    final tier = relation?.tier;
    final standing = relation?.standing ?? faction.initialStanding;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(_factionIcon(faction), size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faction.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  faction.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (tier != null) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StandingBar(standing: standing, color: color),
                const SizedBox(height: 3),
                Text(
                  tier.label,
                  style: TextStyle(
                    color: _tierColor(tier),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StandingBar extends StatelessWidget {
  final double standing; // -100 a 100
  final Color color;
  const _StandingBar({required this.standing, required this.color});

  @override
  Widget build(BuildContext context) {
    final normalized = ((standing + 100) / 200).clamp(0.0, 1.0);
    return SizedBox(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            standing.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.white12, height: 1)),
      ],
    );
  }
}

// ── Empty Inhabitants ─────────────────────────────────────────────────────

class _EmptyInhabitants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Nenhum habitante ativo neste andar.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Inhabitant Card ───────────────────────────────────────────────────────

class _InhabitantCard extends StatelessWidget {
  final FloorInhabitant inhabitant;
  final GameEngine engine;
  const _InhabitantCard({required this.inhabitant, required this.engine});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(inhabitant.category);
    final isRecruitable = inhabitant.isRecruitable;
    final isPendingRecruit = engine.pendingRecruits.any(
      (r) => r.id == inhabitant.id,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPendingRecruit
              ? const Color(0xFF66DD88).withOpacity(0.5)
              : color.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryIcon(category: inhabitant.category),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          inhabitant.name,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _DispositionChip(disposition: inhabitant.disposition),
                      ],
                    ),
                    Text(
                      _categoryLabel(inhabitant.category),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (inhabitant.factionAffiliation != FloorFaction.none)
                _FactionMiniTag(affiliation: inhabitant.factionAffiliation),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inhabitant.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          if (inhabitant.effect.loreText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                inhabitant.effect.loreText,
                style: const TextStyle(
                  color: Color(0xFFAA88FF),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (inhabitant.survivorStats != null) ...[
            const SizedBox(height: 10),
            _SurvivorStatsRow(stats: inhabitant.survivorStats!),
          ],
          if (isPendingRecruit) ...[
            const SizedBox(height: 10),
            _RecruitPendingBadge(),
          ] else if (isRecruitable) ...[
            const SizedBox(height: 10),
            _RecruitHint(
              hasRefuge: engine.citadel.hasBuilding(
                BuildingType.wayfareresRefuge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final InhabitantCategory category;
  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    final icon = switch (category) {
      InhabitantCategory.resident => Icons.home_outlined,
      InhabitantCategory.survivor => Icons.person_search_outlined,
      InhabitantCategory.anomaly => Icons.auto_awesome,
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _DispositionChip extends StatelessWidget {
  final InhabitantDisposition disposition;
  const _DispositionChip({required this.disposition});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (disposition) {
      InhabitantDisposition.friendly => ('Amigável', const Color(0xFF66DD88)),
      InhabitantDisposition.neutral => ('Neutro', const Color(0xFFAAAAAA)),
      InhabitantDisposition.hostile => ('Hostil', const Color(0xFFFF4444)),
      InhabitantDisposition.unknown => ('???', const Color(0xFFAA88FF)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FactionMiniTag extends StatelessWidget {
  final FloorFaction affiliation;
  const _FactionMiniTag({required this.affiliation});

  @override
  Widget build(BuildContext context) {
    final faction = affiliation;
    if (faction == FloorFaction.none) return const SizedBox.shrink();
    final color = _factionColor(faction);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        faction.shortLabel,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SurvivorStatsRow extends StatelessWidget {
  final SurvivorStats stats;
  const _SurvivorStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _StatPill(label: 'POW', value: stats.combatPower),
        _StatPill(label: 'INT', value: stats.intelligence),
        _StatPill(label: 'RES', value: stats.endurance),
        _StatPill(
          label: 'LEAL',
          value: stats.loyalty,
          color: const Color(0xFF66DD88),
        ),
        ...stats.traits.map((t) => _TraitPill(trait: t)),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    this.color = const Color(0xFF64B5F6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TraitPill extends StatelessWidget {
  final String trait;
  const _TraitPill({required this.trait});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        _traitLabel(trait),
        style: const TextStyle(color: Colors.white54, fontSize: 9.5),
      ),
    );
  }

  String _traitLabel(String trait) {
    return switch (trait) {
      'battle-hardened' => '⚔ Endurecido',
      'traumatized' => '💔 Traumatizado',
      'tower-knowledge' => '🗼 Conhece a Torre',
      'resourceful' => '🔧 Engenhoso',
      'cautious' => '👁 Cauteloso',
      'silent' => '🤫 Silencioso',
      'loyal' => '🛡 Leal',
      _ => trait,
    };
  }
}

class _RecruitPendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF66DD88).withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF66DD88).withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top, size: 13, color: Color(0xFF66DD88)),
          SizedBox(width: 6),
          Text(
            'Aguardando recrutamento no Abrigo',
            style: TextStyle(
              color: Color(0xFF66DD88),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecruitHint extends StatelessWidget {
  final bool hasRefuge;
  const _RecruitHint({required this.hasRefuge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_add_outlined, size: 13, color: Colors.amber),
          const SizedBox(width: 6),
          Text(
            hasRefuge
                ? 'Re-explore o andar para recrutá-lo'
                : 'Construa o Abrigo de Viajantes para recrutar',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quest Section ─────────────────────────────────────────────────────────

class _QuestSection extends StatefulWidget {
  final int floorNumber;
  final GameEngine engine;
  const _QuestSection({required this.floorNumber, required this.engine});

  @override
  State<_QuestSection> createState() => _QuestSectionState();
}

class _TradeSection extends StatefulWidget {
  final int floorNumber;
  final GameEngine engine;
  const _TradeSection({required this.floorNumber, required this.engine});

  @override
  State<_TradeSection> createState() => _TradeSectionState();
}

class _TradeSectionState extends State<_TradeSection> {
  @override
  Widget build(BuildContext context) {
    final offers = widget.engine.tradeService.offersForFloor(
      widget.floorNumber,
    );
    if (offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'COMÉRCIO', count: offers.length),
        const SizedBox(height: 8),
        ...offers.map((offer) => _buildTradeCard(context, offer)),
      ],
    );
  }

  Widget _buildTradeCard(BuildContext context, TradeOffer offer) {
    final standing =
        widget
            .engine
            .state
            .factionRelations[offer.merchantFaction.key]
            ?.standing ??
        0.0;
    final canAfford = offer.cost.entries.every((e) {
      final res = widget.engine.citadel.resources;
      return switch (e.key) {
        'food' => res.food >= e.value,
        'knowledge' => res.knowledge >= e.value,
        'woodLog' => res.woodLog >= e.value,
        'stoneRaw' => res.stoneRaw >= e.value,
        'ironOre' => res.ironOre >= e.value,
        'lumber' => res.lumber >= e.value,
        'stoneBrick' => res.stoneBrick >= e.value,
        'ironBar' => res.ironBar >= e.value,
        _ => false,
      };
    });
    final hasStanding = standing >= offer.standingRequirement;
    final canTrade = canAfford && hasStanding;

    final costStr = offer.cost.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');
    final rewardStr = offer.reward.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: canTrade
              ? AppTheme.orange.withValues(alpha: 0.6)
              : AppTheme.border,
        ),
        borderRadius: BorderRadius.circular(3),
        color: canTrade ? AppTheme.orange.withValues(alpha: 0.03) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.orange.withValues(alpha: 0.6),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TerminalText(
                  offer.merchantFaction.shortLabel,
                  fontSize: 7,
                  color: AppTheme.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!hasStanding)
                TerminalText(
                  'Standing insuf.',
                  fontSize: 7,
                  color: AppTheme.red,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const TerminalText(
                'Paga: ',
                fontSize: 8,
                color: AppTheme.textDim,
              ),
              TerminalText(costStr, fontSize: 8, color: AppTheme.red),
            ],
          ),
          Row(
            children: [
              const TerminalText(
                'Recebe: ',
                fontSize: 8,
                color: AppTheme.textDim,
              ),
              TerminalText(rewardStr, fontSize: 8, color: AppTheme.green),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TerminalButton(
              label: 'TROCAR',
              color: canTrade ? AppTheme.orange : AppTheme.textDim,
              onPressed: canTrade
                  ? () {
                      final result = context.read<GameProvider>().executeTrade(
                        offer.id,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: result.success
                              ? Colors.green[900]
                              : Colors.red[900],
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      setState(() {});
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestSectionState extends State<_QuestSection> {
  @override
  Widget build(BuildContext context) {
    final currentDay = widget.engine.state.currentDay;
    final quests = widget.engine.questService
        .questsForFloor(widget.floorNumber)
        .where((q) {
          final daysLeft = q.dayLimit - currentDay;
          // Quests ativas (em curso) sempre aparecem mesmo expiradas
          if (q.isActive) return true;
          // Quests disponíveis só aparecem se não expiraram
          if (q.isAvailable && daysLeft > 0) return true;
          return false;
        })
        .toList();

    if (quests.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'MISSÕES', count: quests.length),
        const SizedBox(height: 8),
        ...quests.map((q) => _buildQuestCard(q)),
      ],
    );
  }

  void _showAcceptDialog(BuildContext context, FloorQuest quest) {
    final busyIds = widget.engine.questService.busyGroupIds;
    final groups = widget.engine.groups
        .where((g) => g.memberIds.isNotEmpty && !busyIds.contains(g.id))
        .toList();
    NpcGroup? selected;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          // Calcula atributos do grupo selecionado
          double power = 0, intel = 0, luck = 0;
          if (selected != null) {
            final members = selected!.memberIds
                .map(
                  (id) => widget.engine.npcs.firstWhereOrNull(
                    (n) => n.id == id && n.alive,
                  ),
                )
                .whereType<Npc>()
                .toList();
            if (members.isNotEmpty) {
              power =
                  members
                      .map((n) => n.attributes.combatPower)
                      .reduce((a, b) => a + b) /
                  members.length;
              intel =
                  members
                      .map((n) => n.attributes.intelligence)
                      .reduce((a, b) => a + b) /
                  members.length;
              luck =
                  members
                      .map((n) => n.attributes.luck)
                      .reduce((a, b) => a + b) /
                  members.length;
            }
          }

          final failureChance = widget.engine.questService.previewFailureChance(
            quest.type,
            groupPower: power,
            groupIntelligence: intel,
            groupLuck: luck,
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Text(
                quest.title,
                style: const TextStyle(
                  fontFamily: 'FiraCode',
                  fontSize: 13,
                  color: AppTheme.cyan,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(ctx).size.height * 0.45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione um grupo para esta missão:',
                      style: TextStyle(
                        fontFamily: 'FiraCode',
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (groups.isEmpty)
                      const Text(
                        'Nenhum grupo disponível.',
                        style: TextStyle(
                          fontFamily: 'FiraCode',
                          fontSize: 10,
                          color: AppTheme.red,
                        ),
                      )
                    else
                      ...groups.map(
                        (g) => RadioListTile<NpcGroup>(
                          value: g,
                          groupValue: selected,
                          onChanged: (v) => setLocal(() => selected = v),
                          title: Text(
                            g.name,
                            style: const TextStyle(
                              fontFamily: 'FiraCode',
                              fontSize: 10,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${g.memberIds.length} membros',
                            style: const TextStyle(
                              fontFamily: 'FiraCode',
                              fontSize: 9,
                              color: AppTheme.textDim,
                            ),
                          ),
                          activeColor: AppTheme.cyan,
                        ),
                      ),
                    if (selected != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Risco de falha: ${(failureChance * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontFamily: 'FiraCode',
                          fontSize: 10,
                          color: failureChance > 0.4
                              ? AppTheme.red
                              : failureChance > 0.2
                              ? AppTheme.yellow
                              : AppTheme.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      fontFamily: 'FiraCode',
                      color: AppTheme.textDim,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          final members = selected!.memberIds
                              .map(
                                (id) => widget.engine.npcs.firstWhereOrNull(
                                  (n) => n.id == id && n.alive,
                                ),
                              )
                              .whereType<Npc>()
                              .toList();
                          final p = members.isEmpty
                              ? 0.0
                              : members
                                        .map((n) => n.attributes.combatPower)
                                        .reduce((a, b) => a + b) /
                                    members.length;
                          final i = members.isEmpty
                              ? 0.0
                              : members
                                        .map((n) => n.attributes.intelligence)
                                        .reduce((a, b) => a + b) /
                                    members.length;
                          final l = members.isEmpty
                              ? 0.0
                              : members
                                        .map((n) => n.attributes.luck)
                                        .reduce((a, b) => a + b) /
                                    members.length;

                          final result = widget.engine.questService.acceptQuest(
                            quest.id,
                            widget.engine.state.currentDay,
                            groupId: selected!.id,
                            npcIds: selected!.memberIds,
                            groupPower: p,
                            groupIntelligence: i,
                            groupLuck: l,
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result,
                                style: const TextStyle(
                                  fontFamily: 'FiraCode',
                                  fontSize: 10,
                                ),
                              ),
                              backgroundColor: AppTheme.bgElevated,
                            ),
                          );
                        },
                  child: const Text(
                    'CONFIRMAR',
                    style: TextStyle(
                      fontFamily: 'FiraCode',
                      color: AppTheme.cyan,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestCard(FloorQuest quest) {
    final borderColor = quest.title.startsWith('GUERRA:')
        ? AppTheme.red
        : quest.title.startsWith('ZONA DE GUERRA:')
        ? AppTheme.orange
        : AppTheme.border;
    final badgeLabel = quest.title.startsWith('GUERRA:')
        ? '⚔ GUERRA'
        : quest.title.startsWith('ZONA DE GUERRA:')
        ? '🔥 ZONA'
        : quest.type.name.toUpperCase();
    final badgeColor = quest.title.startsWith('GUERRA:')
        ? AppTheme.red
        : quest.title.startsWith('ZONA DE GUERRA:')
        ? AppTheme.orange
        : AppTheme.cyan;

    final daysLeft = quest.dayLimit - widget.engine.state.currentDay;
    final isExpired = daysLeft <= 0;
    final deadlineColor = isExpired
        ? AppTheme.red
        : daysLeft <= 3
        ? AppTheme.red
        : daysLeft <= 7
        ? AppTheme.yellow
        : AppTheme.textDim;

    final rewards = quest.resourceReward.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');
    final rewardStr = [
      if (rewards.isNotEmpty) rewards,
      if (quest.standingReward > 0)
        '+${quest.standingReward.toStringAsFixed(0)} standing',
    ].join('  ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                daysLeft <= 3 ? '⚠ ' : '',
                style: TextStyle(color: deadlineColor, fontSize: 11),
              ),
              Text(
                daysLeft <= 0 ? 'EXPIRADO' : '$daysLeft d',
                style: TextStyle(
                  color: deadlineColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quest.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11.5,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (rewardStr.isNotEmpty) ...[
            Text(
              'Recompensa: $rewardStr',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: isExpired
                ? TerminalButton(
                    label: 'EXPIRADO',
                    color: AppTheme.textDim,
                    onPressed: null,
                  )
                : quest.isAvailable
                ? TerminalButton(
                    label: 'ACEITAR',
                    color: AppTheme.cyan,
                    onPressed: () => _showAcceptDialog(context, quest),
                  )
                : quest.isActive
                ? TerminalButton(
                    label: quest.assignedGroupId != null
                        ? 'EM CURSO'
                        : 'SEM GRUPO',
                    color: quest.assignedGroupId != null
                        ? AppTheme.green
                        : AppTheme.orange,
                    onPressed: null,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Anomaly Tags ──────────────────────────────────────────────────────────

class _AnomalyTagsRow extends StatelessWidget {
  final List<String> tags;
  const _AnomalyTagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'EFEITOS ATIVOS', count: 0),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAA88FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFAA88FF).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '✦ ${_tagLabel(t)}',
                    style: const TextStyle(
                      color: Color(0xFFAA88FF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _tagLabel(String tag) {
    return switch (tag) {
      'anomaly_presence' => 'Presença Anômala',
      'anomaly_countdown' => 'Contagem Regressiva',
      _ => tag,
    };
  }
}

// ── Floor Stats ───────────────────────────────────────────────────────────

class _FloorStats extends StatelessWidget {
  final TowerFloor floor;
  const _FloorStats({required this.floor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'ESTATÍSTICAS', count: 0),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatItem(
              label: 'Re-explorado',
              value: '${floor.timesReexplored}x',
            ),
            _StatItem(label: 'Conquistas', value: '${floor.timesCleared}x'),
            _StatItem(label: 'Mortos', value: '${floor.deadOnFloor.length}'),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers globais de cor/ícone ──────────────────────────────────────────

Color _factionColor(FloorFaction faction) {
  return switch (faction) {
    FloorFaction.ironPact => const Color(0xFFFF6B6B),
    FloorFaction.silentOrder => const Color(0xFF64B5F6),
    FloorFaction.bloodMarket => const Color(0xFFFFD54F),
    FloorFaction.voidChildren => const Color(0xFFBA68C8),
    FloorFaction.towerServants => const Color(0xFF4DB6AC),
    FloorFaction.none => const Color(0xFF888888),
  };
}

IconData _factionIcon(FloorFaction faction) {
  return switch (faction) {
    FloorFaction.ironPact => Icons.shield,
    FloorFaction.silentOrder => Icons.auto_stories,
    FloorFaction.bloodMarket => Icons.storefront,
    FloorFaction.voidChildren => Icons.blur_on,
    FloorFaction.towerServants => Icons.castle,
    FloorFaction.none => Icons.remove,
  };
}

Color _categoryColor(InhabitantCategory category) {
  return switch (category) {
    InhabitantCategory.resident => const Color(0xFF64B5F6),
    InhabitantCategory.survivor => const Color(0xFF66DD88),
    InhabitantCategory.anomaly => const Color(0xFFAA88FF),
  };
}

String _categoryLabel(InhabitantCategory category) {
  return switch (category) {
    InhabitantCategory.resident => 'RESIDENTE',
    InhabitantCategory.survivor => 'SURVIVOR',
    InhabitantCategory.anomaly => 'ANOMALIA',
  };
}

class _WarPenaltyBanner extends StatelessWidget {
  final int floorNumber;
  final GameEngine engine;
  const _WarPenaltyBanner({required this.floorNumber, required this.engine});

  @override
  Widget build(BuildContext context) {
    final war = engine.warService.activeWars.firstWhere(
      (w) => w.contestedFloors.contains(floorNumber),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF2200).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFFF2200).withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚔', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              TerminalText(
                'ZONA DE GUERRA',
                fontSize: 9,
                color: const Color(0xFFFF4444),
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              TerminalText(
                '${war.aggressor.shortLabel} vs ${war.defender.shortLabel}',
                fontSize: 8,
                color: const Color(0xFFFF8888),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TerminalText(
            '−40% recursos coletados  •  +30% mortalidade',
            fontSize: 8,
            color: const Color(0xFFFF6666),
          ),
          const SizedBox(height: 4),
          TerminalText(
            'Duração: dia ${war.startDay} → dia ${war.startDay + war.duration}',
            fontSize: 8,
            color: AppTheme.textDim,
          ),
        ],
      ),
    );
  }
}

Color _tierColor(FactionTier tier) {
  return switch (tier) {
    FactionTier.ally => const Color(0xFF66DD88),
    FactionTier.friendly => const Color(0xFF64B5F6),
    FactionTier.neutral => const Color(0xFFAAAAAA),
    FactionTier.cautious => const Color(0xFFFFD54F),
    FactionTier.hostile => const Color(0xFFFF8A65),
    FactionTier.atWar => const Color(0xFFFF4444),
    FactionTier.bloodFeud => const Color(0xFFCC0000),
  };
}

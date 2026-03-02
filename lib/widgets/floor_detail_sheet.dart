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

import 'package:flutter/material.dart';
import 'package:tower_ascension/models/citadel.dart';
import 'package:tower_ascension/models/tower.dart';
import 'package:tower_ascension/models/floor_faction.dart';
import 'package:tower_ascension/models/floor_inhabitant.dart';
import 'package:tower_ascension/services/game_engine.dart';

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
                        relation: engine.state.factionRelations[
                            floor.controllingFaction.name],
                      ),
                    const SizedBox(height: 20),
                    _SectionLabel(
                      label: 'HABITANTES',
                      count: floor.inhabitants
                          .where((i) => i.isActive)
                          .length,
                    ),
                    const SizedBox(height: 8),
                    if (floor.inhabitants.isEmpty ||
                        floor.inhabitants.every((i) => !i.isActive))
                      _EmptyInhabitants()
                    else
                      ...floor.inhabitants
                          .where((i) => i.isActive)
                          .map((i) => _InhabitantCard(
                                inhabitant: i,
                                engine: engine,
                              )),
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
            child: Text(
              floor.type.icon,
              style: const TextStyle(fontSize: 22),
            ),
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
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: Color(0xFFFFB74D)),
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
    final isPendingRecruit = engine.pendingRecruits
        .any((r) => r.id == inhabitant.id);

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
                        _DispositionChip(
                            disposition: inhabitant.disposition),
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
              if (inhabitant.factionAffiliation != null)
                _FactionMiniTag(affiliation: inhabitant.factionAffiliation!),
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
                    BuildingType.wayfareresRefuge)),
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
  final String affiliation;
  const _FactionMiniTag({required this.affiliation});

  @override
  Widget build(BuildContext context) {
    final faction = FloorFaction.values.firstWhere(
      (f) => f.name == affiliation,
      orElse: () => FloorFaction.none,
    );
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
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 9.5,
        ),
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
        border: Border.all(
            color: const Color(0xFF66DD88).withOpacity(0.4)),
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
          const Icon(Icons.person_add_outlined,
              size: 13, color: Colors.amber),
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
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAA88FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFFAA88FF).withOpacity(0.3)),
                    ),
                    child: Text(
                      '✦ ${_tagLabel(t)}',
                      style: const TextStyle(
                        color: Color(0xFFAA88FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
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
                value: '${floor.timesReexplored}x'),
            _StatItem(
                label: 'Conquistas',
                value: '${floor.timesCleared}x'),
            _StatItem(
                label: 'Mortos',
                value: '${floor.deadOnFloor.length}'),
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
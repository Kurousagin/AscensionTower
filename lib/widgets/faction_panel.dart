// lib/widgets/faction_panel.dart
//
// Widget: FactionPanel
// Painel de facções — exibe o estado atual das relações da cidadela
// com todas as facções conhecidas (encontradas ao menos uma vez).
//
// USO como bottom sheet ou aba:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => FactionPanel(engine: engine),
//   );

import 'package:flutter/material.dart';
import 'package:tower_ascension/models/floor_faction.dart';
//import 'package:tower_ascension/models/game_event.dart';
import 'package:tower_ascension/services/game_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TODO — FEATURES FUTURAS (não implementadas nesta versão)
//
// 1. DIPLOMACIA / NEGOCIAÇÃO
//    Ideia: Tela de interação direta com cada facção para negociar tratados,
//    pagar tributos voluntários, propor acordos de não-agressão.
//    Mecânica: cada facção tem um "custo de entrada" baseado no seu primaryAttribute
//    (IronPact: enviar grupo forte numa missão de demonstração;
//     SilentOrder: oferecer conhecimento acumulado;
//     BloodMarket: pagar recursos direto;
//     VoidChildren: ação aleatória — pode dar certo ou piorar tudo;
//     TowerServants: sacrifício de fama/NPCs).
//    UI: modal com 3 opções de "proposta" por facção, cada uma com custo,
//    chance de sucesso e delta de standing esperado.
//    Referência: FactionProcessor.processFloorAttempt() como ponto de entrada.
//
// 2. HISTÓRICO DE INTERAÇÕES POR FACÇÃO
//    Ideia: Timeline de todos os eventos de uma facção específica —
//    cada interação (expedição, re-exploração, incursão) com o delta de standing
//    gerado, o grupo envolvido e o resultado narrativo.
//    Mecânica: filtrar GameEngine.events por GameEventType.politicalEvent
//    e GameEventType.discovery onde o título contém o nome da facção.
//    UI: lista cronológica reversa com chips coloridos por tipo de evento
//    e mini-gráfico de linha mostrando evolução do standing ao longo dos dias.
//    Referência: GameEvent.involvedNpcIds para linkage com NPCs.
//
// 3. MAPA DE TERRITÓRIOS
//    Ideia: Visualização de quais andares cada facção controla,
//    mostrando clusters de controle (ex: andares 11-20 = SilentOrder),
//    andares disputados (seed > 85 em factionForFloor) e andares neutros.
//    Mecânica: iterar engine.floors, agrupar por controllingFaction,
//    renderizar como grade vertical de 100 células coloridas por facção.
//    UI: grade 10x10, cada célula = 1 andar. Cor = facção. Opacidade = standing.
//    Toque na célula abre FloorDetailSheet daquele andar.
//    Referência: FactionProcessor.factionForFloor() + TowerFloor.controllingFaction.
// ═══════════════════════════════════════════════════════════════════════════

class FactionPanel extends StatefulWidget {
  final GameEngine engine;

  const FactionPanel({super.key, required this.engine});

  @override
  State<FactionPanel> createState() => _FactionPanelState();
}

class _FactionPanelState extends State<FactionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return FadeTransition(
          opacity: _fade,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0C0C12),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: Color(0xFFDDAA66), width: 1.5),
              ),
            ),
            child: Column(
              children: [
                _PanelHandle(),
                _PanelHeader(engine: widget.engine),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _OverviewCards(engine: widget.engine),
                      const SizedBox(height: 20),
                      _KnownFactionsSection(engine: widget.engine),
                      const SizedBox(height: 20),
                      _UnknownFactionsSection(engine: widget.engine),
                      const SizedBox(height: 20),
                      _IncursionWarningSection(engine: widget.engine),
                      const SizedBox(height: 20),
                      _TodoFeaturesHint(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Handle ────────────────────────────────────────────────────────────────

class _PanelHandle extends StatelessWidget {
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

// ── Header ────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final GameEngine engine;
  const _PanelHeader({required this.engine});

  @override
  Widget build(BuildContext context) {
    final knownCount = engine.state.factionRelations.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          const Text('⚑', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FACÇÕES DA TORRE',
                style: TextStyle(
                  color: Color(0xFFDDAA66),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$knownCount de 5 facções encontradas · Dia ${engine.state.currentDay}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Overview Cards ────────────────────────────────────────────────────────

class _OverviewCards extends StatelessWidget {
  final GameEngine engine;
  const _OverviewCards({required this.engine});

  @override
  Widget build(BuildContext context) {
    final relations = engine.state.factionRelations.values.toList();

    final allies = relations.where(
      (r) => r.tier == FactionTier.ally || r.tier == FactionTier.friendly,
    );
    final threats = relations.where(
      (r) => r.tier == FactionTier.atWar || r.tier == FactionTier.bloodFeud,
    );
    final hostile = relations.where((r) => r.tier == FactionTier.hostile);

    return Row(
      children: [
        _MiniCard(
          label: 'Aliados',
          value: '${allies.length}',
          color: const Color(0xFF66DD88),
          icon: Icons.handshake_outlined,
        ),
        const SizedBox(width: 8),
        _MiniCard(
          label: 'Hostis',
          value: '${hostile.length}',
          color: const Color(0xFFFF8A65),
          icon: Icons.warning_amber_outlined,
        ),
        const SizedBox(width: 8),
        _MiniCard(
          label: 'Em Guerra',
          value: '${threats.length}',
          color: const Color(0xFFFF4444),
          icon: Icons.local_fire_department_outlined,
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

// ── Known Factions Section ────────────────────────────────────────────────

class _KnownFactionsSection extends StatelessWidget {
  final GameEngine engine;
  const _KnownFactionsSection({required this.engine});

  @override
  Widget build(BuildContext context) {
    final relations = engine.state.factionRelations.values.toList()
      ..sort((a, b) => b.standing.compareTo(a.standing));

    if (relations.isEmpty) {
      return _EmptySection(
        message:
            'Nenhuma facção encontrada ainda.\n'
            'Continue explorando a Torre.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'RELAÇÕES ATIVAS', count: relations.length),
        const SizedBox(height: 10),
        ...relations.map((r) => _FactionCard(relation: r, engine: engine)),
      ],
    );
  }
}

// ── Unknown Factions Section ──────────────────────────────────────────────

class _UnknownFactionsSection extends StatelessWidget {
  final GameEngine engine;
  const _UnknownFactionsSection({required this.engine});

  @override
  Widget build(BuildContext context) {
    final knownNames = engine.state.factionRelations.keys.toSet();
    final unknown = FloorFaction.values
        .where((f) => f != FloorFaction.none && !knownNames.contains(f.name))
        .toList();

    if (unknown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'NÃO ENCONTRADAS', count: unknown.length),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: unknown
              .map((f) => _UnknownFactionChip(faction: f))
              .toList(),
        ),
      ],
    );
  }
}

class _UnknownFactionChip extends StatelessWidget {
  final FloorFaction faction;
  const _UnknownFactionChip({required this.faction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '?',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            faction.label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Incursion Warning Section ─────────────────────────────────────────────

class _IncursionWarningSection extends StatelessWidget {
  final GameEngine engine;
  const _IncursionWarningSection({required this.engine});

  @override
  Widget build(BuildContext context) {
    final dangerous = engine.state.factionRelations.values
        .where((r) => r.standing <= -60)
        .toList();

    if (dangerous.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          label: 'ALERTA DE INCURSÃO',
          count: dangerous.length,
          color: const Color(0xFFFF4444),
        ),
        const SizedBox(height: 10),
        ...dangerous.map((r) => _IncursionAlert(relation: r)),
      ],
    );
  }
}

class _IncursionAlert extends StatelessWidget {
  final FactionRelation relation;
  const _IncursionAlert({required this.relation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0505),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Color(0xFFFF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relation.faction.label,
                  style: const TextStyle(
                    color: Color(0xFFFF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Standing ${relation.standing.toStringAsFixed(0)} · '
                  '${relation.incursionsCaused} incursão(ões) · '
                  'Status: ${relation.tier.label}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Incursões a cada 14 dias enquanto standing ≤ -60.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Faction Card (relação conhecida) ─────────────────────────────────────

class _FactionCard extends StatefulWidget {
  final FactionRelation relation;
  final GameEngine engine;
  const _FactionCard({required this.relation, required this.engine});

  @override
  State<_FactionCard> createState() => _FactionCardState();
}

class _FactionCardState extends State<_FactionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final faction = widget.relation.faction;
    final color = _factionColor(faction);
    final tier = widget.relation.tier;
    final standing = widget.relation.standing;
    final normalized = ((standing + 100) / 200).clamp(0.0, 1.0);

    // Andares conquistados desta facção
    final controlledCleared = widget.engine.clearedFloors
        .where((f) => f.controllingFaction == faction)
        .length;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(_expanded ? 0.5 : 0.25),
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha principal
            Row(
              children: [
                Icon(_factionIcon(faction), color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faction.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          _TierPill(tier: tier),
                          const SizedBox(width: 6),
                          if (widget.relation.hasTreaty) _TreatyPill(),
                        ],
                      ),
                    ],
                  ),
                ),
                // Standing + barra
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      standing.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: normalized,
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white30,
                  size: 18,
                ),
              ],
            ),

            // Expansão com detalhes
            if (_expanded) ...[
              const SizedBox(height: 14),
              Divider(color: color.withOpacity(0.2), height: 1),
              const SizedBox(height: 12),
              Text(
                faction.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              _FactionDetailGrid(
                relation: widget.relation,
                controlledCleared: controlledCleared,
                color: color,
              ),
              const SizedBox(height: 12),
              _FactionPrimaryAttr(faction: faction, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactionDetailGrid extends StatelessWidget {
  final FactionRelation relation;
  final int controlledCleared;
  final Color color;

  const _FactionDetailGrid({
    required this.relation,
    required this.controlledCleared,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DetailCell(
          label: 'Interações',
          value: '${relation.totalInteractions}',
          color: color,
        ),
        _DetailCell(
          label: 'Andares',
          value: '$controlledCleared',
          color: color,
        ),
        _DetailCell(
          label: 'Incursões',
          value: '${relation.incursionsCaused}',
          color: relation.incursionsCaused > 0
              ? const Color(0xFFFF4444)
              : color,
        ),
        _DetailCell(
          label: 'Último dia',
          value: relation.lastInteractionDay > 0
              ? '${relation.lastInteractionDay}'
              : '—',
          color: color,
        ),
      ],
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 9.5,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FactionPrimaryAttr extends StatelessWidget {
  final FloorFaction faction;
  final Color color;
  const _FactionPrimaryAttr({required this.faction, required this.color});

  @override
  Widget build(BuildContext context) {
    if (faction.primaryAttribute.isEmpty) return const SizedBox.shrink();

    final attrLabel = switch (faction.primaryAttribute) {
      'combatPower' => 'Poder de Combate',
      'intelligence' => 'Inteligência',
      'resources' => 'Recursos',
      'luck' => 'Sorte',
      'fame' => 'Fama',
      _ => faction.primaryAttribute,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            'Respeita: $attrLabel',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierPill extends StatelessWidget {
  final FactionTier tier;
  const _TierPill({required this.tier});

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        tier.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _TreatyPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.35)),
      ),
      child: const Text(
        '📜 TRATADO',
        style: TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── TODO Hint ─────────────────────────────────────────────────────────────

class _TodoFeaturesHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.build_circle_outlined,
                color: Colors.white24,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'PRÓXIMAS FEATURES',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...const [
            '🤝 Diplomacia — negociar tratados e tributar facções diretamente',
            '📜 Histórico — timeline de interações e evolução de standing',
            '🗺 Mapa de territórios — grade visual dos andares por facção',
          ].map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                t,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionTitle({
    required this.label,
    required this.count,
    this.color = Colors.white38,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
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
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
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

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 12,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Helpers de cor/ícone (replicados aqui para independência de arquivo) ──

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

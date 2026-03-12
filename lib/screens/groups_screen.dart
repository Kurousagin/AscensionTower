import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/citadel.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../models/group_model.dart';
import '../models/tower.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import '../widgets/collapsible_list.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) => ScanlineOverlay(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GroupHeader(gp: gp),
              const SizedBox(height: 12),
              _CreateGroupButton(gp: gp),
              const SizedBox(height: 12),
              if (gp.groups.isEmpty)
                const _EmptyGroupsCard()
              else
                CollapsibleList(
                  label: 'Grupos ativos',
                  items: gp.groups,
                  initialCount: 5,
                  itemBuilder: (g, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GroupCard(gp: gp, group: g),
                  ),
                ),
              const SizedBox(height: 12),
              _SuggestionHistory(gp: gp),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final GameProvider gp;
  const _GroupHeader({required this.gp});

  @override
  Widget build(BuildContext context) {
    final membersInGroups = gp.aliveNpcs.where((n) => n.groupId != null).length;
    final freeNpcs = gp.aliveNpcs.where((n) => n.groupId == null).length;
    final hasSuspicious = gp.suspiciousNpcs.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(
          color: hasSuspicious
              ? AppTheme.red.withValues(alpha: 0.5)
              : AppTheme.cyan.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: (hasSuspicious ? AppTheme.red : AppTheme.cyan).withValues(
              alpha: 0.05,
            ),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const TerminalText(
            'ESQUADRÕES & GRUPOS',
            fontSize: 8,
            color: AppTheme.textDim,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),

          // Stat chips
          Row(
            children: [
              _headerChip('${gp.groups.length}', 'GRUPOS', AppTheme.cyan),
              const SizedBox(width: 8),
              _headerChip('$membersInGroups', 'EM GRUPO', AppTheme.green),
              const SizedBox(width: 8),
              _headerChip('$freeNpcs', 'LIVRES', AppTheme.textSecondary),
              if (hasSuspicious) ...[
                const SizedBox(width: 8),
                _headerChip(
                  '${gp.suspiciousNpcs.length}',
                  'SUSPEITOS',
                  AppTheme.red,
                ),
              ],
            ],
          ),

          // Alerta de suspeitos
          if (hasSuspicious) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.red.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(2),
                color: AppTheme.red.withValues(alpha: 0.06),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 11,
                    color: AppTheme.red,
                  ),
                  const SizedBox(width: 6),
                  TerminalText(
                    '${gp.suspiciousNpcs.length} habitante(s) suspeito(s) na comunidade',
                    fontSize: 9,
                    color: AppTheme.red,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(3),
        color: color.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          TerminalText(
            value,
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(label, fontSize: 7, color: AppTheme.textDim),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTAO CRIAR GRUPO
// ─────────────────────────────────────────────

class _CreateGroupButton extends StatelessWidget {
  final GameProvider gp;
  const _CreateGroupButton({required this.gp});

  @override
  Widget build(BuildContext context) {
    final canCreate = gp.aliveNpcs.length >= 2;
    final freeNpcs = gp.aliveNpcs.where((n) => n.groupId == null).length;

    return GestureDetector(
      onTap: canCreate ? () => _CreateGroupDialog.show(context, gp) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: Border.all(
            color: canCreate
                ? AppTheme.cyan.withValues(alpha: 0.4)
                : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.group_add,
              size: 20,
              color: canCreate ? AppTheme.cyan : AppTheme.textDim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText(
                    'FORMAR NOVO ESQUADRÃO',
                    fontSize: 11,
                    color: canCreate ? AppTheme.cyan : AppTheme.textDim,
                    fontWeight: FontWeight.bold,
                  ),
                  TerminalText(
                    canCreate
                        ? '$freeNpcs habitante(s) disponível(is) para recrutamento'
                        : 'Necessário ao menos 2 habitantes vivos',
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: canCreate ? AppTheme.cyan : AppTheme.textDim,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD DE GRUPO
// ─────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final GameProvider gp;
  final NpcGroup group;
  const _GroupCard({required this.gp, required this.group});

  @override
  Widget build(BuildContext context) {
    final members = _resolveMembers();
    final aliveMembers = members.where((n) => n.alive).toList();
    final leader = group.leaderId != null
        ? gp.allNpcs.firstWhereOrNull((n) => n.id == group.leaderId)
        : null;

    final avgPower = _average(aliveMembers, (n) => n.attributes.combatPower);
    final avgLoyalty = _average(aliveMembers, (n) => n.loyalty);
    final avgFatigue = _average(aliveMembers, (n) => n.fatigue);
    final exhaustedCount = aliveMembers.where((n) => n.isExhausted).length;

    final cohesionColor = group.cohesion > 70
        ? AppTheme.green
        : group.cohesion > 40
        ? AppTheme.yellow
        : AppTheme.red;

    final activeQuest = gp.activeQuests.firstWhereOrNull(
      (q) => q.assignedGroupId == group.id,
    );
    gp.engine.questService.busyGroupIds.contains(group.id);

    final borderColor = activeQuest != null ? AppTheme.purple : cohesionColor;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header do card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: borderColor.withValues(alpha: 0.25)),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                // Nome + papel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TerminalText(
                            group.name,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.cyan.withValues(alpha: 0.4),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: TerminalText(
                              group.role.label.toUpperCase(),
                              fontSize: 7,
                              color: AppTheme.cyan,
                            ),
                          ),
                          if (activeQuest != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.yellow.withValues(alpha: 0.6),
                                ),
                                borderRadius: BorderRadius.circular(2),
                                color: AppTheme.yellow.withValues(alpha: 0.07),
                              ),
                              child: const TerminalText(
                                '⚔ EM QUEST',
                                fontSize: 7,
                                color: AppTheme.yellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (leader != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 10,
                              color: AppTheme.yellow,
                            ),
                            const SizedBox(width: 3),
                            TerminalText(
                              '${leader.name}  ·  ${leader.profession.label}',
                              fontSize: 8,
                              color: AppTheme.yellow,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Missões completadas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TerminalText(
                      '${group.missionsCompleted}',
                      fontSize: 14,
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                    const TerminalText(
                      'MISSÕES',
                      fontSize: 7,
                      color: AppTheme.textDim,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Stats + barra de coesão ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips de stat
                Row(
                  children: [
                    _statChip(
                      '${aliveMembers.length}/${group.memberIds.length}',
                      'MEMBROS',
                      aliveMembers.length < group.memberIds.length
                          ? AppTheme.orange
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    _statChip(
                      avgPower.toStringAsFixed(1),
                      'PWR MED',
                      AppTheme.orange,
                    ),
                    const SizedBox(width: 6),
                    _statChip(
                      avgLoyalty.toStringAsFixed(0),
                      'LEALDADE',
                      avgLoyalty > 70
                          ? AppTheme.green
                          : avgLoyalty > 40
                          ? AppTheme.yellow
                          : AppTheme.red,
                    ),
                    const SizedBox(width: 6),
                    _statChip(
                      '${avgFatigue.toStringAsFixed(0)}%',
                      'FADIGA',
                      avgFatigue >= 70
                          ? AppTheme.red
                          : avgFatigue >= 50
                          ? AppTheme.orange
                          : avgFatigue >= 30
                          ? AppTheme.yellow
                          : AppTheme.green,
                    ),
                    if (exhaustedCount > 0) ...[
                      const SizedBox(width: 6),
                      _statChip('$exhaustedCount', 'EXAUSTOS', AppTheme.red),
                    ],
                  ],
                ),

                // Barra de coesão
                const SizedBox(height: 10),
                Row(
                  children: [
                    const TerminalText(
                      'COESÃO  ',
                      fontSize: 7,
                      color: AppTheme.textDim,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(1),
                              border: Border.all(color: AppTheme.border),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (group.cohesion / 100.0).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: cohesionColor,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    TerminalText(
                      '${group.cohesion.toStringAsFixed(0)}%',
                      fontSize: 8,
                      color: cohesionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),

                if (group.casualties > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.close, size: 10, color: AppTheme.red),
                      const SizedBox(width: 4),
                      TerminalText(
                        '${group.casualties} baixa(s) acumulada(s)',
                        fontSize: 8,
                        color: AppTheme.red,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Lista de membros ────────────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: CollapsibleList(
                items: aliveMembers,
                initialCount: 4,
                itemBuilder: (npc, _) => _MemberRow(npc: npc, group: group),
              ),
            ),
          ),

          // ── Ações ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: _GroupActions(
              gp: gp,
              group: group,
              aliveMembers: aliveMembers,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(2),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          TerminalText(
            value,
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(label, fontSize: 6, color: AppTheme.textDim),
        ],
      ),
    );
  }

  List<Npc> _resolveMembers() => group.memberIds
      .map((id) => gp.allNpcs.firstWhereOrNull((n) => n.id == id))
      .whereType<Npc>()
      .toList();

  double _average(List<Npc> npcs, double Function(Npc) selector) {
    if (npcs.isEmpty) return 0.0;
    return npcs.map(selector).reduce((a, b) => a + b) / npcs.length;
  }
}

// _GroupStats foi incorporado diretamente no _GroupCard acima

class _MemberRow extends StatelessWidget {
  final Npc npc;
  final NpcGroup group;
  const _MemberRow({required this.npc, required this.group});

  @override
  Widget build(BuildContext context) {
    final isLeader = npc.id == group.leaderId;
    final fatigueColor = npc.fatigue >= 90
        ? const Color(0xFFFF0044)
        : npc.fatigue >= 70
        ? AppTheme.red
        : npc.fatigue >= 50
        ? AppTheme.orange
        : npc.fatigue >= 30
        ? AppTheme.yellow
        : AppTheme.green;

    final nameColor = npc.isIncapacitated
        ? AppTheme.red.withValues(alpha: 0.5)
        : npc.isSuspicious
        ? AppTheme.red
        : isLeader
        ? AppTheme.yellow
        : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.4)),
        ),
        color: isLeader
            ? AppTheme.yellow.withValues(alpha: 0.03)
            : npc.isIncapacitated
            ? AppTheme.red.withValues(alpha: 0.02)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Ícone de papel
          SizedBox(
            width: 14,
            child: isLeader
                ? const Icon(Icons.star, size: 11, color: AppTheme.yellow)
                : npc.isSuspicious
                ? const Icon(Icons.warning, size: 11, color: AppTheme.red)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),

          // Nome + profissão
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(
                  npc.name,
                  fontSize: 9,
                  color: nameColor,
                  fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                ),
                TerminalText(
                  npc.profession.label,
                  fontSize: 7,
                  color: AppTheme.textDim,
                ),
              ],
            ),
          ),

          // PWR
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TerminalText(
                  npc.attributes.combatPower.toStringAsFixed(1),
                  fontSize: 9,
                  color: AppTheme.orange,
                  fontWeight: FontWeight.bold,
                ),
                const TerminalText('PWR', fontSize: 6, color: AppTheme.textDim),
              ],
            ),
          ),

          // Fadiga
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TerminalText(
                '${npc.fatigue.toStringAsFixed(0)}%',
                fontSize: 9,
                color: fatigueColor,
                fontWeight: FontWeight.bold,
              ),
              const TerminalText('FAD', fontSize: 6, color: AppTheme.textDim),
            ],
          ),

          // Status crítico
          if (npc.isIncapacitated || npc.isExhausted)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: TerminalText(
                npc.isIncapacitated ? 'INCAP' : 'EXAU',
                fontSize: 7,
                color: AppTheme.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupActions extends StatelessWidget {
  final GameProvider gp;
  final NpcGroup group;
  final List<Npc> aliveMembers;
  const _GroupActions({
    required this.gp,
    required this.group,
    required this.aliveMembers,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = gp.engine.questService.busyGroupIds.contains(group.id);

    return Column(
      children: [
        // Ações principais lado a lado
        if (gp.nextFloor != null && aliveMembers.length >= 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TerminalButton(
              label: 'DESAFIAR ANDAR ${gp.nextFloor!.number}',
              icon: Icons.rocket_launch,
              color: AppTheme.orange,
              expanded: true,
              onPressed: isBusy
                  ? null
                  : () => _ExpeditionDialog.confirm(context, gp, group),
            ),
          ),
        if (gp.clearedFloors.isNotEmpty && aliveMembers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TerminalButton(
              label: 'COLETAR RECURSOS',
              icon: Icons.search,
              color: AppTheme.green,
              expanded: true,
              onPressed: isBusy
                  ? null
                  : () => _ReexploreDialog.show(context, gp, group),
            ),
          ),

        // Linha: treino + dissolver
        Row(
          children: [
            Expanded(
              child: TerminalButton(
                label: 'SUGERIR TREINO',
                icon: Icons.fitness_center,
                color: AppTheme.cyan,
                onPressed: isBusy
                    ? null
                    : (gp.clearedFloors.isNotEmpty || gp.hasTrainingField)
                    ? () => _SuggestTrainingDialog.show(context, gp, group)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            TerminalButton(
              label: 'DISSOLVER',
              icon: Icons.group_remove,
              color: AppTheme.red,
              onPressed: () => gp.disbandGroup(group.id),
            ),
          ],
        ),

        if (isBusy) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.yellow.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(2),
              color: AppTheme.yellow.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.hourglass_empty, size: 10, color: AppTheme.yellow),
                SizedBox(width: 5),
                TerminalText(
                  'Grupo em missão — ações bloqueadas',
                  fontSize: 8,
                  color: AppTheme.yellow,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HISTORICO DE SUGESTOES
// ─────────────────────────────────────────────

class _SuggestionHistory extends StatelessWidget {
  final GameProvider gp;
  const _SuggestionHistory({required this.gp});

  static const _responseColors = {
    TrainingResponse.accepted: AppTheme.green,
    TrainingResponse.refused: AppTheme.red,
    TrainingResponse.negotiated: AppTheme.yellow,
    TrainingResponse.ignored: AppTheme.textDim,
  };

  @override
  Widget build(BuildContext context) {
    final recent = gp.trainingSuggestions.reversed.take(8).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return TerminalCard(
      title: 'RESPOSTAS DE TREINO',
      borderColor: AppTheme.textDim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recent.map((s) {
          final color = _responseColors[s.response] ?? AppTheme.textSecondary;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 7, top: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TerminalText(
                    s.response.label.toUpperCase(),
                    fontSize: 6,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: TerminalText(
                    s.responseDetail,
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD "COMO FUNCIONA"
// ─────────────────────────────────────────────

class _EmptyGroupsCard extends StatelessWidget {
  const _EmptyGroupsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 32,
            color: AppTheme.textDim.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          const TerminalText(
            'NENHUM GRUPO FORMADO',
            fontSize: 11,
            color: AppTheme.textDim,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const TerminalText(
            'Forme esquadrões para coordenar expedições e treinos.\n'
            'Grupos com alta coesão têm bônus de sinergia.',
            fontSize: 9,
            color: AppTheme.textDim,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// _HowItWorksCard removido — mecânicas são intuitivas pelo contexto do jogo

// ─────────────────────────────────────────────
// DIALOGO: CONFIRMAR EXPEDICAO
// ─────────────────────────────────────────────

class _ExpeditionDialog {
  static void confirm(BuildContext context, GameProvider gp, NpcGroup group) {
    final floor = gp.nextFloor;
    if (floor == null) return;

    final aliveIds = group.memberIds
        .where((id) => gp.allNpcs.any((n) => n.id == id && n.alive))
        .toList();
    final totalPower = aliveIds
        .map((id) => gp.allNpcs.firstWhere((n) => n.id == id))
        .fold<double>(0.0, (sum, n) => sum + n.attributes.combatPower);
    final powerPct = floor.recommendedPower > 0
        ? (totalPower / floor.recommendedPower * 100)
        : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.orange),
        ),
        title: TerminalText(
          'ENVIAR ${group.name.toUpperCase()}?',
          fontSize: 13,
          color: AppTheme.orange,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(
              'Destino: Andar ${floor.number} (${floor.type.label})',
              fontSize: 11,
              color: AppTheme.textPrimary,
            ),
            TerminalText(
              'Dificuldade: ${floor.scaledDifficulty.toStringAsFixed(1)}',
              fontSize: 10,
              color: AppTheme.red,
            ),
            const SizedBox(height: 4),
            TerminalText(
              'Membros vivos: ${aliveIds.length}',
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            TerminalText(
              'Poder: ${totalPower.toStringAsFixed(1)} / ${floor.recommendedPower.toStringAsFixed(1)} '
              '(${powerPct.toStringAsFixed(0)}%)',
              fontSize: 10,
              color: powerPct >= 100
                  ? AppTheme.green
                  : powerPct >= 60
                  ? AppTheme.yellow
                  : AppTheme.red,
            ),
            TerminalText(
              'Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
              fontSize: 10,
              color: AppTheme.red,
            ),
            const SizedBox(height: 8),
            if (powerPct < 60)
              const TerminalText(
                'PERIGO: Poder muito abaixo do recomendado!',
                fontSize: 9,
                color: AppTheme.red,
              ),
            const TerminalText(
              'MORTE PERMANENTE. Eles podem nao voltar.',
              fontSize: 10,
              color: AppTheme.red,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        actions: [
          TerminalButton(
            label: 'CANCELAR',
            color: AppTheme.textDim,
            onPressed: () => Navigator.pop(ctx),
          ),
          TerminalButton(
            label: 'ENVIAR',
            icon: Icons.rocket_launch,
            color: AppTheme.orange,
            onPressed: () {
              final nav = Navigator.of(ctx);
              final result = gp.sendGroupExpedition(group.id);
              nav.pop();
              if (result != null && context.mounted) {
                _ExpeditionResultDialog.show(context, result);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DIALOGO: RESULTADO DA EXPEDICAO
// ─────────────────────────────────────────────

class _ExpeditionResultDialog {
  static void show(BuildContext context, TowerChallenge result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: result.victory ? AppTheme.green : AppTheme.red,
          ),
        ),
        title: TerminalText(
          result.victory ? 'VITORIA!' : 'DERROTA',
          fontSize: 16,
          color: result.victory ? AppTheme.green : AppTheme.red,
          fontWeight: FontWeight.bold,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: min(300, MediaQuery.of(context).size.height * 0.4),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.log.map((line) {
                final color = _logLineColor(line, result.victory);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: TerminalText(line, fontSize: 9, color: color),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TerminalButton(label: 'FECHAR', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  static Color _logLineColor(String line, bool victory) {
    if (line.startsWith('>>')) return victory ? AppTheme.green : AppTheme.red;
    if (line.contains('[X]')) return AppTheme.red;
    if (line.contains('[O]')) return AppTheme.green;
    if (line.startsWith('===')) return AppTheme.cyan;
    if (line.startsWith('>')) return AppTheme.orange;
    return AppTheme.textSecondary;
  }
}

// ─────────────────────────────────────────────
// DIALOGO: RE-EXPLORACAO
// ─────────────────────────────────────────────

class _ReexploreDialog extends StatefulWidget {
  final GameProvider gp;
  final NpcGroup group;

  const _ReexploreDialog({required this.gp, required this.group});

  static void show(BuildContext context, GameProvider gp, NpcGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (_) => _ReexploreDialog(gp: gp, group: group),
    );
  }

  @override
  State<_ReexploreDialog> createState() => _ReexploreDialogState();
}

class _ReexploreDialogState extends State<_ReexploreDialog> {
  int? _selectedFloor;

  List<String> get _aliveIds => widget.group.memberIds
      .where((id) => widget.gp.allNpcs.any((n) => n.id == id && n.alive))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BottomSheetHandle(),
            TerminalText(
              'RE-EXPLORAR COM: ${widget.group.name}',
              fontSize: 12,
              color: AppTheme.green,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 4),
            const TerminalText(
              'Escolha um andar conquistado para coletar recursos:',
              fontSize: 9,
              color: AppTheme.textDim,
            ),
            if (_selectedFloor != null) _buildAnalysis(),
            const SizedBox(height: 8),

            // Lista de andares com scroll independente
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: CollapsibleList<int>(
                items: widget.gp.clearedFloors
                    .map((floor) => floor.number)
                    .toList(),

                initialCount: 8,
                itemBuilder: (floorNumber, idx) {
                  final floor = widget.gp.clearedFloors.firstWhere(
                    (f) => f.number == floorNumber,
                  );
                  return _buildFloorOption(
                    floor.number,
                    'Andar ${floor.number} (${floor.type.label}) - Risco moderado',
                    AppTheme.textSecondary,
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            TerminalButton(
              label: _selectedFloor != null
                  ? 'ENVIAR COLETORES'
                  : 'SELECIONE UM ANDAR',
              icon: Icons.search,
              expanded: true,
              color: AppTheme.green,
              onPressed: _selectedFloor != null ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysis() {
    final floor = widget.gp.clearedFloors.firstWhere(
      (f) => f.number == _selectedFloor,
    );
    final aliveIds = _aliveIds;
    final costPerNpc = widget.gp.engine.reexploreCostPerNpc(_selectedFloor!);
    final totalCost = aliveIds.length * costPerNpc;
    final synergy = widget.gp.engine.previewGroupSynergy(aliveIds) * 100;
    final personalityMod =
        widget.gp.engine.previewPartyPersonalityMod(aliveIds) * 100;
    final attributeYield = widget.gp.engine.previewPartyAttributeYield(
      aliveIds,
      floor.type,
    );
    final eventChances = widget.gp.engine.previewEventChances(aliveIds, floor);

    final estimatedFood = (floor.farmableResources['food'] ?? 0.0);
    final totalYield =
        attributeYield * (1 + synergy / 100) * (1 + personalityMod / 100);
    final netFood = estimatedFood * totalYield - totalCost;

    final threatPct = (0.05 + floor.timesReexplored * 0.02) * 100;

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.cyan),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.cyan.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'ANALISE DA EXPEDICAO',
            fontSize: 11,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          TerminalText(
            'Membros: ${aliveIds.length} NPCs',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          TerminalText(
            'Custo: ${totalCost.toStringAsFixed(1)} comida (${costPerNpc.toStringAsFixed(1)}/NPC)',
            fontSize: 9,
            color: AppTheme.orange,
          ),
          _SynergyText(synergy: synergy),
          TerminalText(
            'Eficiencia: ${(totalYield * 100).toStringAsFixed(0)}%'
            ' (atrib: ${(attributeYield * 100).toStringAsFixed(0)}%,'
            ' pers: ${personalityMod >= 0 ? "+" : ""}${personalityMod.toStringAsFixed(0)}%)',
            fontSize: 9,
            color: totalYield > 1.3
                ? AppTheme.green
                : totalYield > 1.0
                ? AppTheme.yellow
                : AppTheme.orange,
          ),
          const Divider(color: AppTheme.border, height: 12),
          const TerminalText(
            'Estimativa de retorno (comida):',
            fontSize: 9,
            color: AppTheme.textDim,
          ),
          TerminalText(
            'Lucro: ${netFood >= 0 ? "+" : ""}${netFood.toStringAsFixed(1)}'
            ' ${netFood < 0
                ? "(PREJUIZO)"
                : netFood < totalCost * 0.5
                ? "(baixo)"
                : "(bom)"}',
            fontSize: 9,
            color: netFood < 0
                ? AppTheme.red
                : netFood < totalCost * 0.5
                ? AppTheme.orange
                : AppTheme.green,
            fontWeight: FontWeight.bold,
          ),
          const Divider(color: AppTheme.border, height: 12),
          const TerminalText('Riscos:', fontSize: 9, color: AppTheme.textDim),
          _RiskText('Acidente', eventChances['acidente'], threshold: 0.2),
          _RiskText('Doenca', eventChances['doenca']),
          if ((eventChances['conflito'] ?? 0) > 0)
            _RiskText('Conflito', eventChances['conflito'], threshold: 0.15),
          if ((eventChances['traicao'] ?? 0) > 0)
            TerminalText(
              'Traicao: ${((eventChances['traicao'] ?? 0) * 100).toStringAsFixed(0)}%',
              fontSize: 8,
              color: AppTheme.red,
            ),
          TerminalText(
            'Ameaca Reativada: ${threatPct.toStringAsFixed(0)}%',
            fontSize: 8,
            color: floor.timesReexplored > 3 ? AppTheme.red : AppTheme.yellow,
          ),
          if ((eventChances['evento_raro'] ?? 0) > 0)
            TerminalText(
              'Evento Raro (2x recursos): ${((eventChances['evento_raro'] ?? 0) * 100).toStringAsFixed(0)}%',
              fontSize: 8,
              color: AppTheme.green,
            ),
        ],
      ),
    );
  }

  Widget _buildFloorOption(int floorNumber, String label, Color labelColor) {
    final isSelected = _selectedFloor == floorNumber;
    return GestureDetector(
      onTap: () => setState(() => _selectedFloor = floorNumber),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.green : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? AppTheme.green.withValues(alpha: 0.05) : null,
        ),
        child: TerminalText(
          label,
          fontSize: 10,
          color: isSelected ? AppTheme.green : labelColor,
        ),
      ),
    );
  }

  void _submit() {
    // Captura o navigator ANTES de desmontar o widget
    final nav = Navigator.of(context);
    final overlayContext = context;

    final result = widget.gp.sendGroupReexploration(
      widget.group.id,
      _selectedFloor!,
    );
    nav.pop(); // fecha bottom sheet com navigator já capturado

    if (result != null && overlayContext.mounted) {
      _ReexploreResultDialog.show(overlayContext, result);
    }
  }
}

// ─────────────────────────────────────────────
// DIALOGO: RESULTADO RE-EXPLORACAO
// ─────────────────────────────────────────────

class _ReexploreResultDialog {
  static void show(BuildContext context, FloorExplorationResult result) {
    final resStr = result.resourcesGained.entries
        .map((e) => '${e.key}: +${e.value.toStringAsFixed(0)}')
        .join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: result.casualties.isNotEmpty ? AppTheme.red : AppTheme.green,
          ),
        ),
        title: TerminalText(
          result.casualties.isNotEmpty
              ? 'AMEACA REATIVADA!'
              : 'COLETA CONCLUIDA',
          fontSize: 14,
          color: result.casualties.isNotEmpty ? AppTheme.red : AppTheme.green,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(
              'Andar ${result.floorNumber}',
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
            const SizedBox(height: 8),
            const TerminalText(
              'Recursos coletados:',
              fontSize: 10,
              color: AppTheme.cyan,
            ),
            TerminalText(resStr, fontSize: 10, color: AppTheme.green),
            if (result.casualties.isNotEmpty) ...[
              const SizedBox(height: 8),
              TerminalText(
                'BAIXAS: ${result.casualties.length}',
                fontSize: 10,
                color: AppTheme.red,
                fontWeight: FontWeight.bold,
              ),
            ],
            if (result.discoveries.isNotEmpty) ...[
              const SizedBox(height: 8),
              TerminalText(
                'Descobertas: ${result.discoveries.join(', ')}',
                fontSize: 10,
                color: AppTheme.yellow,
              ),
            ],
          ],
        ),
        actions: [
          TerminalButton(label: 'FECHAR', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DIALOGO: CRIAR GRUPO
// ─────────────────────────────────────────────

class _CreateGroupDialog extends StatefulWidget {
  final GameProvider gp;
  const _CreateGroupDialog({required this.gp});

  static void show(BuildContext context, GameProvider gp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (_) => _CreateGroupDialog(gp: gp),
    );
  }

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _selectedIds = <String>{};
  GroupRole _role = GroupRole.general;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _selectedIds.length >= 2 && _nameController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BottomSheetHandle(),
            const TerminalText(
              'FORMAR NOVO ESQUADRAO',
              fontSize: 14,
              color: AppTheme.cyan,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 12),
            _buildRoleSelector(),
            if (_selectedIds.length >= 2) _buildGroupAnalysis(),
            const SizedBox(height: 12),
            TerminalText(
              'Selecionar membros (${_selectedIds.length} selecionados):',
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            CollapsibleList(
              items: widget.gp.aliveNpcs
                  .where((n) => n.groupId == null)
                  .toList(),
              initialCount: 5,
              itemBuilder: (npc, _) => _buildNpcOption(npc),
            ),
            const SizedBox(height: 12),
            TerminalButton(
              label: 'CRIAR GRUPO',
              icon: Icons.group_add,
              expanded: true,
              onPressed: _canCreate ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        fontFamily: 'FiraCode',
        fontSize: 12,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Nome do grupo...',
        hintStyle: const TextStyle(
          color: AppTheme.textDim,
          fontFamily: 'FiraCode',
          fontSize: 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.cyan),
          borderRadius: BorderRadius.circular(4),
        ),
        filled: true,
        fillColor: AppTheme.bgElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TerminalText(
          'Funcao:',
          fontSize: 10,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: GroupRole.values.map((role) {
            final active = _role == role;
            return GestureDetector(
              onTap: () => setState(() => _role = role),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: active ? AppTheme.cyan : AppTheme.border,
                  ),
                  borderRadius: BorderRadius.circular(2),
                  color: active ? AppTheme.cyan.withValues(alpha: 0.1) : null,
                ),
                child: TerminalText(
                  role.label,
                  fontSize: 9,
                  color: active ? AppTheme.cyan : AppTheme.textDim,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupAnalysis() {
    final ids = _selectedIds.toList();
    final synergy = widget.gp.engine.previewGroupSynergy(ids) * 100;
    final personalityMod =
        widget.gp.engine.previewPartyPersonalityMod(ids) * 100;
    final npcs = ids
        .map((id) => widget.gp.aliveNpcs.firstWhere((n) => n.id == id))
        .toList();
    final avgPower =
        npcs.map((n) => n.attributes.combatPower).reduce((a, b) => a + b) /
        npcs.length;
    final avgLoyalty =
        npcs.map((n) => n.loyalty).reduce((a, b) => a + b) / npcs.length;
    final avgFatigue =
        npcs.map((n) => n.fatigue).reduce((a, b) => a + b) / npcs.length;
    final exhaustedCount = npcs.where((n) => n.isExhausted).length;
    final hasSuspicious = npcs.any((n) => n.isSuspicious);

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.cyan),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.cyan.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'ANALISE DE EFICIENCIA',
            fontSize: 11,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          _SynergyText(synergy: synergy),
          TerminalText(
            'Dinamica de grupo: ${personalityMod >= 0 ? "+" : ""}${personalityMod.toStringAsFixed(0)}%'
            ' ${personalityMod > 10
                ? "(Harmoniosa)"
                : personalityMod < -10
                ? "(Conflituosa)"
                : "(Equilibrada)"}',
            fontSize: 9,
            color: personalityMod > 10
                ? AppTheme.green
                : personalityMod < -10
                ? AppTheme.red
                : AppTheme.textSecondary,
          ),
          const Divider(color: AppTheme.border, height: 12),
          TerminalText(
            'Poder medio: ${avgPower.toStringAsFixed(1)}',
            fontSize: 9,
            color: avgPower > 15
                ? AppTheme.green
                : avgPower > 10
                ? AppTheme.yellow
                : AppTheme.orange,
          ),
          TerminalText(
            'Lealdade media: ${avgLoyalty.toStringAsFixed(0)}',
            fontSize: 9,
            color: avgLoyalty > 70
                ? AppTheme.green
                : avgLoyalty > 50
                ? AppTheme.yellow
                : AppTheme.orange,
          ),
          TerminalText(
            'Fadiga media: ${avgFatigue.toStringAsFixed(0)}%'
            '${exhaustedCount > 0 ? " ($exhaustedCount exausto${exhaustedCount > 1 ? "s" : ""})" : ""}',
            fontSize: 9,
            color: avgFatigue >= 70
                ? AppTheme.red
                : avgFatigue >= 50
                ? AppTheme.orange
                : avgFatigue >= 30
                ? AppTheme.yellow
                : AppTheme.green,
          ),
          if (hasSuspicious) ...[
            const SizedBox(height: 4),
            const TerminalText(
              'ALERTA: Membro suspeito no grupo!',
              fontSize: 9,
              color: AppTheme.red,
              fontWeight: FontWeight.bold,
            ),
          ],
          if (exhaustedCount > 0) ...[
            const SizedBox(height: 4),
            TerminalText(
              'AVISO: $exhaustedCount membro${exhaustedCount > 1 ? "s" : ""} '
              'exausto${exhaustedCount > 1 ? "s" : ""}',
              fontSize: 9,
              color: AppTheme.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNpcOption(Npc npc) {
    final selected = _selectedIds.contains(npc.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedIds.remove(npc.id);
        } else {
          _selectedIds.add(npc.id);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppTheme.cyan : AppTheme.border),
          borderRadius: BorderRadius.circular(4),
          color: selected ? AppTheme.cyan.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 14,
              color: selected ? AppTheme.cyan : AppTheme.textDim,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText(
                    npc.name,
                    fontSize: 10,
                    color: AppTheme.textPrimary,
                  ),
                  TerminalText(
                    'PWR:${npc.attributes.combatPower.toStringAsFixed(1)}'
                    ' | ${npc.profession.label}'
                    ' | Leal:${npc.loyalty.toStringAsFixed(0)}'
                    ' | Fad:${npc.fatigue.toStringAsFixed(0)}%',
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
            ),
            if (npc.isSuspicious)
              const TerminalText(
                '[SUSPEITO]',
                fontSize: 8,
                color: AppTheme.red,
              ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    widget.gp.createGroup(_nameController.text, _selectedIds.toList(), _role);
    Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────
// DIALOGO: SUGERIR TREINO
// ─────────────────────────────────────────────
class _SuggestTrainingDialog extends StatefulWidget {
  final GameProvider gp;
  final NpcGroup group;
  const _SuggestTrainingDialog({required this.gp, required this.group});

  static void show(BuildContext context, GameProvider gp, NpcGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (_) => _SuggestTrainingDialog(gp: gp, group: group),
    );
  }

  @override
  State<_SuggestTrainingDialog> createState() => _SuggestTrainingDialogState();
}

class _SuggestTrainingDialogState extends State<_SuggestTrainingDialog> {
  BuildingType? _selectedBuilding;
  int _durationDays = 3;

  static const _durations = [3, 5, 7];

  BuildingType _bestBuildingFor(List<String> ids) {
    if (ids.isEmpty) return BuildingType.trainingField;
    final npcs = ids
        .map(
          (id) =>
              widget.gp.allNpcs.firstWhereOrNull((n) => n.id == id && n.alive),
        )
        .whereType<Npc>()
        .toList();
    if (npcs.isEmpty) return BuildingType.trainingField;

    final avgStr =
        npcs.fold(0.0, (s, n) => s + n.attributes.strength) / npcs.length;
    final avgAgi =
        npcs.fold(0.0, (s, n) => s + n.attributes.agility) / npcs.length;
    final avgInt =
        npcs.fold(0.0, (s, n) => s + n.attributes.intelligence) / npcs.length;
    final avgSan =
        npcs.fold(0.0, (s, n) => s + n.attributes.mentalStability) /
        npcs.length;

    // Sugere treinar o atributo MAIS FRACO (maior ganho potencial)
    final scores = {
      BuildingType.barracks: 15 - avgStr,
      BuildingType.arena: 15 - avgAgi,
      BuildingType.library: 15 - avgInt,
      BuildingType.temple: (100 - avgSan) / 10,
    };

    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static const _buildingMeta = {
    BuildingType.trainingField: (
      label: 'Campo de Treino',
      focus: 'FOR / RES / AGI (balanceado)',
      color: AppTheme.green,
      icon: '🏃',
    ),
    BuildingType.barracks: (
      label: 'Barracks',
      focus: 'FOR / RES (combate)',
      color: AppTheme.orange,
      icon: '⚔️',
    ),
    BuildingType.arena: (
      label: 'Arena',
      focus: 'AGI / FOR (velocidade)',
      color: AppTheme.red,
      icon: '🏟️',
    ),
    BuildingType.temple: (
      label: 'Templo',
      focus: 'SAN / CAR (mental)',
      color: AppTheme.cyan,
      icon: '⛪',
    ),
    BuildingType.library: (
      label: 'Biblioteca',
      focus: 'INT (tática)',
      color: AppTheme.purple,
      icon: '📚',
    ),
  };

  List<String> get _aliveIds => widget.group.memberIds
      .where((id) => widget.gp.allNpcs.any((n) => n.id == id && n.alive))
      .toList();

  bool get _alreadyTraining =>
      widget.gp.activeTrainings.any((m) => m.groupId == widget.group.id);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BottomSheetHandle(),
            TerminalText(
              'SUGERIR TREINO: ${widget.group.name}',
              fontSize: 12,
              color: AppTheme.cyan,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 4),
            TerminalText(
              'NPCs podem aceitar ou recusar baseado em aptitude, fadiga e personalidade.',
              fontSize: 9,
              color: AppTheme.textDim,
            ),

            // Aviso se já em treino
            if (_alreadyTraining) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.yellow),
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.yellow.withValues(alpha: 0.05),
                ),
                child: const TerminalText(
                  'Este grupo já possui missão de treino ativa.',
                  fontSize: 9,
                  color: AppTheme.yellow,
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Seleção de edifício
            const TerminalText(
              'EDIFÍCIO DE TREINO:',
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ), // Sugestão automática
            Builder(
              builder: (_) {
                final best = _bestBuildingFor(_aliveIds);
                final meta = _buildingMeta[best];
                if (meta == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBuilding = best),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.yellow.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: AppTheme.yellow.withValues(alpha: 0.04),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: AppTheme.yellow,
                          ),
                          const SizedBox(width: 6),
                          TerminalText(
                            'Sugerido para este grupo: ${meta.label} (${meta.focus})',
                            fontSize: 8,
                            color: AppTheme.yellow,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            ...widget.gp.trainingBuildings.map((b) {
              final meta = _buildingMeta[b];
              if (meta == null) return const SizedBox.shrink();
              final selected = _selectedBuilding == b;
              return GestureDetector(
                onTap: () => setState(() => _selectedBuilding = b),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? meta.color : AppTheme.border,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: selected ? meta.color.withValues(alpha: 0.07) : null,
                  ),
                  child: Row(
                    children: [
                      Text(meta.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TerminalText(
                              meta.label,
                              fontSize: 10,
                              color: selected
                                  ? meta.color
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            TerminalText(
                              meta.focus,
                              fontSize: 8,
                              color: AppTheme.textDim,
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: meta.color, size: 16),
                    ],
                  ),
                ),
              );
            }),

            if (widget.gp.trainingBuildings.isEmpty)
              const TerminalText(
                'Nenhum edifício de treino disponível. Construa Campo de Treino, Barracks, Arena, Templo ou Biblioteca.',
                fontSize: 9,
                color: AppTheme.red,
              ),

            // Seleção de duração
            if (_selectedBuilding != null) ...[
              const SizedBox(height: 12),
              const TerminalText(
                'DURAÇÃO DO TREINO:',
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 6),
              Row(
                children: _durations.map((d) {
                  final selected = _durationDays == d;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _durationDays = d),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? AppTheme.cyan : AppTheme.border,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: selected
                              ? AppTheme.cyan.withValues(alpha: 0.08)
                              : null,
                        ),
                        child: Column(
                          children: [
                            TerminalText(
                              '$d dias',
                              fontSize: 10,
                              color: selected
                                  ? AppTheme.cyan
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            TerminalText(
                              _durationLabel(d),
                              fontSize: 8,
                              color: AppTheme.textDim,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Preview de ganhos
              const SizedBox(height: 12),
              _buildGainPreview(),
            ],

            const SizedBox(height: 16),
            TerminalButton(
              label: _alreadyTraining
                  ? 'JÁ EM TREINO'
                  : _selectedBuilding == null
                  ? 'SELECIONE UM EDIFÍCIO'
                  : 'SUGERIR TREINO',
              icon: Icons.fitness_center,
              expanded: true,
              color: AppTheme.cyan,
              onPressed: (_selectedBuilding != null && !_alreadyTraining)
                  ? _submit
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGainPreview() {
    if (_selectedBuilding == null) return const SizedBox.shrink();

    final preview = widget.gp.previewTrainingGains(
      _aliveIds,
      _selectedBuilding!,
      _durationDays,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.cyan.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'GANHO ESTIMADO (se aceito):',
            fontSize: 10,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          ...preview.entries.map((entry) {
            final npc = widget.gp.allNpcs.firstWhereOrNull(
              (n) => n.id == entry.key,
            );
            if (npc == null) return const SizedBox.shrink();

            final apt = widget.gp.previewNpcAptitude(
              npc.id,
              _selectedBuilding!,
            );
            final aptColor = apt >= 1.8
                ? AppTheme.cyan
                : apt >= 1.3
                ? AppTheme.green
                : apt >= 0.9
                ? AppTheme.yellow
                : AppTheme.red;
            final isHighStat = switch (_selectedBuilding) {
              BuildingType.barracks => npc.attributes.strength >= 10,
              BuildingType.arena => npc.attributes.agility >= 10,
              BuildingType.library => npc.attributes.intelligence >= 10,
              BuildingType.temple => npc.attributes.mentalStability >= 75,
              _ => false,
            };

            final aptLabel = apt >= 1.8
                ? 'Excelente'
                : apt >= 1.3
                ? 'Alta'
                : apt >= 0.9
                ? 'Média'
                : isHighStat
                ? 'Baixa (já avançado)' // ← não é ruim, é diminishing returns
                : apt >= 0.5
                ? 'Baixa'
                : 'Péssima';

            final buildingFocusAttr = switch (_selectedBuilding) {
              BuildingType.barracks => 'strength',
              BuildingType.arena => 'agility',
              BuildingType.library => 'intelligence',
              BuildingType.temple => 'mentalStability',
              _ => 'strength',
            };

            final gainStr = entry.value.entries
                .map((e) {
                  final label = _attrLabel(e.key);
                  final val = e.value.toStringAsFixed(2);
                  final isFocus = e.key == buildingFocusAttr;
                  return isFocus ? '▶$label+$val' : '$label+$val';
                })
                .join('  ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TerminalText(
                      npc.name,
                      fontSize: 8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TerminalText(
                      'Apt: $aptLabel',
                      fontSize: 8,
                      color: aptColor,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: TerminalText(
                      gainStr,
                      fontSize: 8,
                      color: apt >= 1.3
                          ? AppTheme.green
                          : apt >= 0.9
                          ? AppTheme.yellow
                          : AppTheme.textDim,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: AppTheme.border, height: 12),
          TerminalText(
            'Custo: ${(_aliveIds.length * _durationDays * 1.0).toStringAsFixed(0)} comida total',
            fontSize: 8,
            color: AppTheme.orange,
          ),
        ],
      ),
    );
  }

  String _durationLabel(int days) => switch (days) {
    3 => 'rápido',
    5 => 'normal',
    7 => 'intensivo',
    _ => '',
  };

  String _attrLabel(String attr) => switch (attr) {
    'strength' => 'FOR',
    'endurance' => 'RES',
    'agility' => 'AGI',
    'intelligence' => 'INT',
    'charisma' => 'CAR',
    'mentalStability' => 'SAN',
    _ => attr,
  };

  void _submit() {
    final nav = Navigator.of(context);
    final ctx = context;
    final result = widget.gp.suggestGroupTraining(
      widget.group.id,
      _selectedBuilding!,
      _durationDays,
    );
    nav.pop();
    if (ctx.mounted) _TrainingResponseDialog.show(ctx, result);
  }
}

// ─────────────────────────────────────────────
// WIDGETS AUXILIARES REUTILIZÁVEIS
// ─────────────────────────────────────────────

class _TrainingResponseDialog {
  static const _configs = {
    TrainingResponse.accepted: (
      color: AppTheme.green,
      icon: Icons.check_circle_outline,
      title: 'PROPOSTA ACEITA',
    ),
    TrainingResponse.refused: (
      color: AppTheme.red,
      icon: Icons.cancel_outlined,
      title: 'PROPOSTA RECUSADA',
    ),
    TrainingResponse.negotiated: (
      color: AppTheme.yellow,
      icon: Icons.handshake_outlined,
      title: 'NEGOCIACAO',
    ),
    TrainingResponse.ignored: (
      color: AppTheme.textDim,
      icon: Icons.do_not_disturb_outlined,
      title: 'IGNORADO',
    ),
  };

  static void show(BuildContext context, TrainingSuggestion result) {
    final cfg = _configs[result.response]!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cfg.color),
        ),
        title: Row(
          children: [
            Icon(cfg.icon, color: cfg.color, size: 18),
            const SizedBox(width: 8),
            TerminalText(
              cfg.title,
              fontSize: 13,
              color: cfg.color,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resposta narrativa principal
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
                color: cfg.color.withValues(alpha: 0.05),
              ),
              child: TerminalText(
                '"${result.responseDetail}"',
                fontSize: 10,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Quem aceitou / recusou individualmente (se houver)
            if (result.acceptedIds != null &&
                result.acceptedIds!.isNotEmpty) ...[
              TerminalText(
                '${result.acceptedIds!.length} membro(s) confirmado(s)',
                fontSize: 9,
                color: AppTheme.green,
              ),
            ],
            if (result.refusedIds != null && result.refusedIds!.isNotEmpty) ...[
              const SizedBox(height: 4),
              TerminalText(
                '${result.refusedIds!.length} membro(s) recusou(aram)',
                fontSize: 9,
                color: AppTheme.red,
              ),
            ],

            // Motivo resumido (se vier no model)
            if (result.reason != null) ...[
              const SizedBox(height: 8),
              TerminalText(
                result.reason!,
                fontSize: 8,
                color: AppTheme.textDim,
              ),
            ],
          ],
        ),
        actions: [
          TerminalButton(label: 'FECHAR', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }
}

/// Handle visual do bottom sheet
class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 3,
      color: AppTheme.border,
      margin: const EdgeInsets.only(bottom: 12),
    ),
  );
}

/// Texto de sinergia com cor automática
class _SynergyText extends StatelessWidget {
  final double synergy;
  const _SynergyText({required this.synergy});

  @override
  Widget build(BuildContext context) {
    final label = synergy > 30
        ? '(Excelente)'
        : synergy > 10
        ? '(Boa)'
        : synergy < -10
        ? '(Ruim)'
        : '(Neutra)';
    final color = synergy > 30
        ? AppTheme.green
        : synergy > 10
        ? AppTheme.yellow
        : synergy < -10
        ? AppTheme.red
        : AppTheme.textSecondary;

    return TerminalText(
      'Sinergia: ${synergy.toStringAsFixed(0)}% $label',
      fontSize: 9,
      color: color,
    );
  }
}

/// Linha de risco com cor automática baseada em threshold
class _RiskText extends StatelessWidget {
  final String label;
  final double? chance;
  final double threshold;

  const _RiskText(this.label, this.chance, {this.threshold = double.infinity});

  @override
  Widget build(BuildContext context) {
    if (chance == null) return const SizedBox.shrink();
    final pct = (chance! * 100).toStringAsFixed(0);
    return TerminalText(
      '$label: $pct%',
      fontSize: 8,
      color: chance! > threshold ? AppTheme.red : AppTheme.textDim,
    );
  }
}

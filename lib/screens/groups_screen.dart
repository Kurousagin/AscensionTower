import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../models/group_model.dart';
import '../models/tower.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

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
                ...gp.groups.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GroupCard(gp: gp, group: g),
                  ),
                ),
              const SizedBox(height: 12),
              _SuggestionHistory(gp: gp),
              const SizedBox(height: 12),
              const _HowItWorksCard(),
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
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'ESQUADROES & GRUPOS',
            fontSize: 14,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          TerminalText(
            'Grupos ativos: ${gp.groups.length} | Membros em grupos: $membersInGroups',
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
          if (gp.suspiciousNpcs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TerminalText(
                'ALERTA: ${gp.suspiciousNpcs.length} habitante(s) suspeito(s) na comunidade',
                fontSize: 9,
                color: AppTheme.red,
              ),
            ),
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
    return TerminalCard(
      title: 'CRIAR NOVO GRUPO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'Organize seus melhores NPCs em esquadroes para expedicoes coordenadas.',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          TerminalButton(
            label: 'FORMAR ESQUADRAO',
            icon: Icons.group_add,
            expanded: true,
            onPressed: gp.aliveNpcs.length >= 2
                ? () => _CreateGroupDialog.show(context, gp)
                : null,
          ),
        ],
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

    final borderColor = group.cohesion > 70
        ? AppTheme.green
        : group.cohesion > 40
            ? AppTheme.yellow
            : AppTheme.red;

    return TerminalCard(
      title: '${group.name} (${group.role.label})',
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupStats(
            group: group,
            aliveMembers: aliveMembers,
            avgPower: avgPower,
            avgLoyalty: avgLoyalty,
            avgFatigue: avgFatigue,
            exhaustedCount: exhaustedCount,
          ),
          if (leader != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TerminalText(
                'Lider: ${leader.name} (${leader.profession.label})',
                fontSize: 9,
                color: AppTheme.cyan,
              ),
            ),
          const SizedBox(height: 6),
          ...aliveMembers.map((npc) => _MemberRow(npc: npc, group: group)),
          const SizedBox(height: 8),
          _GroupActions(gp: gp, group: group, aliveMembers: aliveMembers),
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

class _GroupStats extends StatelessWidget {
  final NpcGroup group;
  final List<Npc> aliveMembers;
  final double avgPower, avgLoyalty, avgFatigue;
  final int exhaustedCount;

  const _GroupStats({
    required this.group,
    required this.aliveMembers,
    required this.avgPower,
    required this.avgLoyalty,
    required this.avgFatigue,
    required this.exhaustedCount,
  });

  @override
  Widget build(BuildContext context) {
    final fatigueColor = avgFatigue >= 70
        ? AppTheme.red
        : avgFatigue >= 50
            ? AppTheme.orange
            : avgFatigue >= 30
                ? AppTheme.yellow
                : AppTheme.green;

    final exhaustedSuffix = exhaustedCount > 0
        ? ' ($exhaustedCount exausto${exhaustedCount > 1 ? "s" : ""})'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            TerminalText(
              'Membros: ${aliveMembers.length}/${group.memberIds.length}',
              fontSize: 9, color: AppTheme.textSecondary,
            ),
            TerminalText(
              'Coesao: ${group.cohesion.toStringAsFixed(0)}%',
              fontSize: 9,
              color: group.cohesion > 70 ? AppTheme.green
                  : group.cohesion > 40 ? AppTheme.yellow : AppTheme.red,
            ),
            TerminalText('Missoes: ${group.missionsCompleted}',
                fontSize: 9, color: AppTheme.cyan),
            TerminalText('Baixas: ${group.casualties}',
                fontSize: 9, color: AppTheme.red),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            TerminalText(
              'Poder medio: ${avgPower.toStringAsFixed(1)}',
              fontSize: 9, color: AppTheme.orange,
            ),
            TerminalText(
              'Lealdade media: ${avgLoyalty.toStringAsFixed(0)}',
              fontSize: 9, color: AppTheme.yellow,
            ),
            TerminalText(
              'Fadiga media: ${avgFatigue.toStringAsFixed(0)}%$exhaustedSuffix',
              fontSize: 9, color: fatigueColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final Npc npc;
  final NpcGroup group;
  const _MemberRow({required this.npc, required this.group});

  @override
  Widget build(BuildContext context) {
    final isLeader = npc.id == group.leaderId;
    final fatigueColor = npc.fatigue >= 90
        ? const Color(0xFFFF0044)
        : npc.fatigue >= 70 ? AppTheme.red
        : npc.fatigue >= 50 ? AppTheme.orange
        : npc.fatigue >= 30 ? AppTheme.yellow
        : AppTheme.green;

    final statusSuffix = npc.isIncapacitated ? ' [INCAP]'
        : npc.isExhausted ? ' [EXAU]'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TerminalText(
              '${isLeader ? "[L] " : "  "}${npc.name} | ${npc.profession.label}'
              ' | PWR:${npc.attributes.combatPower.toStringAsFixed(1)} | Leal:${npc.loyalty.toStringAsFixed(0)}$statusSuffix',
              fontSize: 8,
              color: npc.isIncapacitated
                  ? AppTheme.red.withValues(alpha: 0.5)
                  : npc.isSuspicious ? AppTheme.red : AppTheme.textSecondary,
            ),
          ),
          TerminalText(
            'F:${npc.fatigue.toStringAsFixed(0)}',
            fontSize: 8, color: fatigueColor,
          ),
          if (npc.isSuspicious)
            const TerminalText(' [!]', fontSize: 8, color: AppTheme.red),
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
    return Column(
      children: [
        if (gp.nextFloor != null && aliveMembers.length >= 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TerminalButton(
              label: 'DESAFIAR ANDAR ${gp.nextFloor!.number}',
              icon: Icons.rocket_launch,
              color: AppTheme.orange,
              expanded: true,
              onPressed: () => _ExpeditionDialog.confirm(context, gp, group),
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
              onPressed: () => _ReexploreDialog.show(context, gp, group),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TerminalButton(
                label: 'SUGERIR TREINO',
                icon: Icons.fitness_center,
                color: AppTheme.cyan,
                onPressed: gp.clearedFloors.isNotEmpty || gp.hasTrainingField
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
    final recent = gp.trainingSuggestions.reversed.take(10).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return TerminalCard(
      title: 'HISTORICO DE SUGESTOES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recent.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: TerminalText(
            '[${s.response.label}] ${s.responseDetail}',
            fontSize: 8,
            color: _responseColors[s.response] ?? AppTheme.textSecondary,
          ),
        )).toList(),
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
    return const TerminalCard(
      child: Column(
        children: [
          TerminalText('Nenhum grupo formado.', fontSize: 11, color: AppTheme.textDim),
          SizedBox(height: 4),
          TerminalText(
            'Forme grupos para coordenar expedicoes, treinos e defesas. '
            'Grupos com alta coesao trabalham melhor juntos.',
            fontSize: 9, color: AppTheme.textDim,
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return const TerminalCard(
      title: 'COMO FUNCIONA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('SUA UNICA ACAO DIRETA:', AppTheme.orange),
          SizedBox(height: 4),
          TerminalText(
            'Escolher quem desafia novos andares e quem re-explora para coletar recursos.',
            fontSize: 9, color: AppTheme.textPrimary,
          ),
          SizedBox(height: 8),
          _SectionHeader('ACOES DISPONIVEIS:', AppTheme.cyan),
          SizedBox(height: 4),
          TerminalText('1. DESAFIAR ANDAR - Enviar grupo para conquistar o proximo andar',
              fontSize: 9, color: AppTheme.orange),
          TerminalText('2. COLETAR RECURSOS - Re-explorar andares conquistados',
              fontSize: 9, color: AppTheme.green),
          TerminalText('3. SUGERIR TREINO - NPCs podem aceitar ou recusar',
              fontSize: 9, color: AppTheme.cyan),
          SizedBox(height: 8),
          _SectionHeader('HIERARQUIA DE DECISAO:', AppTheme.yellow),
          SizedBox(height: 4),
          TerminalText(
            'Voce NAO diz aos NPCs qual andar explorar - voce os DESIGNA como lideres.',
            fontSize: 9, color: AppTheme.textSecondary,
          ),
          TerminalText(
            'NPCs decidem autonomamente treino, relacionamentos e decisoes pessoais.',
            fontSize: 9, color: AppTheme.textSecondary,
          ),
          SizedBox(height: 8),
          _SectionHeader('FATORES DE DECISAO (para treino):', AppTheme.textDim),
          SizedBox(height: 4),
          TerminalText(
            'Lealdade, fadiga, moral, ambicao, medo, relacionamentos, confianca, experiencias passadas e traumas.',
            fontSize: 9, color: AppTheme.textDim,
          ),
          SizedBox(height: 8),
          _SectionHeader('IMPACTO POLITICO:', AppTheme.red),
          SizedBox(height: 4),
          TerminalText(
            'Favoritismo gera ressentimento. Enviar os mesmos NPCs sempre pode desgasta-los. '
            'Perdas em expedicoes abalam moral e confianca.',
            fontSize: 9, color: AppTheme.textDim,
          ),
        ],
      ),
    );
  }
}

/// Helper para headers de secao dentro do card
class _SectionHeader extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionHeader(this.text, this.color);

  @override
  Widget build(BuildContext context) => TerminalText(
        text,
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.bold,
      );
}

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
          fontSize: 13, color: AppTheme.orange, fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('Destino: Andar ${floor.number} (${floor.type.label})',
                fontSize: 11, color: AppTheme.textPrimary),
            TerminalText('Dificuldade: ${floor.scaledDifficulty.toStringAsFixed(1)}',
                fontSize: 10, color: AppTheme.red),
            const SizedBox(height: 4),
            TerminalText('Membros vivos: ${aliveIds.length}',
                fontSize: 10, color: AppTheme.textSecondary),
            TerminalText(
              'Poder: ${totalPower.toStringAsFixed(1)} / ${floor.recommendedPower.toStringAsFixed(1)} '
              '(${powerPct.toStringAsFixed(0)}%)',
              fontSize: 10,
              color: powerPct >= 100 ? AppTheme.green
                  : powerPct >= 60 ? AppTheme.yellow : AppTheme.red,
            ),
            TerminalText(
              'Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
              fontSize: 10, color: AppTheme.red,
            ),
            const SizedBox(height: 8),
            if (powerPct < 60)
              const TerminalText('PERIGO: Poder muito abaixo do recomendado!',
                  fontSize: 9, color: AppTheme.red),
            const TerminalText(
              'MORTE PERMANENTE. Eles podem nao voltar.',
              fontSize: 10, color: AppTheme.red, fontWeight: FontWeight.bold,
            ),
          ],
        ),
        actions: [
          TerminalButton(label: 'CANCELAR', color: AppTheme.textDim,
              onPressed: () => Navigator.pop(ctx)),
          TerminalButton(
            label: 'ENVIAR',
            icon: Icons.rocket_launch,
            color: AppTheme.orange,
            onPressed: () {
              Navigator.pop(ctx);
              final result = gp.sendGroupExpedition(group.id);
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
          side: BorderSide(color: result.victory ? AppTheme.green : AppTheme.red),
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
            TerminalText('RE-EXPLORAR COM: ${widget.group.name}',
                fontSize: 12, color: AppTheme.green, fontWeight: FontWeight.bold),
            const SizedBox(height: 4),
            const TerminalText('Escolha um andar conquistado para coletar recursos:',
                fontSize: 9, color: AppTheme.textDim),
            if (_selectedFloor != null) _buildAnalysis(),
            const SizedBox(height: 8),

            // Lista de andares com scroll independente
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.gp.clearedFloors.map(_buildFloorOption).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),
            TerminalButton(
              label: _selectedFloor != null ? 'ENVIAR COLETORES' : 'SELECIONE UM ANDAR',
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
    final floor = widget.gp.clearedFloors.firstWhere((f) => f.number == _selectedFloor);
    final aliveIds = _aliveIds;
    final costPerNpc = widget.gp.engine.reexploreCostPerNpc(_selectedFloor!);
    final totalCost = aliveIds.length * costPerNpc;
    final synergy = widget.gp.engine.previewGroupSynergy(aliveIds) * 100;
    final personalityMod = widget.gp.engine.previewPartyPersonalityMod(aliveIds) * 100;
    final attributeYield = widget.gp.engine.previewPartyAttributeYield(aliveIds, floor.type);
    final eventChances = widget.gp.engine.previewEventChances(aliveIds, floor);

    final estimatedFood = (floor.farmableResources['food'] ?? 0.0);
    final totalYield = attributeYield * (1 + synergy / 100) * (1 + personalityMod / 100);
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
          const TerminalText('ANALISE DA EXPEDICAO',
              fontSize: 11, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          TerminalText('Membros: ${aliveIds.length} NPCs',
              fontSize: 9, color: AppTheme.textSecondary),
          TerminalText(
            'Custo: ${totalCost.toStringAsFixed(1)} comida (${costPerNpc.toStringAsFixed(1)}/NPC)',
            fontSize: 9, color: AppTheme.orange,
          ),
          _SynergyText(synergy: synergy),
          TerminalText(
            'Eficiencia: ${(totalYield * 100).toStringAsFixed(0)}%'
            ' (atrib: ${(attributeYield * 100).toStringAsFixed(0)}%,'
            ' pers: ${personalityMod >= 0 ? "+" : ""}${personalityMod.toStringAsFixed(0)}%)',
            fontSize: 9,
            color: totalYield > 1.3 ? AppTheme.green
                : totalYield > 1.0 ? AppTheme.yellow : AppTheme.orange,
          ),
          const Divider(color: AppTheme.border, height: 12),
          const TerminalText('Estimativa de retorno (comida):', fontSize: 9, color: AppTheme.textDim),
          TerminalText(
            'Lucro: ${netFood >= 0 ? "+" : ""}${netFood.toStringAsFixed(1)}'
            ' ${netFood < 0 ? "(PREJUIZO)" : netFood < totalCost * 0.5 ? "(baixo)" : "(bom)"}',
            fontSize: 9,
            color: netFood < 0 ? AppTheme.red
                : netFood < totalCost * 0.5 ? AppTheme.orange : AppTheme.green,
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
              'Traicao: ${((eventChances['traicao'] ?? 0) * 100).toStringAsFixed(0)}% (!)',
              fontSize: 8, color: AppTheme.red,
            ),
          TerminalText(
            'Ameaca Reativada: ${threatPct.toStringAsFixed(0)}%',
            fontSize: 8,
            color: floor.timesReexplored > 3 ? AppTheme.red : AppTheme.yellow,
          ),
          if ((eventChances['evento_raro'] ?? 0) > 0)
            TerminalText(
              'Evento Raro (2x recursos): ${((eventChances['evento_raro'] ?? 0) * 100).toStringAsFixed(0)}%',
              fontSize: 8, color: AppTheme.green,
            ),
        ],
      ),
    );
  }

  Widget _buildFloorOption(TowerFloor floor) {
    final isSelected = _selectedFloor == floor.number;
    final threatPct = ((0.05 + floor.timesReexplored * 0.02) * 100).toStringAsFixed(0);
    final resStr = floor.farmableResources.entries
        .map((e) => '${e.key}: ~${e.value.toStringAsFixed(0)}')
        .join(', ');

    return GestureDetector(
      onTap: () => setState(() => _selectedFloor = floor.number),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.green : AppTheme.border),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? AppTheme.green.withValues(alpha: 0.05) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TerminalText('Andar ${floor.number} (${floor.type.label})',
                    fontSize: 10,
                    color: isSelected ? AppTheme.green : AppTheme.textPrimary),
                const Spacer(),
                TerminalText('Risco: $threatPct%', fontSize: 8, color: AppTheme.yellow),
              ],
            ),
            TerminalText('Recursos base: $resStr', fontSize: 8, color: AppTheme.cyan),
          ],
        ),
      ),
    );
  }

  void _submit() {
    Navigator.pop(context);
    final result = widget.gp.sendGroupReexploration(widget.group.id, _selectedFloor!);
    if (result != null && context.mounted) {
      _ReexploreResultDialog.show(context, result);
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
          result.casualties.isNotEmpty ? 'AMEACA REATIVADA!' : 'COLETA CONCLUIDA',
          fontSize: 14,
          color: result.casualties.isNotEmpty ? AppTheme.red : AppTheme.green,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('Andar ${result.floorNumber}',
                fontSize: 12, color: AppTheme.textPrimary),
            const SizedBox(height: 8),
            const TerminalText('Recursos coletados:', fontSize: 10, color: AppTheme.cyan),
            TerminalText(resStr, fontSize: 10, color: AppTheme.green),
            if (result.casualties.isNotEmpty) ...[
              const SizedBox(height: 8),
              TerminalText('BAIXAS: ${result.casualties.length}',
                  fontSize: 10, color: AppTheme.red, fontWeight: FontWeight.bold),
            ],
            if (result.discoveries.isNotEmpty) ...[
              const SizedBox(height: 8),
              TerminalText('Descobertas: ${result.discoveries.join(', ')}',
                  fontSize: 10, color: AppTheme.yellow),
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

  bool get _canCreate => _selectedIds.length >= 2 && _nameController.text.isNotEmpty;

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
            const TerminalText('FORMAR NOVO ESQUADRAO',
                fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 12),
            _buildRoleSelector(),
            if (_selectedIds.length >= 2) _buildGroupAnalysis(),
            const SizedBox(height: 12),
            TerminalText(
              'Selecionar membros (${_selectedIds.length} selecionados):',
              fontSize: 10, color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            ...widget.gp.aliveNpcs.where((n) => n.groupId == null).map(_buildNpcOption),
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
        fontFamily: 'FiraCode', fontSize: 12, color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Nome do grupo...',
        hintStyle: const TextStyle(
          color: AppTheme.textDim, fontFamily: 'FiraCode', fontSize: 11,
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
        const TerminalText('Funcao:', fontSize: 10, color: AppTheme.textSecondary),
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
                child: TerminalText(role.label, fontSize: 9,
                    color: active ? AppTheme.cyan : AppTheme.textDim),
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
    final personalityMod = widget.gp.engine.previewPartyPersonalityMod(ids) * 100;
    final npcs = ids.map((id) => widget.gp.aliveNpcs.firstWhere((n) => n.id == id)).toList();
    final avgPower = npcs.map((n) => n.attributes.combatPower).reduce((a, b) => a + b) / npcs.length;
    final avgLoyalty = npcs.map((n) => n.loyalty).reduce((a, b) => a + b) / npcs.length;
    final avgFatigue = npcs.map((n) => n.fatigue).reduce((a, b) => a + b) / npcs.length;
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
          const TerminalText('ANALISE DE EFICIENCIA',
              fontSize: 11, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          _SynergyText(synergy: synergy),
          TerminalText(
            'Dinamica de grupo: ${personalityMod >= 0 ? "+" : ""}${personalityMod.toStringAsFixed(0)}%'
            ' ${personalityMod > 10 ? "(Harmoniosa)" : personalityMod < -10 ? "(Conflituosa)" : "(Equilibrada)"}',
            fontSize: 9,
            color: personalityMod > 10 ? AppTheme.green
                : personalityMod < -10 ? AppTheme.red : AppTheme.textSecondary,
          ),
          const Divider(color: AppTheme.border, height: 12),
          TerminalText('Poder medio: ${avgPower.toStringAsFixed(1)}', fontSize: 9,
              color: avgPower > 15 ? AppTheme.green : avgPower > 10 ? AppTheme.yellow : AppTheme.orange),
          TerminalText('Lealdade media: ${avgLoyalty.toStringAsFixed(0)}', fontSize: 9,
              color: avgLoyalty > 70 ? AppTheme.green : avgLoyalty > 50 ? AppTheme.yellow : AppTheme.orange),
          TerminalText(
            'Fadiga media: ${avgFatigue.toStringAsFixed(0)}%'
            '${exhaustedCount > 0 ? " ($exhaustedCount exausto${exhaustedCount > 1 ? "s" : ""})" : ""}',
            fontSize: 9,
            color: avgFatigue >= 70 ? AppTheme.red
                : avgFatigue >= 50 ? AppTheme.orange
                : avgFatigue >= 30 ? AppTheme.yellow : AppTheme.green,
          ),
          if (hasSuspicious) ...[
            const SizedBox(height: 4),
            const TerminalText('ALERTA: Membro suspeito no grupo!',
                fontSize: 9, color: AppTheme.red, fontWeight: FontWeight.bold),
          ],
          if (exhaustedCount > 0) ...[
            const SizedBox(height: 4),
            TerminalText(
              'AVISO: $exhaustedCount membro${exhaustedCount > 1 ? "s" : ""} '
              'exausto${exhaustedCount > 1 ? "s" : ""}',
              fontSize: 9, color: AppTheme.orange,
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
        if (selected) _selectedIds.remove(npc.id);
        else _selectedIds.add(npc.id);
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
                  TerminalText(npc.name, fontSize: 10, color: AppTheme.textPrimary),
                  TerminalText(
                    'PWR:${npc.attributes.combatPower.toStringAsFixed(1)}'
                    ' | ${npc.profession.label}'
                    ' | Leal:${npc.loyalty.toStringAsFixed(0)}'
                    ' | Fad:${npc.fatigue.toStringAsFixed(0)}%',
                    fontSize: 8, color: AppTheme.textDim,
                  ),
                ],
              ),
            ),
            if (npc.isSuspicious)
              const TerminalText('[SUSPEITO]', fontSize: 8, color: AppTheme.red),
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
  int? _selectedFloor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BottomSheetHandle(),
          TerminalText('SUGERIR TREINO: ${widget.group.name}',
              fontSize: 12, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          const TerminalText('Os NPCs podem aceitar, recusar ou ignorar.',
              fontSize: 9, color: AppTheme.textDim),
          const SizedBox(height: 12),
          // Lista de andares com scroll independente
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.gp.hasTrainingField)
                    _buildFloorOption(-1, 'Campo de Treino (seguro, ganhos lentos)', AppTheme.green),
                  ...widget.gp.clearedFloors.map((floor) => _buildFloorOption(
                    floor.number,
                    'Andar ${floor.number} (${floor.type.label}) - Risco moderado',
                    AppTheme.textSecondary,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TerminalButton(
            label: 'SUGERIR',
            icon: Icons.send,
            expanded: true,
            color: AppTheme.green,
            onPressed: _selectedFloor != null ? _submit : null,
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
        ),
        child: TerminalText(label, fontSize: 10, color: isSelected ? AppTheme.green : labelColor),
      ),
    );
  }

  void _submit() {
    widget.gp.suggestTraining(widget.group.id, 'group', _selectedFloor!);
    Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────
// WIDGETS AUXILIARES REUTILIZÁVEIS
// ─────────────────────────────────────────────

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
    final label = synergy > 30 ? '(Excelente)'
        : synergy > 10 ? '(Boa)'
        : synergy < -10 ? '(Ruim)'
        : '(Neutra)';
    final color = synergy > 30 ? AppTheme.green
        : synergy > 10 ? AppTheme.yellow
        : synergy < -10 ? AppTheme.red
        : AppTheme.textSecondary;

    return TerminalText(
      'Sinergia: ${synergy.toStringAsFixed(0)}% $label',
      fontSize: 9, color: color,
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
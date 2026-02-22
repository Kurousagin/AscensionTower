import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../models/group_model.dart';
import '../models/tower.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import 'dart:math';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        return ScanlineOverlay(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(gp),
                const SizedBox(height: 12),
                _buildCreateGroup(context, gp),
                const SizedBox(height: 12),
                if (gp.groups.isEmpty)
                  _buildNoGroups()
                else
                  ...gp.groups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildGroupCard(context, gp, g),
                  )),
                const SizedBox(height: 12),
                _buildSuggestionHistory(gp),
                const SizedBox(height: 12),
                _buildHowItWorks(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(GameProvider gp) {
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText('ESQUADROES & GRUPOS', fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          TerminalText(
            'Grupos ativos: ${gp.groups.length} | Membros em grupos: ${gp.aliveNpcs.where((n) => n.groupId != null).length}',
            fontSize: 10, color: AppTheme.textSecondary,
          ),
          if (gp.suspiciousNpcs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TerminalText(
                'ALERTA: ${gp.suspiciousNpcs.length} habitante(s) suspeito(s) na comunidade',
                fontSize: 9, color: AppTheme.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateGroup(BuildContext context, GameProvider gp) {
    return TerminalCard(
      title: 'CRIAR NOVO GRUPO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'Organize seus melhores NPCs em esquadroes para expedicoes coordenadas.',
            fontSize: 9, color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          TerminalButton(
            label: 'FORMAR ESQUADRAO',
            icon: Icons.group_add,
            expanded: true,
            onPressed: gp.aliveNpcs.length >= 2 ? () => _showCreateGroupDialog(context, gp) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNoGroups() {
    return TerminalCard(
      child: const Column(
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

  Widget _buildGroupCard(BuildContext context, GameProvider gp, NpcGroup group) {
    final members = group.memberIds
        .map((id) => gp.allNpcs.where((n) => n.id == id).firstOrNull)
        .whereType<Npc>()
        .toList();
    final aliveMembers = members.where((n) => n.alive).toList();
    final leader = group.leaderId != null
        ? gp.allNpcs.where((n) => n.id == group.leaderId).firstOrNull
        : null;

    final avgPower = aliveMembers.isEmpty ? 0.0 :
        aliveMembers.map((n) => n.attributes.combatPower).reduce((a, b) => a + b) / aliveMembers.length;
    final avgLoyalty = aliveMembers.isEmpty ? 0.0 :
        aliveMembers.map((n) => n.loyalty).reduce((a, b) => a + b) / aliveMembers.length;

    return TerminalCard(
      title: '${group.name} (${group.role.label})',
      borderColor: group.cohesion > 70 ? AppTheme.green : group.cohesion > 40 ? AppTheme.yellow : AppTheme.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12, runSpacing: 4,
            children: [
              TerminalText('Membros: ${aliveMembers.length}/${group.memberIds.length}', fontSize: 9, color: AppTheme.textSecondary),
              TerminalText('Coesao: ${group.cohesion.toStringAsFixed(0)}%', fontSize: 9,
                  color: group.cohesion > 70 ? AppTheme.green : group.cohesion > 40 ? AppTheme.yellow : AppTheme.red),
              TerminalText('Missoes: ${group.missionsCompleted}', fontSize: 9, color: AppTheme.cyan),
              TerminalText('Baixas: ${group.casualties}', fontSize: 9, color: AppTheme.red),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12, runSpacing: 4,
            children: [
              TerminalText('Poder medio: ${avgPower.toStringAsFixed(1)}', fontSize: 9, color: AppTheme.orange),
              TerminalText('Lealdade media: ${avgLoyalty.toStringAsFixed(0)}', fontSize: 9, color: AppTheme.yellow),
              Builder(builder: (_) {
                final avgFatigue = aliveMembers.isEmpty ? 0.0 :
                    aliveMembers.map((n) => n.fatigue).reduce((a, b) => a + b) / aliveMembers.length;
                final exhausted = aliveMembers.where((n) => n.isExhausted).length;
                return TerminalText(
                  'Fadiga media: ${avgFatigue.toStringAsFixed(0)}%${exhausted > 0 ? " ($exhausted exausto${exhausted > 1 ? "s" : ""})": ""}',
                  fontSize: 9,
                  color: avgFatigue >= 70 ? AppTheme.red : avgFatigue >= 50 ? AppTheme.orange : avgFatigue >= 30 ? AppTheme.yellow : AppTheme.green,
                );
              }),
            ],
          ),
          if (leader != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TerminalText('Lider: ${leader.name} (${leader.profession.label})',
                  fontSize: 9, color: AppTheme.cyan),
            ),
          const SizedBox(height: 6),
          ...aliveMembers.map((npc) {
            final fatigueColor = npc.fatigue >= 90 ? const Color(0xFFFF0044) :
                npc.fatigue >= 70 ? AppTheme.red :
                npc.fatigue >= 50 ? AppTheme.orange :
                npc.fatigue >= 30 ? AppTheme.yellow : AppTheme.green;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: TerminalText(
                      '${npc.id == group.leaderId ? "[L] " : "  "}${npc.name} | ${npc.profession.tag} | PWR:${npc.attributes.combatPower.toStringAsFixed(1)} | Leal:${npc.loyalty.toStringAsFixed(0)}${npc.isIncapacitated ? " [INCAP]" : npc.isExhausted ? " [EXAU]" : ""}',
                      fontSize: 8,
                      color: npc.isIncapacitated ? AppTheme.red.withValues(alpha: 0.5) : npc.isSuspicious ? AppTheme.red : AppTheme.textSecondary,
                    ),
                  ),
                  TerminalText('F:${npc.fatigue.toStringAsFixed(0)}', fontSize: 8, color: fatigueColor),
                  if (npc.isSuspicious)
                    const TerminalText(' [!]', fontSize: 8, color: AppTheme.red),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          // === ACOES PRINCIPAIS DO GRUPO ===
          if (gp.nextFloor != null && aliveMembers.length >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TerminalButton(
                label: 'DESAFIAR ANDAR ${gp.nextFloor!.number}',
                icon: Icons.rocket_launch,
                color: AppTheme.orange,
                expanded: true,
                onPressed: () => _confirmGroupExpedition(context, gp, group),
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
                onPressed: () => _showGroupReexploreDialog(context, gp, group),
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
                      ? () => _showSuggestTrainingDialog(context, gp, group)
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
      ),
    );
  }

  Widget _buildSuggestionHistory(GameProvider gp) {
    final recent = gp.trainingSuggestions.reversed.take(10).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return TerminalCard(
      title: 'HISTORICO DE SUGESTOES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recent.map((s) {
          Color color;
          switch (s.response) {
            case TrainingResponse.accepted: color = AppTheme.green; break;
            case TrainingResponse.refused: color = AppTheme.red; break;
            case TrainingResponse.negotiated: color = AppTheme.yellow; break;
            case TrainingResponse.ignored: color = AppTheme.textDim; break;
            default: color = AppTheme.textSecondary;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: TerminalText(
              '[${s.response.label}] ${s.responseDetail}',
              fontSize: 8, color: color,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return TerminalCard(
      title: 'COMO FUNCIONA',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText('SUA UNICA ACAO DIRETA:', fontSize: 10, color: AppTheme.orange, fontWeight: FontWeight.bold),
          SizedBox(height: 4),
          TerminalText('Escolher quem desafia novos andares e quem re-explora para coletar recursos.', fontSize: 9, color: AppTheme.textPrimary),
          SizedBox(height: 8),
          TerminalText('ACOES DISPONIVEIS:', fontSize: 10, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          SizedBox(height: 4),
          TerminalText('1. DESAFIAR ANDAR - Enviar grupo para conquistar o proximo andar', fontSize: 9, color: AppTheme.orange),
          TerminalText('2. COLETAR RECURSOS - Re-explorar andares conquistados', fontSize: 9, color: AppTheme.green),
          TerminalText('3. SUGERIR TREINO - NPCs podem aceitar ou recusar', fontSize: 9, color: AppTheme.cyan),
          SizedBox(height: 8),
          TerminalText('HIERARQUIA DE DECISAO:', fontSize: 10, color: AppTheme.yellow, fontWeight: FontWeight.bold),
          SizedBox(height: 4),
          TerminalText('Voce NAO diz aos NPCs qual andar explorar - voce os DESIGNA como lideres.',
              fontSize: 9, color: AppTheme.textSecondary),
          TerminalText('NPCs decidem autonomamente treino, relacionamentos e decisoes pessoais.',
              fontSize: 9, color: AppTheme.textSecondary),
          SizedBox(height: 8),
          TerminalText('FATORES DE DECISAO (para treino):', fontSize: 10, color: AppTheme.textDim, fontWeight: FontWeight.bold),
          SizedBox(height: 4),
          TerminalText('Lealdade, fadiga, moral, ambicao, medo, relacionamentos, confianca, experiencias passadas e traumas.',
              fontSize: 9, color: AppTheme.textDim),
          SizedBox(height: 8),
          TerminalText('IMPACTO POLITICO:', fontSize: 10, color: AppTheme.red, fontWeight: FontWeight.bold),
          SizedBox(height: 4),
          TerminalText('Favoritismo gera ressentimento. Enviar os mesmos NPCs sempre pode desgasta-los. '
              'Perdas em expedicoes abalam moral e confianca.',
              fontSize: 9, color: AppTheme.textDim),
        ],
      ),
    );
  }

  // ==================== DIALOGOS ====================

  /// Confirma envio de grupo para desafiar o proximo andar
  void _confirmGroupExpedition(BuildContext context, GameProvider gp, NpcGroup group) {
    final floor = gp.nextFloor;
    if (floor == null) return;

    final aliveMembers = group.memberIds
        .where((id) => gp.allNpcs.any((n) => n.id == id && n.alive))
        .toList();
    final totalPower = aliveMembers
        .map((id) => gp.allNpcs.firstWhere((n) => n.id == id))
        .fold<double>(0.0, (sum, n) => sum + n.attributes.combatPower);
    final powerPct = floor.recommendedPower > 0 ? (totalPower / floor.recommendedPower * 100) : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.orange),
        ),
        title: TerminalText('ENVIAR ${group.name.toUpperCase()}?',
            fontSize: 13, color: AppTheme.orange, fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('Destino: Andar ${floor.number} (${floor.type.label})', fontSize: 11, color: AppTheme.textPrimary),
            TerminalText('Dificuldade: ${floor.scaledDifficulty.toStringAsFixed(1)}', fontSize: 10, color: AppTheme.red),
            const SizedBox(height: 4),
            TerminalText('Membros vivos: ${aliveMembers.length}', fontSize: 10, color: AppTheme.textSecondary),
            TerminalText('Poder: ${totalPower.toStringAsFixed(1)} / ${floor.recommendedPower.toStringAsFixed(1)} (${powerPct.toStringAsFixed(0)}%)',
                fontSize: 10, color: powerPct >= 100 ? AppTheme.green : powerPct >= 60 ? AppTheme.yellow : AppTheme.red),
            TerminalText('Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%', fontSize: 10, color: AppTheme.red),
            const SizedBox(height: 8),
            if (powerPct < 60)
              const TerminalText('PERIGO: Poder muito abaixo do recomendado!',
                  fontSize: 9, color: AppTheme.red),
            const TerminalText('MORTE PERMANENTE. Eles podem nao voltar.',
                fontSize: 10, color: AppTheme.red, fontWeight: FontWeight.bold),
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
              Navigator.pop(ctx);
              final result = gp.sendGroupExpedition(group.id);
              if (result != null) {
                _showExpeditionResult(context, result);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Mostra resultado de expedição
  void _showExpeditionResult(BuildContext context, TowerChallenge result) {
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
                Color color = AppTheme.textSecondary;
                if (line.startsWith('>>') && result.victory) color = AppTheme.green;
                if (line.startsWith('>>') && !result.victory) color = AppTheme.red;
                if (line.contains('[X]')) color = AppTheme.red;
                if (line.contains('[O]')) color = AppTheme.green;
                if (line.startsWith('===')) color = AppTheme.cyan;
                if (line.startsWith('>')) color = AppTheme.orange;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: TerminalText(line, fontSize: 9, color: color),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TerminalButton(
            label: 'FECHAR',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  /// Dialogo para escolher andar para re-explorar com grupo
  void _showGroupReexploreDialog(BuildContext context, GameProvider gp, NpcGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          int? selectedFloor;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 3, color: AppTheme.border, margin: const EdgeInsets.only(bottom: 12))),
                TerminalText('RE-EXPLORAR COM: ${group.name}', fontSize: 12, color: AppTheme.green, fontWeight: FontWeight.bold),
                const SizedBox(height: 4),
                const TerminalText('Escolha um andar conquistado para coletar recursos:', fontSize: 9, color: AppTheme.textDim),
                const SizedBox(height: 12),
                ...gp.clearedFloors.map((floor) {
                  final threatPct = ((0.05 + floor.timesReexplored * 0.02) * 100).toStringAsFixed(0);
                  final resStr = floor.farmableResources.entries
                      .map((e) => '${e.key}: ~${e.value.toStringAsFixed(0)}')
                      .join(', ');
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedFloor = floor.number),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: selectedFloor == floor.number ? AppTheme.green : AppTheme.border),
                        borderRadius: BorderRadius.circular(4),
                        color: selectedFloor == floor.number ? AppTheme.green.withValues(alpha: 0.05) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            TerminalText('Andar ${floor.number} (${floor.type.label})', fontSize: 10,
                                color: selectedFloor == floor.number ? AppTheme.green : AppTheme.textPrimary),
                            const Spacer(),
                            TerminalText('Risco: $threatPct%', fontSize: 8, color: AppTheme.yellow),
                          ]),
                          TerminalText('Recursos: $resStr', fontSize: 8, color: AppTheme.cyan),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TerminalButton(
                  label: selectedFloor != null ? 'ENVIAR COLETORES' : 'SELECIONE UM ANDAR',
                  icon: Icons.search,
                  expanded: true,
                  color: AppTheme.green,
                  onPressed: selectedFloor != null
                      ? () {
                          Navigator.pop(ctx);
                          final result = gp.sendGroupReexploration(group.id, selectedFloor!);
                          if (result != null) {
                            _showReexploreResultDialog(context, result);
                          }
                        }
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Mostra resultado da re-exploracao
  void _showReexploreResultDialog(BuildContext context, FloorExplorationResult result) {
    final resStr = result.resourcesGained.entries
        .map((e) => '${e.key}: +${e.value.toStringAsFixed(0)}')
        .join('\n');
    final hasCasualties = result.casualties.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: hasCasualties ? AppTheme.red : AppTheme.green),
        ),
        title: TerminalText(
          hasCasualties ? 'AMEACA REATIVADA!' : 'COLETA CONCLUIDA',
          fontSize: 14,
          color: hasCasualties ? AppTheme.red : AppTheme.green,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('Andar ${result.floorNumber}', fontSize: 12, color: AppTheme.textPrimary),
            const SizedBox(height: 8),
            const TerminalText('Recursos coletados:', fontSize: 10, color: AppTheme.cyan),
            TerminalText(resStr, fontSize: 10, color: AppTheme.green),
            if (hasCasualties) ...[
              const SizedBox(height: 8),
              TerminalText('BAIXAS: ${result.casualties.length}', fontSize: 10, color: AppTheme.red, fontWeight: FontWeight.bold),
            ],
            if (result.discoveries.isNotEmpty) ...[
              const SizedBox(height: 8),
              TerminalText('Descobertas: ${result.discoveries.join(', ')}', fontSize: 10, color: AppTheme.yellow),
            ],
          ],
        ),
        actions: [
          TerminalButton(
            label: 'FECHAR',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, GameProvider gp) {
    final nameController = TextEditingController();
    final selectedIds = <String>{};
    GroupRole selectedRole = GroupRole.general;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 3, color: AppTheme.border, margin: const EdgeInsets.only(bottom: 12))),
                const TerminalText('FORMAR NOVO ESQUADRAO', fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontFamily: 'FiraCode', fontSize: 12, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nome do grupo...',
                    hintStyle: const TextStyle(color: AppTheme.textDim, fontFamily: 'FiraCode', fontSize: 11),
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
                ),
                const SizedBox(height: 12),
                const TerminalText('Funcao:', fontSize: 10, color: AppTheme.textSecondary),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: GroupRole.values.map((role) {
                    final active = selectedRole == role;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedRole = role),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: active ? AppTheme.cyan : AppTheme.border),
                          borderRadius: BorderRadius.circular(2),
                          color: active ? AppTheme.cyan.withValues(alpha: 0.1) : null,
                        ),
                        child: TerminalText(role.label, fontSize: 9, color: active ? AppTheme.cyan : AppTheme.textDim),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TerminalText('Selecionar membros (${selectedIds.length} selecionados):', fontSize: 10, color: AppTheme.textSecondary),
                const SizedBox(height: 8),
                ...gp.aliveNpcs.where((n) => n.groupId == null).map((npc) {
                  final selected = selectedIds.contains(npc.id);
                  return GestureDetector(
                    onTap: () => setModalState(() {
                      if (selected) {
                        selectedIds.remove(npc.id);
                      } else {
                        selectedIds.add(npc.id);
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
                          Icon(selected ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 14, color: selected ? AppTheme.cyan : AppTheme.textDim),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TerminalText(npc.name, fontSize: 10, color: AppTheme.textPrimary),
                                TerminalText(
                                  'PWR:${npc.attributes.combatPower.toStringAsFixed(1)} | ${npc.profession.label} | Leal:${npc.loyalty.toStringAsFixed(0)} | Fad:${npc.fatigue.toStringAsFixed(0)}%',
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
                }),
                const SizedBox(height: 12),
                TerminalButton(
                  label: 'CRIAR GRUPO',
                  icon: Icons.group_add,
                  expanded: true,
                  onPressed: selectedIds.length >= 2 && nameController.text.isNotEmpty
                      ? () {
                          gp.createGroup(nameController.text, selectedIds.toList(), selectedRole);
                          Navigator.pop(ctx);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuggestTrainingDialog(BuildContext context, GameProvider gp, NpcGroup group) {
    int? selectedFloor;
    final useTrainingField = gp.hasTrainingField;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 3, color: AppTheme.border, margin: const EdgeInsets.only(bottom: 12))),
              TerminalText('SUGERIR TREINO: ${group.name}', fontSize: 12, color: AppTheme.cyan, fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              const TerminalText('Os NPCs podem aceitar, recusar ou ignorar.', fontSize: 9, color: AppTheme.textDim),
              const SizedBox(height: 12),
              if (useTrainingField) ...[
                GestureDetector(
                  onTap: () => setModalState(() => selectedFloor = -1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: selectedFloor == -1 ? AppTheme.green : AppTheme.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const TerminalText('Campo de Treino (seguro, ganhos lentos)', fontSize: 10, color: AppTheme.green),
                  ),
                ),
              ],
              ...gp.clearedFloors.map((floor) => GestureDetector(
                onTap: () => setModalState(() => selectedFloor = floor.number),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: selectedFloor == floor.number ? AppTheme.cyan : AppTheme.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TerminalText(
                    'Andar ${floor.number} (${floor.type.label}) - Risco moderado',
                    fontSize: 10,
                    color: selectedFloor == floor.number ? AppTheme.cyan : AppTheme.textSecondary,
                  ),
                ),
              )),
              const SizedBox(height: 12),
              TerminalButton(
                label: 'SUGERIR',
                icon: Icons.send,
                expanded: true,
                color: AppTheme.green,
                onPressed: selectedFloor != null
                    ? () {
                        gp.suggestTraining(group.id, 'group', selectedFloor!);
                        Navigator.pop(ctx);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

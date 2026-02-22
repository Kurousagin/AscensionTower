import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../models/tower.dart';
import '../models/group_model.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> {
  FloorExplorationResult? _lastReexploreResult;
  int _expandedTier = -1; // -1 = nenhum expandido

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        // Auto-expandir o tier atual
        final currentTier = ((gp.state.highestFloorCleared) ~/ 10) + 1;
        if (_expandedTier == -1) {
          _expandedTier = currentTier.clamp(1, 10);
        }

        return ScanlineOverlay(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTowerOverview(gp),
                const SizedBox(height: 12),
                _buildNextFloor(context, gp),
                const SizedBox(height: 12),
                _buildCommandInfo(),
                const SizedBox(height: 12),
                _buildReexploration(context, gp),
                const SizedBox(height: 12),
                if (gp.lastChallenge != null) _buildLastResult(gp),
                if (_lastReexploreResult != null) ...[
                  const SizedBox(height: 12),
                  _buildLastReexploreResult(),
                ],
                const SizedBox(height: 12),
                _buildFloorMap(gp),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTowerOverview(GameProvider gp) {
    final cleared = gp.state.highestFloorCleared;
    final currentTier = ((cleared) ~/ 10) + (cleared % 10 > 0 ? 1 : 0);
    final tierProgress = cleared % 10;

    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText('A TORRE DOS 100 ANDARES',
              fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          _buildMiniTowerAscii(cleared),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalText('Andares: $cleared / 100',
                        fontSize: 11, color: AppTheme.green),
                    TerminalText('Tier atual: $currentTier / 10',
                        fontSize: 10, color: AppTheme.orange),
                    TerminalText('Progresso no tier: $tierProgress / 10',
                        fontSize: 10, color: AppTheme.textSecondary),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _difficultyBadge(cleared),
                  const SizedBox(height: 4),
                  TerminalText('Mortes: ${gp.state.totalDeaths}',
                      fontSize: 9, color: AppTheme.red),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Barra de progresso total
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppTheme.border),
            ),
            child: FractionallySizedBox(
              widthFactor: (cleared / 100.0).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.green, AppTheme.cyan, AppTheme.orange],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _difficultyBadge(int cleared) {
    String tag;
    Color color;
    if (cleared <= 5) {
      tag = 'FACIL';
      color = AppTheme.green;
    } else if (cleared <= 15) {
      tag = 'NORMAL';
      color = AppTheme.cyan;
    } else if (cleared <= 30) {
      tag = 'DIFICIL';
      color = AppTheme.yellow;
    } else if (cleared <= 50) {
      tag = 'BRUTAL';
      color = AppTheme.orange;
    } else if (cleared <= 75) {
      tag = 'INFERNAL';
      color = AppTheme.red;
    } else {
      tag = 'IMPOSSIVEL';
      color = const Color(0xFFFF44FF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(3),
      ),
      child: TerminalText(tag, fontSize: 9, color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMiniTowerAscii(int cleared) {
    // Mostra 10 blocos representando cada tier
    final tiers = <Widget>[];
    for (int t = 10; t >= 1; t--) {
      final tierStart = (t - 1) * 10 + 1;
      final tierEnd = t * 10;
      final floorsInTier = List.generate(10, (i) => tierStart + i);
      final clearedInTier = floorsInTier.where((f) => f <= cleared).length;
      final isCurrent = cleared >= tierStart - 1 && cleared < tierEnd;
      final isFullyCleared = clearedInTier == 10;
      final isLocked = cleared < tierStart - 1;

      Color color;
      if (isFullyCleared) {
        color = AppTheme.green;
      } else if (isCurrent) {
        color = AppTheme.yellow;
      } else {
        color = AppTheme.textDim;
      }

      final width = 6 + (10 - t) * 2;
      final bar = isFullyCleared
          ? '=' * width
          : isCurrent
              ? '${'=' * clearedInTier}${'-' * (10 - clearedInTier)}'
                  .padRight(width, '-')
                  .substring(0, width)
              : '-' * width;
      final label = isFullyCleared
          ? 'Completo'
          : isCurrent
              ? 'Atual   '
              : isLocked
                  ? 'Bloqueado'
                  : '        ';

      tiers.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
          children: [
            SizedBox(
                width: 70,
                child: TerminalText(label, fontSize: 7, color: color)),
            TerminalText(
                'T${t.toString().padLeft(2, '0')} |$bar| $clearedInTier/10',
                fontSize: 8,
                color: color),
          ],
        ),
      ));
    }
    return Column(children: tiers);
  }

  Widget _buildNextFloor(BuildContext context, GameProvider gp) {
    final floor = gp.nextFloor;
    if (floor == null) {
      return TerminalCard(
        borderColor: AppTheme.green,
        title: 'TORRE COMPLETA - 100 ANDARES',
        child: const TerminalText(
          'Todos os 100 andares foram conquistados! A humanidade provou seu valor '
          'e ascendeu alem do que a Torre imaginava possivel. TEL - A Criadora do Jogo - foi derrotada.',
          color: AppTheme.green,
        ),
      );
    }

    final isBoss = floor.number % 10 == 0;
    final isElite = floor.number % 5 == 0 && !isBoss;

    return TerminalCard(
      title:
          '${isBoss ? "BOSS" : isElite ? "ELITE" : "PROXIMO"}: ANDAR ${floor.number}',
      borderColor: isBoss
          ? AppTheme.red
          : isElite
              ? const Color(0xFFFF44FF)
              : AppTheme.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TerminalText('${floor.type.icon} ${floor.type.label}',
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.red),
                borderRadius: BorderRadius.circular(3),
              ),
              child: TerminalText(
                  'Dif: ${floor.scaledDifficulty.toStringAsFixed(1)} | ${floor.difficultyTag}',
                  fontSize: 8,
                  color: AppTheme.red),
            ),
          ]),
          const SizedBox(height: 6),
          TerminalText(floor.description,
              fontSize: 9, color: AppTheme.textSecondary),
          if (floor.specialCondition.isNotEmpty) ...[
            const SizedBox(height: 4),
            TerminalText('Condicao: ${floor.specialCondition}',
                fontSize: 9, color: AppTheme.orange),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              TerminalText(
                  'Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
                  fontSize: 9,
                  color: AppTheme.red),
              TerminalText('${floor.tierLabel} | ${floor.difficultyTag}',
                  fontSize: 9, color: AppTheme.orange),
            ],
          ),
          TerminalText(
            'Grupo: ${floor.recommendedPartySize} pessoas | Poder: ${floor.recommendedPower.toStringAsFixed(1)}',
            fontSize: 9,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 6),
          TerminalText('Recompensa: ${floor.reward}',
              fontSize: 9, color: AppTheme.green),
          const SizedBox(height: 12),

          // BOTAO DE ACAO
          TerminalButton(
            label: isBoss
                ? 'DESAFIAR BOSS'
                : isElite
                    ? 'ENFRENTAR ELITE'
                    : 'ENVIAR EXPEDICAO',
            icon: isBoss
                ? Icons.whatshot
                : isElite
                    ? Icons.shield
                    : Icons.rocket_launch,
            color: isBoss
                ? AppTheme.red
                : isElite
                    ? const Color(0xFFFF44FF)
                    : AppTheme.orange,
            expanded: true,
            onPressed: gp.aliveNpcs.length >= 2
                ? () => _showSendExpeditionDialog(context, gp, floor)
                : null,
          ),
          if (gp.aliveNpcs.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: TerminalText('Necessario ao menos 2 habitantes vivos.',
                  fontSize: 8, color: AppTheme.red),
            ),

          // Atalhos de grupo
          if (gp.groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            const TerminalText('Enviar grupo formado:',
                fontSize: 9, color: AppTheme.textDim),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: gp.groups.map((group) {
                final aliveCount = group.memberIds
                    .where(
                        (id) => gp.allNpcs.any((n) => n.id == id && n.alive))
                    .length;
                return TerminalButton(
                  label: '${group.name} ($aliveCount)',
                  icon: Icons.groups,
                  color: AppTheme.cyan,
                  onPressed: aliveCount >= 2
                      ? () =>
                          _confirmGroupExpedition(context, gp, group, floor)
                      : null,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommandInfo() {
    return TerminalCard(
      title: 'HIERARQUIA DE COMANDO',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText('VOCE DECIDE QUEM SOBE.',
              fontSize: 11,
              color: AppTheme.orange,
              fontWeight: FontWeight.bold),
          SizedBox(height: 6),
          TerminalText(
            'Acoes diretas: Enviar expedições, re-explorar andares, construir edificios.\n'
            'Sugestoes: Treino de NPCs (eles podem recusar).\n'
            'Tudo mais e autonomo.',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 6),
          TerminalText(
            'DIFICULDADE INSPIRADA EM PICK ME UP:\n'
            '  Andares 1-5: Facil (tutorial)\n'
            '  Andares 6-15: Normal (introducao real)\n'
            '  Andares 16-30: Dificil (mortes frequentes)\n'
            '  Andares 31-50: Brutal (preparo e tudo)\n'
            '  Andares 51-75: Infernal (cada ida e uma aposta)\n'
            '  Andares 76-100: Impossivel (lendario)\n'
            '  Boss a cada 10 andares | Elite a cada 5',
            fontSize: 9,
            color: AppTheme.red,
          ),
        ],
      ),
    );
  }

  Widget _buildReexploration(BuildContext context, GameProvider gp) {
    final cleared = gp.clearedFloors;
    if (cleared.isEmpty) return const SizedBox.shrink();

    // Mostrar apenas os ultimos 5 andares conquistados para nao poluir a UI
    final recentCleared = cleared.reversed.take(5).toList();

    return TerminalCard(
      title: 'RE-EXPLORACAO (${cleared.length} andares disponiveis)',
      borderColor: AppTheme.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'Envie grupos para coletar recursos de andares ja conquistados.',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          ...recentCleared.map((floor) {
            final resStr = floor.farmableResources.entries
                .map((e) => '${e.key}:~${e.value.toStringAsFixed(0)}')
                .join(', ');
            final threatPct =
                ((0.05 + floor.timesReexplored * 0.02) * 100).toStringAsFixed(0);
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                border: Border.all(
                    color: AppTheme.green.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TerminalText(
                            'Andar ${floor.number} (${floor.type.label})',
                            fontSize: 9,
                            color: AppTheme.green,
                            fontWeight: FontWeight.bold),
                        TerminalText(resStr,
                            fontSize: 7, color: AppTheme.cyan),
                        TerminalText(
                            'Visitas:${floor.timesReexplored} | Risco:$threatPct%',
                            fontSize: 7,
                            color: floor.timesReexplored > 3
                                ? AppTheme.red
                                : AppTheme.textDim),
                      ],
                    ),
                  ),
                  TerminalButton(
                    label: 'COLETAR',
                    icon: Icons.search,
                    color: AppTheme.green,
                    onPressed: gp.aliveNpcs.isNotEmpty
                        ? () => _showReexploreDialog(context, gp, floor)
                        : null,
                  ),
                ],
              ),
            );
          }),
          if (cleared.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TerminalText(
                  'E mais ${cleared.length - 5} andares (veja mapa abaixo)',
                  fontSize: 8,
                  color: AppTheme.textDim),
            ),
        ],
      ),
    );
  }

  Widget _buildLastResult(GameProvider gp) {
    final ch = gp.lastChallenge!;
    return TerminalCard(
      title: 'ULTIMA EXPEDIÇÃO',
      borderColor: ch.victory ? AppTheme.green : AppTheme.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            ch.victory
                ? 'VITORIA no Andar ${ch.floor.number}'
                : 'DERROTA no Andar ${ch.floor.number}',
            fontSize: 12,
            color: ch.victory ? AppTheme.green : AppTheme.red,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 6),
          ...ch.log.take(20).map((line) {
            Color color = AppTheme.textSecondary;
            if (line.startsWith('>>') && ch.victory) color = AppTheme.green;
            if (line.startsWith('>>') && !ch.victory) color = AppTheme.red;
            if (line.contains('[X]')) color = AppTheme.red;
            if (line.contains('[O]')) color = AppTheme.green;
            if (line.startsWith('===')) color = AppTheme.cyan;
            if (line.startsWith('>')) color = AppTheme.orange;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: TerminalText(line, fontSize: 9, color: color),
            );
          }),
          if (ch.log.length > 20)
            TerminalText('... e mais ${ch.log.length - 20} linhas',
                fontSize: 8, color: AppTheme.textDim),
        ],
      ),
    );
  }

  Widget _buildLastReexploreResult() {
    final r = _lastReexploreResult!;
    final resStr = r.resourcesGained.entries
        .map((e) => '${e.key}: +${e.value.toStringAsFixed(0)}')
        .join(', ');
    final hasCasualties = r.casualties.isNotEmpty;

    return TerminalCard(
      title: 'ULTIMA RE-EXPLORACAO',
      borderColor: hasCasualties ? AppTheme.red : AppTheme.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            hasCasualties
                ? 'Andar ${r.floorNumber} - AMEACA REATIVADA!'
                : 'Andar ${r.floorNumber} - Coleta OK',
            fontSize: 11,
            color: hasCasualties ? AppTheme.red : AppTheme.green,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          TerminalText('Recursos: $resStr', fontSize: 9, color: AppTheme.cyan),
          if (hasCasualties)
            TerminalText('Baixas: ${r.casualties.length}',
                fontSize: 9, color: AppTheme.red),
        ],
      ),
    );
  }

  // ==================== MAPA DE ANDARES (100 ANDARES EM TIERS) ====================

  Widget _buildFloorMap(GameProvider gp) {
    return TerminalCard(
      title: 'MAPA DA TORRE (100 ANDARES)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
              'Toque em um Tier para expandir/colapsar os andares.',
              fontSize: 8,
              color: AppTheme.textDim),
          const SizedBox(height: 8),
          // 10 tiers, de cima para baixo
          ...List.generate(10, (i) {
            final tier = 10 - i;
            return _buildTierSection(gp, tier);
          }),
        ],
      ),
    );
  }

  Widget _buildTierSection(GameProvider gp, int tier) {
    final tierStart = (tier - 1) * 10 + 1;
    final tierEnd = tier * 10;
    final floorsInTier =
        gp.floors.where((f) => f.number >= tierStart && f.number <= tierEnd).toList();
    final clearedCount = floorsInTier.where((f) => f.cleared).length;
    final isExpanded = _expandedTier == tier;
    final isFullyCleared = clearedCount == 10;
    final hasBossCleared = floorsInTier.last.cleared;
    final isCurrentTier =
        gp.state.highestFloorCleared >= tierStart - 1 &&
            gp.state.highestFloorCleared < tierEnd;
    final isLocked = gp.state.highestFloorCleared < tierStart - 1;

    final tierNames = [
      'Despertar',
      'Abismo',
      'Loucura',
      'Fortaleza',
      'Imperio',
      'Veneno',
      'Almas',
      'Caos',
      'Sombra',
      'Criadora'
    ];

    Color tierColor;
    if (isFullyCleared) {
      tierColor = AppTheme.green;
    } else if (isCurrentTier) {
      tierColor = AppTheme.yellow;
    } else if (isLocked) {
      tierColor = AppTheme.textDim;
    } else {
      tierColor = AppTheme.textSecondary;
    }

    return Column(
      children: [
        GestureDetector(
          onTap: isLocked
              ? null
              : () => setState(() {
                    _expandedTier = isExpanded ? -1 : tier;
                  }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentTier
                  ? AppTheme.yellow.withValues(alpha: 0.05)
                  : AppTheme.bgElevated,
              border: Border.all(
                  color: tierColor.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: isLocked ? AppTheme.textDim : tierColor,
                ),
                const SizedBox(width: 6),
                TerminalText(
                    'TIER $tier: ${tierNames[(tier - 1).clamp(0, 9)].toUpperCase()}',
                    fontSize: 10,
                    color: tierColor,
                    fontWeight: FontWeight.bold),
                const Spacer(),
                TerminalText('$clearedCount/10',
                    fontSize: 9, color: tierColor),
                const SizedBox(width: 6),
                // Mini barra
                SizedBox(
                  width: 50,
                  height: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: clearedCount / 10.0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: tierColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasBossCleared) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 12, color: AppTheme.green),
                ],
                if (isLocked)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.lock, size: 12, color: AppTheme.textDim),
                  ),
              ],
            ),
          ),
        ),

        // Andares expandidos
        if (isExpanded && !isLocked) ...[
          ...floorsInTier.reversed.map((floor) {
            final isCleared = floor.cleared;
            final isNext = floor.number == gp.state.highestFloorCleared + 1;
            final isBoss = floor.number % 10 == 0;
            final isElite = floor.number % 5 == 0 && !isBoss;
            final isFloorLocked = floor.number > gp.state.highestFloorCleared + 1;

            Color floorColor;
            if (isCleared) {
              floorColor = AppTheme.green;
            } else if (isNext) {
              floorColor = AppTheme.yellow;
            } else {
              floorColor = AppTheme.textDim;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 1, left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isBoss && isNext
                      ? AppTheme.red.withValues(alpha: 0.5)
                      : floorColor.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(children: [
                SizedBox(
                  width: 14,
                  child: TerminalText(
                    isCleared
                        ? 'V'
                        : isNext
                            ? '>'
                            : '-',
                    fontSize: 9,
                    color: floorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TerminalText(
                    floor.number.toString().padLeft(3, '0'),
                    fontSize: 9,
                    color: floorColor,
                    fontWeight: FontWeight.bold),
                const SizedBox(width: 6),
                TerminalText(floor.type.icon,
                    fontSize: 8, color: floorColor),
                const SizedBox(width: 4),
                Expanded(
                  child: TerminalText(
                    '${floor.type.label}${isBoss ? ' [BOSS]' : isElite ? ' [ELITE]' : ''}',
                    fontSize: 8,
                    color: isBoss
                        ? (isFloorLocked ? AppTheme.textDim : AppTheme.red)
                        : isElite
                            ? (isFloorLocked ? AppTheme.textDim : const Color(0xFFFF44FF))
                            : floorColor,
                  ),
                ),
                TerminalText(
                    'Dif:${floor.scaledDifficulty.toStringAsFixed(1)}',
                    fontSize: 7,
                    color: floorColor),
              ]),
            );
          }),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  // ==================== DIALOGOS DE ACAO ====================

  void _showSendExpeditionDialog(
      BuildContext context, GameProvider gp, TowerFloor floor) {
    final selectedIds = <String>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final selectedNpcs = selectedIds
              .map((id) => gp.allNpcs.where((n) => n.id == id).firstOrNull)
              .whereType<Npc>()
              .toList();
          final totalPower = selectedNpcs.fold<double>(
              0.0, (sum, n) => sum + n.attributes.combatPower);
          final powerPct = floor.recommendedPower > 0
              ? (totalPower / floor.recommendedPower * 100)
              : 0.0;
          final isReady = selectedIds.length >= 2;

          return DraggableScrollableSheet(
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
                  Center(
                      child: Container(
                          width: 40,
                          height: 3,
                          color: AppTheme.border,
                          margin: const EdgeInsets.only(bottom: 12))),
                  TerminalText(
                      'EXPEDICAO: ANDAR ${floor.number} (${floor.difficultyTag})',
                      fontSize: 14,
                      color: AppTheme.orange,
                      fontWeight: FontWeight.bold),
                  const SizedBox(height: 4),
                  TerminalText(
                      '${floor.type.label} | Dif:${floor.scaledDifficulty.toStringAsFixed(1)} | Mort:${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
                      fontSize: 10,
                      color: AppTheme.textSecondary),
                  const SizedBox(height: 8),

                  // Poder
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: powerPct >= 100
                              ? AppTheme.green
                              : powerPct >= 60
                                  ? AppTheme.yellow
                                  : AppTheme.red),
                      borderRadius: BorderRadius.circular(4),
                      color: AppTheme.bgElevated,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TerminalText(
                                  'Selecionados: ${selectedIds.length} / Recomendado: ${floor.recommendedPartySize}',
                                  fontSize: 10,
                                  color: AppTheme.textPrimary),
                              TerminalText(
                                  'Poder: ${totalPower.toStringAsFixed(1)} / ${floor.recommendedPower.toStringAsFixed(1)} (${powerPct.toStringAsFixed(0)}%)',
                                  fontSize: 10,
                                  color: powerPct >= 100
                                      ? AppTheme.green
                                      : powerPct >= 60
                                          ? AppTheme.yellow
                                          : AppTheme.red),
                            ],
                          ),
                        ),
                        Icon(
                          powerPct >= 100
                              ? Icons.check_circle
                              : powerPct >= 60
                                  ? Icons.warning
                                  : Icons.dangerous,
                          color: powerPct >= 100
                              ? AppTheme.green
                              : powerPct >= 60
                                  ? AppTheme.yellow
                                  : AppTheme.red,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grupos
                  if (gp.groups.isNotEmpty) ...[
                    const TerminalText('Selecao rapida:',
                        fontSize: 10, color: AppTheme.textDim),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: gp.groups.map((group) {
                        final alive = group.memberIds
                            .where((id) =>
                                gp.allNpcs.any((n) => n.id == id && n.alive))
                            .toList();
                        return TerminalButton(
                          label: '${group.name} (${alive.length})',
                          icon: Icons.groups,
                          color: AppTheme.cyan,
                          onPressed: alive.isNotEmpty
                              ? () => setModalState(() {
                                    selectedIds.clear();
                                    selectedIds.addAll(alive);
                                  })
                              : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TerminalText('Habitantes (${selectedIds.length}):',
                      fontSize: 10, color: AppTheme.textSecondary),
                  const SizedBox(height: 8),

                  ...gp.aliveNpcs.map((npc) {
                    final selected = selectedIds.contains(npc.id);
                    final power = npc.attributes.combatPower;
                    final isDisabled = npc.isIncapacitated;
                    final fatigueColor = npc.fatigue >= 90 ? const Color(0xFFFF0044) :
                        npc.fatigue >= 70 ? AppTheme.red :
                        npc.fatigue >= 50 ? AppTheme.orange :
                        npc.fatigue >= 30 ? AppTheme.yellow : AppTheme.green;
                    return GestureDetector(
                      onTap: isDisabled ? null : () => setModalState(() {
                        if (selected) {
                          selectedIds.remove(npc.id);
                        } else {
                          selectedIds.add(npc.id);
                        }
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isDisabled
                                  ? AppTheme.red.withValues(alpha: 0.3)
                                  : selected
                                      ? AppTheme.orange
                                      : AppTheme.border),
                          borderRadius: BorderRadius.circular(3),
                          color: isDisabled
                              ? AppTheme.red.withValues(alpha: 0.03)
                              : selected
                                  ? AppTheme.orange.withValues(alpha: 0.05)
                                  : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                                isDisabled
                                    ? Icons.block
                                    : selected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                size: 14,
                                color: isDisabled
                                    ? AppTheme.red.withValues(alpha: 0.5)
                                    : selected
                                        ? AppTheme.orange
                                        : AppTheme.textDim),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TerminalText(
                                '${npc.name} | ${npc.profession.label} | PWR:${power.toStringAsFixed(1)} | Leal:${npc.loyalty.toStringAsFixed(0)}${isDisabled ? " [INCAPACITADO]" : npc.isExhausted ? " [EXAUSTO]" : ""}',
                                fontSize: 8,
                                color: isDisabled ? AppTheme.red.withValues(alpha: 0.5) : AppTheme.textSecondary,
                              ),
                            ),
                            if (npc.isSuspicious)
                              const TerminalText(' [!]',
                                  fontSize: 8, color: AppTheme.red),
                            const SizedBox(width: 4),
                            TerminalText('F:${npc.fatigue.toStringAsFixed(0)}',
                                fontSize: 8, color: fatigueColor),
                            TerminalText(' ${power.toStringAsFixed(1)}',
                                fontSize: 9, color: AppTheme.orange),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  if (powerPct < 60 && isReady)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: TerminalText(
                          'AVISO: Poder abaixo de 60%. Risco altissimo!',
                          fontSize: 9,
                          color: AppTheme.red),
                    ),
                  TerminalButton(
                    label: isReady ? 'ENVIAR' : 'SELECIONE 2+',
                    icon: Icons.rocket_launch,
                    expanded: true,
                    color: AppTheme.orange,
                    onPressed: isReady
                        ? () {
                            Navigator.pop(ctx);
                            _executeExpedition(
                                context, gp, selectedIds.toList());
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmGroupExpedition(BuildContext context, GameProvider gp,
      NpcGroup group, TowerFloor floor) {
    final aliveMembers = group.memberIds
        .where((id) => gp.allNpcs.any((n) => n.id == id && n.alive))
        .toList();
    final totalPower = aliveMembers
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
        title: TerminalText('ENVIAR ${group.name.toUpperCase()}?',
            fontSize: 14,
            color: AppTheme.orange,
            fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('Andar ${floor.number} (${floor.type.label})',
                fontSize: 11, color: AppTheme.textPrimary),
            TerminalText('Membros: ${aliveMembers.length}',
                fontSize: 10, color: AppTheme.textSecondary),
            TerminalText(
                'Poder: ${totalPower.toStringAsFixed(1)} (${powerPct.toStringAsFixed(0)}%)',
                fontSize: 10,
                color: powerPct >= 100 ? AppTheme.green : AppTheme.red),
            TerminalText(
                'Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
                fontSize: 10,
                color: AppTheme.red),
            const SizedBox(height: 8),
            const TerminalText('MORTE PERMANENTE.',
                fontSize: 10,
                color: AppTheme.red,
                fontWeight: FontWeight.bold),
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
              if (result != null) _showExpeditionResult(context, result);
            },
          ),
        ],
      ),
    );
  }

  void _executeExpedition(
      BuildContext context, GameProvider gp, List<String> partyIds) {
    final floor = gp.nextFloor;
    if (floor == null) return;

    final totalPower = partyIds
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
        title: const TerminalText('CONFIRMAR?',
            fontSize: 14,
            color: AppTheme.orange,
            fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('Andar ${floor.number}: ${floor.type.label}',
                fontSize: 11, color: AppTheme.textPrimary),
            TerminalText('${partyIds.length} habitantes',
                fontSize: 10, color: AppTheme.textSecondary),
            TerminalText(
                'Poder: ${totalPower.toStringAsFixed(1)} (${powerPct.toStringAsFixed(0)}%)',
                fontSize: 10,
                color: powerPct >= 100 ? AppTheme.green : AppTheme.red),
            const SizedBox(height: 8),
            const TerminalText('MORTE PERMANENTE.',
                fontSize: 10,
                color: AppTheme.red,
                fontWeight: FontWeight.bold),
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
              final result = gp.sendExpedition(partyIds);
              if (result != null) _showExpeditionResult(context, result);
            },
          ),
        ],
      ),
    );
  }

  void _showExpeditionResult(BuildContext context, TowerChallenge result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: result.victory ? AppTheme.green : AppTheme.red),
        ),
        title: TerminalText(
          result.victory ? 'VITORIA!' : 'DERROTA',
          fontSize: 16,
          color: result.victory ? AppTheme.green : AppTheme.red,
          fontWeight: FontWeight.bold,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.log.map((line) {
                Color color = AppTheme.textSecondary;
                if (line.startsWith('>>') && result.victory) {
                  color = AppTheme.green;
                }
                if (line.startsWith('>>') && !result.victory) {
                  color = AppTheme.red;
                }
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

  void _showReexploreDialog(
      BuildContext context, GameProvider gp, TowerFloor floor) {
    final selectedIds = <String>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final threatPct = ((0.05 + floor.timesReexplored * 0.02) * 100)
              .toStringAsFixed(0);
          final isReady = selectedIds.isNotEmpty;

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 3,
                          color: AppTheme.border,
                          margin: const EdgeInsets.only(bottom: 12))),
                  TerminalText('RE-EXPLORAR: ANDAR ${floor.number}',
                      fontSize: 14,
                      color: AppTheme.green,
                      fontWeight: FontWeight.bold),
                  const SizedBox(height: 4),
                  TerminalText(
                      '${floor.type.label} | Risco: $threatPct%',
                      fontSize: 10,
                      color: AppTheme.textSecondary),
                  const SizedBox(height: 4),
                  TerminalText(
                      'Recursos: ${floor.farmableResources.entries.map((e) => '${e.key}:~${e.value.toStringAsFixed(0)}').join(', ')}',
                      fontSize: 9,
                      color: AppTheme.cyan),
                  const SizedBox(height: 12),

                  if (gp.groups.isNotEmpty) ...[
                    const TerminalText('Selecao rapida:',
                        fontSize: 10, color: AppTheme.textDim),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: gp.groups.map((group) {
                        final alive = group.memberIds
                            .where((id) =>
                                gp.allNpcs.any((n) => n.id == id && n.alive))
                            .toList();
                        return TerminalButton(
                          label: '${group.name} (${alive.length})',
                          icon: Icons.groups,
                          color: AppTheme.cyan,
                          onPressed: alive.isNotEmpty
                              ? () => setModalState(() {
                                    selectedIds.clear();
                                    selectedIds.addAll(alive);
                                  })
                              : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TerminalText('Coletores (${selectedIds.length}):',
                      fontSize: 10, color: AppTheme.textSecondary),
                  const SizedBox(height: 8),

                  ...gp.aliveNpcs.map((npc) {
                    final selected = selectedIds.contains(npc.id);
                    final isDisabled = npc.isIncapacitated;
                    final fatigueColor = npc.fatigue >= 90 ? const Color(0xFFFF0044) :
                        npc.fatigue >= 70 ? AppTheme.red :
                        npc.fatigue >= 50 ? AppTheme.orange :
                        npc.fatigue >= 30 ? AppTheme.yellow : AppTheme.green;
                    return GestureDetector(
                      onTap: isDisabled ? null : () => setModalState(() {
                        if (selected) {
                          selectedIds.remove(npc.id);
                        } else {
                          selectedIds.add(npc.id);
                        }
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isDisabled
                                  ? AppTheme.red.withValues(alpha: 0.3)
                                  : selected
                                      ? AppTheme.green
                                      : AppTheme.border),
                          borderRadius: BorderRadius.circular(3),
                          color: isDisabled
                              ? AppTheme.red.withValues(alpha: 0.03)
                              : selected
                                  ? AppTheme.green.withValues(alpha: 0.05)
                                  : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                                isDisabled
                                    ? Icons.block
                                    : selected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                size: 14,
                                color: isDisabled
                                    ? AppTheme.red.withValues(alpha: 0.5)
                                    : selected
                                        ? AppTheme.green
                                        : AppTheme.textDim),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TerminalText(
                                '${npc.name} | ${npc.profession.label} | PWR:${npc.attributes.combatPower.toStringAsFixed(1)}${isDisabled ? " [INCAPACITADO]" : npc.isExhausted ? " [EXAUSTO]" : ""}',
                                fontSize: 9,
                                color: isDisabled ? AppTheme.red.withValues(alpha: 0.5) : AppTheme.textSecondary,
                              ),
                            ),
                            TerminalText('F:${npc.fatigue.toStringAsFixed(0)}',
                                fontSize: 8, color: fatigueColor),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  TerminalButton(
                    label: isReady ? 'ENVIAR COLETORES' : 'SELECIONE 1+',
                    icon: Icons.search,
                    expanded: true,
                    color: AppTheme.green,
                    onPressed: isReady
                        ? () {
                            Navigator.pop(ctx);
                            final result = gp.sendReexploration(
                                floor.number, selectedIds.toList());
                            if (result != null) {
                              setState(() => _lastReexploreResult = result);
                              _showReexploreResultDialog(context, result);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReexploreResultDialog(
      BuildContext context, FloorExplorationResult result) {
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
          side: BorderSide(
              color: hasCasualties ? AppTheme.red : AppTheme.green),
        ),
        title: TerminalText(
          hasCasualties ? 'AMEACA REATIVADA!' : 'COLETA OK',
          fontSize: 14,
          color: hasCasualties ? AppTheme.red : AppTheme.green,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText('Andar ${result.floorNumber}',
                fontSize: 12, color: AppTheme.textPrimary),
            const SizedBox(height: 8),
            const TerminalText('Recursos:',
                fontSize: 10, color: AppTheme.cyan),
            TerminalText(resStr, fontSize: 10, color: AppTheme.green),
            if (hasCasualties) ...[
              const SizedBox(height: 8),
              TerminalText('BAIXAS: ${result.casualties.length}',
                  fontSize: 10,
                  color: AppTheme.red,
                  fontWeight: FontWeight.bold),
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
}

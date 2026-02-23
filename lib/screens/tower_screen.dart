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
          const TerminalText(
            'A TORRE DOS 100 ANDARES',
            fontSize: 14,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          _buildMiniTowerAscii(cleared),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalText(
                      'Andares: $cleared / 100',
                      fontSize: 11,
                      color: AppTheme.green,
                    ),
                    TerminalText(
                      'Tier atual: $currentTier / 10',
                      fontSize: 10,
                      color: AppTheme.orange,
                    ),
                    TerminalText(
                      'Progresso no tier: $tierProgress / 10',
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _difficultyBadge(cleared),
                  const SizedBox(height: 4),
                  TerminalText(
                    'Mortes: ${gp.state.totalDeaths}',
                    fontSize: 9,
                    color: AppTheme.red,
                  ),
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
      child: TerminalText(
        tag,
        fontSize: 9,
        color: color,
        fontWeight: FontWeight.bold,
      ),
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

      tiers.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: TerminalText(label, fontSize: 7, color: color),
              ),
              TerminalText(
                'T${t.toString().padLeft(2, '0')} |$bar| $clearedInTier/10',
                fontSize: 8,
                color: color,
              ),
            ],
          ),
        ),
      );
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
          '${isBoss
              ? "BOSS"
              : isElite
              ? "ELITE"
              : "PROXIMO"}: ANDAR ${floor.number}',
      borderColor: isBoss
          ? AppTheme.red
          : isElite
          ? const Color(0xFFFF44FF)
          : AppTheme.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TerminalText(
                '${floor.type.icon} ${floor.type.label}',
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
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
                  color: AppTheme.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TerminalText(
            floor.description,
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          if (floor.specialCondition.isNotEmpty) ...[
            const SizedBox(height: 4),
            TerminalText(
              'Condicao: ${floor.specialCondition}',
              fontSize: 9,
              color: AppTheme.orange,
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              TerminalText(
                'Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
                fontSize: 9,
                color: AppTheme.red,
              ),
              TerminalText(
                '${floor.tierLabel} | ${floor.difficultyTag}',
                fontSize: 9,
                color: AppTheme.orange,
              ),
            ],
          ),
          TerminalText(
            'Grupo: ${floor.recommendedPartySize} pessoas | Poder: ${floor.recommendedPower.toStringAsFixed(1)}',
            fontSize: 9,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 6),
          TerminalText(
            'Recompensa: ${floor.reward}',
            fontSize: 9,
            color: AppTheme.green,
          ),
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
              child: TerminalText(
                'Necessario ao menos 2 habitantes vivos.',
                fontSize: 8,
                color: AppTheme.red,
              ),
            ),

          // Atalhos de grupo
          if (gp.groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            const TerminalText(
              'Enviar grupo formado:',
              fontSize: 9,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: gp.groups.map((group) {
                final aliveCount = group.memberIds
                    .where((id) => gp.allNpcs.any((n) => n.id == id && n.alive))
                    .length;
                return TerminalButton(
                  label: '${group.name} ($aliveCount)',
                  icon: Icons.groups,
                  color: AppTheme.cyan,
                  onPressed: aliveCount >= 2
                      ? () => _confirmGroupExpedition(context, gp, group, floor)
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
          TerminalText(
            'VOCE DECIDE QUEM SOBE.',
            fontSize: 11,
            color: AppTheme.orange,
            fontWeight: FontWeight.bold,
          ),
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

    // Mostrar todos os andares conquistados em ordem reversa (mais recentes primeiro)
    final sortedCleared = cleared.reversed.toList();

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
          // Container com altura máxima e scroll
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children: sortedCleared.map((floor) {
                  final resStr = floor.farmableResources.entries
                      .map((e) => '${e.key}:~${e.value.toStringAsFixed(0)}')
                      .join(', ');
                  final threatPct = ((0.05 + floor.timesReexplored * 0.02) * 100)
                      .toStringAsFixed(0);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      border: Border.all(
                        color: AppTheme.green.withValues(alpha: 0.2),
                      ),
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
                                fontWeight: FontWeight.bold,
                              ),
                              TerminalText(resStr, fontSize: 7, color: AppTheme.cyan),
                              TerminalText(
                                'Visitas:${floor.timesReexplored} | Risco:$threatPct%',
                                fontSize: 7,
                                color: floor.timesReexplored > 3
                                    ? AppTheme.red
                                    : AppTheme.textDim,
                              ),
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
                }).toList(),
              ),
            ),
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
            TerminalText(
              '... e mais ${ch.log.length - 20} linhas',
              fontSize: 8,
              color: AppTheme.textDim,
            ),
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
          TerminalText(
            'Custo: ${r.foodCost.toStringAsFixed(0)} comida',
            fontSize: 9,
            color: AppTheme.orange,
          ),
          TerminalText('Recursos: $resStr', fontSize: 9, color: AppTheme.cyan),
          if (r.expeditionEvents.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...r.expeditionEvents.map(
              (e) => TerminalText(
                e,
                fontSize: 8,
                color: e.contains('Traicao')
                    ? AppTheme.red
                    : e.contains('raro')
                    ? AppTheme.yellow
                    : e.contains('Conflito')
                    ? AppTheme.orange
                    : AppTheme.textDim,
              ),
            ),
          ],
          if (hasCasualties)
            TerminalText(
              'Baixas: ${r.casualties.length}',
              fontSize: 9,
              color: AppTheme.red,
            ),
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
            color: AppTheme.textDim,
          ),
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
    final floorsInTier = gp.floors
        .where((f) => f.number >= tierStart && f.number <= tierEnd)
        .toList();
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
      'Criadora',
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
              border: Border.all(color: tierColor.withValues(alpha: 0.4)),
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
                  fontWeight: FontWeight.bold,
                ),
                const Spacer(),
                TerminalText('$clearedCount/10', fontSize: 9, color: tierColor),
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
            final isFloorLocked =
                floor.number > gp.state.highestFloorCleared + 1;

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
              child: Row(
                children: [
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
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(width: 6),
                  TerminalText(floor.type.icon, fontSize: 8, color: floorColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TerminalText(
                      '${floor.type.label}${isBoss
                          ? ' [BOSS]'
                          : isElite
                          ? ' [ELITE]'
                          : ''}',
                      fontSize: 8,
                      color: isBoss
                          ? (isFloorLocked ? AppTheme.textDim : AppTheme.red)
                          : isElite
                          ? (isFloorLocked
                                ? AppTheme.textDim
                                : const Color(0xFFFF44FF))
                          : floorColor,
                    ),
                  ),
                  TerminalText(
                    'Dif:${floor.scaledDifficulty.toStringAsFixed(1)}',
                    fontSize: 7,
                    color: floorColor,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  // ==================== DIALOGOS DE ACAO ====================

  void _showSendExpeditionDialog(
    BuildContext context,
    GameProvider gp,
    TowerFloor floor,
  ) {
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
            0.0,
            (sum, n) => sum + n.attributes.combatPower,
          );
          final powerPct = floor.recommendedPower > 0
              ? (totalPower / floor.recommendedPower * 100)
              : 0.0;
          final isReady = selectedIds.length >= 2;
          final totalCost = gp.expeditionCostEstimate(selectedIds.length);
          final hasFood = gp.citadel.resources.food >= totalCost;

          // Calculos de analise avancada
          final synergy = selectedIds.length >= 2
              ? gp.engine.previewGroupSynergy(selectedIds.toList())
              : 0.0;
          final personalityMod = selectedIds.isNotEmpty
              ? gp.engine.previewPartyPersonalityMod(selectedIds.toList())
              : 0.0;
          final attrYield = selectedIds.isNotEmpty
              ? gp.engine.previewPartyAttributeYield(
                  selectedIds.toList(),
                  floor.type,
                )
              : 0.0;
          final eventChances = selectedIds.isNotEmpty
              ? gp.engine.previewEventChances(selectedIds.toList(), floor)
              : <String, double>{};

          // Analise de traicao
          final hasSuspect = selectedNpcs.any(
            (n) => n.isSuspicious || n.calculatedBetrayalRisk > 35,
          );
          final hasLazy = selectedNpcs.any(
            (n) => n.traits.contains(PersonalityTrait.lazy),
          );
          final allExhausted =
              selectedNpcs.isNotEmpty &&
              selectedNpcs.every((n) => n.isExhausted);

          return DraggableScrollableSheet(
            initialChildSize: 0.90,
            minChildSize: 0.5,
            maxChildSize: 0.98,
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
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                  ),

                  // === CABECALHO ===
                  TerminalText(
                    'EXPEDICAO: ANDAR ${floor.number} (${floor.difficultyTag})',
                    fontSize: 14,
                    color: AppTheme.orange,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  TerminalText(
                    '${floor.type.icon} ${floor.type.label} | Dif: ${floor.scaledDifficulty.toStringAsFixed(1)} | Mort: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                  if (floor.specialCondition.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    TerminalText(
                      'Condicao: ${floor.specialCondition}',
                      fontSize: 9,
                      color: AppTheme.yellow,
                    ),
                  ],
                  const SizedBox(height: 10),

                  // === PAINEL DE ANALISE (aparece apos selecionar NPCs) ===
                  if (selectedIds.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: powerPct >= 100
                              ? AppTheme.green
                              : powerPct >= 60
                              ? AppTheme.yellow
                              : AppTheme.red,
                        ),
                        borderRadius: BorderRadius.circular(5),
                        color: AppTheme.bgElevated,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titulo
                          Row(
                            children: [
                              Icon(
                                powerPct >= 100
                                    ? Icons.check_circle
                                    : powerPct >= 60
                                    ? Icons.warning_amber
                                    : Icons.dangerous,
                                color: powerPct >= 100
                                    ? AppTheme.green
                                    : powerPct >= 60
                                    ? AppTheme.yellow
                                    : AppTheme.red,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              TerminalText(
                                'ANALISE DA EXPEDICAO',
                                fontSize: 11,
                                color: AppTheme.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Poder
                          _analysisRow(
                            'Poder de Combate',
                            '${totalPower.toStringAsFixed(1)} / ${floor.recommendedPower.toStringAsFixed(1)} (${powerPct.toStringAsFixed(0)}%)',
                            powerPct >= 100
                                ? AppTheme.green
                                : powerPct >= 60
                                ? AppTheme.yellow
                                : AppTheme.red,
                          ),

                          // Custo
                          _analysisRow(
                            'Custo Fixo',
                            '${totalCost.toStringAsFixed(0)} comida (${gp.expeditionCostEstimate(1).toStringAsFixed(1)}/NPC)',
                            hasFood ? AppTheme.orange : AppTheme.red,
                          ),
                          if (!hasFood)
                            const Padding(
                              padding: EdgeInsets.only(left: 100, bottom: 2),
                              child: TerminalText(
                                'SEM COMIDA SUFICIENTE!',
                                fontSize: 8,
                                color: AppTheme.red,
                              ),
                            ),

                          // Sinergia
                          if (selectedIds.length >= 2) ...[
                            _analysisRow(
                              'Sinergia Grupo',
                              synergy > 0
                                  ? '+${(synergy * 100).toStringAsFixed(0)}% bonus'
                                  : synergy < 0
                                  ? '${(synergy * 100).toStringAsFixed(0)}% penalidade'
                                  : 'Neutro',
                              synergy > 0.1
                                  ? AppTheme.green
                                  : synergy < -0.1
                                  ? AppTheme.red
                                  : AppTheme.textSecondary,
                            ),
                          ],

                          // Personalidade
                          _analysisRow(
                            'Personalidade',
                            personalityMod > 0
                                ? '+${(personalityMod * 100).toStringAsFixed(0)}% eficiencia'
                                : personalityMod < 0
                                ? '${(personalityMod * 100).toStringAsFixed(0)}% eficiencia'
                                : 'Neutro',
                            personalityMod >= 0
                                ? AppTheme.cyan
                                : AppTheme.orange,
                          ),

                          // Atributos
                          _analysisRow(
                            'Yield de Atributos',
                            '${(attrYield * 100).toStringAsFixed(0)}% media',
                            attrYield >= 1.2
                                ? AppTheme.green
                                : attrYield >= 0.8
                                ? AppTheme.cyan
                                : AppTheme.orange,
                          ),

                          const SizedBox(height: 6),
                          const Divider(color: AppTheme.border, height: 1),
                          const SizedBox(height: 6),

                          // Riscos de evento
                          const TerminalText(
                            'RISCOS ESTIMADOS:',
                            fontSize: 9,
                            color: AppTheme.textDim,
                          ),
                          const SizedBox(height: 3),
                          if (eventChances.containsKey('acidente'))
                            _riskRow('Acidente', eventChances['acidente']!),
                          if (eventChances.containsKey('doenca'))
                            _riskRow('Doenca', eventChances['doenca']!),
                          if (eventChances.containsKey('conflito') &&
                              eventChances['conflito']! > 0.05)
                            _riskRow(
                              'Conflito Interno',
                              eventChances['conflito']!,
                            ),
                          if (eventChances.containsKey('traicao') &&
                              eventChances['traicao']! > 0)
                            _riskRow(
                              'Traicao',
                              eventChances['traicao']!,
                              isWarning: true,
                            ),
                          if (eventChances.containsKey('evento_raro'))
                            _riskRow(
                              'Evento Raro (+)',
                              eventChances['evento_raro']!,
                              isPositive: true,
                            ),

                          // Alertas criticos
                          if (hasSuspect) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.red.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppTheme.red.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    size: 11,
                                    color: AppTheme.red,
                                  ),
                                  SizedBox(width: 4),
                                  TerminalText(
                                    'NPC SUSPEITO na expedicao! Risco de traicao elevado.',
                                    fontSize: 8,
                                    color: AppTheme.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (hasLazy) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.orange.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: AppTheme.orange.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.bedtime,
                                    size: 11,
                                    color: AppTheme.orange,
                                  ),
                                  SizedBox(width: 4),
                                  TerminalText(
                                    'NPC PREGUICOSO reduz eficiencia do grupo.',
                                    fontSize: 8,
                                    color: AppTheme.orange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (allExhausted) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.red.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppTheme.red.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.dangerous,
                                    size: 11,
                                    color: AppTheme.red,
                                  ),
                                  SizedBox(width: 4),
                                  TerminalText(
                                    'TODOS EXAUSTOS! Rendimento drasticamente reduzido.',
                                    fontSize: 8,
                                    color: AppTheme.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Painel vazio (aguardando selecao)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(5),
                        color: AppTheme.bgElevated,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TerminalText(
                                      'Selecionados: 0 / Recomendado: ${floor.recommendedPartySize}',
                                      fontSize: 10,
                                      color: AppTheme.textPrimary,
                                    ),
                                    TerminalText(
                                      'Poder Necesssario: ${floor.recommendedPower.toStringAsFixed(1)}',
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TerminalText(
                            'Custo: ${gp.expeditionCostEstimate(1).toStringAsFixed(1)}/NPC | Estoque: ${gp.citadel.resources.food.toStringAsFixed(0)} comida',
                            fontSize: 9,
                            color: AppTheme.orange,
                          ),
                          const SizedBox(height: 4),
                          const TerminalText(
                            'Selecione ao menos 2 NPCs para ver a analise completa.',
                            fontSize: 8,
                            color: AppTheme.textDim,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Grupos
                  if (gp.groups.isNotEmpty) ...[
                    const TerminalText(
                      'Selecao rapida:',
                      fontSize: 10,
                      color: AppTheme.textDim,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: gp.groups.map((group) {
                        final alive = group.memberIds
                            .where(
                              (id) =>
                                  gp.allNpcs.any((n) => n.id == id && n.alive),
                            )
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

                  TerminalText(
                    'Habitantes (${gp.aliveNpcs.length} vivos):',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 6),

                  ...gp.aliveNpcs.map((npc) {
                    final selected = selectedIds.contains(npc.id);
                    final power = npc.attributes.combatPower;
                    final isDisabled = npc.isIncapacitated;
                    final fatigueColor = npc.fatigue >= 90
                        ? const Color(0xFFFF0044)
                        : npc.fatigue >= 70
                        ? AppTheme.red
                        : npc.fatigue >= 50
                        ? AppTheme.orange
                        : npc.fatigue >= 30
                        ? AppTheme.yellow
                        : AppTheme.green;

                    // Tags de personalidade relevantes
                    final dangerTraits = npc.traits
                        .where(
                          (t) =>
                              t == PersonalityTrait.lazy ||
                              t == PersonalityTrait.coward ||
                              t == PersonalityTrait.treacherous ||
                              t == PersonalityTrait.individualist,
                        )
                        .map((t) => t.label)
                        .toList();
                    final goodTraits = npc.traits
                        .where(
                          (t) =>
                              t == PersonalityTrait.brave ||
                              t == PersonalityTrait.loyal ||
                              t == PersonalityTrait.ambitious ||
                              t == PersonalityTrait.analytical ||
                              t == PersonalityTrait.leader,
                        )
                        .map((t) => t.label)
                        .toList();

                    return GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () => setModalState(() {
                              if (selected) {
                                selectedIds.remove(npc.id);
                              } else {
                                selectedIds.add(npc.id);
                              }
                            }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDisabled
                                ? AppTheme.red.withValues(alpha: 0.3)
                                : selected
                                ? AppTheme.orange
                                : AppTheme.border,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: isDisabled
                              ? AppTheme.red.withValues(alpha: 0.03)
                              : selected
                              ? AppTheme.orange.withValues(alpha: 0.06)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                      : AppTheme.textDim,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TerminalText(
                                    '${npc.name} | ${npc.profession.label}',
                                    fontSize: 9,
                                    color: isDisabled
                                        ? AppTheme.red.withValues(alpha: 0.5)
                                        : selected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (npc.isSuspicious)
                                  const Icon(
                                    Icons.warning,
                                    size: 12,
                                    color: AppTheme.red,
                                  ),
                                const SizedBox(width: 4),
                                TerminalText(
                                  'F:${npc.fatigue.toStringAsFixed(0)}',
                                  fontSize: 8,
                                  color: fatigueColor,
                                ),
                                const SizedBox(width: 6),
                                TerminalText(
                                  'PWR:${power.toStringAsFixed(1)}',
                                  fontSize: 9,
                                  color: AppTheme.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            if (isDisabled)
                              const Padding(
                                padding: EdgeInsets.only(left: 20, top: 2),
                                child: TerminalText(
                                  '[INCAPACITADO - NAO PODE PARTICIPAR]',
                                  fontSize: 7,
                                  color: AppTheme.red,
                                ),
                              )
                            else if (npc.isExhausted)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  top: 2,
                                ),
                                child: TerminalText(
                                  '[EXAUSTO - rendimento severamente reduzido]',
                                  fontSize: 7,
                                  color: AppTheme.red,
                                ),
                              )
                            else if (dangerTraits.isNotEmpty ||
                                goodTraits.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  top: 2,
                                ),
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    ...goodTraits.map(
                                      (t) => TerminalText(
                                        '[+$t]',
                                        fontSize: 7,
                                        color: AppTheme.green,
                                      ),
                                    ),
                                    ...dangerTraits.map(
                                      (t) => TerminalText(
                                        '[-$t]',
                                        fontSize: 7,
                                        color: AppTheme.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Alertas finais
                  if (powerPct < 60 && isReady)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.dangerous, size: 14, color: AppTheme.red),
                          SizedBox(width: 6),
                          Expanded(
                            child: TerminalText(
                              'PODER INSUFICIENTE (<60%). Probabilidade de DERROTA muito alta. Mortes certas.',
                              fontSize: 9,
                              color: AppTheme.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!hasFood && isReady)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.no_food,
                            size: 14,
                            color: AppTheme.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TerminalText(
                              'COMIDA INSUFICIENTE! Precisa: ${totalCost.toStringAsFixed(0)}, Tem: ${gp.citadel.resources.food.toStringAsFixed(0)}.',
                              fontSize: 9,
                              color: AppTheme.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                  TerminalButton(
                    label: !isReady
                        ? 'SELECIONE 2+ NPCs'
                        : !hasFood
                        ? 'SEM COMIDA SUFICIENTE'
                        : 'CONFIRMAR EXPEDICAO',
                    icon: Icons.rocket_launch,
                    expanded: true,
                    color: !isReady || !hasFood
                        ? AppTheme.textDim
                        : AppTheme.orange,
                    onPressed: isReady && hasFood
                        ? () {
                            Navigator.pop(ctx);
                            _executeExpedition(
                              context,
                              gp,
                              selectedIds.toList(),
                            );
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

  Widget _analysisRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 115,
            child: TerminalText(label, fontSize: 9, color: AppTheme.textDim),
          ),
          Expanded(
            child: TerminalText(
              value,
              fontSize: 9,
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskRow(
    String label,
    double chance, {
    bool isWarning = false,
    bool isPositive = false,
  }) {
    final pct = (chance * 100).toStringAsFixed(0);
    Color color;
    if (isPositive) {
      color = AppTheme.green;
    } else if (isWarning || chance > 0.20) {
      color = AppTheme.red;
    } else if (chance > 0.10) {
      color = AppTheme.orange;
    } else {
      color = AppTheme.yellow;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 115,
            child: TerminalText(
              isPositive ? '  + $label' : '  - $label',
              fontSize: 8,
              color: AppTheme.textSecondary,
            ),
          ),
          TerminalText(
            '$pct%',
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  void _confirmGroupExpedition(
    BuildContext context,
    GameProvider gp,
    NpcGroup group,
    TowerFloor floor,
  ) {
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
        title: TerminalText(
          'ENVIAR ${group.name.toUpperCase()}?',
          fontSize: 14,
          color: AppTheme.orange,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(
              'Andar ${floor.number} (${floor.type.label})',
              fontSize: 11,
              color: AppTheme.textPrimary,
            ),
            TerminalText(
              'Membros: ${aliveMembers.length}',
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            TerminalText(
              'Poder: ${totalPower.toStringAsFixed(1)} (${powerPct.toStringAsFixed(0)}%)',
              fontSize: 10,
              color: powerPct >= 100 ? AppTheme.green : AppTheme.red,
            ),
            TerminalText(
              'Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
              fontSize: 10,
              color: AppTheme.red,
            ),
            const SizedBox(height: 8),
            const TerminalText(
              'MORTE PERMANENTE.',
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
    BuildContext context,
    GameProvider gp,
    List<String> partyIds,
  ) {
    final floor = gp.nextFloor;
    if (floor == null) return;

    final partyNpcs = partyIds
        .map((id) => gp.allNpcs.where((n) => n.id == id).firstOrNull)
        .whereType<Npc>()
        .toList();
    final totalPower = partyNpcs.fold<double>(
      0.0,
      (sum, n) => sum + n.attributes.combatPower,
    );
    final powerPct = floor.recommendedPower > 0
        ? (totalPower / floor.recommendedPower * 100)
        : 0.0;
    final totalCost = gp.expeditionCostEstimate(partyIds.length);
    final isBoss = floor.number % 10 == 0;
    final isElite = floor.number % 5 == 0 && !isBoss;

    // Avaliacao de risco
    String riskTag;
    Color riskColor;
    if (powerPct >= 110) {
      riskTag = 'VANTAGEM';
      riskColor = AppTheme.green;
    } else if (powerPct >= 90) {
      riskTag = 'EQUILIBRADO';
      riskColor = AppTheme.cyan;
    } else if (powerPct >= 70) {
      riskTag = 'ARRISCADO';
      riskColor = AppTheme.yellow;
    } else if (powerPct >= 50) {
      riskTag = 'PERIGOSO';
      riskColor = AppTheme.orange;
    } else {
      riskTag = 'SUICIDA';
      riskColor = AppTheme.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isBoss
                ? AppTheme.red
                : isElite
                ? const Color(0xFFFF44FF)
                : AppTheme.orange,
            width: isBoss ? 2 : 1,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(
              isBoss
                  ? 'CONFRONTO FINAL - BOSS!'
                  : isElite
                  ? 'ANDAR ELITE'
                  : 'CONFIRMAR EXPEDICAO',
              fontSize: 13,
              color: isBoss
                  ? AppTheme.red
                  : isElite
                  ? const Color(0xFFFF44FF)
                  : AppTheme.orange,
              fontWeight: FontWeight.bold,
            ),
            TerminalText(
              'Andar ${floor.number} | ${floor.type.label}',
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NPCs selecionados
              TerminalText(
                'Enviando ${partyNpcs.length} NPC${partyNpcs.length > 1 ? "s" : ""}:',
                fontSize: 9,
                color: AppTheme.textDim,
              ),
              const SizedBox(height: 2),
              ...partyNpcs
                  .take(5)
                  .map(
                    (npc) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 1),
                      child: TerminalText(
                        '> ${npc.name} (PWR:${npc.attributes.combatPower.toStringAsFixed(1)}, F:${npc.fatigue.toStringAsFixed(0)})',
                        fontSize: 8,
                        color: npc.isExhausted
                            ? AppTheme.orange
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
              if (partyNpcs.length > 5)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TerminalText(
                    '... e mais ${partyNpcs.length - 5}',
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                ),
              const SizedBox(height: 10),

              // Custo fixo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.06),
                  border: Border.all(
                    color: AppTheme.orange.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 12,
                      color: AppTheme.orange,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TerminalText(
                          'CUSTO FIXO: ${totalCost.toStringAsFixed(0)} comida',
                          fontSize: 9,
                          color: AppTheme.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        TerminalText(
                          'Pago AGORA independente do resultado',
                          fontSize: 7,
                          color: AppTheme.textDim,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Avaliacao de risco
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.06),
                  border: Border.all(color: riskColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TerminalText(
                                'RISCO: ',
                                fontSize: 9,
                                color: AppTheme.textDim,
                              ),
                              TerminalText(
                                riskTag,
                                fontSize: 10,
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          TerminalText(
                            'Poder: ${totalPower.toStringAsFixed(1)} / ${floor.recommendedPower.toStringAsFixed(1)} (${powerPct.toStringAsFixed(0)}%)',
                            fontSize: 8,
                            color: AppTheme.textSecondary,
                          ),
                          TerminalText(
                            'Mortalidade base: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%',
                            fontSize: 8,
                            color: AppTheme.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.red.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppTheme.red.withValues(alpha: 0.6),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.close, size: 14, color: AppTheme.red),
                    SizedBox(width: 6),
                    Expanded(
                      child: TerminalText(
                        'MORTE PERMANENTE. Nao ha retorno.',
                        fontSize: 9,
                        color: AppTheme.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TerminalButton(
            label: 'RECUAR',
            color: AppTheme.textDim,
            onPressed: () => Navigator.pop(ctx),
          ),
          TerminalButton(
            label: isBoss ? 'ENFRENTAR BOSS' : 'ENVIAR',
            icon: Icons.rocket_launch,
            color: isBoss ? AppTheme.red : AppTheme.orange,
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
          TerminalButton(label: 'FECHAR', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  void _showReexploreDialog(
    BuildContext context,
    GameProvider gp,
    TowerFloor floor,
  ) {
    final selectedIds = <String>{}; // Mover para fora do StatefulBuilder

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

          // Análise de expedição (se NPCs selecionados)
          Widget? analysisWidget;
          if (selectedIds.isNotEmpty) {
            final selectedNpcs = selectedIds.toList();
            final costPerNpc = gp.engine.reexploreCostPerNpc(floor.number);
            final totalCost = selectedNpcs.length * costPerNpc;
            final synergy = gp.engine.previewGroupSynergy(selectedNpcs) * 100;
            final personalityMod = gp.engine.previewPartyPersonalityMod(selectedNpcs) * 100;
            final attributeYield = gp.engine.previewPartyAttributeYield(selectedNpcs, floor.type);
            final eventChances = gp.engine.previewEventChances(selectedNpcs, floor);

            // Estima recursos considerando sinergia e eficiência
            final baseResources = floor.farmableResources;
            final estimatedFood = baseResources['food'] ?? 0.0;
            final totalYield = attributeYield * (1 + synergy / 100) * (1 + personalityMod / 100);
            final estimatedReturn = estimatedFood * totalYield;
            final netFood = estimatedReturn - totalCost;

            analysisWidget = Container(
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
                    'Membros: ${selectedNpcs.length} NPCs',
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
                  TerminalText(
                    'Custo: ${totalCost.toStringAsFixed(1)} comida (${costPerNpc.toStringAsFixed(1)}/NPC)',
                    fontSize: 9,
                    color: AppTheme.orange,
                  ),
                  TerminalText(
                    'Sinergia: ${synergy.toStringAsFixed(0)}% ${synergy > 30 ? "(Excelente)" : synergy > 10 ? "(Boa)" : synergy < -10 ? "(Ruim)" : "(Neutra)"}',
                    fontSize: 9,
                    color: synergy > 30 ? AppTheme.green : synergy > 10 ? AppTheme.yellow : synergy < -10 ? AppTheme.red : AppTheme.textSecondary,
                  ),
                  TerminalText(
                    'Eficiencia: ${(totalYield * 100).toStringAsFixed(0)}% (atrib: ${(attributeYield * 100).toStringAsFixed(0)}%, pers: ${personalityMod >= 0 ? "+" : ""}${personalityMod.toStringAsFixed(0)}%)',
                    fontSize: 9,
                    color: totalYield > 1.3 ? AppTheme.green : totalYield > 1.0 ? AppTheme.yellow : AppTheme.orange,
                  ),
                  const SizedBox(height: 4),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 4),
                  const TerminalText(
                    'Estimativa de retorno (comida):',
                    fontSize: 9,
                    color: AppTheme.textDim,
                  ),
                  TerminalText(
                    'Lucro: ${netFood >= 0 ? "+" : ""}${netFood.toStringAsFixed(1)} ${netFood < 0 ? "(PREJUIZO)" : netFood < totalCost * 0.5 ? "(baixo)" : "(bom)"}',
                    fontSize: 9,
                    color: netFood < 0 ? AppTheme.red : netFood < totalCost * 0.5 ? AppTheme.orange : AppTheme.green,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 4),
                  const TerminalText(
                    'Riscos:',
                    fontSize: 9,
                    color: AppTheme.textDim,
                  ),
                  if (eventChances['acidente'] != null)
                    TerminalText(
                      'Acidente: ${(eventChances['acidente']! * 100).toStringAsFixed(0)}%',
                      fontSize: 8,
                      color: eventChances['acidente']! > 0.2 ? AppTheme.red : AppTheme.textDim,
                    ),
                  if (eventChances['doenca'] != null)
                    TerminalText(
                      'Doenca: ${(eventChances['doenca']! * 100).toStringAsFixed(0)}%',
                      fontSize: 8,
                      color: AppTheme.textDim,
                    ),
                  if (eventChances['conflito'] != null && eventChances['conflito']! > 0)
                    TerminalText(
                      'Conflito: ${(eventChances['conflito']! * 100).toStringAsFixed(0)}%',
                      fontSize: 8,
                      color: eventChances['conflito']! > 0.15 ? AppTheme.orange : AppTheme.textDim,
                    ),
                  if (eventChances['traicao'] != null && eventChances['traicao']! > 0)
                    TerminalText(
                      'Traicao: ${(eventChances['traicao']! * 100).toStringAsFixed(0)}% (!)',
                      fontSize: 8,
                      color: AppTheme.red,
                    ),
                  TerminalText(
                    'Ameaca Reativada: ${((0.05 + floor.timesReexplored * 0.02) * 100).toStringAsFixed(0)}%',
                    fontSize: 8,
                    color: floor.timesReexplored > 3 ? AppTheme.red : AppTheme.yellow,
                  ),
                  if (eventChances['evento_raro'] != null)
                    TerminalText(
                      'Evento Raro (2x recursos): ${(eventChances['evento_raro']! * 100).toStringAsFixed(0)}%',
                      fontSize: 8,
                      color: AppTheme.green,
                    ),
                ],
              ),
            );
          }

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
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                  ),
                  TerminalText(
                    'RE-EXPLORAR: ANDAR ${floor.number}',
                    fontSize: 14,
                    color: AppTheme.green,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  TerminalText(
                    '${floor.type.label} | Risco: $threatPct%',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  TerminalText(
                    'Recursos: ${floor.farmableResources.entries.map((e) => '${e.key}:~${e.value.toStringAsFixed(0)}').join(', ')}',
                    fontSize: 9,
                    color: AppTheme.cyan,
                  ),

                  // Mostra análise quando NPCs são selecionados
                  if (analysisWidget != null) analysisWidget,

                  const SizedBox(height: 12),

                  if (gp.groups.isNotEmpty) ...[
                    const TerminalText(
                      'Selecao rapida:',
                      fontSize: 10,
                      color: AppTheme.textDim,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: gp.groups.map((group) {
                        final alive = group.memberIds
                            .where(
                              (id) =>
                                  gp.allNpcs.any((n) => n.id == id && n.alive),
                            )
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

                  TerminalText(
                    'Coletores (${selectedIds.length}):',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),

                  ...gp.aliveNpcs.map((npc) {
                    final selected = selectedIds.contains(npc.id);
                    final isTooYoung = !npc.canGoOnExpedition(gp.state.currentDay);
                    final isDisabled = npc.isIncapacitated || isTooYoung;
                    final power = npc.attributes.combatPower;

                    final fatigueColor = npc.fatigue >= 90
                        ? const Color(0xFFFF0044)
                        : npc.fatigue >= 70
                        ? AppTheme.red
                        : npc.fatigue >= 50
                        ? AppTheme.orange
                        : npc.fatigue >= 30
                        ? AppTheme.yellow
                        : AppTheme.green;

                    // Tags de personalidade relevantes
                    final dangerTraits = npc.traits
                        .where(
                          (t) =>
                              t == PersonalityTrait.lazy ||
                              t == PersonalityTrait.coward ||
                              t == PersonalityTrait.treacherous ||
                              t == PersonalityTrait.individualist,
                        )
                        .map((t) => t.label)
                        .toList();
                    final goodTraits = npc.traits
                        .where(
                          (t) =>
                              t == PersonalityTrait.brave ||
                              t == PersonalityTrait.loyal ||
                              t == PersonalityTrait.ambitious ||
                              t == PersonalityTrait.analytical ||
                              t == PersonalityTrait.leader,
                        )
                        .map((t) => t.label)
                        .toList();

                    return GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () => setModalState(() {
                              if (selected) {
                                selectedIds.remove(npc.id);
                              } else {
                                selectedIds.add(npc.id);
                              }
                            }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDisabled
                                ? AppTheme.red.withValues(alpha: 0.3)
                                : selected
                                ? AppTheme.green
                                : AppTheme.border,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: isDisabled
                              ? AppTheme.red.withValues(alpha: 0.03)
                              : selected
                              ? AppTheme.green.withValues(alpha: 0.06)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                      : AppTheme.textDim,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TerminalText(
                                    '${npc.name} | ${npc.profession.label}',
                                    fontSize: 9,
                                    color: isDisabled
                                        ? AppTheme.red.withValues(alpha: 0.5)
                                        : selected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (npc.isSuspicious)
                                  const Icon(
                                    Icons.warning,
                                    size: 12,
                                    color: AppTheme.red,
                                  ),
                                const SizedBox(width: 4),
                                TerminalText(
                                  'F:${npc.fatigue.toStringAsFixed(0)}',
                                  fontSize: 8,
                                  color: fatigueColor,
                                ),
                                const SizedBox(width: 6),
                                TerminalText(
                                  'PWR:${power.toStringAsFixed(1)}',
                                  fontSize: 9,
                                  color: AppTheme.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            if (isTooYoung)
                              const Padding(
                                padding: EdgeInsets.only(left: 20, top: 2),
                                child: TerminalText(
                                  '[JOVEM DEMAIS - NAO PODE PARTICIPAR]',
                                  fontSize: 7,
                                  color: AppTheme.red,
                                ),
                              )
                            else if (isDisabled)
                              const Padding(
                                padding: EdgeInsets.only(left: 20, top: 2),
                                child: TerminalText(
                                  '[INCAPACITADO - NAO PODE PARTICIPAR]',
                                  fontSize: 7,
                                  color: AppTheme.red,
                                ),
                              )
                            else if (npc.isExhausted)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  top: 2,
                                ),
                                child: TerminalText(
                                  '[EXAUSTO - rendimento severamente reduzido]',
                                  fontSize: 7,
                                  color: AppTheme.red,
                                ),
                              )
                            else if (dangerTraits.isNotEmpty ||
                                goodTraits.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  top: 2,
                                ),
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    ...goodTraits.map(
                                      (t) => TerminalText(
                                        '[+$t]',
                                        fontSize: 7,
                                        color: AppTheme.green,
                                      ),
                                    ),
                                    ...dangerTraits.map(
                                      (t) => TerminalText(
                                        '[-$t]',
                                        fontSize: 7,
                                        color: AppTheme.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              floor.number,
                              selectedIds.toList(),
                            );
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
    BuildContext context,
    FloorExplorationResult result,
  ) {
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
            color: hasCasualties ? AppTheme.red : AppTheme.green,
          ),
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
            TerminalText(
              'Andar ${result.floorNumber}',
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
            const SizedBox(height: 8),
            const TerminalText('Recursos:', fontSize: 10, color: AppTheme.cyan),
            TerminalText(resStr, fontSize: 10, color: AppTheme.green),
            if (hasCasualties) ...[
              const SizedBox(height: 8),
              TerminalText(
                'BAIXAS: ${result.casualties.length}',
                fontSize: 10,
                color: AppTheme.red,
                fontWeight: FontWeight.bold,
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

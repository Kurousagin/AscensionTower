import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../models/tower.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> {
  final List<String> _selectedParty = [];
  bool _showResult = false;
  TowerChallenge? _result;

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
                _buildTowerOverview(gp),
                const SizedBox(height: 12),
                if (_showResult && _result != null)
                  _buildChallengeResult(_result!)
                else ...[
                  _buildNextFloor(gp),
                  const SizedBox(height: 12),
                  _buildPartySelection(gp),
                  const SizedBox(height: 12),
                  _buildActions(gp),
                ],
                const SizedBox(height: 12),
                _buildFloorList(gp),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTowerOverview(GameProvider gp) {
    final cleared = gp.state.highestFloorCleared;
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText('A TORRE', fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          _buildTowerAscii(cleared),
          const SizedBox(height: 8),
          Row(children: [
            TerminalText('Andares limpos: $cleared/10', fontSize: 10, color: AppTheme.green),
            const SizedBox(width: 16),
            TerminalText('Proximo: ${cleared + 1 <= 10 ? "Andar ${cleared + 1}" : "COMPLETO"}', fontSize: 10, color: AppTheme.yellow),
          ]),
        ],
      ),
    );
  }

  Widget _buildTowerAscii(int cleared) {
    final lines = <Widget>[];
    for (int i = 10; i >= 1; i--) {
      final floor = i;
      final isCleared = floor <= cleared;
      final isNext = floor == cleared + 1;
      final width = 6 + (10 - floor) * 2;
      final bar = '=' * width;
      Color color;
      String prefix;
      if (isCleared) {
        color = AppTheme.green;
        prefix = '[V]';
      } else if (isNext) {
        color = AppTheme.yellow;
        prefix = '[>]';
      } else {
        color = AppTheme.textDim;
        prefix = '[ ]';
      }
      lines.add(Center(
        child: TerminalText('$prefix ${floor.toString().padLeft(2, '0')} |$bar|',
            fontSize: 9, color: color),
      ));
    }
    return Column(children: lines);
  }

  Widget _buildNextFloor(GameProvider gp) {
    final floor = gp.nextFloor;
    if (floor == null) {
      return TerminalCard(
        borderColor: AppTheme.green,
        title: 'TORRE COMPLETA',
        child: const TerminalText('Todos os andares foram conquistados! A humanidade prevaleceu.', color: AppTheme.green),
      );
    }

    return TerminalCard(
      title: 'PROXIMO: ANDAR ${floor.number}',
      borderColor: floor.type == FloorType.boss ? AppTheme.red : AppTheme.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TerminalText(floor.type.icon, fontSize: 12, color: AppTheme.red),
            const SizedBox(width: 6),
            TerminalText(floor.type.label.toUpperCase(), fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            const Spacer(),
            TerminalText('DIF: ${floor.scaledDifficulty.toStringAsFixed(1)}', fontSize: 9, color: AppTheme.red),
          ]),
          const SizedBox(height: 6),
          TerminalText(floor.description, fontSize: 9, color: AppTheme.textSecondary),
          const SizedBox(height: 4),
          if (floor.specialCondition.isNotEmpty)
            TerminalText('> ${floor.specialCondition}', fontSize: 9, color: AppTheme.orange),
          const SizedBox(height: 4),
          Row(children: [
            TerminalText('Mortalidade: ${(floor.scaledMortality * 100).toStringAsFixed(0)}%', fontSize: 9, color: AppTheme.red),
            const SizedBox(width: 12),
            TerminalText('Recomp: ${floor.reward}', fontSize: 9, color: AppTheme.green),
          ]),
          TerminalText('Grupo recomendado: ${floor.recommendedPartySize} | Poder rec: ${floor.recommendedPower.toStringAsFixed(1)}',
              fontSize: 9, color: AppTheme.textDim),
        ],
      ),
    );
  }

  Widget _buildPartySelection(GameProvider gp) {
    final alive = gp.aliveNpcs;
    alive.sort((a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower));

    return TerminalCard(
      title: 'SELECIONAR GRUPO (${_selectedParty.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedParty.isNotEmpty) ...[
            TerminalText(
              'Poder total: ${_calculatePartyPower(gp).toStringAsFixed(1)}',
              fontSize: 10, color: AppTheme.orange, fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 6),
          ],
          ...alive.map((npc) {
            final selected = _selectedParty.contains(npc.id);
            final mentalOk = npc.attributes.mentalStability > 15;
            return GestureDetector(
              onTap: mentalOk ? () {
                setState(() {
                  if (selected) {
                    _selectedParty.remove(npc.id);
                  } else if (_selectedParty.length < 6) {
                    _selectedParty.add(npc.id);
                  }
                });
              } : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: selected ? AppTheme.cyan : AppTheme.border),
                  borderRadius: BorderRadius.circular(2),
                  color: selected ? AppTheme.cyan.withValues(alpha: 0.05) : null,
                ),
                child: Row(children: [
                  TerminalText(selected ? '[X]' : '[ ]', fontSize: 9, color: selected ? AppTheme.cyan : AppTheme.textDim),
                  const SizedBox(width: 6),
                  Expanded(child: TerminalText(npc.name, fontSize: 10,
                      color: mentalOk ? AppTheme.textPrimary : AppTheme.red.withValues(alpha: 0.5))),
                  TerminalText('${npc.profession.tag}', fontSize: 8, color: AppTheme.textDim),
                  const SizedBox(width: 8),
                  TerminalText('PWR:${npc.attributes.combatPower.toStringAsFixed(1)}', fontSize: 8, color: AppTheme.orange),
                  const SizedBox(width: 6),
                  TerminalText('MS:${npc.attributes.mentalStability.toStringAsFixed(0)}', fontSize: 8,
                      color: npc.attributes.mentalStability > 60 ? AppTheme.green :
                      npc.attributes.mentalStability > 30 ? AppTheme.yellow : AppTheme.red),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  double _calculatePartyPower(GameProvider gp) {
    double total = 0;
    for (final id in _selectedParty) {
      final npc = gp.allNpcs.firstWhere((n) => n.id == id);
      double power = npc.attributes.combatPower;
      if (npc.talentDiscovered && npc.hiddenTalent == HiddenTalent.combatGenius) power *= 1.5;
      if (npc.traits.contains(PersonalityTrait.brave)) power *= 1.1;
      if (npc.traits.contains(PersonalityTrait.coward)) power *= 0.85;
      total += power;
    }
    return total;
  }

  Widget _buildActions(GameProvider gp) {
    final hasParty = _selectedParty.isNotEmpty;
    final hasNextFloor = gp.nextFloor != null;
    final clearedFloors = gp.floors.where((f) => f.cleared).toList();

    return TerminalCard(
      title: 'ACOES',
      child: Column(
        children: [
          TerminalButton(
            label: 'EXPLORAR PROXIMO ANDAR',
            icon: Icons.arrow_upward,
            color: hasParty && hasNextFloor ? AppTheme.cyan : AppTheme.textDim,
            expanded: true,
            onPressed: hasParty && hasNextFloor && !gp.state.gameOver ? () {
              final result = gp.attemptFloor(_selectedParty.toList());
              setState(() {
                _result = result;
                _showResult = true;
                _selectedParty.removeWhere((id) => result.casualties.contains(id));
              });
            } : null,
          ),
          if (clearedFloors.isNotEmpty) ...[
            const SizedBox(height: 8),
            TerminalButton(
              label: 'TREINAR EM ANDAR LIMPO',
              icon: Icons.fitness_center,
              color: hasParty ? AppTheme.blue : AppTheme.textDim,
              expanded: true,
              onPressed: hasParty && !gp.state.gameOver ? () {
                _showTrainingPicker(gp, clearedFloors);
              } : null,
            ),
          ],
        ],
      ),
    );
  }

  void _showTrainingPicker(GameProvider gp, List<TowerFloor> floors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SELECIONAR ANDAR PARA TREINO'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: floors.map((f) => ListTile(
              dense: true,
              title: TerminalText('Andar ${f.number} - ${f.type.label}', fontSize: 10, color: AppTheme.textPrimary),
              subtitle: TerminalText(f.type.description, fontSize: 8, color: AppTheme.textDim),
              onTap: () {
                Navigator.pop(ctx);
                final result = gp.trainOnFloor(f.number, _selectedParty.toList());
                setState(() {
                  _result = result;
                  _showResult = true;
                });
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeResult(TowerChallenge result) {
    return TerminalCard(
      title: result.victory ? 'RESULTADO: VITORIA' : 'RESULTADO: DERROTA',
      borderColor: result.victory ? AppTheme.green : AppTheme.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...result.log.map((line) {
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
          }),
          const SizedBox(height: 12),
          TerminalButton(
            label: 'VOLTAR',
            icon: Icons.arrow_back,
            expanded: true,
            onPressed: () => setState(() {
              _showResult = false;
              _result = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorList(GameProvider gp) {
    return TerminalCard(
      title: 'MAPA DOS ANDARES',
      child: Column(
        children: gp.floors.reversed.map((floor) {
          final isCleared = floor.cleared;
          final isNext = floor.number == gp.state.highestFloorCleared + 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCleared ? AppTheme.green.withValues(alpha: 0.3) :
                       isNext ? AppTheme.yellow.withValues(alpha: 0.5) :
                       AppTheme.border.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(children: [
              TerminalText(
                isCleared ? '[V]' : isNext ? '[>]' : '[ ]',
                fontSize: 9,
                color: isCleared ? AppTheme.green : isNext ? AppTheme.yellow : AppTheme.textDim,
              ),
              const SizedBox(width: 6),
              TerminalText('${floor.number.toString().padLeft(2, '0')}', fontSize: 10,
                  color: isCleared ? AppTheme.green : AppTheme.textPrimary, fontWeight: FontWeight.bold),
              const SizedBox(width: 8),
              TerminalText(floor.type.icon, fontSize: 9, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: TerminalText(floor.type.label, fontSize: 9, color: AppTheme.textSecondary)),
              TerminalText('DIF:${floor.scaledDifficulty.toStringAsFixed(1)}', fontSize: 8, color: AppTheme.red),
              if (floor.deadOnFloor.isNotEmpty) ...[
                const SizedBox(width: 6),
                TerminalText('${floor.deadOnFloor.length} mortes', fontSize: 8, color: AppTheme.red),
              ],
            ]),
          );
        }).toList(),
      ),
    );
  }
}

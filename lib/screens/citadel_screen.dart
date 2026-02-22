import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/citadel.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class CitadelScreen extends StatelessWidget {
  const CitadelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final citadel = gp.citadel;
        final res = citadel.resources;

        return ScanlineOverlay(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCitadelHeader(citadel, gp),
                const SizedBox(height: 12),
                _buildResourcesDetailed(res),
                const SizedBox(height: 12),
                _buildBuildings(citadel),
                const SizedBox(height: 12),
                _buildBuildMenu(context, gp),
                const SizedBox(height: 12),
                _buildUpgradeSection(context, gp),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCitadelHeader(Citadel citadel, GameProvider gp) {
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText('CIDADELA: ${citadel.level.label.toUpperCase()}', fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          TerminalText(citadel.level.ascii, fontSize: 12, color: AppTheme.textDim),
          const SizedBox(height: 8),
          Row(children: [
            TerminalText('Edificios: ${citadel.buildings.length}/${citadel.level.maxBuildings}',
                fontSize: 10, color: AppTheme.textSecondary),
            const SizedBox(width: 16),
            TerminalText('Populacao: ${gp.population}/${citadel.populationCapacity}',
                fontSize: 10, color: AppTheme.textSecondary),
          ]),
        ],
      ),
    );
  }

  Widget _buildResourcesDetailed(Resources res) {
    return TerminalCard(
      title: 'RECURSOS',
      child: Column(
        children: [
          _resRow('Comida', res.food, AppTheme.green, 'Consumo: ${(res.food).toStringAsFixed(0)} disponivel'),
          _resRow('Madeira', res.wood, AppTheme.orange, 'Material de construcao'),
          _resRow('Pedra', res.stone, AppTheme.textSecondary, 'Construcao avancada'),
          _resRow('Ferro', res.iron, AppTheme.blue, 'Armas e ferramentas'),
          _resRow('Conhecimento', res.knowledge, AppTheme.purple, 'Pesquisa e evolucao'),
          const SizedBox(height: 4),
          StatBar(label: 'MORAL', value: res.morale, maxValue: 100,
              color: res.morale > 70 ? AppTheme.green : res.morale > 40 ? AppTheme.yellow : AppTheme.red),
        ],
      ),
    );
  }

  Widget _resRow(String label, double value, Color color, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 90, child: TerminalText(label, fontSize: 10, color: color)),
        TerminalText(value.toStringAsFixed(0), fontSize: 11, color: color, fontWeight: FontWeight.bold),
        const SizedBox(width: 8),
        Expanded(child: TerminalText(desc, fontSize: 8, color: AppTheme.textDim)),
      ]),
    );
  }

  Widget _buildBuildings(Citadel citadel) {
    if (citadel.buildings.isEmpty) {
      return const TerminalCard(
        title: 'EDIFICIOS',
        child: TerminalText('Nenhum edificio construido.', color: AppTheme.textDim),
      );
    }
    return TerminalCard(
      title: 'EDIFICIOS (${citadel.buildings.length})',
      child: Column(
        children: citadel.buildings.map((b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            TerminalText(b.tag, fontSize: 9, color: AppTheme.cyan),
            const SizedBox(width: 6),
            Expanded(child: TerminalText(b.name, fontSize: 10, color: AppTheme.textPrimary)),
            TerminalText('Nv.${b.level}', fontSize: 9, color: AppTheme.textDim),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildBuildMenu(BuildContext context, GameProvider gp) {
    final citadel = gp.citadel;
    final canBuild = citadel.buildings.length < citadel.level.maxBuildings;

    final available = BuildingType.values.where((type) {
      if (citadel.hasBuilding(type)) return false;
      return true;
    }).toList();

    return TerminalCard(
      title: 'CONSTRUIR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!canBuild)
            const TerminalText('Limite de edificios atingido. Evolua a Cidadela.', fontSize: 9, color: AppTheme.orange)
          else
            ...available.map((type) {
              final b = Building(type: type);
              final canAfford = citadel.resources.canAfford(b.cost);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  border: Border.all(color: canAfford ? AppTheme.border : AppTheme.border.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TerminalText(b.name, fontSize: 10, color: canAfford ? AppTheme.textPrimary : AppTheme.textDim,
                              fontWeight: FontWeight.bold),
                          TerminalText(b.description, fontSize: 8, color: AppTheme.textDim),
                          TerminalText(_costString(b.cost), fontSize: 8, color: canAfford ? AppTheme.green : AppTheme.red),
                        ],
                      ),
                    ),
                    TerminalButton(
                      label: 'BUILD',
                      color: canAfford ? AppTheme.green : AppTheme.textDim,
                      onPressed: canAfford ? () {
                        gp.buildStructure(type);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${b.name} construido(a)!'), backgroundColor: AppTheme.bgElevated),
                        );
                      } : null,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUpgradeSection(BuildContext context, GameProvider gp) {
    final citadel = gp.citadel;
    final next = citadel.nextLevel;
    if (next == null) {
      return const TerminalCard(
        title: 'EVOLUCAO',
        borderColor: AppTheme.green,
        child: TerminalText('Nivel maximo atingido! A Cidadela e um Reino.', color: AppTheme.green),
      );
    }

    final cost = citadel.upgradeCost;
    final canAfford = citadel.resources.canAfford(cost);
    final hasPopulation = gp.population >= next.populationRequired;
    final canUpgrade = canAfford && hasPopulation;

    return TerminalCard(
      title: 'EVOLUCAO DA CIDADELA',
      borderColor: canUpgrade ? AppTheme.cyan : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText('${citadel.level.label} -> ${next.label}', fontSize: 12, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          TerminalText('Custo: ${_costString(cost)}', fontSize: 9, color: canAfford ? AppTheme.green : AppTheme.red),
          TerminalText('Populacao necessaria: ${next.populationRequired} (atual: ${gp.population})',
              fontSize: 9, color: hasPopulation ? AppTheme.green : AppTheme.red),
          TerminalText('Max edificios: ${citadel.level.maxBuildings} -> ${next.maxBuildings}', fontSize: 9, color: AppTheme.textSecondary),
          const SizedBox(height: 8),
          TerminalButton(
            label: 'EVOLUIR CIDADELA',
            icon: Icons.upgrade,
            color: canUpgrade ? AppTheme.cyan : AppTheme.textDim,
            expanded: true,
            onPressed: canUpgrade ? () {
              gp.upgradeCitadel();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cidadela evoluiu para ${next.label}!'), backgroundColor: AppTheme.bgElevated),
              );
            } : null,
          ),
        ],
      ),
    );
  }

  String _costString(Resources cost) {
    final parts = <String>[];
    if (cost.food > 0) parts.add('C:${cost.food.toStringAsFixed(0)}');
    if (cost.wood > 0) parts.add('M:${cost.wood.toStringAsFixed(0)}');
    if (cost.stone > 0) parts.add('P:${cost.stone.toStringAsFixed(0)}');
    if (cost.iron > 0) parts.add('F:${cost.iron.toStringAsFixed(0)}');
    if (cost.knowledge > 0) parts.add('K:${cost.knowledge.toStringAsFixed(0)}');
    return parts.join(' | ');
  }
}

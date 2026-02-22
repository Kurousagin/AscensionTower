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
                _buildUpgradeSection(context, citadel, gp),
                const SizedBox(height: 12),
                _buildCurrentBuildings(context, citadel, gp),
                const SizedBox(height: 12),
                _buildBuildSection(context, citadel, gp),
                const SizedBox(height: 12),
                _buildHowItWorks(),
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
          TerminalText('CIDADELA: ${citadel.level.label.toUpperCase()}',
              fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          _buildCitadelAscii(citadel.level),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              TerminalText(
                  'Edificios: ${citadel.buildings.length}/${citadel.level.maxBuildings}',
                  fontSize: 10, color: AppTheme.textSecondary),
              TerminalText(
                  'Populacao: ${gp.population}/${citadel.populationCapacity}',
                  fontSize: 10, color: AppTheme.textSecondary),
              TerminalText(
                  'Tier Torre: ${((gp.state.highestFloorCleared) ~/ 10) + (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0)}',
                  fontSize: 10, color: AppTheme.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCitadelAscii(CitadelLevel level) {
    String art;
    switch (level) {
      case CitadelLevel.shelter:
        art = '  /\\_\n /  \\\n/____\\';
      case CitadelLevel.camp:
        art = '  /\\_   /\\_\n /  \\ /  \\\n/____X____\\';
      case CitadelLevel.village:
        art = '   _|_|_\n  /     \\\n /  [ ]  \\\n/=========\\';
      case CitadelLevel.town:
        art = '  |_|  _|_|_  |_|\n  | | /     \\ | |\n  | |/ [ ] [ ]\\| |\n==|=============|==';
      case CitadelLevel.city:
        art = '  |T|  _|_|_  |T|\n  | | /     \\ | |\n  | |/ [ ] [ ]\\| |\n==|=============|==';
      case CitadelLevel.fortress:
        art = ' /T\\  _|_|_  /T\\\n |=| /  *  \\ |=|\n |=|/ [=][=] \\|=|\n=|=============|=';
      case CitadelLevel.citadel:
        art = ' .|T|.  ._|_|_.  .|T|.\n |=|=| /  ***  \\ |=|=|\n |=|=|/ [=] [=] \\|=|=|\n=|===|===========|===|=';
      case CitadelLevel.kingdom:
        art = '  .*T*. .._|*|_.. .*T*.\n  |===| / *** *** \\ |===|\n  |===|/ [===][===] \\|===|\n==|=====|===========|=====|==';
      case CitadelLevel.empire:
        art = ' .***T***. .._|***|_.. .***T***.\n |=======| / ********* \\ |=======|\n |=======|/[====][====] \\|=======|\n=|=========|==============|=========|=';
      case CitadelLevel.ascended:
        art = '       ._*_.\n      / * * \\\n   ._|__*__|_.\n  / * * * * * \\\n |=============|\n=|=== APEX ===|=';
    }
    return TerminalText(art, fontSize: 9, color: AppTheme.cyan);
  }

  Widget _buildResourcesDetailed(Resources res) {
    return TerminalCard(
      title: 'RECURSOS',
      child: Column(
        children: [
          _resRow('Comida', res.food, AppTheme.green,
              'Consumo: ~${(res.food > 0 ? "estavel" : "CRITICO")}'),
          _resRow('Madeira', res.wood, AppTheme.orange, 'Material de construcao'),
          _resRow('Pedra', res.stone, AppTheme.textSecondary, 'Construcao avancada'),
          _resRow('Ferro', res.iron, AppTheme.blue, 'Armas e ferramentas'),
          _resRow('Conhecimento', res.knowledge, AppTheme.purple,
              'Pesquisa e evolucao'),
          const SizedBox(height: 4),
          StatBar(
              label: 'MORAL',
              value: res.morale,
              maxValue: 100,
              color: res.morale > 70
                  ? AppTheme.green
                  : res.morale > 40
                      ? AppTheme.yellow
                      : AppTheme.red),
        ],
      ),
    );
  }

  Widget _resRow(String label, double value, Color color, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
            width: 100,
            child: TerminalText(label, fontSize: 10, color: color)),
        TerminalText(value.toStringAsFixed(0),
            fontSize: 11, color: color, fontWeight: FontWeight.bold),
        const SizedBox(width: 8),
        Expanded(child: TerminalText(desc, fontSize: 8, color: AppTheme.textDim)),
      ]),
    );
  }

  // ==================== EVOLUCAO DA CIDADELA (MANUAL) ====================

  Widget _buildUpgradeSection(
      BuildContext context, Citadel citadel, GameProvider gp) {
    final next = citadel.nextLevel;
    if (next == null) {
      return TerminalCard(
        title: 'NIVEL MAXIMO',
        borderColor: AppTheme.green,
        child: const TerminalText(
            'A Cidadela atingiu o nivel Ascendido! Voce transcendeu.',
            color: AppTheme.green),
      );
    }

    final cost = citadel.upgradeCost;
    final canAfford = citadel.resources.canAfford(cost);
    final hasPopulation = gp.population >= next.populationRequired;
    final currentTier = ((gp.state.highestFloorCleared) ~/ 10) +
        (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0);
    final hasTier = currentTier >= next.requiredTowerTier;
    final canUpgrade = canAfford && hasPopulation && hasTier;

    return TerminalCard(
      title: 'EVOLUIR CIDADELA',
      borderColor: canUpgrade ? AppTheme.cyan : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText('${citadel.level.label} -> ${next.label}',
              fontSize: 12,
              color: AppTheme.cyan,
              fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          _progressRow('Comida', citadel.resources.food, cost.food),
          _progressRow('Madeira', citadel.resources.wood, cost.wood),
          _progressRow('Pedra', citadel.resources.stone, cost.stone),
          if (cost.iron > 0)
            _progressRow('Ferro', citadel.resources.iron, cost.iron),
          if (cost.knowledge > 0)
            _progressRow(
                'Conhecimento', citadel.resources.knowledge, cost.knowledge),
          const SizedBox(height: 4),
          Row(children: [
            TerminalText(
              'Populacao: ${gp.population}/${next.populationRequired}',
              fontSize: 9,
              color: hasPopulation ? AppTheme.green : AppTheme.red,
            ),
            const SizedBox(width: 12),
            TerminalText(
              'Tier Torre: $currentTier/${next.requiredTowerTier}',
              fontSize: 9,
              color: hasTier ? AppTheme.green : AppTheme.red,
            ),
          ]),
          const SizedBox(height: 4),
          TerminalText(
            'Apos evolucao: max ${next.maxBuildings} edificios',
            fontSize: 8,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 8),
          TerminalButton(
            label: canUpgrade ? 'EVOLUIR CIDADELA' : 'REQUISITOS FALTANDO',
            icon: Icons.upgrade,
            color: canUpgrade ? AppTheme.cyan : AppTheme.textDim,
            expanded: true,
            onPressed: canUpgrade
                ? () {
                    gp.upgradeCitadel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.bgCard,
                        content: TerminalText(
                            'Cidadela evoluiu para ${next.label}!',
                            color: AppTheme.cyan),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double current, double needed) {
    if (needed <= 0) return const SizedBox.shrink();
    final pct = (current / needed).clamp(0.0, 1.0);
    final enough = current >= needed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child:
                  TerminalText(label, fontSize: 9, color: AppTheme.textSecondary)),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppTheme.border),
              ),
              child: FractionallySizedBox(
                widthFactor: pct,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: enough ? AppTheme.green : AppTheme.cyan,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TerminalText(
              '${current.toStringAsFixed(0)}/${needed.toStringAsFixed(0)}',
              fontSize: 8,
              color: enough ? AppTheme.green : AppTheme.red,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EDIFICIOS CONSTRUIDOS ====================

  Widget _buildCurrentBuildings(
      BuildContext context, Citadel citadel, GameProvider gp) {
    if (citadel.buildings.isEmpty) {
      return TerminalCard(
        title: 'EDIFICIOS CONSTRUIDOS',
        child: const TerminalText(
            'Nenhum edificio construido. Use a secao abaixo para construir!',
            color: AppTheme.textDim),
      );
    }

    // Agrupar por categoria
    final byCategory = <BuildingCategory, List<Building>>{};
    for (final b in citadel.buildings) {
      byCategory.putIfAbsent(b.category, () => []).add(b);
    }

    return TerminalCard(
      title: 'EDIFICIOS CONSTRUIDOS (${citadel.buildings.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: byCategory.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: TerminalText('--- ${entry.key.label.toUpperCase()} ---',
                    fontSize: 8, color: AppTheme.textDim),
              ),
              ...entry.value.map((b) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      border: Border.all(
                          color: AppTheme.green.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                TerminalText(b.name,
                                    fontSize: 10,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold),
                                const SizedBox(width: 6),
                                TerminalText('Nv.${b.level}/${b.maxLevel}',
                                    fontSize: 9, color: AppTheme.green),
                              ],
                            ),
                            TerminalText(b.description,
                                fontSize: 8, color: AppTheme.textDim),
                          ],
                        ),
                      ),
                      if (b.level < b.maxLevel)
                        TerminalButton(
                          label: 'UP',
                          icon: Icons.arrow_upward,
                          color: gp.canUpgradeBuilding(b.type)
                              ? AppTheme.cyan
                              : AppTheme.textDim,
                          onPressed: gp.canUpgradeBuilding(b.type)
                              ? () {
                                  gp.upgradeBuilding(b.type);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppTheme.bgCard,
                                      content: TerminalText(
                                          '${b.name} evoluiu para nivel ${b.level + 1}!',
                                          color: AppTheme.cyan),
                                    ),
                                  );
                                }
                              : null,
                        ),
                    ]),
                  )),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ==================== CONSTRUIR NOVOS EDIFICIOS ====================

  Widget _buildBuildSection(
      BuildContext context, Citadel citadel, GameProvider gp) {
    final atLimit = citadel.buildings.length >= citadel.level.maxBuildings;
    final available = gp.availableBuildings;
    final currentTier = ((gp.state.highestFloorCleared) ~/ 10) +
        (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0);

    // Tambem mostrar edificios bloqueados por tier
    final locked = BuildingType.values.where((type) {
      if (citadel.hasBuilding(type)) return false;
      if (available.contains(type)) return false;
      final b = Building(type: type);
      return b.requiredTier > currentTier;
    }).toList();

    return TerminalCard(
      title: 'CONSTRUIR NOVO EDIFICIO',
      borderColor: AppTheme.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (atLimit) ...[
            const TerminalText(
                'Limite de edificios atingido! Evolua a Cidadela para desbloquear mais slots.',
                fontSize: 9,
                color: AppTheme.orange),
            const SizedBox(height: 8),
          ],
          const TerminalText(
              'VOCE ESCOLHE O QUE CONSTRUIR. NPCs reagirao a sua decisao.',
              fontSize: 9,
              color: AppTheme.orange,
              fontWeight: FontWeight.bold),
          const SizedBox(height: 8),

          // Edificios disponiveis (desbloqueados)
          if (available.isNotEmpty) ...[
            const TerminalText('DISPONIVEIS:',
                fontSize: 9, color: AppTheme.green),
            const SizedBox(height: 4),
            ...available.map((type) {
              final b = Building(type: type);
              final canAfford = citadel.resources.canAfford(b.cost);
              return _buildBuildingOption(context, gp, b, canAfford, atLimit);
            }),
          ] else ...[
            const TerminalText(
                'Nenhum edificio novo disponivel. Conquiste mais andares da Torre para desbloquear!',
                fontSize: 9,
                color: AppTheme.textDim),
          ],

          // Edificios bloqueados (por tier)
          if (locked.isNotEmpty) ...[
            const SizedBox(height: 12),
            TerminalText('BLOQUEADOS (${locked.length}):',
                fontSize: 9, color: AppTheme.textDim),
            const SizedBox(height: 4),
            ...locked.take(5).map((type) {
              final b = Building(type: type);
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  border: Border.all(
                      color: AppTheme.border.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 14, color: AppTheme.textDim),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TerminalText(b.name,
                              fontSize: 10, color: AppTheme.textDim),
                          TerminalText(b.description,
                              fontSize: 8, color: AppTheme.textDim),
                        ],
                      ),
                    ),
                    TerminalText('Tier ${b.requiredTier}',
                        fontSize: 8, color: AppTheme.red),
                  ],
                ),
              );
            }),
            if (locked.length > 5)
              TerminalText('...e mais ${locked.length - 5} edificios',
                  fontSize: 8, color: AppTheme.textDim),
          ],
        ],
      ),
    );
  }

  Widget _buildBuildingOption(BuildContext context, GameProvider gp,
      Building b, bool canAfford, bool atLimit) {
    final canBuild = canAfford && !atLimit;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        border: Border.all(
            color: canBuild
                ? AppTheme.orange.withValues(alpha: 0.4)
                : AppTheme.border.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TerminalText(b.name,
                        fontSize: 10,
                        color: canBuild ? AppTheme.textPrimary : AppTheme.textDim,
                        fontWeight: FontWeight.bold),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _categoryColor(b.category)
                                .withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TerminalText(b.category.label,
                          fontSize: 7, color: _categoryColor(b.category)),
                    ),
                  ],
                ),
                TerminalText(b.description,
                    fontSize: 8, color: AppTheme.textDim),
                TerminalText(_costString(b.cost),
                    fontSize: 8,
                    color: canAfford ? AppTheme.green : AppTheme.red),
              ],
            ),
          ),
          TerminalButton(
            label: 'CONSTRUIR',
            icon: Icons.build,
            color: canBuild ? AppTheme.orange : AppTheme.textDim,
            onPressed: canBuild
                ? () {
                    _confirmBuild(context, gp, b);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _confirmBuild(
      BuildContext context, GameProvider gp, Building building) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.orange),
        ),
        title: TerminalText('CONSTRUIR ${building.name.toUpperCase()}?',
            fontSize: 14, color: AppTheme.orange, fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(building.description,
                fontSize: 10, color: AppTheme.textSecondary),
            const SizedBox(height: 8),
            TerminalText('Custo: ${_costString(building.cost)}',
                fontSize: 10, color: AppTheme.cyan),
            const SizedBox(height: 8),
            const TerminalText(
                'Os moradores podem reagir positiva ou negativamente a esta construcao.',
                fontSize: 9,
                color: AppTheme.textDim),
          ],
        ),
        actions: [
          TerminalButton(
            label: 'CANCELAR',
            color: AppTheme.textDim,
            onPressed: () => Navigator.pop(ctx),
          ),
          TerminalButton(
            label: 'CONSTRUIR',
            icon: Icons.build,
            color: AppTheme.orange,
            onPressed: () {
              Navigator.pop(ctx);
              final result = gp.buildStructure(building.type);
              if (result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.bgCard,
                    content: TerminalText(
                        '${building.name} construido! NPCs reagindo...',
                        color: AppTheme.green),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _categoryColor(BuildingCategory cat) {
    switch (cat) {
      case BuildingCategory.essential:
        return AppTheme.green;
      case BuildingCategory.production:
        return AppTheme.orange;
      case BuildingCategory.knowledge:
        return AppTheme.purple;
      case BuildingCategory.military:
        return AppTheme.red;
      case BuildingCategory.social:
        return AppTheme.yellow;
      case BuildingCategory.advanced:
        return AppTheme.cyan;
      case BuildingCategory.endgame:
        return const Color(0xFFFF44FF);
    }
  }

  // ==================== INFO ====================

  Widget _buildHowItWorks() {
    return TerminalCard(
      title: 'COMO FUNCIONA',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            'VOCE DECIDE: Escolha quais edificios construir e quando evoluir a cidadela. '
            'Os NPCs REAGEM as suas decisoes com eventos narrativos - '
            'alguns podem aprovar, outros podem se revoltar.',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 6),
          TerminalText(
            'EDIFICIOS DESBLOQUEIAM POR TIER: Conforme voce conquista andares '
            'da Torre, novos tipos de edificio se tornam disponiveis.',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 6),
          TerminalText(
            'UPGRADE: Cada edificio pode ser melhorado ate nivel 5. '
            'Upgrades custam recursos crescentes mas aumentam a eficiencia.',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 6),
          TerminalText(
            'CIDADELA EVOLUI: Abrigo > Acampamento > Vila > Povoado > '
            'Cidade > Fortaleza > Cidadela > Reino > Imperio > Ascendido',
            fontSize: 9,
            color: AppTheme.cyan,
          ),
          SizedBox(height: 6),
          TerminalText(
            'Edificios especiais:\n'
            '  Taverna - revela traidores por fofocas\n'
            '  Arena - duelos entre NPCs, resolve conflitos\n'
            '  C. Sintese - combina materiais raros\n'
            '  S. Promocao - evolui rank de NPCs\n'
            '  Conselho - votacoes politicas democraticas\n'
            '  Nexus - conexao com a Torre, -10% dificuldade',
            fontSize: 9,
            color: AppTheme.textDim,
          ),
        ],
      ),
    );
  }

  String _costString(Resources cost) {
    final parts = <String>[];
    if (cost.food > 0) parts.add('Comida:${cost.food.toStringAsFixed(0)}');
    if (cost.wood > 0) parts.add('Madeira:${cost.wood.toStringAsFixed(0)}');
    if (cost.stone > 0) parts.add('Pedra:${cost.stone.toStringAsFixed(0)}');
    if (cost.iron > 0) parts.add('Ferro:${cost.iron.toStringAsFixed(0)}');
    if (cost.knowledge > 0) {
      parts.add('Conhec.:${cost.knowledge.toStringAsFixed(0)}');
    }
    return parts.join(' | ');
  }
}

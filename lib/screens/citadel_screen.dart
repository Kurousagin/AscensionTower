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

        return ScanlineOverlay(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCitadelHeader(citadel, gp),
                const SizedBox(height: 12),
                // DEBUG — remover depois
                // Row(
                //   children: [
                //     ElevatedButton(
                //       onPressed: () =>
                //           context.read<GameProvider>().debugForceCouple(),
                //       child: const Text('🧪 Forçar Casal'),
                //     ),
                //     const SizedBox(width: 8),
                //     ElevatedButton(
                //       onPressed: () =>
                //           context.read<GameProvider>().debugAdvanceDays(10),
                //       child: const Text('⏩ +10 dias'),
                //     ),
                //     const SizedBox(width: 8),
                //     ElevatedButton(
                //       onPressed: () =>
                //           context.read<GameProvider>().debugAddResources(),
                //       child: const Text('💰 +200 recursos'),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 12),
                _buildResourcesDetailed(citadel, gp),
                const SizedBox(height: 12),
                _buildStorageUpgrade(context, citadel, gp),
                const SizedBox(height: 12),
                _buildUpgradeSection(context, citadel, gp),
                const SizedBox(height: 12),
                _buildRequestSettlersSection(context, citadel, gp),
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
          TerminalText(
            'CIDADELA: ${citadel.level.label.toUpperCase()}',
            fontSize: 14,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          _buildCitadelAscii(citadel.level),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              TerminalText(
                'Edificios: ${citadel.buildings.length}/${citadel.level.maxBuildings}',
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              TerminalText(
                'Populacao: ${gp.population}/${citadel.totalPopulationCapacity}',
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              TerminalText(
                'Tier Torre: ${((gp.state.highestFloorCleared) ~/ 10) + (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0)}',
                fontSize: 10,
                color: AppTheme.orange,
              ),
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
        art =
            '  |_|  _|_|_  |_|\n  | | /     \\ | |\n  | |/ [ ] [ ]\\| |\n==|=============|==';
      case CitadelLevel.city:
        art =
            '  |T|  _|_|_  |T|\n  | | /     \\ | |\n  | |/ [ ] [ ]\\| |\n==|=============|==';
      case CitadelLevel.fortress:
        art =
            ' /T\\  _|_|_  /T\\\n |=| /  *  \\ |=|\n |=|/ [=][=] \\|=|\n=|=============|=';
      case CitadelLevel.citadel:
        art =
            ' .|T|.  ._|_|_.  .|T|.\n |=|=| /  ***  \\ |=|=|\n |=|=|/ [=] [=] \\|=|=|\n=|===|===========|===|=';
      case CitadelLevel.kingdom:
        art =
            '  .*T*. .._|*|_.. .*T*.\n  |===| / ********* \\ |===|\n  |===|/ [===][===] \\|===|\n==|=====|===========|=====|==';
      case CitadelLevel.empire:
        art =
            ' .***T***. .._|***|_.. .***T***.\n |=======| / ********* \\ |=======|\n |=======|/[====][====] \\|=======|\n=|=========|==============|=========|=';
      case CitadelLevel.ascended:
        art =
            '       ._*_.\n      / * * \\\n   ._|__*__|_.\n  / * * * * * \\\n |=============|\n=|=== APEX ===|=';
    }
    return TerminalText(art, fontSize: 9, color: AppTheme.cyan);
  }

  Widget _buildResourcesDetailed(Citadel citadel, GameProvider gp) {
    final res = citadel.resources;
    final cap = citadel.storageCapacity;
    final isInfinite = citadel.hasInfiniteStorage;
    final atCapacity = !isInfinite && res.anyAtCapacity(citadel.storageLevel);

    // Calcular uso percentual medio
    final maxUsage = isInfinite
        ? 0.0
        : [
            res.food / cap,
            res.wood / cap,
            res.stone / cap,
            res.iron / cap,
            res.knowledge / cap,
          ].reduce((a, b) => a > b ? a : b);

    Color storageBorderColor = AppTheme.border;
    if (!isInfinite) {
      if (maxUsage >= 1.0) {
        storageBorderColor = AppTheme.red;
      } else if (maxUsage >= 0.8) {
        storageBorderColor = AppTheme.orange;
      } else if (maxUsage >= 0.6) {
        storageBorderColor = AppTheme.yellow;
      }
    }

    return TerminalCard(
      title: 'RECURSOS',
      borderColor: storageBorderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de capacidade do armazem
          Row(
            children: [
              Icon(
                isInfinite ? Icons.all_inclusive : Icons.warehouse,
                size: 11,
                color: isInfinite
                    ? AppTheme.green
                    : atCapacity
                    ? AppTheme.red
                    : AppTheme.cyan,
              ),
              const SizedBox(width: 4),
              TerminalText(
                '${citadel.storageLabel}  ',
                fontSize: 9,
                color: isInfinite ? AppTheme.green : AppTheme.cyan,
              ),
              TerminalText(
                isInfinite
                    ? 'Capacidade: INFINITA'
                    : 'Capacidade: ${cap.toStringAsFixed(0)} por recurso',
                fontSize: 9,
                color: atCapacity ? AppTheme.red : AppTheme.textDim,
              ),
              const Spacer(),
              if (!isInfinite)
                TerminalText(
                  '${(maxUsage * 100).toStringAsFixed(0)}% cheio',
                  fontSize: 8,
                  color: maxUsage >= 0.9
                      ? AppTheme.red
                      : maxUsage >= 0.7
                      ? AppTheme.orange
                      : AppTheme.textDim,
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Barra de uso geral do armazem
          if (!isInfinite) ...[
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(1),
                border: Border.all(color: AppTheme.border),
              ),
              child: FractionallySizedBox(
                widthFactor: maxUsage.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: maxUsage >= 1.0
                        ? AppTheme.red
                        : maxUsage >= 0.8
                        ? AppTheme.orange
                        : maxUsage >= 0.6
                        ? AppTheme.yellow
                        : AppTheme.green,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          _resRowCapped(
            'Comida',
            res.food,
            cap,
            isInfinite,
            AppTheme.green,
            'Consumo: ~${gp.dailyFoodConsumption.toStringAsFixed(1)}/dia',
          ),
          _resRowCapped(
            'Madeira',
            res.wood,
            cap,
            isInfinite,
            AppTheme.orange,
            'Material de construcao',
          ),
          _resRowCapped(
            'Pedra',
            res.stone,
            cap,
            isInfinite,
            AppTheme.textSecondary,
            'Construcao avancada',
          ),
          _resRowCapped(
            'Ferro',
            res.iron,
            cap,
            isInfinite,
            AppTheme.blue,
            'Armas e ferramentas',
          ),
          _resRowCapped(
            'Conhecimento',
            res.knowledge,
            cap,
            isInfinite,
            AppTheme.purple,
            'Pesquisa e evolucao',
          ),
          TerminalText(
            'Bônus diário: +${gp.dailyFoodBonus.toStringAsFixed(1)} comida  '
            '+${gp.dailyWoodBonus.toStringAsFixed(1)} madeira  '
            '+${gp.dailyIronBonus.toStringAsFixed(1)} ferro  '
            '+${gp.dailyResearchBonus.toStringAsFixed(1)} conhecimento  '
            '+${gp.dailyMoraleBonus.toStringAsFixed(1)} moral',
            fontSize: 9,
            color: AppTheme.green,
          ),
          const SizedBox(height: 4),
          StatBar(
            label: 'MORAL',
            value: res.morale,
            maxValue: 100,
            color: res.morale > 70
                ? AppTheme.green
                : res.morale > 40
                ? AppTheme.yellow
                : AppTheme.red,
          ),
          const SizedBox(height: 6),

          // Avisos de capacidade
          if (!isInfinite && atCapacity)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.red.withValues(alpha: 0.10),
                border: Border.all(color: AppTheme.red.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 14, color: AppTheme.red),
                  SizedBox(width: 6),
                  Expanded(
                    child: TerminalText(
                      'ARMAZEM CHEIO! Excedente sendo PERDIDO. Amplie o armazem urgente.',
                      fontSize: 8,
                      color: AppTheme.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (!isInfinite && maxUsage >= 0.80)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppTheme.orange.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, size: 12, color: AppTheme.orange),
                  SizedBox(width: 6),
                  Expanded(
                    child: TerminalText(
                      'Armazem quase cheio. Recursos podem ser perdidos em breve.',
                      fontSize: 8,
                      color: AppTheme.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resRowCapped(
    String label,
    double value,
    double cap,
    bool isInfinite,
    Color color,
    String desc,
  ) {
    final pct = isInfinite ? 0.0 : (value / cap).clamp(0.0, 1.0);
    final atCap = !isInfinite && value >= cap;
    final nearCap = !isInfinite && pct >= 0.80 && !atCap;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: TerminalText(label, fontSize: 10, color: color),
          ),
          TerminalText(
            value.toStringAsFixed(0),
            fontSize: 11,
            color: atCap
                ? AppTheme.red
                : nearCap
                ? AppTheme.orange
                : color,
            fontWeight: FontWeight.bold,
          ),
          if (!isInfinite) ...[
            TerminalText(
              '/${cap.toStringAsFixed(0)}',
              fontSize: 8,
              color: AppTheme.textDim,
            ),
            const SizedBox(width: 3),
            if (atCap)
              const TerminalText('[MAX]', fontSize: 7, color: AppTheme.red)
            else if (nearCap)
              TerminalText(
                '[${(pct * 100).toStringAsFixed(0)}%]',
                fontSize: 7,
                color: AppTheme.orange,
              ),
          ] else
            const TerminalText('/INF', fontSize: 8, color: AppTheme.green),
          const SizedBox(width: 6),
          Expanded(
            child: TerminalText(desc, fontSize: 8, color: AppTheme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageUpgrade(
    BuildContext context,
    Citadel citadel,
    GameProvider gp,
  ) {
    final next = citadel.storageLevel.nextLevel;
    if (next == null) {
      return TerminalCard(
        title: 'ARMAZEM ESPACIAL',
        borderColor: AppTheme.green,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.all_inclusive, size: 16, color: AppTheme.green),
                SizedBox(width: 6),
                TerminalText(
                  'Armazem Espacial ativo!',
                  color: AppTheme.green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            SizedBox(height: 4),
            TerminalText(
              'Capacidade INFINITA. Nunca mais perca recursos por falta de espaco.',
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      );
    }

    final cost = citadel.storageLevel.upgradeCost;
    final canAfford = citadel.resources.canAfford(cost);
    final currentTier =
        ((gp.state.highestFloorCleared) ~/ 10) +
        (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0);
    final hasTier = currentTier >= next.requiredTier;
    final canUpgrade = canAfford && hasTier;
    final atCapacity = citadel.resources.anyAtCapacity(citadel.storageLevel);
    final isUrgent = atCapacity && !canUpgrade;

    return TerminalCard(
      title: 'ARMAZEM',
      borderColor: atCapacity
          ? (canUpgrade ? AppTheme.orange : AppTheme.red)
          : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status atual do armazem
          Row(
            children: [
              // Niveis em sequencia visual
              for (int i = 0; i < StorageLevel.values.length; i++) ...[
                if (i > 0)
                  const TerminalText(
                    ' > ',
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: StorageLevel.values[i] == citadel.storageLevel
                          ? AppTheme.orange
                          : AppTheme.border,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    color: StorageLevel.values[i] == citadel.storageLevel
                        ? AppTheme.orange.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: TerminalText(
                    StorageLevel.values[i].isInfinite
                        ? 'INF'
                        : StorageLevel.values[i].capacity.toStringAsFixed(0),
                    fontSize: 8,
                    color: StorageLevel.values[i] == citadel.storageLevel
                        ? AppTheme.orange
                        : AppTheme.textDim,
                    fontWeight: StorageLevel.values[i] == citadel.storageLevel
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          if (isUrgent)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.red.withValues(alpha: 0.10),
                border: Border.all(color: AppTheme.red),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, size: 12, color: AppTheme.red),
                  SizedBox(width: 6),
                  Expanded(
                    child: TerminalText(
                      'ARMAZEM CHEIO! Recursos estao sendo PERDIDOS. '
                      'Expanda sua capacidade para parar o desperdicio.',
                      fontSize: 8,
                      color: AppTheme.red,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              TerminalText(
                '${citadel.storageLevel.shortLabel} (${citadel.storageCapacity.toStringAsFixed(0)})',
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              const TerminalText(
                '  ->  ',
                fontSize: 9,
                color: AppTheme.textDim,
              ),
              TerminalText(
                next.isInfinite
                    ? '${next.shortLabel} (INFINITO)'
                    : '${next.shortLabel} (${next.capacity.toStringAsFixed(0)})',
                fontSize: 11,
                color: AppTheme.orange,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TerminalText(
            'Custo: ${_costString(cost)}',
            fontSize: 9,
            color: canAfford ? AppTheme.green : AppTheme.red,
          ),
          if (!canAfford)
            TerminalText(
              'Faltam recursos para construir.',
              fontSize: 8,
              color: AppTheme.red,
            ),
          if (!hasTier)
            TerminalText(
              'Requer Tier ${next.requiredTier} da Torre (atual: $currentTier)',
              fontSize: 9,
              color: AppTheme.red,
            ),

          if (next.isInfinite)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: const TerminalText(
                'ARMAZEM ESPACIAL: Marco de progressao final. Extremamente dificil de alcancar.',
                fontSize: 8,
                color: AppTheme.yellow,
              ),
            ),

          const SizedBox(height: 8),
          TerminalButton(
            label: canUpgrade ? 'AMPLIAR ARMAZEM' : 'REQUISITOS FALTANDO',
            icon: Icons.warehouse,
            color: canUpgrade ? AppTheme.orange : AppTheme.textDim,
            expanded: true,
            onPressed: canUpgrade
                ? () {
                    gp.upgradeStorage();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.bgCard,
                        content: TerminalText(
                          'Armazem evoluiu para ${next.label}! Cap: ${next.isInfinite ? "INFINITA" : next.capacity.toStringAsFixed(0)}',
                          color: AppTheme.orange,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ==================== EVOLUCAO DA CIDADELA (MANUAL) ====================

  Widget _buildUpgradeSection(
    BuildContext context,
    Citadel citadel,
    GameProvider gp,
  ) {
    final next = citadel.nextCitadelLevel;
    if (next == null) {
      return TerminalCard(
        title: 'NIVEL MAXIMO',
        borderColor: AppTheme.green,
        child: const TerminalText(
          'A Cidadela atingiu o nivel Ascendido! Voce transcendeu.',
          color: AppTheme.green,
        ),
      );
    }

    final cost = citadel.upgradeCost;
    final canAfford = citadel.resources.canAfford(cost.toResources());
    final hasPopulation = gp.population >= next.populationRequired;
    final currentTier =
        ((gp.state.highestFloorCleared) ~/ 10) +
        (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0);
    final hasTier = currentTier >= next.requiredTowerTier;
    final canUpgrade = canAfford && hasPopulation && hasTier;

    return TerminalCard(
      title: 'EVOLUIR CIDADELA',
      borderColor: canUpgrade ? AppTheme.cyan : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            '${citadel.level.label} -> ${next.label}',
            fontSize: 12,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          _progressRow('Comida', citadel.resources.food, cost.food),
          _progressRow('Madeira', citadel.resources.wood, cost.wood),
          _progressRow('Pedra', citadel.resources.stone, cost.stone),
          if (cost.iron > 0)
            _progressRow('Ferro', citadel.resources.iron, cost.iron),
          if (cost.knowledge > 0)
            _progressRow(
              'Conhecimento',
              citadel.resources.knowledge,
              cost.knowledge,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
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
            ],
          ),
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
                          color: AppTheme.cyan,
                        ),
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
            child: TerminalText(
              label,
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
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

  // ==================== SOLICITAR NOVOS MORADORES ====================

  Widget _buildRequestSettlersSection(
    BuildContext context,
    Citadel citadel,
    GameProvider gp,
  ) {
    final spacesAvailable = citadel.totalPopulationCapacity - gp.population;
    final isOvercapacity = gp.population > citadel.totalPopulationCapacity;
    final canRequest = citadel.resources.morale >= 60 && spacesAvailable > 0;

    return TerminalCard(
      title: 'SOLICITAR NOVOS MORADORES',
      borderColor: canRequest ? AppTheme.green : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOvercapacity) ...[
            TerminalText(
              '⚠️ SUPERPOPULACAO: ${gp.population}/${citadel.totalPopulationCapacity}',
              fontSize: 10,
              color: AppTheme.orange,
              fontWeight: FontWeight.bold,
            ),
            const TerminalText(
              'Populacao acima do limite! Construa mais moradias ou evolua a cidadela.',
              fontSize: 8,
              color: AppTheme.orange,
            ),
            const SizedBox(height: 8),
          ],

          TerminalText(
            'Espacos disponiveis: $spacesAvailable',
            fontSize: 10,
            color: spacesAvailable > 0 ? AppTheme.green : AppTheme.red,
          ),
          const SizedBox(height: 4),
          const TerminalText(
            'Custo: ~30 comida por morador',
            fontSize: 8,
            color: AppTheme.textDim,
          ),
          const TerminalText(
            'Moral necessaria: 60+ (chance de familias e casais)',
            fontSize: 8,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 8),

          TerminalButton(
            label: canRequest ? 'SOLICITAR MORADORES' : 'REQUISITOS FALTANDO',
            icon: Icons.group_add,
            color: canRequest ? AppTheme.green : AppTheme.textDim,
            expanded: true,
            onPressed: canRequest
                ? () {
                    final result = gp.requestNewSettlers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.bgCard,
                        content: TerminalText(result, color: AppTheme.green),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ==================== EDIFICIOS CONSTRUIDOS ====================

  Widget _buildCurrentBuildings(
    BuildContext context,
    Citadel citadel,
    GameProvider gp,
  ) {
    if (citadel.buildings.isEmpty) {
      return TerminalCard(
        title: 'EDIFICIOS CONSTRUIDOS',
        child: const TerminalText(
          'Nenhum edificio construido. Use a secao abaixo para construir!',
          color: AppTheme.textDim,
        ),
      );
    }

    // Agrupar por categoria e por tipo
    final byCategory = <BuildingCategory, Map<BuildingType, List<Building>>>{};
    for (final b in citadel.buildings) {
      byCategory.putIfAbsent(b.category, () => {});
      byCategory[b.category]!.putIfAbsent(b.type, () => []).add(b);
    }

    return TerminalCard(
      title: 'EDIFICIOS CONSTRUIDOS (${citadel.buildings.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: byCategory.entries.map((categoryEntry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: TerminalText(
                  '--- ${categoryEntry.key.label.toUpperCase()} ---',
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
              ),
              ...categoryEntry.value.entries.map((typeEntry) {
                final buildings = typeEntry.value;
                final first = buildings.first;
                final count = buildings.length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    border: Border.all(
                      color: AppTheme.green.withValues(alpha: 0.2),
                    ),
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
                                if (count > 1) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyan.withValues(
                                        alpha: 0.2,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.cyan.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: TerminalText(
                                      'x$count',
                                      fontSize: 8,
                                      color: AppTheme.cyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                TerminalText(
                                  first.name,
                                  fontSize: 10,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(width: 6),
                                TerminalText(
                                  'Nv.${first.level}/${first.maxLevel}',
                                  fontSize: 9,
                                  color: AppTheme.green,
                                ),
                              ],
                            ),
                            TerminalText(
                              first.description,
                              fontSize: 8,
                              color: AppTheme.textDim,
                            ),
                            if (first.level < first.maxLevel)
                              TerminalText(
                                count > 1
                                    ? 'Custo de upgrade (${count}x): ${_costString(_multiplyResources(first.upgradeCost, count))}'
                                    : 'Custo de upgrade: ${_costString(first.upgradeCost)}',
                                fontSize: 8,
                                color: AppTheme.orange,
                              ),
                          ],
                        ),
                      ),
                      if (first.level < first.maxLevel)
                        TerminalButton(
                          label: count > 1 ? 'UP TODAS' : 'UP',
                          icon: Icons.arrow_upward,
                          color: gp.canUpgradeAllBuildings(first.type)
                              ? AppTheme.cyan
                              : AppTheme.textDim,
                          onPressed: gp.canUpgradeAllBuildings(first.type)
                              ? () {
                                  // Upgrade todas as cópias de uma vez
                                  final success = gp.upgradeAllBuildings(
                                    first.type,
                                  );
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTheme.bgCard,
                                        content: TerminalText(
                                          count > 1
                                              ? '$count x ${first.name} evoluiram para nivel ${first.level + 1}!'
                                              : '${first.name} evoluiu para nivel ${first.level + 1}!',
                                          color: AppTheme.cyan,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Resources _multiplyResources(Resources r, int factor) => Resources(
    food: r.food * factor,
    wood: r.wood * factor,
    stone: r.stone * factor,
    iron: r.iron * factor,
    knowledge: r.knowledge * factor,
  );

  // ==================== CONSTRUIR NOVOS EDIFICIOS ====================

  Widget _buildBuildSection(
    BuildContext context,
    Citadel citadel,
    GameProvider gp,
  ) {
    final atLimit = citadel.buildings.length >= citadel.level.maxBuildings;
    final available = gp.availableBuildings;
    final currentTier =
        ((gp.state.highestFloorCleared) ~/ 10) +
        (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0);

    // Tambem mostrar edificios bloqueados por tier
    final locked = BuildingType.values.where((type) {
      if (available.contains(type)) return false;
      final b = Building(type: type);

      // Se ja atingiu o limite de copias, nao mostrar como locked (esta disponivel para upgrade)
      final count = citadel.countBuildings(type);
      final maxCopies = b.isUnique ? 1 : citadel.level.maxBuildingCopies;
      if (count >= maxCopies) return false;

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
              color: AppTheme.orange,
            ),
            const SizedBox(height: 8),
          ],
          const TerminalText(
            'VOCE ESCOLHE O QUE CONSTRUIR. NPCs reagirao a sua decisao.',
            fontSize: 9,
            color: AppTheme.orange,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),

          // Edificios disponiveis (desbloqueados)
          if (available.isNotEmpty) ...[
            const TerminalText(
              'DISPONIVEIS:',
              fontSize: 9,
              color: AppTheme.green,
            ),
            const SizedBox(height: 4),
            ...available.map((type) {
              try {
                final b = Building(type: type);
                final canAfford = citadel.resources.canAfford(
                  b.cost.toResources(),
                );
                return _buildBuildingOption(context, gp, b, canAfford, atLimit);
              } catch (e) {
                return const SizedBox.shrink(); // falha silenciosa segura
              }
            }),
          ] else ...[
            const TerminalText(
              'Nenhum edificio novo disponivel. Conquiste mais andares da Torre para desbloquear!',
              fontSize: 9,
              color: AppTheme.textDim,
            ),
          ],

          // Edificios bloqueados (por tier)
          if (locked.isNotEmpty) ...[
            const SizedBox(height: 12),
            TerminalText(
              'BLOQUEADOS (${locked.length}):',
              fontSize: 9,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 4),
            ...locked.take(5).map((type) {
              final b = Building(type: type);
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.2),
                  ),
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
                          TerminalText(
                            b.name,
                            fontSize: 10,
                            color: AppTheme.textDim,
                          ),
                          TerminalText(
                            b.description,
                            fontSize: 8,
                            color: AppTheme.textDim,
                          ),
                        ],
                      ),
                    ),
                    TerminalText(
                      'Tier ${b.requiredTier}',
                      fontSize: 8,
                      color: AppTheme.red,
                    ),
                  ],
                ),
              );
            }),
            if (locked.length > 5)
              TerminalText(
                '...e mais ${locked.length - 5} edificios',
                fontSize: 8,
                color: AppTheme.textDim,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuildingOption(
    BuildContext context,
    GameProvider gp,
    Building b,
    bool canAfford,
    bool atLimit,
  ) {
    final canBuild = canAfford;
    final citadel = gp.citadel;
    final currentCount = citadel.countBuildings(b.type);
    final maxCopies = b.isUnique ? 1 : citadel.level.maxBuildingCopies;
    final showCopyInfo = currentCount > 0 || !b.isUnique;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        border: Border.all(
          color: canBuild
              ? AppTheme.orange.withValues(alpha: 0.4)
              : AppTheme.border.withValues(alpha: 0.3),
        ),
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
                    TerminalText(
                      b.name,
                      fontSize: 10,
                      color: canBuild ? AppTheme.textPrimary : AppTheme.textDim,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _categoryColor(
                            b.category,
                          ).withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TerminalText(
                        b.category.label,
                        fontSize: 7,
                        color: _categoryColor(b.category),
                      ),
                    ),
                    if (showCopyInfo) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: currentCount >= maxCopies
                              ? AppTheme.red.withValues(alpha: 0.2)
                              : AppTheme.cyan.withValues(alpha: 0.2),
                          border: Border.all(
                            color: currentCount >= maxCopies
                                ? AppTheme.red.withValues(alpha: 0.5)
                                : AppTheme.cyan.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TerminalText(
                          b.isUnique ? 'UNICA' : '$currentCount/$maxCopies',
                          fontSize: 7,
                          color: currentCount >= maxCopies
                              ? AppTheme.red
                              : AppTheme.cyan,
                        ),
                      ),
                    ],
                  ],
                ),
                TerminalText(
                  b.description,
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
                TerminalText(
                  _costString(b.cost.toResources()),
                  fontSize: 8,
                  color: canAfford ? AppTheme.green : AppTheme.red,
                ),
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

  void _confirmBuild(BuildContext context, GameProvider gp, Building building) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.orange),
        ),
        title: TerminalText(
          'CONSTRUIR ${building.name.toUpperCase()}?',
          fontSize: 14,
          color: AppTheme.orange,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(
              building.description,
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            TerminalText(
              'Custo: ${_costString(building.cost.toResources())}',
              fontSize: 10,
              color: AppTheme.cyan,
            ),
            const SizedBox(height: 8),
            const TerminalText(
              'Os moradores podem reagir positiva ou negativamente a esta construcao.',
              fontSize: 9,
              color: AppTheme.textDim,
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
                      color: AppTheme.green,
                    ),
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

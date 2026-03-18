import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/npc.dart';
import 'package:tower_ascension/models/npc_enums.dart';
import '../providers/game_provider.dart';
import '../models/citadel.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

// ── Paleta Gótica ────────────────────────────────────────────────────────────
// Usada em todo o CitadelScreen para substituir a estética cyberpunk
const _arcaneViolet = Color(0xFF9966EE); // substitui cyan
const _tarnishedGold = Color(0xFFAA8844); // substitui yellow
const _mossGreen = Color(0xFF4A9E6A); // verde mais sombrio
// AppTheme.red, .orange, .purple, .textDim, etc. mantidos
// ─────────────────────────────────────────────────────────────────────────────

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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCitadelHeader(Citadel citadel, GameProvider gp) {
    final tier =
        ((gp.state.highestFloorCleared) ~/ 10) +
        (gp.state.highestFloorCleared % 10 > 0 ? 1 : 0);
    final popRatio = gp.population / citadel.totalPopulationCapacity;
    final buildRatio = citadel.buildings.length / citadel.level.maxBuildings;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: _arcaneViolet.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: _arcaneViolet.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Topo ornamentado ───────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _arcaneViolet.withValues(alpha: 0.3)),
              ),
              color: _arcaneViolet.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                TerminalText(
                  '†',
                  fontSize: 10,
                  color: _arcaneViolet.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: TerminalText(
                    'CIDADELA',
                    fontSize: 7,
                    color: AppTheme.textDim,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TerminalText(
                  '†',
                  fontSize: 10,
                  color: _arcaneViolet.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nome do nível ────────────────────────────────
                TerminalText(
                  citadel.level.label.toUpperCase(),
                  fontSize: 18,
                  color: _arcaneViolet,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 10),

                // ── ASCII Art ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _arcaneViolet.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(2),
                    color: AppTheme.bgElevated,
                  ),
                  child: _buildCitadelAscii(citadel.level),
                ),

                const SizedBox(height: 12),

                // ── Stat chips ───────────────────────────────────
                Row(
                  children: [
                    _headerStatChip(
                      '${citadel.buildings.length}/${citadel.level.maxBuildings}',
                      'ESTRUTURAS',
                      buildRatio >= 1.0 ? AppTheme.orange : _arcaneViolet,
                    ),
                    const SizedBox(width: 8),
                    _headerStatChip(
                      '${gp.population}/${citadel.totalPopulationCapacity}',
                      'HABITANTES',
                      popRatio > 1.0
                          ? AppTheme.red
                          : popRatio >= 0.9
                          ? AppTheme.orange
                          : _mossGreen,
                    ),
                    const SizedBox(width: 8),
                    _headerStatChip('TIER $tier', 'DA TORRE', _tarnishedGold),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(3),
        color: color.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TerminalText(
            value,
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(label, fontSize: 7, color: AppTheme.textDim),
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
    return TerminalText(
      art,
      fontSize: 9,
      color: _arcaneViolet.withValues(alpha: 0.8),
    );
  }

  Widget _buildResourcesDetailed(Citadel citadel, GameProvider gp) {
    final res = citadel.resources;
    final cap = citadel.storageCapacity;
    final isInfinite = citadel.hasInfiniteStorage;
    final atCapacity = !isInfinite && res.anyAtCapacity(citadel.storageLevel);

    final maxUsage = isInfinite
        ? 0.0
        : [
            res.food / cap,
            res.woodLog / cap,
            res.stoneRaw / cap,
            res.ironOre / cap,
            res.lumber / cap,
            res.stoneBrick / cap,
            res.ironBar / cap,
            res.knowledge / cap,
          ].reduce((a, b) => a > b ? a : b);

    Color storageBorderColor = AppTheme.border;
    if (!isInfinite) {
      if (maxUsage >= 1.0) {
        storageBorderColor = AppTheme.red;
      } else if (maxUsage >= 0.8) {
        storageBorderColor = AppTheme.orange;
      } else if (maxUsage >= 0.6) {
        storageBorderColor = _tarnishedGold;
      }
    }

    return _gothicCard(
      title: 'RESERVAS',
      titleIcon: '⚗',
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
                    ? _mossGreen
                    : atCapacity
                    ? AppTheme.red
                    : _arcaneViolet,
              ),
              const SizedBox(width: 4),
              TerminalText(
                '${citadel.storageLabel}  ',
                fontSize: 9,
                color: isInfinite ? _mossGreen : _arcaneViolet,
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
                        ? _tarnishedGold
                        : _mossGreen,
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
            _mossGreen,
            'Consumo: ~${gp.dailyFoodConsumption.toStringAsFixed(1)}/dia',
          ),
          // Raw
          _resRowCapped(
            'Troncos',
            res.woodLog,
            cap,
            isInfinite,
            AppTheme.orange,
            'Coleta de madeira bruta',
          ),
          _resRowCapped(
            'Pedra Bruta',
            res.stoneRaw,
            cap,
            isInfinite,
            AppTheme.textSecondary,
            'Coleta de pedra bruta',
          ),
          _resRowCapped(
            'Minério',
            res.ironOre,
            cap,
            isInfinite,
            AppTheme.blue,
            'Minério de ferro',
          ),
          // Processado
          _resRowCapped(
            'Madeira',
            res.lumber,
            cap,
            isInfinite,
            AppTheme.orange,
            'Madeira serrada',
          ),
          _resRowCapped(
            'Tijolos',
            res.stoneBrick,
            cap,
            isInfinite,
            AppTheme.textSecondary,
            'Pedra processada',
          ),
          _resRowCapped(
            'Ferro',
            res.ironBar,
            cap,
            isInfinite,
            AppTheme.blue,
            'Barras de ferro',
          ),
          _resRowCapped(
            'Conhecimento',
            res.knowledge,
            cap,
            isInfinite,
            AppTheme.purple,
            'Pesquisa e evolucao',
          ),
          _DailyProductionBreakdown(gp: gp),
          const SizedBox(height: 4),
          StatBar(
            label: 'MORAL',
            value: res.morale,
            maxValue: 100,
            color: res.morale > 70
                ? _mossGreen
                : res.morale > 40
                ? _tarnishedGold
                : AppTheme.red,
          ),
          const SizedBox(height: 6),

          if (!isInfinite && atCapacity)
            _gothicWarning(
              'OS ARMAZÉNS TRANSBORDAM — o excedente se perde nas trevas.',
              AppTheme.red,
              Icons.warning,
            )
          else if (!isInfinite && maxUsage >= 0.80)
            _gothicWarning(
              'As reservas chegam ao limite. Expanda antes que o desperdício comece.',
              AppTheme.orange,
              Icons.warning_amber,
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

  // ── Helpers Góticos ──────────────────────────────────────────────────────────

  Widget _gothicCard({
    required String title,
    required Widget child,
    String titleIcon = '†',
    Color borderColor = AppTheme.border,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho ornamentado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor.withValues(alpha: 0.3)),
              ),
              color: borderColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                TerminalText(
                  '$titleIcon ',
                  fontSize: 9,
                  color: borderColor.withValues(alpha: 0.7),
                ),
                TerminalText(
                  title,
                  fontSize: 9,
                  color: borderColor == AppTheme.border
                      ? AppTheme.textSecondary
                      : borderColor,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  Widget _gothicWarning(String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: TerminalText(
              message,
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStorageUpgrade(
    BuildContext context,
    Citadel citadel,
    GameProvider gp,
  ) {
    final next = citadel.storageLevel.nextLevel;
    if (next == null) {
      return _gothicCard(
        title: 'ARMAZÉM DO ABISMO',
        titleIcon: '∞',
        borderColor: _mossGreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.all_inclusive, size: 16, color: _mossGreen),
                const SizedBox(width: 6),
                TerminalText(
                  'Capacidade Infinita — as trevas guardam tudo.',
                  color: _mossGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const TerminalText(
              'Nenhum recurso se perde mais nas sombras.',
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

    return _gothicCard(
      title: 'ARMAZÉM',
      titleIcon: '⚰',
      borderColor: atCapacity
          ? (canUpgrade ? AppTheme.orange : AppTheme.red)
          : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 0; i < StorageLevel.values.length; i++) ...[
                if (i > 0)
                  TerminalText(
                    ' · ',
                    fontSize: 8,
                    color: AppTheme.textDim.withValues(alpha: 0.4),
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
                        ? '∞'
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
            _gothicWarning(
              'OS ARMAZÉNS TRANSBORDAM — recursos se perdem nas sombras.',
              AppTheme.red,
              Icons.block,
            ),

          const SizedBox(height: 6),
          Row(
            children: [
              TerminalText(
                '${citadel.storageLevel.shortLabel} (${citadel.storageCapacity.toStringAsFixed(0)})',
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              const TerminalText('  ⟶  ', fontSize: 9, color: AppTheme.textDim),
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
            color: canAfford ? _mossGreen : AppTheme.red,
          ),
          if (!canAfford)
            TerminalText(
              'Recursos insuficientes.',
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
              child: TerminalText(
                'ARMAZÉM DO ABISMO: Marco final. Extremamente difícil de alcançar.',
                fontSize: 8,
                color: AppTheme.purple,
              ),
            ),

          const SizedBox(height: 8),
          TerminalButton(
            label: canUpgrade ? 'EXPANDIR ARMAZÉM' : 'REQUISITOS FALTANDO',
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
      return _gothicCard(
        title: 'ASCENSÃO COMPLETA',
        titleIcon: '✦',
        borderColor: _mossGreen,
        child: const TerminalText(
          'A Cidadela atingiu o nível Ascendido. Transcendência alcançada.',
          color: _mossGreen,
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

    return _gothicCard(
      title: 'EVOLUIR CIDADELA',
      titleIcon: '⬆',
      borderColor: canUpgrade ? _arcaneViolet : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TerminalText(
                citadel.level.label,
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
              const TerminalText(
                '  ⟶  ',
                fontSize: 10,
                color: AppTheme.textDim,
              ),
              TerminalText(
                next.label,
                fontSize: 13,
                color: _arcaneViolet,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _progressRow('Comida', citadel.resources.food, cost.food),
          if (cost.woodLog > 0)
            _progressRow('Troncos', citadel.resources.woodLog, cost.woodLog),
          if (cost.stoneRaw > 0)
            _progressRow(
              'Pedra Bruta',
              citadel.resources.stoneRaw,
              cost.stoneRaw,
            ),
          if (cost.ironOre > 0)
            _progressRow('Minério', citadel.resources.ironOre, cost.ironOre),
          if (cost.lumber > 0)
            _progressRow('Madeira', citadel.resources.lumber, cost.lumber),
          if (cost.stoneBrick > 0)
            _progressRow(
              'Tijolos',
              citadel.resources.stoneBrick,
              cost.stoneBrick,
            ),
          if (cost.ironBar > 0)
            _progressRow('Ferro', citadel.resources.ironBar, cost.ironBar),
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
                'Habitantes: ${gp.population}/${next.populationRequired}',
                fontSize: 9,
                color: hasPopulation ? _mossGreen : AppTheme.red,
              ),
              const SizedBox(width: 12),
              TerminalText(
                'Tier Torre: $currentTier/${next.requiredTowerTier}',
                fontSize: 9,
                color: hasTier ? _mossGreen : AppTheme.red,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TerminalText(
            'Após evolução: até ${next.maxBuildings} estruturas',
            fontSize: 8,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 8),
          TerminalButton(
            label: canUpgrade ? 'ERGUER OS MUROS' : 'REQUISITOS FALTANDO',
            icon: Icons.upgrade,
            color: canUpgrade ? _arcaneViolet : AppTheme.textDim,
            expanded: true,
            onPressed: canUpgrade
                ? () {
                    gp.upgradeCitadel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.bgCard,
                        content: TerminalText(
                          'Cidadela evoluiu para ${next.label}!',
                          color: _arcaneViolet,
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
                    color: enough ? _mossGreen : _arcaneViolet,
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

    return _gothicCard(
      title: 'RECRUTAR HABITANTES',
      titleIcon: '☩',
      borderColor: canRequest ? _mossGreen : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOvercapacity)
            _gothicWarning(
              'SUPERLOTAÇÃO: ${gp.population}/${citadel.totalPopulationCapacity} — construa moradias ou evolua a cidadela.',
              AppTheme.orange,
              Icons.warning_amber,
            ),

          const SizedBox(height: 4),
          TerminalText(
            spacesAvailable > 0
                ? '$spacesAvailable espaço(s) disponível(is) nos muros'
                : 'Nenhum espaço disponível',
            fontSize: 10,
            color: spacesAvailable > 0 ? _mossGreen : AppTheme.red,
          ),
          const SizedBox(height: 4),
          const TerminalText(
            '~30 comida por habitante  ·  Moral mínima: 60',
            fontSize: 8,
            color: AppTheme.textDim,
          ),
          const TerminalText(
            'Famílias e casais chegam quando a moral é alta',
            fontSize: 8,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 8),

          TerminalButton(
            label: canRequest ? 'ABRIR OS PORTÕES' : 'REQUISITOS FALTANDO',
            icon: Icons.group_add,
            color: canRequest ? _mossGreen : AppTheme.textDim,
            expanded: true,
            onPressed: canRequest
                ? () {
                    final result = gp.requestNewSettlers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.bgCard,
                        content: TerminalText(result, color: _mossGreen),
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
      return _gothicCard(
        title: 'ESTRUTURAS ERGUIDAS',
        titleIcon: '⚒',
        child: const TerminalText(
          'Nenhuma estrutura erguida. Construa abaixo para fortalecer os muros.',
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

    return _gothicCard(
      title: 'ESTRUTURAS ERGUIDAS  (${citadel.buildings.length})',
      titleIcon: '⚒',
      borderColor: _arcaneViolet.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: byCategory.entries.map((categoryEntry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: TerminalText(
                  '— ${categoryEntry.key.label.toUpperCase()} —',
                  fontSize: 8,
                  color: _categoryColor(
                    categoryEntry.key,
                  ).withValues(alpha: 0.6),
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
                                      color: _arcaneViolet.withValues(
                                        alpha: 0.2,
                                      ),
                                      border: Border.all(
                                        color: _arcaneViolet.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: TerminalText(
                                      'x$count',
                                      fontSize: 8,
                                      color: _arcaneViolet,
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
                              ? _arcaneViolet
                              : AppTheme.textDim,
                          onPressed: gp.canUpgradeAllBuildings(first.type)
                              ? () {
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
                                          color: _arcaneViolet,
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
    knowledge: r.knowledge * factor,
    woodLog: r.woodLog * factor,
    stoneRaw: r.stoneRaw * factor,
    ironOre: r.ironOre * factor,
    lumber: r.lumber * factor,
    stoneBrick: r.stoneBrick * factor,
    ironBar: r.ironBar * factor,
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

    return _gothicCard(
      title: 'ERGUER NOVA ESTRUTURA',
      titleIcon: '🏗',
      borderColor: AppTheme.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (atLimit)
            _gothicWarning(
              'Os muros estão cheios. Evolua a Cidadela para abrir mais espaço.',
              AppTheme.orange,
              Icons.warning_amber,
            ),
          const SizedBox(height: 4),
          const TerminalText(
            'Você decide o que construir — os habitantes reagirão.',
            fontSize: 9,
            color: AppTheme.orange,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),

          if (available.isNotEmpty) ...[
            TerminalText('DISPONÍVEIS:', fontSize: 9, color: _mossGreen),
            const SizedBox(height: 4),
            ...available.map((type) {
              try {
                final b = Building(type: type);
                final canAfford = citadel.resources.canAfford(
                  b.cost.toResources(),
                );
                return _buildBuildingOption(context, gp, b, canAfford, atLimit);
              } catch (e) {
                return const SizedBox.shrink();
              }
            }),
          ] else ...[
            const TerminalText(
              'Nenhuma estrutura disponível. Conquiste mais andares para desbloquear.',
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
                              : _arcaneViolet.withValues(alpha: 0.2),
                          border: Border.all(
                            color: currentCount >= maxCopies
                                ? AppTheme.red.withValues(alpha: 0.5)
                                : _arcaneViolet.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TerminalText(
                          b.isUnique ? 'ÚNICA' : '$currentCount/$maxCopies',
                          fontSize: 7,
                          color: currentCount >= maxCopies
                              ? AppTheme.red
                              : _arcaneViolet,
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
                  color: canAfford ? _mossGreen : AppTheme.red,
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
              color: _arcaneViolet,
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
        return _mossGreen;
      case BuildingCategory.production:
        return AppTheme.orange;
      case BuildingCategory.knowledge:
        return AppTheme.purple;
      case BuildingCategory.military:
        return AppTheme.red;
      case BuildingCategory.social:
        return _tarnishedGold;
      case BuildingCategory.advanced:
        return _arcaneViolet;
      case BuildingCategory.endgame:
        return const Color(0xFFCC44CC);
    }
  }

  // _buildHowItWorks removido — mecânicas compreendidas pelo contexto

  String _costString(Resources cost) {
    final parts = <String>[];
    if (cost.food > 0) parts.add('Comida:${cost.food.toStringAsFixed(0)}');
    if (cost.woodLog > 0) {
      parts.add('Troncos:${cost.woodLog.toStringAsFixed(0)}');
    }
    if (cost.stoneRaw > 0) {
      parts.add('Pedra Bruta:${cost.stoneRaw.toStringAsFixed(0)}');
    }
    if (cost.ironOre > 0) {
      parts.add('Minério:${cost.ironOre.toStringAsFixed(0)}');
    }
    if (cost.lumber > 0) parts.add('Madeira:${cost.lumber.toStringAsFixed(0)}');
    if (cost.stoneBrick > 0) {
      parts.add('Tijolos:${cost.stoneBrick.toStringAsFixed(0)}');
    }
    if (cost.ironBar > 0) parts.add('Ferro:${cost.ironBar.toStringAsFixed(0)}');
    if (cost.knowledge > 0) {
      parts.add('Conhec.:${cost.knowledge.toStringAsFixed(0)}');
    }
    return parts.join(' · ');
  }
}
// ── Breakdown de produção diária ─────────────────────────────────────────────

class _DailyProductionBreakdown extends StatelessWidget {
  final GameProvider gp;
  const _DailyProductionBreakdown({required this.gp});

  @override
  Widget build(BuildContext context) {
    final citadel = gp.citadel;

    int count(Profession p) =>
        gp.aliveNpcs.where((n) => n.profession == p).length;
    final lumberjacks = count(Profession.lumberjack);
    final carpenters = count(Profession.carpenter);
    final quarrymen = count(Profession.quarryman);
    final masons = count(Profession.mason);
    final blacksmiths = count(Profession.blacksmith);
    final farmers = count(Profession.farmer);
    final chefs = count(Profession.chef);

    bool has(BuildingType t) => citadel.hasBuilding(t);
    int lvl(BuildingType t) => citadel.getBuilding(t)?.level ?? 0;

    final rows = <_ProdRow>[
      _ProdRow(
        icon: '🌾',
        label: 'Comida',
        value: gp.dailyFoodBonus,
        detail:
            '$farmers fazendeiros'
            '${chefs > 0 ? ' · $chefs cozinheiros ×${(1 + chefs * 0.06).toStringAsFixed(2)}' : ' · sem cozinha'}',
        color: const Color(0xFF4A9E6A),
      ),
    ];

    if (has(BuildingType.silviculture)) {
      rows.add(
        _ProdRow(
          icon: '🪵',
          label: 'Troncos',
          value: gp.dailyWoodLogBonus,
          detail:
              'Silvicultura nv${lvl(BuildingType.silviculture)} · $lumberjacks lenhadores',
          color: AppTheme.orange,
        ),
      );
    }

    if (has(BuildingType.sawmill)) {
      rows.add(
        _ProdRow(
          icon: '🪚',
          label: 'Madeira',
          value: gp.dailyLumberBonus,
          detail:
              'Serraria nv${lvl(BuildingType.sawmill)} · $carpenters carpinteiros',
          color: AppTheme.orange,
        ),
      );
    }

    if (has(BuildingType.quarry)) {
      rows.add(
        _ProdRow(
          icon: '⛏',
          label: 'Pedra Bruta',
          value: gp.dailyStoneRawBonus,
          detail:
              'Pedreira nv${lvl(BuildingType.quarry)} · $quarrymen pedreiros',
          color: AppTheme.textSecondary,
        ),
      );
    }

    if (has(BuildingType.masonry)) {
      rows.add(
        _ProdRow(
          icon: '🧱',
          label: 'Tijolos',
          value: gp.dailyStoneBrickBonus,
          detail: 'Cantaria nv${lvl(BuildingType.masonry)} · $masons canteiros',
          color: AppTheme.textSecondary,
        ),
      );
    }

    if (has(BuildingType.forge)) {
      rows.add(
        _ProdRow(
          icon: '⚙️',
          label: 'Ferro',
          value: gp.dailyIronBarBonus,
          detail:
              'Forja nv${lvl(BuildingType.forge)} · $blacksmiths ferreiros'
              '${gp.dailyIronOreBonus > 0 ? ' · ${gp.dailyIronOreBonus.toStringAsFixed(0)} minério/dia' : ''}',
          color: AppTheme.blue,
        ),
      );
    } else if (gp.dailyIronOreBonus > 0) {
      rows.add(
        _ProdRow(
          icon: '⛏',
          label: 'Minério',
          value: gp.dailyIronOreBonus,
          detail: 'Sem Forja — minério acumulando sem uso',
          color: AppTheme.blue,
        ),
      );
    }
    rows.addAll([
      _ProdRow(
        icon: '📚',
        label: 'Conhecimento',
        value: gp.dailyResearchBonus,
        detail: '',
        color: AppTheme.purple,
      ),
      _ProdRow(
        icon: '💛',
        label: 'Moral',
        value: gp.dailyMoraleBonus,
        detail: '',
        color: AppTheme.yellow,
      ),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              TerminalText('${r.icon} ${r.label}', fontSize: 9, color: r.color),
              const Spacer(),
              TerminalText(
                '+${r.value.toStringAsFixed(1)}/dia',
                fontSize: 9,
                color: r.color,
                fontWeight: FontWeight.bold,
              ),
              if (r.detail.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: TerminalText(
                    r.detail,
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ProdRow {
  final String icon, label, detail;
  final double value;
  final Color color;
  const _ProdRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });
}

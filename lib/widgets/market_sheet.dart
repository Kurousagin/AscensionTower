// lib/widgets/market_sheet.dart
//
// MarketSheet — centraliza todas as ofertas de comércio da torre.
// Acessível via banner no dashboard quando BuildingType.market está construído.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/citadel.dart';
import 'package:tower_ascension/models/floor_faction.dart';
import 'package:tower_ascension/models/floor_inhabitant.dart';
import 'package:tower_ascension/providers/game_provider.dart';
import 'package:tower_ascension/widgets/theme.dart';
import 'package:tower_ascension/widgets/terminal_widgets.dart'
    show TerminalButton, TerminalText;

// ── Banner (exibido no dashboard) ────────────────────────────────────────────

class MarketBanner extends StatelessWidget {
  final int offerCount;
  final VoidCallback onTap;

  const MarketBanner({
    super.key,
    required this.offerCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1408),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.orange.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orange.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: AppTheme.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$offerCount oferta(s) disponível(is) no Mercado',
                    style: const TextStyle(
                      color: AppTheme.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Toque para ver todas as trocas da torre',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.orange,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet principal ───────────────────────────────────────────────────────────

class MarketSheet extends StatefulWidget {
  const MarketSheet({super.key});

  @override
  State<MarketSheet> createState() => _MarketSheetState();
}

class _MarketSheetState extends State<MarketSheet> {
  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final offers = List<TradeOffer>.from(gp.allTradeOffers);
    final marketLevel =
        gp.citadel.getBuilding(BuildingType.market)?.level ?? 1;
    final marketBonus = (marketLevel - 1) * 10;

    // Agrupa por facção
    final Map<FloorFaction, List<TradeOffer>> byFaction = {};
    for (final offer in offers) {
      byFaction.putIfAbsent(offer.merchantFaction, () => []).add(offer);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppTheme.orange, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: AppTheme.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'MERCADO CENTRAL',
                style: TextStyle(
                  color: AppTheme.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.orange.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  'Nv $marketLevel${marketBonus > 0 ? ' · +$marketBonus% recomp.' : ''}',
                  style: const TextStyle(
                    color: AppTheme.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'Todas as ofertas ativas na torre',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // Lista
          if (offers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Nenhuma oferta disponível no momento.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: byFaction.entries.map((entry) {
                    return _FactionTradeSection(
                      faction: entry.key,
                      offers: entry.value,
                      onTraded: () => setState(() {}),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Seção por facção ──────────────────────────────────────────────────────────

class _FactionTradeSection extends StatelessWidget {
  final FloorFaction faction;
  final List<TradeOffer> offers;
  final VoidCallback onTraded;

  const _FactionTradeSection({
    required this.faction,
    required this.offers,
    required this.onTraded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: faction.label.toUpperCase(), count: offers.length),
        const SizedBox(height: 8),
        ...offers.map(
          (offer) => _TradeCard(offer: offer, onTraded: onTraded),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Card de oferta ────────────────────────────────────────────────────────────

class _TradeCard extends StatelessWidget {
  final TradeOffer offer;
  final VoidCallback onTraded;

  const _TradeCard({required this.offer, required this.onTraded});

  @override
  Widget build(BuildContext context) {
    final gp = context.read<GameProvider>();
    final standing = gp.engine.state.factionRelations[offer.merchantFaction.key]
            ?.standing ??
        0.0;

    final res = gp.citadel.resources;
    final canAfford = offer.cost.entries.every((e) => switch (e.key) {
          'food' => res.food >= e.value,
          'iron' => res.iron >= e.value,
          'wood' => res.wood >= e.value,
          'stone' => res.stone >= e.value,
          'knowledge' => res.knowledge >= e.value,
          _ => false,
        });
    final hasStanding = standing >= offer.standingRequirement;
    final canTrade = canAfford && hasStanding;

    final costStr =
        offer.cost.entries.map((e) => '${e.value} ${e.key}').join(', ');
    final rewardStr =
        offer.reward.entries.map((e) => '${e.value} ${e.key}').join(', ');

    // Bônus de recompensa do market para exibição
    final marketLevel =
        gp.citadel.getBuilding(BuildingType.market)?.level ?? 1;
    final marketMult = 1.0 + (marketLevel - 1) * 0.1;
    final rewardBonusStr = marketLevel > 1
        ? offer.reward.entries
            .map((e) => '${(e.value * marketMult).round()} ${e.key}')
            .join(', ')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: canTrade
              ? AppTheme.orange.withOpacity(0.6)
              : AppTheme.border,
        ),
        borderRadius: BorderRadius.circular(3),
        color: canTrade ? AppTheme.orange.withOpacity(0.03) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.orange.withOpacity(0.6),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TerminalText(
                  'Andar ${offer.floorNumber}',
                  fontSize: 7,
                  color: AppTheme.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TerminalText(
                  offer.merchantFaction.shortLabel,
                  fontSize: 7,
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!hasStanding)
                TerminalText(
                  'Standing insuf.',
                  fontSize: 7,
                  color: AppTheme.red,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const TerminalText('Paga: ', fontSize: 8, color: AppTheme.textDim),
              TerminalText(costStr, fontSize: 8, color: AppTheme.red),
            ],
          ),
          Row(
            children: [
              const TerminalText(
                  'Recebe: ', fontSize: 8, color: AppTheme.textDim),
              TerminalText(
                rewardBonusStr ?? rewardStr,
                fontSize: 8,
                color: AppTheme.green,
              ),
              if (rewardBonusStr != null) ...[
                const SizedBox(width: 4),
                TerminalText(
                  '(+${((marketMult - 1) * 100).round()}%)',
                  fontSize: 7,
                  color: AppTheme.orange,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TerminalButton(
              label: 'TROCAR',
              color: canTrade ? AppTheme.orange : AppTheme.textDim,
              onPressed: canTrade
                  ? () {
                      final result = gp.executeTrade(offer.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: result.success
                              ? Colors.green[900]
                              : Colors.red[900],
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      onTraded();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;

  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.white12, height: 1)),
      ],
    );
  }
}
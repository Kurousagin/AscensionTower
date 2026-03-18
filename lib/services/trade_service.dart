// lib/services/trade_service.dart
//
// TradeService — gerencia ofertas de comércio com facções da torre.
// Cada facção tem um perfil de troca único; preços variam com o standing.

import 'dart:math';
import '../models/floor_faction.dart';
import '../models/floor_inhabitant.dart';
import '../models/tower.dart';
import '../models/citadel.dart';

class TradeService {
  final Random _rng;
  final List<TradeOffer> _availableOffers = [];
  int _offerIdCounter = 0;

  TradeService(this._rng);

  // ── Accessors ─────────────────────────────────────────────────────────────

  List<TradeOffer> get allOffers => List.unmodifiable(_availableOffers);

  List<TradeOffer> offersForFloor(int floorNumber) =>
      _availableOffers.where((o) => o.floorNumber == floorNumber).toList();

  // ── Atualização de ofertas ─────────────────────────────────────────────────

  void refreshOffers({
    required List<TowerFloor> floors,
    required Map<String, FactionRelation> factionRelations,
    required int currentDay,
  }) {
    // Remove ofertas antigas (mais de 7 dias)
    _availableOffers.removeWhere((o) => currentDay - o.refreshDay >= 7);

    // Gera novas ofertas para andares conquistados com facções
    for (final floor in floors.where((f) => f.cleared)) {
      final faction = floor.controllingFaction;
      if (faction == FloorFaction.none) continue;

      // Verifica se já há oferta para este andar
      if (_availableOffers.any((o) => o.floorNumber == floor.number)) continue;

      final relation = factionRelations[faction.key];
      final standing = relation?.standing ?? faction.initialStanding;

      // Só gera ofertas se standing for >= -30
      if (standing < -30) continue;

      // Blood Market hub: standing >= 50 → +30% variedade
      final extraVariety =
          faction == FloorFaction.bloodMarket && standing >= 50;

      final newOffers = _generateOffersForFaction(
        faction: faction,
        floorNumber: floor.number,
        standing: standing,
        currentDay: currentDay,
        extraVariety: extraVariety,
      );

      _availableOffers.addAll(newOffers);
    }
  }

  List<TradeOffer> _generateOffersForFaction({
    required FloorFaction faction,
    required int floorNumber,
    required double standing,
    required int currentDay,
    bool extraVariety = false,
  }) {
    final offers = <TradeOffer>[];
    final priceMod = _priceModifier(standing);
    final merchantId = 'merchant_${faction.key}_f$floorNumber';

    switch (faction) {
      case FloorFaction.ironPact:
        // Ferro → equipamento (comida, pedra como recompensa)
        offers.add(
          _makeOffer(
            merchantId: merchantId,
            floorNumber: floorNumber,
            faction: faction,
            cost: {'ironOre': (20 * priceMod).round()},
            reward: {'food': 30, 'stoneRaw': 15},
            refreshDay: currentDay,
            standingReq: -30,
          ),
        );
        if (extraVariety || standing >= 30) {
          offers.add(
            _makeOffer(
              merchantId: merchantId,
              floorNumber: floorNumber,
              faction: faction,
              cost: {'ironOre': (35 * priceMod).round(), 'food': 10},
              reward: {'food': 20, 'stoneRaw': 30, 'knowledge': 5},
              refreshDay: currentDay,
              standingReq: 30,
            ),
          );
        }

      case FloorFaction.silentOrder:
        // Comida + madeira → conhecimento
        offers.add(
          _makeOffer(
            merchantId: merchantId,
            floorNumber: floorNumber,
            faction: faction,
            cost: {
              'food': (15 * priceMod).round(),
              'woodLog': (10 * priceMod).round(),
            },
            reward: {'knowledge': 25},
            refreshDay: currentDay,
            standingReq: -30,
          ),
        );
        if (extraVariety || standing >= 20) {
          offers.add(
            _makeOffer(
              merchantId: merchantId,
              floorNumber: floorNumber,
              faction: faction,
              cost: {'knowledge': (20 * priceMod).round()},
              reward: {'food': 10, 'ironOre': 5, 'woodLongLog': 15},
              refreshDay: currentDay,
              standingReq: 20,
            ),
          );
        }

      case FloorFaction.bloodMarket:
        // Variado, melhores preços
        offers.add(
          _makeOffer(
            merchantId: merchantId,
            floorNumber: floorNumber,
            faction: faction,
            cost: {'food': (25 * priceMod).round()},
            reward: {'ironOre': 20, 'woodLong': 10},
            refreshDay: currentDay,
            standingReq: -30,
          ),
        );
        offers.add(
          _makeOffer(
            merchantId: merchantId,
            floorNumber: floorNumber,
            faction: faction,
            cost: {'ironOre': (15 * priceMod).round(), 'woodLong': 10},
            reward: {'food': 35, 'knowledge': 8},
            refreshDay: currentDay,
            standingReq: -10,
          ),
        );
        if (extraVariety) {
          // Hub especial com -15% preço adicional
          offers.add(
            _makeOffer(
              merchantId: merchantId,
              floorNumber: floorNumber,
              faction: faction,
              cost: {'food': (10 * priceMod * 0.85).round()},
              reward: {'stoneRaw': 25, 'ironOre': 10, 'knowledge': 5},
              refreshDay: currentDay,
              standingReq: 50,
            ),
          );
        }

      case FloorFaction.voidChildren:
        // Resultado aleatório: pode ser bom ou ruim
        final goodDeal = _rng.nextBool();
        if (goodDeal) {
          offers.add(
            _makeOffer(
              merchantId: merchantId,
              floorNumber: floorNumber,
              faction: faction,
              cost: {'food': (5 * priceMod).round()},
              reward: {'food': 50, 'ironOre': 20, 'knowledge': 15}, // muito bom
              refreshDay: currentDay,
              standingReq: -50,
            ),
          );
        } else {
          offers.add(
            _makeOffer(
              merchantId: merchantId,
              floorNumber: floorNumber,
              faction: faction,
              cost: {'food': (30 * priceMod).round()},
              reward: {'food': 5}, // muito ruim
              refreshDay: currentDay,
              standingReq: -50,
            ),
          );
        }

      case FloorFaction.towerServants:
        // Itens raros, preços altos
        offers.add(
          _makeOffer(
            merchantId: merchantId,
            floorNumber: floorNumber,
            faction: faction,
            cost: {
              'ironOre': (40 * priceMod).round(),
              'knowledge': (30 * priceMod).round(),
            },
            reward: {'food': 60, 'stoneRaw': 40, 'woodLong': 30},
            refreshDay: currentDay,
            standingReq: 0,
          ),
        );

      case FloorFaction.none:
        break;
    }

    return offers;
  }

  TradeOffer _makeOffer({
    required String merchantId,
    required int floorNumber,
    required FloorFaction faction,
    required Map<String, int> cost,
    required Map<String, int> reward,
    required int refreshDay,
    required double standingReq,
  }) {
    _offerIdCounter++;
    return TradeOffer(
      id: 'offer_$_offerIdCounter',
      merchantInhabitantId: merchantId,
      floorNumber: floorNumber,
      merchantFaction: faction,
      cost: cost,
      reward: reward,
      standingRequirement: standingReq,
      refreshDay: refreshDay,
    );
  }

  double _priceModifier(double standing) {
    if (standing >= 80) return 0.8; // aliado: -20%
    if (standing >= 50) return 0.9; // amigável: -10%
    if (standing >= -10) return 1.0; // neutro: preço normal
    if (standing >= -30) return 1.25; // cauteloso: +25%
    return 1.5; // hostil: +50%
  }

  // ── Executar troca ────────────────────────────────────────────────────────

  TradeResult executeTrade({
    required String offerId,
    required Citadel citadel,
    required Map<String, FactionRelation> factionRelations,
    int marketLevel = 1,
  }) {
    final offer = _availableOffers.firstWhereOrNull((o) => o.id == offerId);
    if (offer == null) {
      return const TradeResult(
        success: false,
        message: 'Oferta não encontrada.',
      );
    }

    final relation = factionRelations[offer.merchantFaction.key];
    final standing =
        relation?.standing ?? offer.merchantFaction.initialStanding;

    if (standing < offer.standingRequirement) {
      return TradeResult(
        success: false,
        message:
            'Standing insuficiente com ${offer.merchantFaction.label}. '
            'Necessário: ${offer.standingRequirement.toStringAsFixed(0)}.',
      );
    }

    // Verifica recursos
    for (final entry in offer.cost.entries) {
      final available = _getResource(citadel, entry.key);
      if (available < entry.value) {
        return TradeResult(
          success: false,
          message:
              'Recursos insuficientes: precisa de ${entry.value} ${entry.key}.',
        );
      }
    }

    // Debita custo
    for (final entry in offer.cost.entries) {
      _adjustResource(citadel, entry.key, -entry.value.toDouble());
    }

    // Credita recompensa
    final marketMult = 1.0 + (marketLevel - 1) * 0.1;
    for (final entry in offer.reward.entries) {
      _adjustResource(citadel, entry.key, entry.value * marketMult);
    }
    // Remove oferta (usada)
    _availableOffers.removeWhere((o) => o.id == offerId);

    final costStr = offer.cost.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');
    final rewardStr = offer.reward.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');

    return TradeResult(
      success: true,
      message:
          'Troca concluída com ${offer.merchantFaction.label}! '
          'Pagou: $costStr → Recebeu: $rewardStr',
    );
  }

  double _getResource(Citadel citadel, String key) {
    switch (key) {
      case 'food':
        return citadel.resources.food;
      case 'ironOre':
        return citadel.resources.ironOre;
      case 'woodLongLog':
        return citadel.resources.woodLog;
      case 'stoneRaw':
        return citadel.resources.stoneRaw;
      case 'ironOreBar':
        return citadel.resources.ironBar;
      case 'lumber':
        return citadel.resources.lumber;
      case 'stoneBrick':
        return citadel.resources.stoneBrick;
      case 'knowledge':
        return citadel.resources.knowledge;
      default:
        return 0;
    }
  }

  void _adjustResource(Citadel citadel, String key, double amount) {
    switch (key) {
      case 'food':
        citadel.resources.food += amount;
      case 'ironOre':
        citadel.resources.ironOre += amount;
      case 'woodLong':
        citadel.resources.woodLog += amount;
      case 'stoneRaw':
        citadel.resources.stoneRaw += amount;
      case 'knowledge':
        citadel.resources.knowledge += amount;
      default:
        assert(false, 'Unknown resource key: $key');
    }
  }

  // ── Serialização ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'availableOffers': _availableOffers.map((o) => o.toJson()).toList(),
    'offerIdCounter': _offerIdCounter,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _availableOffers
      ..clear()
      ..addAll(
        (json['availableOffers'] as List<dynamic>? ?? []).map(
          (e) => TradeOffer.fromJson(e as Map<String, dynamic>),
        ),
      );
    _offerIdCounter = json['offerIdCounter'] as int? ?? 0;
  }

  void clear() {
    _availableOffers.clear();
    _offerIdCounter = 0;
  }
}

// ── Iterable extension ────────────────────────────────────────────────────────

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

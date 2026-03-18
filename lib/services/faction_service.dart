// lib/services/faction_service.dart
//
// FactionService — extrai e centraliza a lógica de facções do GameEngine.
// Gerencia: incursões, interações de tentativa/re-exploração, standing,
// diplomatia, recrutamento de survivors, expiração de tratados e recompensas de aliança.

import 'dart:math';

import '../models/floor_faction.dart';
import '../models/floor_inhabitant.dart';
import '../models/tower.dart';
import '../models/citadel.dart';
import '../models/npc.dart';
import '../models/game_event.dart';
import '../models/equipment.dart';
import 'package:collection/collection.dart';
import 'war_service.dart';

// ── Resultado público de smuggling ─────────────────────────────────────────

class SmugglingResult {
  final bool success;
  final double taxSaved;
  final double standingChange;
  final bool casualty;
  final String message;

  const SmugglingResult({
    required this.success,
    required this.taxSaved,
    required this.standingChange,
    required this.casualty,
    required this.message,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

// ── Service Event for inter-service communication ────────────────────────────

class ServiceEvent {
  final GameEventType type;
  final String title;
  final String description;
  final bool isMajor;
  final double? extraFoodGain;

  const ServiceEvent({
    required this.type,
    required this.title,
    required this.description,
    this.isMajor = false,
    this.extraFoodGain,
  });
}

class FactionService {
  final Random _rng;
  final WarService _warService;
  FactionService(this._rng, this._warService);
  // ── Incursões ─────────────────────────────────────────────────────────────

  /// Processa incursões das facções hostis contra a cidadela.
  /// Retorna lista de [ServiceEvent] para o GameEngine converter em GameEvents.
  List<ServiceEvent> processFactionIncursions({
    required Map<String, FactionRelation> factionRelations,
    required Citadel citadel,
    required int currentDay,
  }) {
    final events = <ServiceEvent>[];

    for (final relation in factionRelations.values) {
      // Bloqueia incursão se há tratado ativo
      if (relation.hasTreaty) continue;

      if (!FactionProcessor.shouldIncurse(
        relation: relation,
        currentDay: currentDay,
        incursionCooldownDays: 14,
      )) {
        continue;
      }

      final severity = (-relation.standing / 100).clamp(0.0, 1.0);
      citadel.resources.food -= 10 * severity;
      citadel.resources.morale -= 5 * severity;
      citadel.resources.clampNegatives();

      relation.incursionsCaused++;
      relation.lastInteractionDay = currentDay;

      final foodLost = (10 * severity).toStringAsFixed(1);
      final moraleLost = (5 * severity).toStringAsFixed(1);
      events.add(
        ServiceEvent(
          type: GameEventType.crisis,
          title: '⚔ INCURSÃO: ${relation.faction.label}',
          description:
              '${relation.faction.label} atacou os suprimentos da cidadela!\n'
              '−$foodLost comida  −$moraleLost moral\n'
              'Standing: ${relation.standing.toStringAsFixed(0)} · '
              'Incursão nº ${relation.incursionsCaused}.',
          isMajor: true,
        ),
      );
    }

    return events;
  }

  // ── Interação em tentativa de andar ───────────────────────────────────────

  /// Processa efeitos de facção ao tentar conquistar um andar.
  /// Equivalente a _processFactionOnAttempt do GameEngine.
  FactionInteractionResult processFactionOnAttempt({
    required TowerFloor floor,
    required List<String> partyIds,
    required List<Npc> npcs,
    required Map<String, FactionRelation> factionRelations,
    required int currentDay,
    required Citadel citadel,
  }) {
    final faction = floor.controllingFaction;
    if (faction == FloorFaction.none) {
      return const FactionInteractionResult(faction: FloorFaction.none);
    }

    final relation = getOrCreateFactionRelation(faction, factionRelations);
    final party = _resolveParty(partyIds, npcs);
    if (party.isEmpty) return FactionInteractionResult(faction: faction);

    final stats = _calcPartyStats(party);
    final food = citadel.resources.food;

    // Treaty bonus: +10% success chance, -15% mortality
    final treatySuccessBonus = relation.hasTreaty ? 0.10 : 0.0;
    final treatyMortalityBonus = relation.hasTreaty ? -0.15 : 0.0;

    final result = FactionProcessor.processFloorAttempt(
      faction: faction,
      relation: relation,
      partyPower: stats.power,
      partyIntelligence: stats.intel,
      partyResources: food,
      partyFame: stats.fame,
      partyLuck: stats.luck,
      currentDay: currentDay,
    );

    // Apply treaty bonuses on top
    final adjustedResult =
        treatySuccessBonus != 0.0 || treatyMortalityBonus != 0.0
        ? FactionInteractionResult(
            faction: result.faction,
            standingDelta: result.standingDelta,
            successChanceMod: result.successChanceMod + treatySuccessBonus,
            mortalityMod: result.mortalityMod + treatyMortalityBonus,
            resourceMod: result.resourceMod,
            foodTribute: result.foodTribute,
            narrativeLines: result.narrativeLines,
            triggeredIncursion: result.triggeredIncursion,
          )
        : result;

    if (result.standingDelta != 0) {
      applyFactionStandingChange(
        faction: faction,
        delta: result.standingDelta,
        factionRelations: factionRelations,
        floors: null,
        affectedFloor: floor,
      );
    }

    return adjustedResult;
  }

  // ── Interação em re-exploração ────────────────────────────────────────────

  /// Processa efeitos de facção durante re-exploração de andar.
  /// Retorna [resourcesGained] modificado + narrativas via [ServiceEvent].
  ({Map<String, double> resources, List<ServiceEvent> events})
  processFactionOnReexploration({
    required TowerFloor floor,
    required Map<String, double> resourcesGained,
    required List<Npc> party,
    required Map<String, FactionRelation> factionRelations,
    required int currentDay,
    required Citadel citadel,
    required List<Equipment> inventory,
    required EquipmentServiceInterface? equipmentService,
  }) {
    final faction = floor.controllingFaction;
    if (faction == FloorFaction.none) {
      return (resources: resourcesGained, events: <ServiceEvent>[]);
    }

    if (party.isEmpty) {
      return (resources: resourcesGained, events: <ServiceEvent>[]);
    }

    final power =
        party.map((n) => n.attributes.combatPower).fold(0.0, (a, b) => a + b) /
        party.length;
    final intel =
        party.map((n) => n.attributes.intelligence).fold(0.0, (a, b) => a + b) /
        party.length;

    final relation = getOrCreateFactionRelation(faction, factionRelations);
    final factionResult = FactionProcessor.processReexploration(
      faction: faction,
      relation: relation,
      partyPower: power,
      partyIntelligence: intel,
      currentDay: currentDay,
    );

    if (factionResult.resourceMod != 1.0) {
      for (final key in resourcesGained.keys.toList()) {
        resourcesGained[key] =
            (resourcesGained[key] ?? 0) * factionResult.resourceMod;
      }
    }

    final narratives = <String>[...factionResult.narrativeLines];
    final events = <ServiceEvent>[];
    final standing = relation.standing;

    // Custom faction logic
    if (faction == FloorFaction.bloodMarket && standing >= 50) {
      if (citadel.resources.ironOre >= 5) {
        citadel.resources.ironOre -= 5;
        citadel.resources.food += 15 + (standing / 10);
        narratives.add(
          '💰 Mercado de Sangue trocou ferro por mantimentos. '
          '(-5 ferro, +${(15 + standing / 10).toStringAsFixed(0)} comida)',
        );
      }
    }

    if (faction == FloorFaction.towerServants && standing >= 80) {
      if (equipmentService != null) {
        final drop = equipmentService.rollDrop(
          floorNumber: floor.number,
          tier: max(floor.tier, 3),
          currentDay: currentDay,
        );
        if (drop != null) {
          inventory.add(drop);
          narratives.add(
            '🏛 Servos da Torre presentearam seu grupo: ${drop.name}',
          );
        }
      }
      events.add(
        ServiceEvent(
          type: GameEventType.discovery,
          title: 'Segredo dos Servos',
          description:
              'Um Servo se ajoelhou e sussurrou: '
              '"A Torre não é uma prisão. É um filtro. '
              'Apenas os dignos chegam ao topo." '
              'Ninguém sabe o que isso significa.',
        ),
      );
    }

    if (faction == FloorFaction.silentOrder) {
      final scribes = party
          .where((n) => n.profession == Profession.scribe)
          .toList();
      for (final scribe in scribes) {
        scribe.attributes.intelligence = (scribe.attributes.intelligence + 0.5)
            .clamp(1, 20);
        citadel.resources.knowledge += 5;
        scribe.history.add('Estudou nos arquivos da Ordem Silenciosa');
      }
      if (scribes.isNotEmpty) {
        narratives.add(
          '📚 ${scribes.map((n) => n.name).join(", ")} estudou nos arquivos '
          'da Ordem. +0.5 inteligência cada, +${scribes.length * 5} conhecimento.',
        );
      }
    }

    if (faction == FloorFaction.voidChildren) {
      final voidEvents = _voidChildrenChaosEvent(floor, party, relation);
      events.addAll(voidEvents);
    }

    if (factionResult.standingDelta != 0) {
      applyFactionStandingChange(
        faction: faction,
        delta: factionResult.standingDelta,
        factionRelations: factionRelations,
        floors: null,
        affectedFloor: floor,
      );
    }

    if (narratives.isNotEmpty) {
      events.insert(
        0,
        ServiceEvent(
          type: GameEventType.discovery,
          title: 'Facção: ${faction.label} — Andar ${floor.number}',
          description: narratives.join('\n'),
          isMajor: true,
        ),
      );
    }

    return (resources: resourcesGained, events: events);
  }

  // ── Standing ─────────────────────────────────────────────────────────────

  void applyFactionStandingChange({
    required FloorFaction faction,
    required double delta,
    required Map<String, FactionRelation> factionRelations,
    required List<TowerFloor>? floors,
    TowerFloor? affectedFloor,
    int? currentDay,
  }) {
    if (faction == FloorFaction.none || delta == 0) return;

    final relation = getOrCreateFactionRelation(faction, factionRelations);
    relation.standing = (relation.standing + delta).clamp(-100.0, 100.0);
    relation.totalInteractions++;
    if (currentDay != null) relation.lastInteractionDay = currentDay;

    if (affectedFloor != null && affectedFloor.inhabitants.isNotEmpty) {
      InhabitantProcessor.updateForFactionStanding(
        inhabitants: affectedFloor.inhabitants,
        factionStanding: relation.standing,
      );
    }

    if (floors != null) {
      for (final floor in floors.where((f) => f.cleared)) {
        if (floor.controllingFaction == faction &&
            floor.inhabitants.isNotEmpty) {
          InhabitantProcessor.updateForFactionStanding(
            inhabitants: floor.inhabitants,
            factionStanding: relation.standing,
          );
        }
      }
    }
  }

  FactionRelation getOrCreateFactionRelation(
    FloorFaction faction,
    Map<String, FactionRelation> factionRelations,
  ) {
    return factionRelations.putIfAbsent(
      faction.key,
      () => FactionRelation(faction: faction),
    );
  }

  // ── Diplomacia ────────────────────────────────────────────────────────────

  List<DiplomacyOffer> getDiplomacyOffers({
    required FloorFaction faction,
    required Map<String, FactionRelation> factionRelations,
    required Citadel citadel,
    required int currentDay,
    required double partyPower,
  }) {
    final relation = getOrCreateFactionRelation(faction, factionRelations);
    if (relation.tier == FactionTier.ally) return [];
    if (currentDay - relation.lastDiplomacyDay < 7) return [];

    return FactionProcessor.buildDiplomacyOffers(
      faction: faction,
      relation: relation,
      currentResources: citadel.resources,
      partyPower: partyPower,
    );
  }

  String executeDiplomacy({
    required FloorFaction faction,
    required DiplomacyOfferType offerType,
    required Map<String, FactionRelation> factionRelations,
    required Citadel citadel,
    required int currentDay,
    required double partyPower,
  }) {
    final activeWar = _warService.activeWars.firstWhereOrNull(
      (w) =>
          (w.aggressor == faction || w.defender == faction) &&
          w.playerSidedWith != null &&
          w.playerSidedWith != faction,
    );
    if (activeWar != null) {
      final ally = activeWar.playerSidedWith!;
      return 'Impossível negociar com ${faction.label} enquanto você está aliado a ${ally.label}.';
    }

    final relation = getOrCreateFactionRelation(faction, factionRelations);
    if (currentDay - relation.lastDiplomacyDay < 7) {
      return 'Esta facção não aceita propostas tão seguidas.';
    }

    final offers = getDiplomacyOffers(
      faction: faction,
      factionRelations: factionRelations,
      citadel: citadel,
      currentDay: currentDay,
      partyPower: partyPower,
    );
    final offer = offers.firstWhereOrNull((o) => o.type == offerType);
    if (offer == null) return 'Oferta indisponível.';

    for (final entry in offer.resourceCost.entries) {
      switch (entry.key) {
        case 'food':
          if (citadel.resources.food < entry.value) {
            return 'Recursos insuficientes.';
          }
        case 'ironOre':
          if (citadel.resources.ironOre < entry.value) {
            return 'Recursos insuficientes.';
          }
        case 'woodLog':
          if (citadel.resources.woodLog < entry.value) {
            return 'Recursos insuficientes.';
          }
        case 'knowledge':
          if (citadel.resources.knowledge < entry.value) {
            return 'Recursos insuficientes.';
          }
      }
    }

    for (final entry in offer.resourceCost.entries) {
      switch (entry.key) {
        case 'food':
          citadel.resources.food -= entry.value;
        case 'ironOre':
          citadel.resources.ironOre -= entry.value;
        case 'woodLong':
          citadel.resources.woodLog -= entry.value;
        case 'knowledge':
          citadel.resources.knowledge -= entry.value;
      }
    }

    final success = _rng.nextDouble() < offer.successChance;
    final delta = success ? offer.standingGain : offer.standingGain * 0.2;

    applyFactionStandingChange(
      faction: faction,
      delta: delta,
      factionRelations: factionRelations,
      floors: null,
      currentDay: currentDay,
    );

    relation.lastDiplomacyDay = currentDay;

    // Set treaty if proposeNonAggression succeeded
    if (offerType == DiplomacyOfferType.proposeNonAggression && success) {
      relation.hasTreaty = true;
      relation.treatyStartDay = currentDay;
    }

    return success
        ? '${faction.label} aceitou a proposta. +${delta.toStringAsFixed(0)} standing.'
        : '${faction.label} foi reticente. +${delta.toStringAsFixed(0)} standing.';
  }

  // ── Expiração de tratados ─────────────────────────────────────────────────

  /// Tratados expiram após 60 dias.
  List<ServiceEvent> processTreatyExpiration({
    required Map<String, FactionRelation> factionRelations,
    required int currentDay,
  }) {
    const treatyDuration = 60;
    final events = <ServiceEvent>[];

    for (final relation in factionRelations.values) {
      if (!relation.hasTreaty) continue;
      if (currentDay - relation.treatyStartDay >= treatyDuration) {
        relation.hasTreaty = false;
        relation.treatyStartDay = 0;
        events.add(
          ServiceEvent(
            type: GameEventType.politicalEvent,
            title: 'Tratado Expirado: ${relation.faction.label}',
            description:
                'O tratado de não-agressão com ${relation.faction.label} expirou. '
                'A facção pode voltar a ser hostil se o standing cair.',
          ),
        );
      }
    }

    return events;
  }

  // ── Recompensas de aliança ─────────────────────────────────────────────────

  /// Aplica recompensas únicas quando uma facção atinge o tier aliado.
  List<ServiceEvent> processFactionRewards({
    required Map<String, FactionRelation> factionRelations,
    required Citadel citadel,
    required int currentDay,
  }) {
    final events = <ServiceEvent>[];

    for (final relation in factionRelations.values) {
      if (relation.tier != FactionTier.ally) continue;
      final rewardKey = 'ally_${relation.faction.key}';
      if (relation.rewardsGranted.contains(rewardKey)) continue;

      relation.rewardsGranted.add(rewardKey);
      String description;

      switch (relation.faction) {
        case FloorFaction.ironPact:
          citadel.resources.ironOre += 50;
          description = '+50 ferro como presente de aliança do Pacto de Ferro';
        case FloorFaction.silentOrder:
          citadel.resources.knowledge += 60;
          description =
              '+60 conhecimento como presente de aliança da Ordem Silenciosa';
        case FloorFaction.bloodMarket:
          citadel.resources.food += 40;
          description =
              '+40 comida como presente de aliança do Mercado de Sangue';
        case FloorFaction.voidChildren:
          // Evento caótico especial
          final roll = _rng.nextInt(3);
          switch (roll) {
            case 0:
              citadel.resources.food += 80;
              description =
                  'Evento caótico especial: +80 comida materializada do Vazio';
            case 1:
              citadel.resources.morale += 30;
              description =
                  'Evento caótico especial: +30 moral infundido pelos Filhos do Vazio';
            default:
              citadel.resources.ironOre += 60;
              description =
                  'Evento caótico especial: +60 ferro forjado no Vazio';
          }
        case FloorFaction.towerServants:
          description = '+1 nível de construção upgrade grátis (disponível)';
          // Marca upgrade grátis como pendente (engine pode consumir)
          relation.rewardsGranted.add('free_upgrade');
        case FloorFaction.none:
          continue;
      }

      events.add(
        ServiceEvent(
          type: GameEventType.celebration,
          title: 'Recompensa de Aliança: ${relation.faction.label}',
          description: description,
          isMajor: true,
        ),
      );
    }

    return events;
  }

  // ── Economia de facção ────────────────────────────────────────────────────

  /// Calcula taxa territorial baseada no tier (0.0–0.25).
  double calculateTerritoryTax(FloorFaction faction, FactionRelation relation) {
    switch (relation.tier) {
      case FactionTier.ally:
        return 0.0;
      case FactionTier.friendly:
        return 0.05;
      case FactionTier.neutral:
        return 0.10;
      case FactionTier.cautious:
        return 0.15;
      case FactionTier.hostile:
        return 0.20;
      case FactionTier.atWar:
        return 0.22;
      case FactionTier.bloodFeud:
        return 0.25;
    }
  }

  /// Tenta smuggling: contornar as taxas territoriais.
  SmugglingResult attemptSmuggling({
    required int floorNumber,
    required List<String> partyIds,
    required List<Npc> npcs,
    required List<TowerFloor> floors,
    required Map<String, FactionRelation> factionRelations,
    required int currentDay,
  }) {
    final floor = floors.firstWhereOrNull((f) => f.number == floorNumber);
    if (floor == null || floor.controllingFaction == FloorFaction.none) {
      return const SmugglingResult(
        success: false,
        taxSaved: 0,
        standingChange: 0,
        casualty: false,
        message: 'Sem facção a evitar neste andar.',
      );
    }

    final faction = floor.controllingFaction;
    final relation = getOrCreateFactionRelation(faction, factionRelations);
    final tax = calculateTerritoryTax(faction, relation);

    if (tax == 0.0) {
      return const SmugglingResult(
        success: true,
        taxSaved: 0,
        standingChange: 0,
        casualty: false,
        message: 'Facção aliada — sem taxa a evitar.',
      );
    }

    final party = _resolveParty(partyIds, npcs);
    final hasSmugglerTrait = party.any(
      (n) =>
          n.traits.contains(PersonalityTrait.treacherous) ||
          n.traits.contains(PersonalityTrait.cautious) ||
          n.origin == NpcOrigin.thief ||
          n.origin == NpcOrigin.assassin,
    );

    final baseChance = hasSmugglerTrait ? 0.65 : 0.35;
    final success = _rng.nextDouble() < baseChance;

    if (success) {
      final bonus = tax * 0.20;
      return SmugglingResult(
        success: true,
        taxSaved: tax + bonus,
        standingChange: 0,
        casualty: false,
        message:
            'Contrabando bem-sucedido! Taxa evitada (+${(tax * 100).toStringAsFixed(0)}%) '
            'e bônus extra (+${(bonus * 100).toStringAsFixed(0)}%).',
      );
    } else {
      applyFactionStandingChange(
        faction: faction,
        delta: -5.0,
        factionRelations: factionRelations,
        floors: floors,
        currentDay: currentDay,
      );
      final hasCasualty = _rng.nextDouble() < 0.20;
      return SmugglingResult(
        success: false,
        taxSaved: 0,
        standingChange: -5.0,
        casualty: hasCasualty,
        message:
            'Flagrado! -5 standing com ${faction.label}.'
            '${hasCasualty ? ' Um membro do grupo foi capturado!' : ''}',
      );
    }
  }

  // ── Recrutamento de survivors ──────────────────────────────────────────────

  // ── Serialização ──────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {};

  void loadFromJson(Map<String, dynamic> json) {}

  void clear() {}

  // ── Helpers privados ──────────────────────────────────────────────────────

  List<Npc> _resolveParty(List<String> partyIds, List<Npc> npcs) {
    return partyIds
        .map((id) => npcs.firstWhereOrNull((n) => n.id == id && n.alive))
        .whereType<Npc>()
        .toList();
  }

  ({double power, double intel, double fame, double luck}) _calcPartyStats(
    List<Npc> party,
  ) {
    if (party.isEmpty) return (power: 0, intel: 0, fame: 0, luck: 0);
    final count = party.length;
    return (
      power:
          party
              .map((n) => n.attributes.combatPower)
              .fold(0.0, (a, b) => a + b) /
          count,
      intel:
          party
              .map((n) => n.attributes.intelligence)
              .fold(0.0, (a, b) => a + b) /
          count,
      fame: party.map((n) => n.fame).fold(0.0, (a, b) => a + b) / count,
      luck:
          party.map((n) => n.attributes.luck).fold(0.0, (a, b) => a + b) /
          count,
    );
  }

  List<ServiceEvent> _voidChildrenChaosEvent(
    TowerFloor floor,
    List<Npc> party,
    FactionRelation relation,
  ) {
    if (party.isEmpty) return [];
    final events = <ServiceEvent>[];
    final roll = _rng.nextInt(6);
    switch (roll) {
      case 0:
        final randomNpc = party[_rng.nextInt(party.length)];
        randomNpc.attributes.luck += 3;
        events.add(
          ServiceEvent(
            type: GameEventType.discovery,
            title: 'Dom do Vazio',
            description:
                'Os Filhos do Vazio presentearam ${randomNpc.name} com algo impossível de descrever. '
                'Ela(e) parece mais sortudo(a). +3 sorte.',
          ),
        );
      case 1:
        final victim = party[_rng.nextInt(party.length)];
        victim.attributes.mentalStability -= 15;
        events.add(
          ServiceEvent(
            type: GameEventType.mentalBreak,
            title: 'Maldição do Vazio',
            description:
                '${victim.name} foi tocado(a) pelo caos. '
                '-15 estabilidade mental. Ninguém sabe por quê.',
          ),
        );
      case 2:
        events.add(
          ServiceEvent(
            type: GameEventType.resourceGain,
            title: 'Generosidade Caótica',
            description:
                'Uma pilha de mantimentos apareceu do nada. '
                'Os Filhos do Vazio balançaram as cabeças aprovadoramente. +30 comida.',
            extraFoodGain: 30,
          ),
        );
      case 3:
        relation.standing = _rng.nextDouble() * 40 - 20;
        events.add(
          ServiceEvent(
            type: GameEventType.politicalEvent,
            title: 'Reset Caótico',
            description:
                'Os Filhos do Vazio esqueceram toda a história com vocês. '
                'Ou fingiram. Standing resetado para ${relation.standing.toStringAsFixed(0)}.',
          ),
        );
      case 4:
        final npc = party[_rng.nextInt(party.length)];
        npc.fatigue = 100;
        npc.history.add('Desapareceu brevemente no Vazio');
        events.add(
          ServiceEvent(
            type: GameEventType.crisis,
            title: '${npc.name} desaparece',
            description:
                '${npc.name} sumiu por alguns segundos. Voltou. '
                'Não quer falar. Fadiga máxima.',
          ),
        );
      case 5:
        for (final n in party) {
          n.fame += 10;
        }
        events.add(
          ServiceEvent(
            type: GameEventType.celebration,
            title: 'Os Filhos aprovam',
            description:
                'Por razões incompreensíveis, os Filhos do Vazio erigiram '
                'estandartes com os rostos do grupo. '
                '+10 fama para todos. Perturbador.',
          ),
        );
    }
    return events;
  }
}

abstract class EquipmentServiceInterface {
  Equipment? rollDrop({
    required int floorNumber,
    required int tier,
    required int currentDay,
  });
}

// Move this method inside GameEngine class
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:tower_ascension/models/floor_faction.dart';
import 'package:tower_ascension/models/floor_inhabitant.dart';
import 'package:tower_ascension/services/crisis_flag_service.dart';
import 'package:tower_ascension/widgets/event_toast.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/tower.dart';
import '../models/game_event.dart';
import '../models/group_model.dart';
import '../models/equipment.dart';
import 'equipment_service.dart';
import '../models/citadel_record.dart';
import '../models/prison.dart';
import '../services/prison_service.dart';
import '../services/faction_service.dart';
import '../services/war_service.dart';
import '../services/trade_service.dart';
import '../services/quest_service.dart';

class GameEngine {
  final Random _rng;
  GameState state;
  List<Npc> npcs;
  Citadel citadel;
  List<TowerFloor> floors;
  List<GameEvent> events;
  List<GameEvent> _dayEvents = [];
  List<NpcGroup> groups;
  List<TrainingSuggestion> trainingSuggestions;
  List<TrainingMission> activeTrainings = [];
  int _trainingMissionCounter = 0;
  String _nextMissionId() => 'mission_${++_trainingMissionCounter}';
  int _groupIdCounter = 0;
  int _suggestionIdCounter = 0;

  // ======== Facções ==================
  // Survivors encontrados nos andares, aguardando recrutamento
  // (mantido por compatibilidade — FactionService agora gerencia _pendingRecruits)
  final List<FloorInhabitant> _pendingRecruits = [];

  List<FloorInhabitant> get pendingRecruits =>
      List.unmodifiable(_pendingRecruits);

  void addPendingRecruit(FloorInhabitant inhabitant) {
    if (!_pendingRecruits.any((r) => r.id == inhabitant.id)) {
      _pendingRecruits.add(inhabitant);
    }
  }

  // ====== Equipamentos ==================
  final EquipmentService _equipmentService = EquipmentService();
  final List<Equipment> _inventory = [];
  final PrisonService _prisonService = PrisonService();

  // ====== Novos Serviços ==================
  late final WarService _warService = WarService(_rng);
  late final FactionService _factionService = FactionService(_rng, _warService);
  late final TradeService _tradeService = TradeService(_rng);
  late final QuestService _questService = QuestService(_rng);

  // ── Accessors para novos serviços ──
  FactionService get factionService => _factionService;
  WarService get warService => _warService;
  TradeService get tradeService => _tradeService;
  QuestService get questService => _questService;

  // ====== Registro Oficial da Cidadela ==================
  final List<CitadelRecord> _records = [];
  int _recordIdCounter = 0;
  static const int _maxRawEvents = 200;

  GameEngine({int? seed})
    : _rng = Random(seed),
      state = GameState(),
      npcs = [],
      citadel = Citadel(),
      floors = TowerFloor.generateMvpFloors(),
      events = [],
      groups = [],
      trainingSuggestions = [] {
    // Inicializa processadores de eventos
  }

  // ── Accessors ──────────────────────────────

  List<Npc> get aliveNpcs => npcs.where((n) => n.alive).toList();
  List<Npc> get deadNpcs => npcs.where((n) => !n.alive).toList();
  int get population => aliveNpcs.length;
  List<TowerFloor> get clearedFloors => floors.where((f) => f.cleared).toList();
  bool get hasTrainingField => citadel.hasBuilding(BuildingType.trainingField);

  TowerFloor? get nextFloor {
    final idx = state.highestFloorCleared;
    return idx < floors.length ? floors[idx] : null;
  }

  // ====== Getter de Inventário ==============================
  List<Equipment> get inventory => List.unmodifiable(_inventory);

  // ====== Getter de Registros Oficiais ==============================
  List<CitadelRecord> get records => List.unmodifiable(_records);

  // ====== Getter de Prisão  ==============================
  PrisonService get prison => _prisonService;
  // ── ID Generators ──────────────────────────

  String _nextGroupId() => 'grp_${++_groupIdCounter}';
  String _nextSuggestionId() => 'sug_${++_suggestionIdCounter}';

  // ─────────────────────────────────────────────
  // INICIALIZACAO
  // ─────────────────────────────────────────────

  void initNewGame() {
    state = GameState();
    citadel = Citadel(
      buildings: [Building(type: BuildingType.firepit)],
      resources: Resources(
        food: 30,
        wood: 30,
        stone: 30,
        iron: 0,
        knowledge: 5,
        morale: 25,
      ),
    );
    floors = TowerFloor.generateMvpFloors();
    events = [];
    npcs = [];
    groups = [];
    trainingSuggestions = [];
    _groupIdCounter = 0;
    _suggestionIdCounter = 0;
    _inventory.clear(); // [FASE 1]
    _records.clear();
    _recordIdCounter = 0;
    _prisonService.clear();
    _factionService.clear();
    _warService.clear();
    _tradeService.clear();
    _questService.clear();
    _pendingRecruits.clear();

    // Gerar 15 Primordiais
    for (int i = 0; i < 15; i++) {
      npcs.add(Npc.generateRandom(state.generateNpcId(), 0, _rng));
    }
    _assignInitialProfessions();

    _addEvent(
      GameEventType.system,
      'Os Primordiais',
      '15 humanos comuns foram arrancados de suas vidas e jogados na base de uma torre impossivel. '
          'Ninguem sabe por que estao aqui. Mas a Torre observa. '
          'ATENCAO: Alguns dos Primordiais podem ter passados obscuros...',
      isMajor: true,
    );

    for (int i = 0; i < npcs.length; i++) {
      if (npcs[i].origin.isDarkOrigin) {
        npcs[i] = npcs[i].copyWith(isSuspicious: true);
        _addEvent(
          GameEventType.system,
          'Invocado Suspeito',
          '${npcs[i].name} (${npcs[i].origin.label}) demonstra comportamento inquietante.',
          involvedIds: [npcs[i].id],
        );
      }
    }
  }

  void _assignInitialProfessions() {
    final alive = aliveNpcs;
    if (alive.isEmpty) return;

    final byStrength = [...alive]
      ..sort((a, b) => b.attributes.strength.compareTo(a.attributes.strength));
    if (byStrength.isNotEmpty) byStrength[0].profession = Profession.guard;
    if (byStrength.length > 1) byStrength[1].profession = Profession.explorer;

    final byInt = [...alive]
      ..sort(
        (a, b) =>
            b.attributes.intelligence.compareTo(a.attributes.intelligence),
      );
    if (byInt.length > 2) byInt[2].profession = Profession.scribe;

    final byCharisma = [...alive]
      ..sort((a, b) => b.attributes.charisma.compareTo(a.attributes.charisma));
    if (byCharisma.length > 3) byCharisma[3].profession = Profession.merchant;

    for (final npc in alive.where((n) => n.profession == Profession.idle)) {
      npc.profession = _professionFromOrigin(npc.origin);
    }
  }

  Profession _professionFromOrigin(NpcOrigin origin) {
    switch (origin) {
      case NpcOrigin.chef:
      case NpcOrigin.farmer:
        return Profession.farmer;
      case NpcOrigin.doctor:
      case NpcOrigin.nurse:
        return Profession.doctor;
      case NpcOrigin.soldier:
      case NpcOrigin.firefighter:
        return Profession.guard;
      case NpcOrigin.teacher:
        return Profession.teacher;
      default:
        return Profession.idle;
    }
  }

  // ─────────────────────────────────────────────
  // LOOP DIÁRIO
  // ─────────────────────────────────────────────

  List<GameEvent> simulateDay() {
    for (final floor in clearedFloors) {
      floor.clearTemporaryTags();
    }
    _dayEvents = [];
    if (state.gameOver) return _dayEvents;
    autoEquipAllNpcs();

    if (aliveNpcs.isEmpty) {
      state.gameOver = true;
      state.gameOverReason = 'Todos morreram. A humanidade falhou.';
      _addEvent(
        GameEventType.death,
        'EXTINCAO',
        'O ultimo humano caiu. A Torre devora os restos em silencio.',
        isMajor: true,
      );
      return _dayEvents;
    }

    state.currentDay++;

    _processResourceProduction();
    _processResourceConsumption();
    _processOverpopulationPenalty();
    _processFatigueRecovery();
    _processRelationships();
    _processMentalHealth();
    _processLoyalty();
    _processIdleness();
    _processAutonomousProfessionChoice();
    _processRandomEvents();
    _processBetrayalAttempts();
    _processPregnancies();
    _processChildMortality();
    _processGrowthTransitions();
    _processAging();
    _processTraining();
    _processAutonomousTraining();
    _processActiveTrainings();
    _processAutoReexploration();
    _processPassiveEnvironmentalTraining();
    _processSurvivalGrowth();
    _processMoraleBonus();
    _processTalentDiscovery();
    _processArenaEvents();
    _processTavernEvents();
    _processEmergencySummon();
    _processPrisonSystem();

    _processFameGains();
    _processFactionIncursions();

    // ── Novos serviços ──
    // Expiração de tratados (diário)
    for (final ev in _factionService.processTreatyExpiration(
      factionRelations: state.factionRelations,
      currentDay: state.currentDay,
    )) {
      _addEvent(ev.type, ev.title, ev.description, isMajor: ev.isMajor);
    }

    // Recompensas de aliança (diário, só dispara uma vez)
    for (final ev in _factionService.processFactionRewards(
      factionRelations: state.factionRelations,
      citadel: citadel,
      currentDay: state.currentDay,
    )) {
      _addEvent(ev.type, ev.title, ev.description, isMajor: ev.isMajor);
      if (ev.extraFoodGain != null && ev.extraFoodGain! > 0) {
        citadel.resources.food += ev.extraFoodGain!;
      }
    }
    // Guerras (diário)
    for (final ev in _warService.processWars(
      currentDay: state.currentDay,
      floors: floors,
      factionRelations: state.factionRelations,
    )) {
      _addEvent(ev.type, ev.title, ev.description, isMajor: ev.isMajor);
    }

    // ← ADICIONA AQUI
    for (final floor in floors.where(
      (f) => f.cleared && f.inhabitants.isNotEmpty,
    )) {
      final isContested = _warService.isFloorContested(floor.number);
      FloorFaction? contestingFaction;
      if (isContested && _warService.activeWars.isNotEmpty) {
        final war = _warService.activeWars.firstWhere(
          (w) => w.contestedFloors.contains(floor.number),
          orElse: () => _warService.activeWars.first,
        );
        contestingFaction = war.aggressor;
      }
      InhabitantProcessor.updateForWarState(
        inhabitants: floor.inhabitants,
        isContested: isContested,
        contestingFaction: contestingFaction,
      );
    }

    // Ofertas de comércio (a cada 7 dias)
    if (state.currentDay % 7 == 0) {
      _tradeService.refreshOffers(
        floors: floors,
        factionRelations: state.factionRelations,
        currentDay: state.currentDay,
      );
    }

    // Geração de missões (a cada 5 dias)
    if (state.currentDay % 5 == 0) {
      _questService.generateQuests(
        floors: floors,
        factionRelations: state.factionRelations,
        currentDay: state.currentDay,
        activeWars: _warService.activeWars,
      );
    }

    // Expiração de missões (diário)
    for (final ev in _questService.processExpiration(state.currentDay)) {
      _addEvent(ev.type, ev.title, ev.description, isMajor: ev.isMajor);
    }

    if (state.currentDay % 7 == 0) _autonomousGroupFormation();

    final overflow = citadel.resources.clampToCapacity(citadel.storageLevel);
    if (overflow.totalPhysical > 0) {
      _addEvent(
        GameEventType.resourceLoss,
        'Recursos Estragaram!',
        'O armazem nao comportou tudo que foi coletado hoje. '
            'Excedente perdido: ${_formatOverflow(overflow)}\n'
            'Amplie o Armazem ou reduza as coletas para evitar perdas.',
      );
    }
    for (final npc in aliveNpcs) {
      npc.daysSurvived++;
    }

    return _dayEvents;
  }

  String _formatOverflow(overflow) {
    final parts = <String>[];
    if (overflow.food > 0) {
      parts.add('Comida:${overflow.food.toStringAsFixed(0)}');
    }
    if (overflow.wood > 0) {
      parts.add('Madeira:${overflow.wood.toStringAsFixed(0)}');
    }
    if (overflow.stone > 0) {
      parts.add('Pedra:${overflow.stone.toStringAsFixed(0)}');
    }
    if (overflow.iron > 0) {
      parts.add('Ferro:${overflow.iron.toStringAsFixed(0)}');
    }
    if (overflow.knowledge > 0) {
      parts.add('Conhec.:${overflow.knowledge.toStringAsFixed(0)}');
    }
    return parts.join(' ');
  }

  // ─────────────────────────────────────────────
  // PRODUCAO & CONSUMO
  // ─────────────────────────────────────────────
  void _applyGlobalModifiers(Resources res) {
    final moraleModifier =
        1 + ((citadel.resources.morale - 50) / 200).clamp(-0.25, 0.25);

    res.food *= moraleModifier;
    res.wood *= moraleModifier;
    res.stone *= moraleModifier;
    res.iron *= moraleModifier;
    res.knowledge *= moraleModifier;
  }

  // double _softCap(double value, double capStart) {
  //   if (value <= capStart) return value;
  //   return capStart + (value - capStart) * 0.5;
  // }

  void _processResourceProduction() {
    final res = citadel.resources;
    final farmers = _countProfession(Profession.farmer);
    final builders = _countProfession(Profession.builder);
    final scribes = _countProfession(Profession.scribe);

    res.food += 2.0 + farmers * 1.0;
    res.wood += 1.0 + builders * 2.0;
    res.stone += 0.5 + builders * 1.0;
    res.knowledge += 0.2 + scribes * 1.5;

    for (final building in citadel.buildings) {
      _applyBuildingProduction(building, res);
    }

    _applyGlobalModifiers(citadel.resources);

    // Não aplicamos soft cap aqui — o clampToCapacity no final do processDay
    // é o único ponto de corte. Isso permite que coletas e produção do mesmo dia
    // se acumulem livremente; o excedente "estraga" apenas ao virar o dia.
  }

  double _expProduction({
    required int level,
    required double base,
    double growth = 1.6,
  }) {
    return base * pow(growth, level - 1);
  }

  void _applyBuildingProduction(Building building, Resources res) {
    final level = building.level;
    final tierBonus = 1 + (building.tier * 0.15);
    final population = aliveNpcs.length;

    switch (building.type) {
      // 🌾 FARM
      case BuildingType.farm:
        final farmers = _countProfession(Profession.farmer);
        final chefs = _countProfession(Profession.chef);
        final kitchenCount = citadel.countBuildings(BuildingType.kitchen);

        // Retorno decrescente: farm só aproveita até (level+1) farmers
        final effectiveFarmers = min(farmers, level + 1);

        // Produção base flat por nível (controlada, sem exp agressivo)
        const farmBaseProd = <int, double>{1: 4, 2: 6, 3: 9, 4: 13, 5: 18};
        final baseProduction = farmBaseProd[level] ?? 18.0;

        // Population bonus suave com teto logarítmico (~1.30x máx)
        final softPopBonus = 1.0 + log(1.0 + population / 20.0) * 0.15;

        // Chef multiplier: chefs em kitchens ampliam a farm (cap = (level+2)*kitchens)
        final effectiveChefs = min(chefs, (level + 2) * kitchenCount);
        final chefMultiplier = 1.0 + effectiveChefs * 0.06;

        // tierBonus reduzido de 0.15 para 0.10 por tier
        final farmTierBonus = 1.0 + (building.tier * 0.10);

        res.food +=
            (baseProduction + effectiveFarmers * 2.0) *
            farmTierBonus *
            softPopBonus *
            chefMultiplier;
        break;

      // 🍲 KITCHEN — amplificador da farm, não fonte direta de food
      case BuildingType.kitchen:
        // Kitchen não produz food diretamente.
        // Seu efeito é contabilizado na fórmula do farm via chefMultiplier.
        break;

      // ⚒ WORKSHOP
      case BuildingType.workshop:
        final ironProduction = _expProduction(
          level: level,
          base: 1,
          growth: 2.0,
        );

        final woodProduction = _expProduction(
          level: level,
          base: 0.5,
          growth: 1.8,
        );

        res.iron += ironProduction * tierBonus;
        res.wood += woodProduction * tierBonus;
        break;

      // 🪵 WOODWORKING
      case BuildingType.woodworking:
        final woodProduction = _expProduction(
          level: level,
          base: 2,
          growth: 1.9,
        );

        final moraleBonus = _expProduction(
          level: level,
          base: 0.5,
          growth: 1.5,
        );

        res.wood += woodProduction * tierBonus;
        res.morale += moraleBonus;
        break;

      // 🔨 FORGE
      case BuildingType.forge:
        final ironProduction = _expProduction(
          level: level,
          base: 2,
          growth: 1.8,
        );

        res.iron += ironProduction * tierBonus;
        break;

      // 📚 LIBRARY
      case BuildingType.library:
        final knowledgeProduction = _expProduction(
          level: level,
          base: 2,
          growth: 1.6,
        );

        res.knowledge += knowledgeProduction * tierBonus;
        break;

      // 🏫 SCHOOL
      case BuildingType.school:
        final schoolProduction = _expProduction(
          level: level,
          base: 1,
          growth: 1.6,
        );

        res.knowledge += schoolProduction * tierBonus;
        break;
      // ⛪ TEMPLE
      case BuildingType.temple:
        final moraleBoost = _expProduction(
          level: level,
          base: 1.5,
          growth: 1.5,
        );

        res.morale += moraleBoost;

        for (final npc in aliveNpcs) {
          npc.attributes.mentalStability =
              (npc.attributes.mentalStability + (0.3 * level)).clamp(0, 100);
        }
        break;

      // 🔥 FIREPIT
      case BuildingType.firepit:
        final moraleBoost = _expProduction(level: level, base: 1, growth: 1.7);

        res.morale += moraleBoost;
        break;
      // 🏛 MONUMENT
      case BuildingType.monument:
        res.morale += 5.0;
        break;

      default:
        break;
    }
  }

  void _processResourceConsumption() {
    final consumption = population * 1.5;
    // Aplica redução do granary
    final granaryReduction = citadel.buildings
        .where((b) => b.type == BuildingType.granary)
        .fold(0.0, (sum, b) => sum + b.foodConsumptionReduction);
    final effectiveConsumption =
        consumption * (1.0 - granaryReduction.clamp(0.0, 0.50));

    citadel.resources.food -= effectiveConsumption;

    if (citadel.resources.food < 0) {
      citadel.resources.food = 0;
      citadel.resources.morale -= 5;
      _addEvent(
        GameEventType.crisis,
        'Fome!',
        'Nao ha comida suficiente. A fome se espalha. Moral despenca.',
        isMajor: true,
      );
      _addPsychologicalMarksToChildren('Testemunhou fome severa na cidadela');

      for (final npc in aliveNpcs) {
        npc.attributes.mentalStability -= 3;
        npc.attributes.endurance -= 0.2;
        npc.loyalty -= 2;
        if (_rng.nextDouble() < 0.05) _killNpc(npc, 'Morreu de fome');
      }
    }
  }

  void _processOverpopulationPenalty() {
    final capacity = citadel.totalPopulationCapacity;
    final pop = aliveNpcs.length;
    if (pop <= capacity) return;

    final excess = pop - capacity;
    final severity = excess / capacity.clamp(1, 9999); // 0.0 a N

    // Penalidade de moral proporcional ao excesso
    final moraleLoss = (excess * 1.5).clamp(2.0, 20.0);
    citadel.resources.morale -= moraleLoss;

    // Penalidade de comida — mais bocas, menos espaço → desperdício/conflito
    final foodLoss = excess * 0.5;
    citadel.resources.food = (citadel.resources.food - foodLoss).clamp(
      0,
      99999,
    );

    // Lealdade cai para todos por tensão social
    for (final npc in aliveNpcs) {
      npc.loyalty -= (0.2 * severity).clamp(0.1, 1.0);
      npc.attributes.mentalStability -= (0.3 * severity).clamp(0.1, 2.0);
    }

    // Evento periódico de aviso (a cada 3 dias para não spammar)
    if (state.currentDay % 3 == 0) {
      _addEvent(
        GameEventType.crisis,
        'Superpopulação!',
        'A cidadela tem $excess habitante(s) acima da capacidade ($pop/$capacity). '
            'Tensão social crescente. Construa moradias ou evolua a cidadela.',
        isMajor: excess > capacity * 0.2,
      );
    }
  }
  // ─────────────────────────────────────────────
  // FADIGA
  // ─────────────────────────────────────────────

  void _processFatigueRecovery() {
    for (final npc in aliveNpcs) {
      var recovery = 30.0 + (npc.attributes.endurance / 15.0) * 15.0;
      if (citadel.hasBuilding(BuildingType.infirmary)) recovery += 15.0;
      if (citadel.hasBuilding(BuildingType.temple)) recovery += 10.0;
      if (_hasLivingPartner(npc)) recovery += 2.0;
      if (npc.groupId != null) recovery += 1.0;
      if (npc.lastExpeditionDay == state.currentDay) recovery *= 0.3;

      npc.fatigue = (npc.fatigue - recovery).clamp(0.0, 100.0);
      _applyFatigueConsequences(npc);
    }
  }

  void _applyFatigueConsequences(Npc npc) {
    if (npc.fatigue >= 90) {
      npc.attributes.mentalStability -= 5;
      npc.loyalty -= 1;
      npc.profession = Profession.idle;
      if (_rng.nextDouble() < 0.08) {
        npc.attributes.endurance -= 0.5;
        npc.traumas.add(
          'Colapso fisico por exaustao no dia ${state.currentDay}',
        );
        _addEvent(
          GameEventType.crisis,
          'Colapso Fisico!',
          '${npc.name} colapsou por exaustao. Resistencia permanentemente reduzida.',
          involvedIds: [npc.id],
          isMajor: true,
        );
      }
    } else if (npc.fatigue >= 70) {
      npc.attributes.mentalStability -= 3;
      npc.loyalty -= 0.5;
      if (state.currentDay % 3 == 0) {
        _addEvent(
          GameEventType.crisis,
          'NPC Exausto',
          '${npc.name} esta exausto(a). Precisa de descanso urgente.',
          involvedIds: [npc.id],
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // RELACIONAMENTOS
  // ─────────────────────────────────────────────

  void _processRelationships() {
    final alive = aliveNpcs;
    if (alive.length < 2 || _rng.nextDouble() >= 0.15) return;

    final a = alive[_rng.nextInt(alive.length)];
    final b = _pickOther(alive, a);
    final existing = a.relationships.firstWhereOrNull(
      (r) => r.targetId == b.id,
    );

    if (existing == null) {
      _createRelationship(a, b);
    } else {
      _evolveRelationship(a, b, existing);
    }
  }

  void _createRelationship(Npc a, Npc b) {
    // ✅ Garante mínimo de 0.05 para o relacionamento ter chance de evoluir
    final rawAffinity =
        (a.attributes.charisma + b.attributes.charisma) /
        20.0 *
        _rng.nextDouble();
    final affinity = (rawAffinity + 0.05).clamp(0.05, 1.0);

    a.relationships.add(
      Relationship(targetId: b.id, type: 'amigo', affinity: affinity),
    );
    b.relationships.add(
      Relationship(targetId: a.id, type: 'amigo', affinity: affinity),
    );

    if (a.groupId != null && a.groupId == b.groupId) {
      final lastIndexA = a.relationships.length - 1;
      final lastIndexB = b.relationships.length - 1;
      a.relationships[lastIndexA] = a.relationships[lastIndexA].copyWith(
        affinity: (a.relationships[lastIndexA].affinity + 0.1).clamp(0.0, 1.0),
      );
      b.relationships[lastIndexB] = b.relationships[lastIndexB].copyWith(
        affinity: (b.relationships[lastIndexB].affinity + 0.1).clamp(0.0, 1.0),
      );
    }
  }

  void _evolveRelationship(Npc a, Npc b, Relationship rel) {
    final indexInA = a.relationships.indexWhere((r) => r.targetId == b.id);
    if (indexInA == -1) return;

    final newAffinity = (rel.affinity + _rng.nextDouble() * 0.3 - 0.05).clamp(
      -1.0,
      1.0,
    );
    a.relationships[indexInA] = a.relationships[indexInA].copyWith(
      affinity: newAffinity,
    );

    final threshold = citadel.resources.morale > 85
        ? 0.55
        : citadel.resources.morale > 70
        ? 0.6
        : 0.7;

    if (newAffinity > threshold && a.partnerId == null && b.partnerId == null) {
      a.partnerId = b.id;
      b.partnerId = a.id;

      a.relationships[indexInA] = a.relationships[indexInA].copyWith(
        type: 'parceiro',
      );

      final indexInB = b.relationships.indexWhere((r) => r.targetId == a.id);
      if (indexInB != -1) {
        b.relationships[indexInB] = b.relationships[indexInB].copyWith(
          type: 'parceiro',
        );
      }

      _addEvent(
        GameEventType.romance,
        'Novo Vinculo',
        '${a.name} e ${b.name} formaram uma uniao.',
        involvedIds: [a.id, b.id],
      );
    }
  }

  // ─────────────────────────────────────────────
  // SAÚDE MENTAL
  // ─────────────────────────────────────────────

  void _processMentalHealth() {
    for (final npc in aliveNpcs) {
      double mod = 0;
      if (citadel.resources.morale > 70) mod += 0.5;
      if (citadel.resources.morale < 30) mod -= 2.0;
      if (npc.traumas.length > 3) mod -= 1.0;
      if (_hasLivingPartner(npc)) mod += 5.0;
      if (npc.traits.contains(PersonalityTrait.optimist)) mod += 0.5;
      if (npc.traits.contains(PersonalityTrait.pessimist)) mod -= 0.5;
      if (npc.groupId != null) mod += 0.2;

      npc.attributes.mentalStability = (npc.attributes.mentalStability + mod)
          .clamp(0, 100);

      if (npc.attributes.mentalStability < 15 && _rng.nextDouble() < 0.1) {
        _processMentalBreak(npc);
      }
    }
  }

  void _processMentalBreak(Npc npc) {
    final breakType = _rng.nextInt(5);
    switch (breakType) {
      case 0:
        npc.profession = Profession.idle;
        npc.traumas.add('Colapso mental no dia ${state.currentDay}');
        _addEvent(
          GameEventType.mentalBreak,
          'Colapso Mental',
          '${npc.name} se trancou. ${npc.traumas.isNotEmpty ? "Os traumas acumulados foram longe demais." : "Ninguém sabe o que aconteceu."}',
          involvedIds: [npc.id],
        );
        break;
      case 1:
        citadel.resources.food -= 10;
        citadel.resources.morale -= 5;
        npc.loyalty -= 10;
        npc.fame -= 5;
        npc.traumas.add('Rebeliao no dia ${state.currentDay}');
        _prisonService.recordCrime(
          npcId: npc.id,
          type: CrimeType.rebellion,
          day: state.currentDay,
          witnessed: true, // rebelião é sempre pública
        );
        _addEvent(
          GameEventType.betrayal,
          'Rebeliao',
          '${npc.name} destruiu suprimentos e gritou que "${npc.loyalty < 20 ? 'nunca pertenceu a este lugar' : 'isso não é o que foi prometido'}".',
          involvedIds: [npc.id],
        );
        break;
      case 2:
        if (_rng.nextDouble() < 0.3) {
          _killNpc(npc, 'Sacrificio suicida - partiu sozinho para a Torre');
          _addEvent(
            GameEventType.death,
            'Sacrificio Suicida',
            '${npc.name} partiu sozinho. ${npc.floorsCleared > 5 ? "Havia sobrevivido a ${npc.floorsCleared} andares. Não foi suficiente." : "Nunca chegou a conhecer a torre de verdade."}',
            involvedIds: [npc.id],
            isMajor: true,
          );
        } else {
          npc.attributes.endurance -= 2;
          npc.traumas.add('Tentativa de fuga no dia ${state.currentDay}');
          _addEvent(
            GameEventType.mentalBreak,
            'Tentativa de Fuga',
            '${npc.name} tentou escalar as paredes externas. ${npc.partnerId != null ? "Gritou um nome antes de perder a consciência." : "Encontrado sozinho, inconsciente."}',
            involvedIds: [npc.id],
          );
        }
        break;
      case 3:
        npc.profession = Profession.idle;
        npc.attributes.strength -= 1;
        npc.traumas.add('Depressao severa no dia ${state.currentDay}');
        _addEvent(
          GameEventType.mentalBreak,
          'Depressao Profunda',
          '${npc.name} parou de comer. Parou de falar. ${npc.traits.isNotEmpty ? "O(a) ${npc.traits.first.label} que todos conheciam desapareceu." : "Como se tivesse apagado."}',
          involvedIds: [npc.id],
        );
        break;
      default:
        citadel.resources.morale -= 3;
        npc.fame -= 3;
        npc.traumas.add('Surto violento no dia ${state.currentDay}');
        _addEvent(
          GameEventType.mentalBreak,
          'Surto Agressivo',
          '${npc.name} atacou outros moradores sem motivo aparente. ${npc.floorsCleared > 0 ? "Veterano(a) de ${npc.floorsCleared} andares. A torre cobra seu preço." : "A pressão foi longe demais."}',
          involvedIds: [npc.id],
        );
    }
  }

  // ─────────────────────────────────────────────
  // LEALDADE
  // ─────────────────────────────────────────────

  void _processLoyalty() {
    for (final npc in aliveNpcs) {
      double mod = 0;
      if (citadel.resources.morale > 70) mod += 0.1;
      if (citadel.resources.morale < 30) mod -= 0.3;
      if (citadel.resources.food > population * 3) mod += 0.05;
      if (npc.traits.contains(PersonalityTrait.loyal)) mod += 0.1;
      if (npc.traits.contains(PersonalityTrait.treacherous)) mod -= 0.1;
      if (npc.origin.isDarkOrigin) mod -= 0.05;
      if (npc.groupId != null) mod += 0.05;
      npc.loyalty = (npc.loyalty + mod).clamp(0, 100);
    }
  }

  // ─────────────────────────────────────────────
  // OCIOSIDADE
  // ─────────────────────────────────────────────

  void _processIdleness() {
    for (final npc in aliveNpcs) {
      final stage = npc.growthStage(state.currentDay);
      if (stage == GrowthStage.baby ||
          stage == GrowthStage.child ||
          stage == GrowthStage.adolescent) {
        npc.daysIdle = 0;
        continue;
      }

      if (npc.profession == Profession.idle) {
        npc.daysIdle++;
      } else {
        npc.daysIdle = 0;
        continue;
      }

      if (npc.daysIdle >= 7) {
        _applyIdlenessPenalties(npc);
      }
    }
  }

  void _applyIdlenessPenalties(Npc npc) {
    final weeksIdle = npc.daysIdle ~/ 7;

    if (npc.traits.contains(PersonalityTrait.ambitious) ||
        npc.traits.contains(PersonalityTrait.leader)) {
      npc.attributes.mentalStability -= 0.5 * weeksIdle;
    } else {
      npc.attributes.mentalStability -= 0.2 * weeksIdle;
    }

    npc.loyalty -= 0.3 * weeksIdle;

    if (npc.traits.contains(PersonalityTrait.lazy)) return;

    if (npc.daysIdle >= 14) {
      npc.attributes.strength -= 0.05;
      npc.attributes.endurance -= 0.05;
    }

    if (npc.daysIdle == 21 && _rng.nextDouble() < 0.6) {
      _triggerIdlenessEvent(npc);
    }
  }

  void _triggerIdlenessEvent(Npc npc) {
    final roll = _rng.nextInt(3);
    switch (roll) {
      case 0:
        citadel.resources.morale -= 2;
        npc.fame -= 3;
        _addEvent(
          GameEventType.crisis,
          'Reclamacao de Ocioso',
          '${npc.name} reclama publicamente: "Por que ainda nao me deram um trabalho? '
              'Estou aqui a ${npc.daysIdle} dias sem fazer nada!"',
          involvedIds: [npc.id],
        );
        break;
      case 1:
        npc.loyalty -= 5;
        _addEvent(
          GameEventType.mentalBreak,
          'Descontentamento Crescente',
          '${npc.name} esta visivelmente frustrado com a ociosidade prolongada. '
              'Alguns moradores notam olhares ressentidos.',
          involvedIds: [npc.id],
        );
        break;
      case 2:
        npc.attributes.mentalStability -= 5;
        _addEvent(
          GameEventType.mentalBreak,
          'Crise de Proposito',
          '${npc.name} entra em depressao por falta de proposito. '
              '"Para que estou aqui se nao contribuo em nada?"',
          involvedIds: [npc.id],
        );
        break;
    }
  }

  // ─────────────────────────────────────────────
  // ESCOLHA AUTÔNOMA DE PROFISSÕES
  // ─────────────────────────────────────────────

  void _processAutonomousProfessionChoice() {
    if (state.currentDay % 3 != 0) return;

    for (final npc in aliveNpcs) {
      final stage = npc.growthStage(state.currentDay);
      if (stage != GrowthStage.adult || npc.profession != Profession.idle) {
        continue;
      }

      final choiceChance = _calculateProfessionChoiceChance(npc);
      if (_rng.nextDouble() > choiceChance) continue;

      final chosen = _chooseProfessionFor(npc);
      if (chosen != null && chosen != Profession.idle) {
        npc.profession = chosen;
        npc.daysIdle = 0;
        npc.loyalty += 2;
        _addEvent(
          GameEventType.system,
          'Nova Profissao',
          '${npc.name} decidiu trabalhar como ${chosen.label}.',
          involvedIds: [npc.id],
        );
      }
    }
  }

  double _calculateProfessionChoiceChance(Npc npc) {
    double baseChance = 0.15;
    if (npc.traits.contains(PersonalityTrait.ambitious)) baseChance += 0.15;
    if (npc.traits.contains(PersonalityTrait.leader)) baseChance += 0.10;
    if (npc.traits.contains(PersonalityTrait.lazy)) baseChance -= 0.20;
    if (npc.traits.contains(PersonalityTrait.loyal)) baseChance += 0.10;
    if (npc.daysIdle >= 14) baseChance += 0.15;
    if (npc.daysIdle >= 21) baseChance += 0.25;
    if (citadel.resources.morale < 40) baseChance -= 0.10;
    return baseChance.clamp(0.0, 0.8);
  }

  Profession? _chooseProfessionFor(Npc npc) {
    final needs = _analyzeCitadelNeeds();
    final candidates = <Profession, double>{};
    for (final profession in Profession.values) {
      if (profession == Profession.idle) continue;
      final score = _calculateProfessionScore(npc, profession, needs);
      if (score > 0) candidates[profession] = score;
    }
    if (candidates.isEmpty) return null;
    return _weightedRandomChoice(candidates);
  }

  Map<String, double> _analyzeCitadelNeeds() {
    final population = aliveNpcs.length;
    final farmers = _countProfession(Profession.farmer);
    final guards = _countProfession(Profession.guard);
    final builders = _countProfession(Profession.builder);
    final doctors = _countProfession(Profession.doctor);
    return {
      'food': population > 0 ? 1.0 - (farmers / (population * 0.3)) : 1.0,
      'defense': population > 0 ? 1.0 - (guards / (population * 0.2)) : 1.0,
      'construction': population > 0
          ? 1.0 - (builders / (population * 0.15))
          : 1.0,
      'health': population > 0 ? 1.0 - (doctors / (population * 0.1)) : 1.0,
    };
  }

  double _calculateProfessionScore(
    Npc npc,
    Profession profession,
    Map<String, double> needs,
  ) {
    double score = 0.5;
    if (_professionFromOrigin(npc.origin) == profession) score += 0.4;

    switch (profession) {
      case Profession.farmer:
        score += npc.attributes.endurance / 20;
        score += (needs['food'] ?? 0) * 0.5;
        break;
      case Profession.guard:
      case Profession.explorer:
        score += npc.attributes.strength / 15;
        score += npc.attributes.endurance / 20;
        score += (needs['defense'] ?? 0) * 0.4;
        if (npc.traits.contains(PersonalityTrait.brave)) score += 0.3;
        if (npc.traits.contains(PersonalityTrait.coward)) score -= 0.5;
        break;
      case Profession.builder:
        score += npc.attributes.strength / 20;
        score += npc.attributes.intelligence / 20;
        score += (needs['construction'] ?? 0) * 0.4;
        break;
      case Profession.doctor:
        score += npc.attributes.intelligence / 15;
        score += npc.attributes.charisma / 20;
        score += (needs['health'] ?? 0) * 0.5;
        break;
      case Profession.scribe:
      case Profession.teacher:
        score += npc.attributes.intelligence / 12;
        if (npc.traits.contains(PersonalityTrait.analytical)) score += 0.3;
        break;
      case Profession.merchant:
        score += npc.attributes.charisma / 12;
        if (npc.traits.contains(PersonalityTrait.ambitious)) score += 0.2;
        break;
      case Profession.chef:
        score += npc.attributes.intelligence / 20;
        break;
      default:
        break;
    }

    if (npc.traits.contains(PersonalityTrait.lazy) &&
        [
          Profession.guard,
          Profession.explorer,
          Profession.builder,
        ].contains(profession)) {
      score -= 0.4;
    }

    return score.clamp(0.0, 2.0);
  }

  T _weightedRandomChoice<T>(Map<T, double> weights) {
    final totalWeight = weights.values.reduce((a, b) => a + b);
    var random = _rng.nextDouble() * totalWeight;
    for (final entry in weights.entries) {
      random -= entry.value;
      if (random <= 0) return entry.key;
    }
    return weights.keys.first;
  }

  // ─────────────────────────────────────────────
  // TRAIÇÃO
  // ─────────────────────────────────────────────
  void _processBetrayalAttempts() {
    if (state.currentDay % 7 != 0) return;
    for (int i = 0; i < npcs.length; i++) {
      if (!npcs[i].alive) continue;
      if (npcs[i].betrayalRisk < 30) continue;
      if (_rng.nextDouble() * 100 > npcs[i].betrayalRisk) continue;
      npcs[i] = _executeBetrayal(npcs[i]);
    }
  }

  Npc _executeBetrayal(Npc npc) {
    switch (_rng.nextInt(4)) {
      case 0:
        return _betrayalTheft(npc);
      case 1:
        return _betrayalSabotage(npc);
      case 2:
        return _betrayalManipulation(npc);
      case 3:
        return _betrayalAssassination(npc);
      default:
        return npc;
    }
  }

  // ── Roubo ──────────────────────────────────────────────────

  Npc _betrayalTheft(Npc npc) {
    final stolen = 5.0 + _rng.nextDouble() * 15;
    citadel.resources.food = (citadel.resources.food - stolen).clamp(0, 9999);

    final witnessed = citadel.hasBuilding(BuildingType.watchtower)
        ? _rng.nextDouble() < 0.8
        : _rng.nextDouble() < 0.4;

    _prisonService.recordCrime(
      npcId: npc.id,
      type: CrimeType.theft,
      day: state.currentDay,
      witnessed: witnessed,
    );
    _addPsychologicalMarksToChildren('Testemunhou traicao: roubo de comida');
    _addEvent(
      GameEventType.betrayalAttempt,
      'Roubo de Suprimentos!',
      '${npc.name} roubou ${stolen.toStringAsFixed(0)} de comida! '
          '${witnessed ? "Foi visto!" : "Passou despercebido."}',
      involvedIds: [npc.id],
      isMajor: true,
    );
    return npc.copyWith(fame: npc.fame - 10, loyalty: npc.loyalty - 5);
  }

  // ── Sabotagem ──────────────────────────────────────────────

  Npc _betrayalSabotage(Npc npc) {
    if (citadel.resources.morale <= 20) return npc;

    citadel.resources.morale -= 8;
    _prisonService.recordCrime(
      npcId: npc.id,
      type: CrimeType.sabotage,
      day: state.currentDay,
      witnessed: _rng.nextDouble() < 0.5,
    );
    _addEvent(
      GameEventType.betrayalAttempt,
      'Sabotagem!',
      '${npc.name} sabotou equipamentos durante a noite. -8 moral.',
      involvedIds: [npc.id],
      isMajor: true,
    );
    return npc.copyWith(fame: npc.fame - 8);
  }

  // ── Manipulação ────────────────────────────────────────────

  Npc _betrayalManipulation(Npc npc) {
    final targets = aliveNpcs
        .where((n) => n.id != npc.id && n.loyalty < 60)
        .toList();
    if (targets.isEmpty) return npc;

    final target = targets[_rng.nextInt(targets.length)];
    final idx = npcs.indexWhere((n) => n.id == target.id);
    if (idx != -1) {
      npcs[idx] = npcs[idx].copyWith(loyalty: npcs[idx].loyalty - 5);
    }
    _addEvent(
      GameEventType.politicalEvent,
      'Manipulacao',
      '${npc.name} espalhou rumores sobre ${target.name}.',
      involvedIds: [npc.id, target.id],
    );
    return npc.copyWith(fame: npc.fame - 5);
  }

  // ── Assassinato ────────────────────────────────────────────

  Npc _betrayalAssassination(Npc npc) {
    if (npc.origin != NpcOrigin.assassin) return npc;

    final targets = aliveNpcs
        .where((n) => n.id != npc.id && n.fame > 15)
        .toList();
    if (targets.isEmpty) return npc;

    final target = targets[_rng.nextInt(targets.length)];
    final succeeded = _rng.nextDouble() < 0.4;

    if (succeeded) {
      _killNpc(target, 'Assassinado por ${npc.name}');
      _prisonService.recordCrime(
        npcId: npc.id,
        type: CrimeType.assassination,
        day: state.currentDay,
        witnessed: true,
      );
      _addPsychologicalMarksToChildren(
        'Testemunhou assassinato - ${target.name} morto',
        exceptIds: [target.id],
      );
      _addEvent(
        GameEventType.betrayalAttempt,
        'ASSASSINATO!',
        '${npc.name} assassinou ${target.name} durante a noite!',
        involvedIds: [npc.id, target.id],
        isMajor: true,
      );
      return npc.copyWith(killCount: npc.killCount + 1, fame: npc.fame - 30);
    } else {
      _addEvent(
        GameEventType.betrayalAttempt,
        'Tentativa de Assassinato Frustrada',
        '${npc.name} tentou matar ${target.name}, mas foi impedido!',
        involvedIds: [npc.id, target.id],
        isMajor: true,
      );
      return npc.copyWith(fame: npc.fame - 15, isSuspicious: true);
    }
  }

  // ─────────────────────────────────────────────
  // TREINO AUTÔNOMO
  // ─────────────────────────────────────────────

  double _trainingAptitude(Npc npc, BuildingType building) {
    double apt = 1.0;

    switch (building) {
      case BuildingType.barracks:
        if ([
          Profession.guard,
          Profession.explorer,
          Profession.trainer,
        ].contains(npc.profession)) {
          apt += 0.6;
        }
        if (npc.traits.contains(PersonalityTrait.brave)) apt += 0.2;
        if (npc.traits.contains(PersonalityTrait.aggressive)) apt += 0.15;
        if (npc.traits.contains(PersonalityTrait.coward)) apt -= 0.45;
        if (npc.traits.contains(PersonalityTrait.lazy)) apt -= 0.3;
        // Retorno diminuído: mais forte = menos ganho
        apt *= (1.0 - (npc.attributes.strength - 5) * 0.03).clamp(0.4, 1.6);

      case BuildingType.arena:
        if (npc.traits.contains(PersonalityTrait.brave)) apt += 0.4;
        if (npc.traits.contains(PersonalityTrait.aggressive)) apt += 0.3;
        if (npc.traits.contains(PersonalityTrait.coward)) apt -= 0.55;
        if (npc.traits.contains(PersonalityTrait.ambitious)) apt += 0.2;
        apt *= (1.0 - (npc.attributes.agility - 5) * 0.03).clamp(0.4, 1.6);

      case BuildingType.temple:
        if (npc.traits.contains(PersonalityTrait.calm)) apt += 0.3;
        if (npc.traits.contains(PersonalityTrait.optimist)) apt += 0.2;
        if (npc.traits.contains(PersonalityTrait.pessimist)) apt -= 0.2;
        if (npc.traits.contains(PersonalityTrait.aggressive)) apt -= 0.15;
        apt *= (1.0 - (npc.attributes.mentalStability - 50) * 0.01).clamp(
          0.5,
          1.5,
        );

      case BuildingType.library:
        if ([
          Profession.scribe,
          Profession.teacher,
          Profession.doctor,
        ].contains(npc.profession)) {
          apt += 0.55;
        }
        if (npc.traits.contains(PersonalityTrait.analytical)) apt += 0.35;
        if (npc.traits.contains(PersonalityTrait.creative)) apt += 0.2;
        if (npc.traits.contains(PersonalityTrait.lazy)) apt -= 0.35;
        apt *= (1.0 - (npc.attributes.intelligence - 5) * 0.03).clamp(0.4, 1.6);

      case BuildingType.trainingField:
      default:
        if (npc.traits.contains(PersonalityTrait.ambitious)) apt += 0.15;
        if (npc.traits.contains(PersonalityTrait.lazy)) apt -= 0.25;
    }

    // Fadiga penaliza aptitude
    apt -= (npc.fatigue / 100.0) * 0.3;

    return apt.clamp(0.1, 2.2);
  }

  Map<String, double> _dailyTrainingGains(
    Npc npc,
    BuildingType building,
    int buildingLevel,
  ) {
    final apt = _trainingAptitude(npc, building);
    final levelMult = 1.0 + (buildingLevel - 1) * 0.3;
    final base = 0.07 * apt * levelMult;

    switch (building) {
      case BuildingType.barracks:
        return {'strength': base, 'endurance': base * 0.6};
      case BuildingType.arena:
        return {'agility': base * 1.1, 'strength': base * 0.7};
      case BuildingType.temple:
        return {'mentalStability': base * 10, 'charisma': base * 0.5};
      case BuildingType.library:
        return {'intelligence': base * 1.2};
      case BuildingType.trainingField:
      default:
        return {
          'strength': base * 0.65,
          'endurance': base * 0.65,
          'agility': base * 0.55,
        };
    }
  }

  // Para mostrar ganho estimado ANTES de confirmar
  Map<String, Map<String, double>> previewTrainingGains(
    List<String> npcIds,
    BuildingType buildingType,
    int durationDays,
  ) {
    final building = citadel.getBuilding(buildingType);
    final level = building?.level ?? 1;
    final result = <String, Map<String, double>>{};

    for (final id in npcIds) {
      final npc = npcs.firstWhereOrNull((n) => n.id == id && n.alive);
      if (npc == null) continue;
      final dailyGains = _dailyTrainingGains(npc, buildingType, level);
      result[id] = dailyGains.map(
        (attr, gain) => MapEntry(attr, gain * durationDays),
      );
    }
    return result;
  }

  double previewNpcAptitude(String npcId, BuildingType building) {
    final npc = npcs.firstWhereOrNull((n) => n.id == npcId);
    if (npc == null) return 0;
    return _trainingAptitude(npc, building);
  }

  void _processAutonomousTraining() {
    if (state.currentDay % 5 != 0 || clearedFloors.isEmpty) return;

    final candidates = aliveNpcs
        .where(
          (n) =>
              [
                Profession.guard,
                Profession.explorer,
                Profession.scout,
                Profession.trainer,
              ].contains(n.profession) &&
              n.attributes.mentalStability >= 30,
        )
        .toList();

    for (final npc in candidates) {
      if (_rng.nextDouble() > 0.15) continue;
      final floor = clearedFloors[_rng.nextInt(clearedFloors.length)];
      _trainNpcOnFloor(npc, floor, fatigueGain: 6.0);
    }
  }

  void _trainNpcOnFloor(Npc npc, TowerFloor floor, {double fatigueGain = 0}) {
    npc.fatigue = (npc.fatigue + fatigueGain).clamp(0.0, 100.0);
    final gain = 0.05 + _rng.nextDouble() * 0.15;

    switch (floor.type) {
      case FloorType.combat:
        npc.attributes.strength += gain;
        npc.attributes.endurance += gain * 0.5;
        break;
      case FloorType.strategic:
        npc.attributes.intelligence += gain;
        break;
      case FloorType.survival:
        npc.attributes.endurance += gain;
        npc.attributes.agility += gain * 0.5;
        break;
      case FloorType.moral:
        npc.attributes.mentalStability += gain * 3;
        npc.attributes.charisma += gain * 0.5;
        break;
      default:
        npc.attributes.intelligence += gain * 0.5;
        npc.attributes.agility += gain * 0.5;
    }

    if (_rng.nextDouble() < 0.02) {
      npc.attributes.endurance -= 0.3;
      npc.traumas.add(
        'Acidente de treino no andar ${floor.number}, dia ${state.currentDay}',
      );
      _addEvent(
        GameEventType.training,
        'Acidente de Treino',
        '${npc.name} sofreu acidente treinando sozinho.',
        involvedIds: [npc.id],
      );
    }

    if (_rng.nextDouble() < 0.03) {
      floor.timesReexplored++;
      _addEvent(
        GameEventType.exploration,
        'Ameaca Reativada!',
        '${npc.name} encontrou novas criaturas no Andar ${floor.number} durante treino.',
        involvedIds: [npc.id],
      );
    }
  }

  // ─────────────────────────────────────────────
  // RE-EXPLORAÇÃO AUTOMÁTICA
  // ─────────────────────────────────────────────

  void _processFactionIncursions() {
    for (final relation in state.factionRelations.values) {
      if (!FactionProcessor.shouldIncurse(
        relation: relation,
        currentDay: state.currentDay,
        incursionCooldownDays: 14,
      )) {
        continue;
      }

      final severity = (-relation.standing / 100).clamp(0.0, 1.0);
      citadel.resources.food -= 10 * severity;
      citadel.resources.morale -= 5 * severity;
      citadel.resources.clampNegatives();

      relation.incursionsCaused++;

      _addEvent(
        GameEventType.crisis,
        'Incursão: ${relation.faction.label}',
        '${relation.faction.label} atacou os suprimentos da cidadela. '
            'Standing atual: ${relation.standing.toStringAsFixed(0)}. '
            'Incursões totais desta facção: ${relation.incursionsCaused}.',
        isMajor: severity > 0.7,
      );
      relation.lastInteractionDay = state.currentDay;
    }
  }

  String confirmRecruitSurvivor(String survivorId) {
    final idx = _pendingRecruits.indexWhere((r) => r.id == survivorId);
    if (idx == -1) return 'Survivor não encontrado.';
    if (!citadel.hasBuilding(BuildingType.wayfareresRefuge)) {
      return 'Requer Abrigo de Viajantes para recrutar survivors.';
    }

    final survivor = _pendingRecruits[idx];
    _pendingRecruits.removeAt(idx);

    // ✅ Identifica a facção de origem e aplica mudança de standing
    final originFloor = floors.firstWhereOrNull(
      (f) => f.inhabitants.any((i) => i.id == survivorId),
    );
    if (originFloor != null &&
        originFloor.controllingFaction != FloorFaction.none) {
      // Recrutar um membro da facção: pode ser positivo (mostra respeito)
      // ou negativo (roubou um deles). Aqui varia por facção:
      final standingDelta = switch (originFloor.controllingFaction) {
        FloorFaction.bloodMarket => 5.0, // mercado aprecia a transação
        FloorFaction.ironPact => -8.0, // pacto vê como deserção
        FloorFaction.towerServants => 3.0, // servos aprovam quem é salvo
        FloorFaction.silentOrder => 2.0, // ordem é indiferente
        FloorFaction.voidChildren => _rng.nextDouble() * 20 - 10, // caos
        _ => 0.0,
      };
      _applyFactionStandingChange(
        faction: originFloor.controllingFaction,
        delta: standingDelta,
        affectedFloor: originFloor,
      );
    }

    final npc = _survivorToNpc(survivor);
    npcs.add(npc);

    _addEvent(
      GameEventType.recruitment,
      'Survivor Recrutado',
      '${npc.name} se juntou à cidadela.',
      involvedIds: [npc.id],
    );
    return '${npc.name} se juntou à cidadela.';
  }

  void rejectRecruit(String survivorId) {
    final idx = _pendingRecruits.indexWhere((r) => r.id == survivorId);
    if (idx == -1) return;

    final survivor = _pendingRecruits[idx];
    // Remove dos pendentes mas NÃO marca isRecruited=true
    // → pode ser encontrado novamente
    _pendingRecruits.removeAt(idx);

    _addEvent(
      GameEventType.system,
      'Survivor Dispensado',
      '${survivor.name} foi dispensado. Pode ser encontrado novamente.',
    );
  }

  Npc _survivorToNpc(FloorInhabitant survivor) {
    final stats = survivor.survivorStats;
    final npc = Npc.generateRandom(state.generateNpcId(), 1, _rng);

    // Preserva identidade do survivor — nome e origem do andar
    npc.name = survivor.name;

    if (stats != null) {
      npc.attributes.strength = stats.combatPower.clamp(1, 20);
      npc.attributes.endurance = stats.endurance.clamp(1, 20);
      npc.attributes.intelligence = stats.intelligence.clamp(1, 20);
      npc.loyalty = stats.loyalty;

      if (stats.traits.contains('battle-hardened')) {
        if (!npc.traits.contains(PersonalityTrait.brave)) {
          npc.traits = List.of(npc.traits)..add(PersonalityTrait.brave);
        }
      }
      if (stats.traits.contains('traumatized')) {
        npc.attributes.mentalStability = (npc.attributes.mentalStability - 20)
            .clamp(0, 100)
            .toDouble();
        npc.traumas = List.of(npc.traumas)
          ..add('Sobreviveu sozinho na Torre por semanas');
      }
      if (stats.traits.contains('tower-knowledge')) {
        npc.attributes.intelligence = (npc.attributes.intelligence + 1.5).clamp(
          1,
          20,
        );
      }
    }

    npc.profession = Profession.explorer;
    npc.history.add(
      'Survivor recrutado no Abrigo de Viajantes (Dia ${state.currentDay})',
    );

    // Marca o habitante como recrutado no andar de origem —
    // ele se juntou à cidadela, não está mais lá.
    // Se for ignorado/descartado, pode ser encontrado novamente em re-explorações futuras.
    survivor.isRecruited = true;

    return npc;
  }

  FactionRelation _getOrCreateFactionRelation(FloorFaction faction) {
    return state.factionRelations.putIfAbsent(
      faction.key,
      () => FactionRelation(faction: faction),
    );
  }

  void _applyFactionStandingChange({
    required FloorFaction faction,
    required double delta,
    TowerFloor? affectedFloor,
  }) {
    if (faction == FloorFaction.none || delta == 0) return;

    final relation = _getOrCreateFactionRelation(faction);
    relation.standing = (relation.standing + delta).clamp(-100.0, 100.0);
    relation.totalInteractions++;
    relation.lastInteractionDay = state.currentDay;

    // Atualiza disposição dos habitantes no andar afetado
    if (affectedFloor != null && affectedFloor.inhabitants.isNotEmpty) {
      InhabitantProcessor.updateForFactionStanding(
        inhabitants: affectedFloor.inhabitants,
        factionStanding: relation.standing,
      );
    }

    // Para andares conquistados com a mesma facção: atualiza todos os habitantes
    for (final floor in clearedFloors) {
      if (floor.controllingFaction == faction && floor.inhabitants.isNotEmpty) {
        InhabitantProcessor.updateForFactionStanding(
          inhabitants: floor.inhabitants,
          factionStanding: relation.standing,
        );
      }
    }
  }

  FactionInteractionResult _processFactionOnAttempt(
    TowerFloor floor,
    List<String> partyIds,
  ) {
    final faction = floor.controllingFaction;
    if (faction == FloorFaction.none) {
      return const FactionInteractionResult(faction: FloorFaction.none);
    }
    final relation = _getOrCreateFactionRelation(faction);

    final party = _resolveParty(partyIds);
    if (party.isEmpty) return FactionInteractionResult(faction: faction);

    // ✅ Usa helper — sem repetição
    final stats = _calcPartyStats(party);
    final food = citadel.resources.food;

    final result = FactionProcessor.processFloorAttempt(
      faction: faction,
      relation: relation,
      partyPower: stats.power,
      partyIntelligence: stats.intel,
      partyResources: food,
      partyFame: stats.fame,
      partyLuck: stats.luck,
      currentDay: state.currentDay,
    );

    // Standing muda com a tentativa
    if (result.standingDelta != 0) {
      _applyFactionStandingChange(
        faction: faction,
        delta: result.standingDelta,
        affectedFloor: floor,
      );
    }

    // Narrativa da facção
    if (result.narrativeLines.isNotEmpty) {
      _addEvent(
        GameEventType.discovery,
        '${faction.label} — Andar ${floor.number}',
        result.narrativeLines.join('\n'),
        involvedIds: partyIds,
      );
    }

    return result;
  }

  // Filhos do Vazio devem ter eventos REALMENTE imprevisíveis

  void _voidChildrenChaosEvent(
    TowerFloor floor,
    List<Npc> party,
    FactionRelation relation,
  ) {
    final roll = _rng.nextInt(6);
    switch (roll) {
      case 0: // Presente bizarro
        final randomNpc = party[_rng.nextInt(party.length)];
        randomNpc.attributes.luck += 3;
        _addEvent(
          GameEventType.discovery,
          'Dom do Vazio',
          'Os Filhos do Vazio presentearam ${randomNpc.name} com algo impossível de descrever. '
              'Ela(e) parece mais sortudo(a). +3 sorte.',
        );
        break;
      case 1: // Banem aleatoriamente
        final victim = party[_rng.nextInt(party.length)];
        victim.attributes.mentalStability -= 15;
        _addEvent(
          GameEventType.mentalBreak,
          'Maldição do Vazio',
          '${victim.name} foi tocado(a) pelo caos. '
              '-15 estabilidade mental. Ninguém sabe por quê.',
        );
        break;
      case 2: // Recurso impossível
        citadel.resources.food += 30;
        _addEvent(
          GameEventType.resourceGain,
          'Generosidade Caótica',
          'Uma pilha de mantimentos apareceu do nada. '
              'Os Filhos do Vazio balançaram as cabeças aprovadoramente. +30 comida.',
        );
        break;
      case 3: // Trocam standing por algo
        relation.standing = _rng.nextDouble() * 40 - 20; // randomiza standing
        _addEvent(
          GameEventType.politicalEvent,
          'Reset Caótico',
          'Os Filhos do Vazio esqueceram toda a história com vocês. '
              'Ou fingiram. Standing resetado para ${relation.standing.toStringAsFixed(0)}.',
        );
        break;
      case 4: // NPC some temporariamente
        final npc = party[_rng.nextInt(party.length)];
        npc.fatigue = 100; // "desapareceu por um momento"
        npc.history.add('Desapareceu brevemente no Vazio');
        _addEvent(
          GameEventType.crisis,
          '${npc.name} desaparece',
          '${npc.name} sumiu por alguns segundos. Voltou. '
              'Não quer falar. Fadiga máxima.',
        );
        break;
      case 5: // Visão do topo
        for (final n in party) {
          n.fame += 10;
        }
        _addEvent(
          GameEventType.celebration,
          'Os Filhos aprovam',
          'Por razões incompreensíveis, os Filhos do Vazio erigiram '
              'estandartes com os rostos do grupo. '
              '+10 fama para todos. Perturbador.',
        );
        break;
    }
  }

  Map<String, double> _processFactionOnReexploration(
    TowerFloor floor,
    Map<String, double> resourcesGained,
    List<Npc> party,
  ) {
    final faction = floor.controllingFaction;
    if (faction == FloorFaction.none) return resourcesGained;

    final power =
        party.map((n) => n.attributes.combatPower).fold(0.0, (a, b) => a + b) /
        party.length;
    final intel =
        party.map((n) => n.attributes.intelligence).fold(0.0, (a, b) => a + b) /
        party.length;

    final relation = _getOrCreateFactionRelation(faction);
    final factionResult = FactionProcessor.processReexploration(
      faction: faction,
      relation: relation,
      partyPower: power,
      partyIntelligence: intel,
      currentDay: state.currentDay,
    );

    // Aplica multiplicador de recurso da facção
    if (factionResult.resourceMod != 1.0) {
      for (final key in resourcesGained.keys.toList()) {
        resourcesGained[key] =
            (resourcesGained[key] ?? 0) * factionResult.resourceMod;
      }
    }

    // Custom faction logic
    final standing = relation.standing;
    final narratives = <String>[];
    if (faction == FloorFaction.bloodMarket && standing >= 50) {
      if (citadel.resources.iron >= 5) {
        citadel.resources.iron -= 5;
        citadel.resources.food += 15 + (standing / 10);
        narratives.add(
          '💰 Mercado de Sangue trocou ferro por mantimentos. '
          '(-5 ferro, +${(15 + standing / 10).toStringAsFixed(0)} comida)',
        );
      }
    }
    if (faction == FloorFaction.towerServants && standing >= 80) {
      final drop = _equipmentService.rollDrop(
        floorNumber: floor.number,
        tier: max(floor.tier, 3),
        currentDay: state.currentDay,
      );
      if (drop != null) {
        _inventory.add(drop);
        narratives.add(
          '🏛 Servos da Torre presentearam seu grupo: ${drop.name}',
        );
      }
      _addEvent(
        GameEventType.discovery,
        'Segredo dos Servos',
        'Um Servo se ajoelhou e sussurrou: '
            '"A Torre não é uma prisão. É um filtro. '
            'Apenas os dignos chegam ao topo." '
            'Ninguém sabe o que isso significa.',
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
      _voidChildrenChaosEvent(floor, party, relation);
    }

    // Atualiza standing
    if (factionResult.standingDelta != 0) {
      _applyFactionStandingChange(
        faction: faction,
        delta: factionResult.standingDelta,
        affectedFloor: floor,
      );
    }

    // Narrativa da facção (adicionar ao evento de re-exploração)
    final allNarratives = [...factionResult.narrativeLines, ...narratives];
    if (allNarratives.isNotEmpty) {
      _addEvent(
        GameEventType.discovery,
        'Facção: ${faction.label} — Andar ${floor.number}',
        allNarratives.join('\n'),
        isMajor: true,
      );
    }

    return resourcesGained;
  }

  void _processAutoReexploration() {
    if (state.currentDay % 14 != 0 || clearedFloors.isEmpty) return;
    if (_rng.nextDouble() > 0.4) return;

    final explorers = aliveNpcs
        .where(
          (n) =>
              (n.profession == Profession.explorer ||
                  n.profession == Profession.scout) &&
              n.attributes.mentalStability > 35 &&
              n.fatigue < 50 &&
              !_isGroupBusyOnQuest(n.groupId),
        )
        .toList();

    if (explorers.isEmpty) return;

    final floor = clearedFloors[_rng.nextInt(clearedFloors.length)];
    final party = explorers
        .take(min(3, explorers.length))
        .map((n) => n.id)
        .toList();
    reexploreFloor(floor.number, party);
  }

  /// Retorna as ofertas diplomáticas disponíveis para uma facção
  List<DiplomacyOffer> getDiplomacyOffers(FloorFaction faction) {
    final relation = _getOrCreateFactionRelation(faction);
    if (relation.tier == FactionTier.ally) return []; // já aliado
    if (state.currentDay - relation.lastDiplomacyDay < 7) return []; // cooldown

    return FactionProcessor.buildDiplomacyOffers(
      faction: faction,
      relation: relation,
      currentResources: citadel.resources,
      partyPower: _averagePartyPower(),
    );
  }

  /// Executa uma oferta diplomática. Retorna narrativa do resultado.
  String executeDiplomacy(FloorFaction faction, DiplomacyOfferType offerType) {
    final relation = _getOrCreateFactionRelation(faction);
    if (state.currentDay - relation.lastDiplomacyDay < 7) {
      return 'Esta facção não aceita propostas tão seguidas.';
    }

    final offers = getDiplomacyOffers(faction);
    final offer = offers.firstWhereOrNull((o) => o.type == offerType);
    if (offer == null) return 'Oferta indisponível.';

    // Verifica recursos
    for (final entry in offer.resourceCost.entries) {
      switch (entry.key) {
        case 'food':
          if (citadel.resources.food < entry.value) {
            return 'Recursos insuficientes.';
          }
        case 'iron':
          if (citadel.resources.iron < entry.value) {
            return 'Recursos insuficientes.';
          }
        case 'wood':
          if (citadel.resources.wood < entry.value) {
            return 'Recursos insuficientes.';
          }
        case 'knowledge':
          if (citadel.resources.knowledge < entry.value) {
            return 'Recursos insuficientes.';
          }
      }
    }

    // Cobra recursos
    for (final entry in offer.resourceCost.entries) {
      switch (entry.key) {
        case 'food':
          citadel.resources.food -= entry.value;
        case 'iron':
          citadel.resources.iron -= entry.value;
        case 'wood':
          citadel.resources.wood -= entry.value;
        case 'knowledge':
          citadel.resources.knowledge -= entry.value;
      }
    }

    // Determina sucesso
    final success = _rng.nextDouble() < offer.successChance;
    final delta = success ? offer.standingGain : offer.standingGain * 0.2;

    _applyFactionStandingChange(faction: faction, delta: delta);
    relation.lastDiplomacyDay = state.currentDay;
    // Ativa tratado se proposta de não-agressão foi aceita
    if (offerType == DiplomacyOfferType.proposeNonAggression && success) {
      relation.hasTreaty = true;
      relation.treatyStartDay = state.currentDay;
    }

    final resultStr = success ? 'SUCESSO' : 'PARCIALMENTE ACEITO';
    _addEvent(
      GameEventType.politicalEvent,
      'Diplomacia: ${faction.label} [$resultStr]',
      '${offer.description}\nStanding: ${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}',
      isMajor: success && delta >= 15,
    );

    return success
        ? '${faction.label} aceitou a proposta. +${delta.toStringAsFixed(0)} standing.'
        : '${faction.label} foi reticente. +${delta.toStringAsFixed(0)} standing.';
  }
  // ─────────────────────────────────────────────
  // SISTEMA DE EXPEDIÇÃO HARDCORE
  // ─────────────────────────────────────────────

  double expeditionCostPerNpc(int floorNumber) {
    final tier = ((floorNumber - 1) ~/ 10) + 1;
    return 3.0 + tier * 1.0;
  }

  double reexploreCostPerNpc(int floorNumber) {
    final tier = ((floorNumber - 1) ~/ 10) + 1;
    return 2.0 + tier * 0.6;
  }

  // ── Preview de métricas para UI ────────────────

  // ── Preview de métricas para UI ────────────────

  /// Calcula a chance de sucesso usando a MESMA lógica do attemptFloor,
  /// sem efeitos colaterais (não altera estado, não mata NPCs, não gasta comida).
  /// Retorna um mapa com:
  ///   'chance'        → chance final (0.0–0.95)
  ///   'partyPower'    → poder efetivo calculado
  ///   'difficulty'    → dificuldade efetiva (com mirrorRule se aplicável)
  ///   'factionMod'    → modificador de facção na chance
  ///   'rulePenalty'   → se alguma regra penalizou o grupo (0 = não, 1 = sim)
  Map<String, double> previewSuccessChance(
    List<String> partyIds,
    TowerFloor floor,
  ) {
    final party = _resolveParty(partyIds);
    if (party.isEmpty) {
      return {
        'chance': 0.0,
        'partyPower': 0.0,
        'difficulty': floor.scaledDifficulty,
        'factionMod': 0.0,
        'rulePenalty': 0.0,
      };
    }

    final rule = floor.rule;

    // soloEntry: apenas o NPC mais forte entra
    List<Npc> effectiveParty = List.from(party);
    if (rule.type == FloorRuleType.soloEntry && party.isNotEmpty) {
      effectiveParty = [
        party.reduce(
          (a, b) =>
              a.effectiveCombatPowerWithGear(_inventory) >=
                  b.effectiveCombatPowerWithGear(_inventory)
              ? a
              : b,
        ),
      ];
    }

    double partyPower = 0;
    bool hadRulePenalty = false;

    for (final npc in effectiveParty) {
      double power;

      if (rule.type == FloorRuleType.intelligenceOnly) {
        power = npc.attributes.intelligence * 1.5;
        if (npc.talentDiscovered &&
            npc.hiddenTalent == HiddenTalent.runeReader) {
          power *= 1.4;
        }
      } else {
        power = npc.effectiveCombatPowerWithGear(_inventory);
        if (npc.talentDiscovered &&
            npc.hiddenTalent == HiddenTalent.combatGenius) {
          power *= 1.5;
        }
      }

      if (npc.traits.contains(PersonalityTrait.brave)) power *= 1.1;
      if (npc.traits.contains(PersonalityTrait.coward)) power *= 0.85;

      switch (rule.type) {
        case FloorRuleType.loyaltyTest:
          if (npc.loyalty < 40 ||
              npc.traits.contains(PersonalityTrait.treacherous) ||
              npc.origin.isDarkOrigin) {
            power *= 0.6;
            hadRulePenalty = true;
          } else if (npc.loyalty > 70 &&
              npc.traits.contains(PersonalityTrait.loyal)) {
            power *= 1.3;
          } else if (npc.loyalty > 60) {
            power *= 1.15;
          }
          break;
        case FloorRuleType.silenceRequired:
          if (npc.traits.contains(PersonalityTrait.aggressive)) {
            power *= 0.45;
            hadRulePenalty = true;
          }
          break;
        default:
          break;
      }

      partyPower += power;
    }

    // weakLeads
    if (rule.type == FloorRuleType.weakLeads && effectiveParty.isNotEmpty) {
      final weakestPower = effectiveParty
          .map((n) => n.effectiveCombatPowerWithGear(_inventory))
          .reduce(min);
      partyPower = weakestPower * effectiveParty.length * 0.75;
      hadRulePenalty = true;
    }

    // mirrorRule
    final effectiveDifficulty = rule.type == FloorRuleType.mirrorRule
        ? floor.scaledDifficulty + partyPower * 0.25
        : floor.scaledDifficulty;

    final tributeBonus = rule.type == FloorRuleType.tributeRequired ? 0.1 : 0.0;

    double successChance =
        ((partyPower / (effectiveDifficulty * effectiveParty.length) * 0.7) +
                0.1 +
                tributeBonus)
            .clamp(0.05, 0.95);

    // Modificador de facção (read-only: apenas lê o standing atual)
    double factionMod = 0.0;
    final faction = floor.controllingFaction;
    if (faction != FloorFaction.none) {
      final relation = _getOrCreateFactionRelation(faction);
      final relationCopy = FactionRelation.copyOf(relation);
      final factionResult = FactionProcessor.processFloorAttempt(
        faction: faction,
        relation: relationCopy,
        partyPower: partyPower,
        partyIntelligence:
            party.fold(0.0, (s, n) => s + n.attributes.intelligence) /
            party.length,
        partyResources: citadel.resources.food,
        partyFame: party.fold(0.0, (s, n) => s + n.fame) / party.length,
        partyLuck:
            party.fold(0.0, (s, n) => s + n.attributes.luck) / party.length,
        currentDay: state.currentDay,
      );
      factionMod = factionResult.successChanceMod;
    }

    successChance = (successChance + factionMod).clamp(0.1, 0.95);

    return {
      'chance': successChance,
      'partyPower': partyPower,
      'difficulty': effectiveDifficulty,
      'factionMod': factionMod,
      'rulePenalty': hadRulePenalty ? 1.0 : 0.0,
    };
  }

  /// Calcula a produção diária real de todos os edifícios sem alterar estado.
  /// Usa a mesma lógica de _applyBuildingProduction — garante que UI e engine
  /// mostrem sempre o mesmo valor.
  Resources previewDailyProduction() {
    final res = Resources();
    for (final building in citadel.buildings) {
      _applyBuildingProduction(building, res);
    }
    return res;
  }

  double previewGroupSynergy(List<String> partyIds) {
    final party = _resolveParty(partyIds);
    return party.isEmpty ? 0.0 : _calculateGroupSynergy(party);
  }

  double previewPartyPersonalityMod(List<String> partyIds) {
    final party = _resolveParty(partyIds);
    return party.isEmpty
        ? 0.0
        : party.fold<double>(0, (s, n) => s + _personalityRewardMod(n)) /
              party.length;
  }

  double previewPartyAttributeYield(
    List<String> partyIds,
    FloorType floorType,
  ) {
    final party = _resolveParty(partyIds);
    return party.isEmpty
        ? 0.0
        : party.fold<double>(0, (s, n) => s + _attributeYield(n, floorType)) /
              party.length;
  }

  Map<String, double> previewEventChances(
    List<String> partyIds,
    TowerFloor floor,
  ) {
    final party = _resolveParty(partyIds);
    if (party.isEmpty) return {};

    final tier = floor.tier;
    final avgEndurance = _avg(party, (n) => n.attributes.endurance);
    final avgLuck = _avg(party, (n) => n.attributes.luck);
    final cautiousCount = party
        .where((n) => n.traits.contains(PersonalityTrait.cautious))
        .length;
    final ambitiousCount = party
        .where((n) => n.traits.contains(PersonalityTrait.ambitious))
        .length;
    final aggressiveCount = party
        .where((n) => n.traits.contains(PersonalityTrait.aggressive))
        .length;

    return {
      'acidente':
          (0.12 +
                  tier * 0.01 -
                  avgEndurance * 0.005 -
                  cautiousCount * 0.02 +
                  ambitiousCount * 0.02)
              .clamp(0.02, 0.30),
      'doenca': (0.06 + tier * 0.005).clamp(0.01, 0.20),
      'conflito': party.length >= 2
          ? (0.08 + aggressiveCount * 0.05).clamp(0.02, 0.35)
          : 0.0,
      'traicao':
          party.any(
            (n) =>
                (n.traits.contains(PersonalityTrait.treacherous) ||
                    n.origin.isDarkOrigin) &&
                n.loyalty < 40,
          )
          ? 0.08
          : 0.0,
      'evento_raro': (0.05 + avgLuck * 0.005).clamp(0.03, 0.15),
    };
  }

  // ── Cálculo de Sinergia ────────────────────────

  double _calculateGroupSynergy(List<Npc> party) {
    if (party.length <= 1) return 0.0;
    double synergy = 0.0;

    final groupIds = party
        .where((n) => n.groupId != null)
        .map((n) => n.groupId!)
        .toSet();
    if (groupIds.length == 1 &&
        party.every((n) => n.groupId == groupIds.first)) {
      final group = groups.firstWhereOrNull((g) => g.id == groupIds.first);
      if (group != null) synergy += (group.cohesion / 100.0) * 0.3;
      synergy += 0.1;
    }

    int positiveRels = 0, negativeRels = 0;
    for (final a in party) {
      for (final b in party) {
        if (a.id == b.id) continue;
        final rel = a.relationships.firstWhereOrNull((r) => r.targetId == b.id);
        if (rel != null) {
          if (rel.affinity > 0.3) positiveRels++;
          if (rel.affinity < -0.2) negativeRels++;
        }
      }
    }
    synergy += (positiveRels * 0.03).clamp(0.0, 0.2);
    synergy -= (negativeRels * 0.05).clamp(0.0, 0.3);

    final loyal = party
        .where((n) => n.traits.contains(PersonalityTrait.loyal))
        .length;
    final loner = party
        .where((n) => n.traits.contains(PersonalityTrait.loner))
        .length;
    final leader = party
        .where((n) => n.traits.contains(PersonalityTrait.leader))
        .length;
    final individualist = party
        .where((n) => n.traits.contains(PersonalityTrait.individualist))
        .length;
    synergy += loyal * 0.05;
    synergy -= loner * 0.08;
    synergy -= individualist * 0.10;
    if (leader == 1) synergy += 0.1;
    if (leader > 1) synergy -= 0.05;

    if (party.any(
      (n) => n.talentDiscovered && n.hiddenTalent == HiddenTalent.naturalLeader,
    )) {
      synergy += 0.15;
    }

    return synergy.clamp(-0.3, 0.6);
  }

  double _personalityRewardMod(Npc npc) {
    double mod = 0.0;
    if (npc.traits.contains(PersonalityTrait.cautious)) mod -= 0.12;
    if (npc.traits.contains(PersonalityTrait.calm)) mod -= 0.05;
    if (npc.traits.contains(PersonalityTrait.ambitious)) mod += 0.15;
    if (npc.traits.contains(PersonalityTrait.impulsive)) mod += 0.08;
    if (npc.traits.contains(PersonalityTrait.brave)) mod += 0.05;
    if (npc.traits.contains(PersonalityTrait.lazy)) mod -= 0.15;
    if (npc.traits.contains(PersonalityTrait.coward)) mod -= 0.10;
    if (npc.traits.contains(PersonalityTrait.pessimist)) mod -= 0.05;
    if (npc.traits.contains(PersonalityTrait.individualist)) mod -= 0.05;
    if (npc.traits.contains(PersonalityTrait.analytical)) mod += 0.06;
    if (npc.traits.contains(PersonalityTrait.pragmatic)) mod += 0.04;
    if (npc.traits.contains(PersonalityTrait.creative)) mod += 0.03;
    return mod;
  }

  double _attributeYield(Npc npc, FloorType floorType) {
    double yield =
        1.0 +
        (npc.attributes.strength - 5) * 0.05 +
        (npc.attributes.intelligence - 5) * 0.04 +
        (npc.attributes.endurance - 5) * 0.025 +
        (npc.attributes.agility - 5) * 0.025 +
        (npc.attributes.luck - 5) * 0.025 -
        npc.fatigue * 0.004;

    if (npc.traits.contains(PersonalityTrait.lazy)) yield *= 0.80;

    switch (floorType) {
      case FloorType.combat:
      case FloorType.gauntlet:
        yield += npc.attributes.strength * 0.025;
        break;
      case FloorType.survival:
      case FloorType.hunt:
        yield +=
            npc.attributes.endurance * 0.025 + npc.attributes.agility * 0.01;
        break;
      case FloorType.strategic:
      case FloorType.puzzle:
        yield += npc.attributes.intelligence * 0.035;
        break;
      case FloorType.mystery:
        yield +=
            npc.attributes.intelligence * 0.02 + npc.attributes.luck * 0.025;
        break;
      default:
        yield += (npc.attributes.strength + npc.attributes.intelligence) * 0.01;
    }

    return yield.clamp(0.2, 2.0);
  }

  // ─────────────────────────────────────────────
  // RE-EXPLORAÇÃO
  // ─────────────────────────────────────────────

  FloorExplorationResult reexploreFloor(
    int floorNumber,
    List<String> partyIds,
  ) {
    final floor = floors.firstWhere((f) => f.number == floorNumber);
    final party = _resolveParty(partyIds);

    if (party.any((n) => _isGroupBusyOnQuest(n.groupId))) {
      return FloorExplorationResult(
        floorNumber: floorNumber,
        day: state.currentDay,
        partyIds: partyIds,
      );
    }
    if (!floor.canReexploreOnDay(state.currentDay)) {
      return FloorExplorationResult(
        floorNumber: floorNumber,
        day: state.currentDay,
        partyIds: partyIds,
      );
    }
    final result = FloorExplorationResult(
      floorNumber: floorNumber,
      day: state.currentDay,
      partyIds: partyIds,
    );

    // Custo de comida
    final costPerNpc = reexploreCostPerNpc(floorNumber);
    final totalCost = party.length * costPerNpc;
    result.foodCost = totalCost;
    citadel.resources.food -= totalCost;

    // Incrementa contador ANTES de calcular recursos (para aplicar diminishing)
    floor.timesReexplored++;
    floor.lastReexploredDay = state.currentDay;
    _applyExpeditionFatigue(party, floor.tier, baseFatigue: 15.0);

    final synergy = _calculateGroupSynergy(party);

    // ── RECURSOS COM DIMINISHING RETURNS (centralizado no TowerFloor) ──
    for (final entry in floor.farmableResources.entries) {
      double totalYield = 0.0;
      final baseYield = entry.value; // ← já vem com diminishing do getter!

      for (final npc in party) {
        totalYield +=
            baseYield *
            _attributeYield(npc, floor.type) *
            (1.0 + _personalityRewardMod(npc));
      }

      // Bônus de grupo + variação aleatória (mantém o "feeling" bom)
      totalYield *= (1.0 + synergy) * (0.85 + _rng.nextDouble() * 0.30);

      // Proteção para solo (não fica no prejuízo)
      if (party.length == 1) {
        totalYield = totalYield.clamp(costPerNpc * 0.5, double.infinity);
      }

      result.resourcesGained[entry.key] = totalYield.roundToDouble();
    }

    // Processamentos adicionais (mantidos)
    _processFactionOnReexploration(floor, result.resourcesGained, party);
    _processInhabitantsOnReexplore(floor, partyIds, result.resourcesGained);
    _processNpcInhabitantInteraction(floor, party);

    // Fama (removido duplicata)
    for (final npc in party.where((n) => n.alive)) {
      npc.fame += 1;
    }

    final expeditionLogs = _processExpeditionEvents(party, floor, result);
    if (expeditionLogs.isNotEmpty) {
      _addEvent(
        GameEventType.floorReexplore,
        'Reexploração — Andar ${floor.number}',
        expeditionLogs.join('\n'),
        involvedIds: partyIds,
      );
    }

    // Adiciona os recursos SEM cap imediato.
    // O jogador pode exceder o armazém durante o dia (coletou mais do que cabe).
    // Ao virar o dia, _processDay chama clampToCapacity e o excedente
    // é perdido com evento de "recursos estragados".
    for (final entry in result.resourcesGained.entries) {
      final res = Resources();
      switch (entry.key) {
        case 'food':
          res.food = entry.value;
          break;
        case 'wood':
          res.wood = entry.value;
          break;
        case 'stone':
          res.stone = entry.value;
          break;
        case 'iron':
          res.iron = entry.value;
          break;
        case 'knowledge':
          res.knowledge = entry.value;
          break;
      }
      citadel.resources.add(res);
    }

    return result;
  }

  void _processInhabitantsOnReexplore(
    TowerFloor floor,
    List<String> partyIds,
    Map<String, double> resourcesGained,
  ) {
    if (floor.inhabitants.isEmpty) return;

    final hasRefuge = citadel.hasBuilding(BuildingType.wayfareresRefuge);
    final encounterResult = InhabitantProcessor.process(
      inhabitants: floor.inhabitants,
      hasWayfareresRefuge: hasRefuge,
      currentDay: state.currentDay,
    );

    // Aplica multiplicador de recursos
    if (encounterResult.resourceMultiplier != 1.0) {
      for (final key in resourcesGained.keys.toList()) {
        resourcesGained[key] =
            (resourcesGained[key] ?? 0) * encounterResult.resourceMultiplier;
      }
    }

    // Aplica tags temporárias de anomalias
    for (final inhabitant in floor.inhabitants) {
      if (inhabitant.isActive &&
          inhabitant.category == InhabitantCategory.anomaly &&
          inhabitant.effect.floorModTag != null) {
        floor.addTemporaryTag(inhabitant.effect.floorModTag!);
      }
    }

    // Registra survivors recrutáveis com chance probabilística —
    // não aparecem em toda re-exploração, apenas ocasionalmente.
    // Se já está pendente (jogador ainda não decidiu), não duplica.
    for (final survivor in encounterResult.recruitableSurvivors) {
      if (_pendingRecruits.any((r) => r.id == survivor.id)) continue;

      // Chance base: 35% por re-exploração, sobe para 55% com Abrigo de Viajantes
      final encounterChance = citadel.hasBuilding(BuildingType.wayfareresRefuge)
          ? 0.55
          : 0.35;

      if (_rng.nextDouble() < encounterChance) {
        _pendingRecruits.add(survivor);
        _addEvent(
          GameEventType.recruitment,
          'Sobrevivente Encontrado',
          '${survivor.name} foi avistado no Andar ${floor.number}. '
              'Está disposto a se juntar à cidadela.',
        );
      }
    }

    // Lore fragments como evento separado
    if (encounterResult.loreFragments.isNotEmpty) {
      _addEvent(
        GameEventType.discovery,
        'Fragmento de Lore — Andar ${floor.number}',
        encounterResult.loreFragments.join('\n'),
        involvedIds: partyIds,
        isMajor: true,
      );
    }
  }

  // ─────────────────── Interação NPCS habitantes ──────────────────────────
  void _processNpcInhabitantInteraction(TowerFloor floor, List<Npc> party) {
    for (final inhabitant in floor.inhabitants.where((i) => i.isActive)) {
      // Só processa se houver NPC compatível com o habitante
      final compatibleNpc = _findCompatibleNpc(party, inhabitant);
      if (compatibleNpc == null) continue;
      if (_rng.nextDouble() > 0.40) continue; // 40% de chance por visita

      _applyInhabitantInteraction(compatibleNpc, inhabitant, floor);
    }
  }

  Npc? _findCompatibleNpc(List<Npc> party, FloorInhabitant inhabitant) {
    // Comerciante → NPC com charisma alta ou profissão merchant
    if (inhabitant.id.contains('trader') || inhabitant.id.contains('smith')) {
      return party.firstWhereOrNull(
        (n) => n.attributes.charisma > 7 || n.profession == Profession.merchant,
      );
    }
    // Eremita / Anomalia → NPC com intelligence alta ou scribe
    if (inhabitant.id.contains('hermit') ||
        inhabitant.category == InhabitantCategory.anomaly) {
      return party.firstWhereOrNull(
        (n) =>
            n.attributes.intelligence > 7 || n.profession == Profession.scribe,
      );
    }
    // Survivor → qualquer um (afinidade mais alta escolhida)
    if (inhabitant.category == InhabitantCategory.survivor) {
      return party.reduce(
        (a, b) => a.attributes.charisma > b.attributes.charisma ? a : b,
      );
    }
    return party.isNotEmpty ? party[_rng.nextInt(party.length)] : null;
  }

  void _applyInhabitantInteraction(
    Npc npc,
    FloorInhabitant inhabitant,
    TowerFloor floor,
  ) {
    switch (inhabitant.category) {
      case InhabitantCategory.resident:
        _residentInteraction(npc, inhabitant, floor);
        break;
      case InhabitantCategory.survivor:
        _survivorInteraction(npc, inhabitant);
        break;
      case InhabitantCategory.anomaly:
        _anomalyInteraction(npc, inhabitant, floor);
        break;
    }
  }

  void _residentInteraction(
    Npc npc,
    FloorInhabitant inhabitant,
    TowerFloor floor,
  ) {
    // Comerciante troca informação ou itens
    if (inhabitant.id.contains('trader')) {
      final gain = _rng.nextDouble() < 0.5;
      if (gain) {
        citadel.resources.knowledge += 2 + npc.attributes.charisma * 0.3;
        npc.fame += 2;
        npc.history.add(
          'Trocou informações com ${inhabitant.name} no Andar ${floor.number}',
        );
        _addEvent(
          GameEventType.discovery,
          '${npc.name} negocia com ${inhabitant.name}',
          '"${inhabitant.effect.loreText}" — '
              'O comerciante compartilhou rotas seguras. +conhecimento',
          involvedIds: [npc.id],
        );
      }
    }

    // Ferreiro Mudo melhora equipamento passivamente
    if (inhabitant.id.contains('smith') && npc.equippedWeaponId != null) {
      npc.attributes.strength = (npc.attributes.strength + 0.2).clamp(1, 20);
      npc.history.add(
        'Ferreiro Mudo aprimorou seu arsenal no Andar ${floor.number}',
      );
      _addEvent(
        GameEventType.training,
        '${npc.name} aprende com o Ferreiro',
        'O ferreiro não falou. Apenas mostrou como segurar a arma. '
            '${npc.name} entendeu. +0.2 força',
        involvedIds: [npc.id],
      );
    }

    // Eremita afeta mental stability
    if (inhabitant.id.contains('hermit')) {
      npc.attributes.mentalStability = (npc.attributes.mentalStability + 5)
          .clamp(0, 100);
      npc.history.add('Conversou com o Eremita da Torre — algo se assentou');
      _addEvent(
        GameEventType.discovery,
        '${npc.name} e o Eremita',
        '"${inhabitant.effect.loreText}" — '
            '${npc.name} saiu do andar mais calmo que entrou. +5 estabilidade mental.',
        involvedIds: [npc.id],
      );
    }
  }

  void _survivorInteraction(Npc npc, FloorInhabitant survivor) {
    // NPC compartilha comida / constrói relacionamento
    if (citadel.resources.food > 20) {
      citadel.resources.food -= 3;
      survivor.disposition = InhabitantDisposition.friendly;
      npc.history.add('Compartilhou comida com ${survivor.name}');

      // Adiciona à fila de recrutamento se ainda não estiver pendente
      if (!_pendingRecruits.any((r) => r.id == survivor.id)) {
        _pendingRecruits.add(survivor);
      }

      _addEvent(
        GameEventType.recruitment,
        '${npc.name} trouxe ${survivor.name}',
        '${npc.name} deixou parte do rancho. '
            '${survivor.name} olhou com algo parecido com esperança '
            'e concordou em seguir o grupo de volta.',
        involvedIds: [npc.id],
      );
    }
  }

  void _anomalyInteraction(Npc npc, FloorInhabitant anomaly, TowerFloor floor) {
    // NPCs com alta inteligência ou luck têm respostas diferentes
    final isScholar = npc.attributes.intelligence > 8;
    final isLucky = npc.attributes.luck > 8;

    if (isScholar) {
      npc.attributes.intelligence = (npc.attributes.intelligence + 0.3).clamp(
        1,
        20,
      );
      citadel.resources.knowledge += 3;
      npc.history.add('Estudou ${anomaly.name} no Andar ${floor.number}');
      _addEvent(
        GameEventType.discovery,
        '${npc.name} documenta a anomalia',
        '"${anomaly.effect.loreText}" — '
            '${npc.name} preencheu três páginas de anotações. +0.3 inteligência, +3 conhecimento.',
        involvedIds: [npc.id],
      );
    } else if (isLucky) {
      // Lucky NPCs têm visões
      npc.fame += 5;
      npc.history.add('Teve uma visão com ${anomaly.name}');
      _addEvent(
        GameEventType.discovery,
        '${npc.name} — Visão da Anomalia',
        '"${anomaly.effect.loreText}" — '
            '${npc.name} ficou parado por minutos. Depois disse: "Eu vi o topo." +5 fama.',
        involvedIds: [npc.id],
      );
    } else {
      // NPC comum: abalo mental leve mas ganho de lore
      npc.attributes.mentalStability = (npc.attributes.mentalStability - 5)
          .clamp(0, 100);
      npc.traumas.add('Encontrou ${anomaly.name} no Andar ${floor.number}');
      _addEvent(
        GameEventType.discovery,
        '${npc.name} se perturba',
        '"${anomaly.effect.loreText}" — '
            '${npc.name} não quer falar sobre o que viu. −5 estabilidade mental.',
        involvedIds: [npc.id],
      );
    }
  }

  // ── Eventos aleatórios de expedição ────────────

  List<String> _processExpeditionEvents(
    List<Npc> party,
    TowerFloor floor,
    FloorExplorationResult result,
  ) {
    final logs = <String>[];
    final tier = floor.tier;

    final avgEndurance = _avg(party, (n) => n.attributes.endurance);
    final cautiousCount = party
        .where((n) => n.traits.contains(PersonalityTrait.cautious))
        .length;
    final ambitiousCount = party
        .where((n) => n.traits.contains(PersonalityTrait.ambitious))
        .length;
    final accidentChance =
        (0.12 +
                tier * 0.01 -
                avgEndurance * 0.005 -
                cautiousCount * 0.02 +
                ambitiousCount * 0.02)
            .clamp(0.02, 0.30);

    if (_rng.nextDouble() < accidentChance) {
      final victim = party[_rng.nextInt(party.length)];
      final severity = (1.0 - victim.attributes.endurance * 0.06).clamp(
        0.3,
        1.0,
      );
      final foodLost = (3 + tier * 1.5) * severity;
      citadel.resources.food -= foodLost;
      victim.attributes.endurance -= 0.3 * severity;
      victim.fatigue += 8 * severity;
      logs.add(
        '[ACIDENTE] ${victim.name} sofreu acidente! -${foodLost.toStringAsFixed(0)} comida.',
      );
      result.expeditionEvents.add('Acidente: ${victim.name}');
    }

    if (_rng.nextDouble() < (0.06 + tier * 0.005)) {
      final alive = party.where((n) => n.alive).toList();
      if (alive.isNotEmpty) {
        final sick = alive[_rng.nextInt(alive.length)];
        sick.attributes.endurance -= 1.0;
        sick.attributes.strength -= 0.5;
        sick.attributes.mentalStability -= 5;
        sick.fatigue += 20;
        sick.traumas.add(
          'Doenca no Andar ${floor.number}, dia ${state.currentDay}',
        );
        logs.add('[DOENCA] ${sick.name} contraiu doenca!');
        result.expeditionEvents.add('Doenca: ${sick.name}');
      }
    }

    if (party.length >= 2) {
      final aggressives = party
          .where((n) => n.traits.contains(PersonalityTrait.aggressive))
          .length;
      final loners = party
          .where((n) => n.traits.contains(PersonalityTrait.loner))
          .length;
      final conflictChance = (0.08 + aggressives * 0.05 + loners * 0.03);
      if (_rng.nextDouble() < conflictChance) {
        final penalty = 0.2 + _rng.nextDouble() * 0.2;
        for (final key in result.resourcesGained.keys.toList()) {
          result.resourcesGained[key] =
              (result.resourcesGained[key] ?? 0) * (1 - penalty);
        }
        citadel.resources.morale -= 2;
        logs.add(
          '[CONFLITO] Briga interna reduziu eficiencia em ${(penalty * 100).toStringAsFixed(0)}%!',
        );
        result.expeditionEvents.add('Conflito interno');
      }
    }

    final traitors = party
        .where(
          (n) =>
              n.alive &&
              (n.traits.contains(PersonalityTrait.treacherous) ||
                  n.origin.isDarkOrigin) &&
              n.loyalty < 40,
        )
        .toList();
    for (final traitor in traitors) {
      if (_rng.nextDouble() >= 0.04 + traitor.betrayalRisk * 0.001) continue;
      final stolenPct = 0.15 + _rng.nextDouble() * 0.25;
      for (final key in result.resourcesGained.keys.toList()) {
        final stolen = (result.resourcesGained[key] ?? 0) * stolenPct;
        result.resourcesGained[key] =
            (result.resourcesGained[key] ?? 0) - stolen;
      }
      final traitorIndex = npcs.indexWhere((n) => n.id == traitor.id);
      if (traitorIndex != -1) {
        npcs[traitorIndex] = npcs[traitorIndex].copyWith(
          fame: npcs[traitorIndex].fame - 8,
          loyalty: npcs[traitorIndex].loyalty - 5,
          isSuspicious: true,
        );
      }
      citadel.resources.morale -= 4;
      logs.add(
        '[TRAICAO] ${traitor.name} roubou ${(stolenPct * 100).toStringAsFixed(0)}% dos recursos!',
      );
      result.expeditionEvents.add('Traicao: ${traitor.name}');
      break;
    }

    if (result.expeditionEvents.none((e) => e.startsWith('Traicao'))) {
      final avgLuck = _avg(
        party.where((n) => n.alive).toList(),
        (n) => n.attributes.luck,
      );
      final rareChance = (0.05 + avgLuck * 0.005).clamp(0.03, 0.15);
      if (_rng.nextDouble() < rareChance) {
        for (final key in result.resourcesGained.keys.toList()) {
          result.resourcesGained[key] =
              (result.resourcesGained[key] ?? 0) * 1.5;
        }
        citadel.resources.morale += 3;
        logs.add('[RARO] Descoberta excepcional! Recompensa DOBRADA!');
        result.expeditionEvents.add('Evento raro');

        final candidates = party
            .where(
              (n) =>
                  n.alive &&
                  !n.talentDiscovered &&
                  n.hiddenTalent != HiddenTalent.none,
            )
            .toList();
        if (candidates.isNotEmpty && _rng.nextDouble() < 0.3) {
          final lucky = candidates[_rng.nextInt(candidates.length)];
          lucky.talentDiscovered = true;
          logs.add(
            '[TALENTO] ${lucky.name} revelou ${lucky.hiddenTalent.label}!',
          );
        }
      }
    }

    return logs;
  }

  // ─────────────────────────────────────────────
  // SUGESTÃO DE TREINO
  // ─────────────────────────────────────────────

  TrainingSuggestion suggestTraining(
    String targetId,
    String targetType,
    int floorNumber,
  ) {
    final suggestion = TrainingSuggestion(
      id: _nextSuggestionId(),
      day: state.currentDay,
      targetType: targetType,
      targetId: targetId,
      floorNumber: floorNumber,
    );

    if (targetType == 'npc') {
      _processNpcTrainingSuggestion(suggestion);
    } else {
      _processGroupTrainingSuggestion(suggestion);
    }

    trainingSuggestions.add(suggestion);
    return suggestion;
  }

  void _processNpcTrainingSuggestion(TrainingSuggestion s) {
    final npc = npcs.firstWhere((n) => n.id == s.targetId);
    npc.trainingSuggestionsReceived++;

    if (npc.isIncapacitated) {
      s.response = TrainingResponse.refused;
      s.responseDetail =
          '${npc.name} esta incapacitado(a). Nao consegue nem se levantar.';
      _addEvent(
        GameEventType.trainingSuggestion,
        'Impossivel Treinar',
        s.responseDetail,
        involvedIds: [npc.id],
      );
      return;
    }

    final acceptance = npc.trainingAcceptanceChance(
      hasTrainingField: hasTrainingField && s.floorNumber == -1,
    );
    final roll = _rng.nextDouble();

    if (roll < acceptance) {
      s.response = TrainingResponse.accepted;
      s.responseDetail = '${npc.name} aceitou treinar.';
      npc.trainingSuggestionsAccepted++;
      npc.loyalty += 2;
      if (s.floorNumber == -1 && hasTrainingField) {
        _trainInTrainingField([npc]);
      } else if (s.floorNumber > 0) {
        trainOnFloor(s.floorNumber, [npc.id]);
      }
    } else if (roll < acceptance + 0.15) {
      s.response = TrainingResponse.negotiated;
      s.responseDetail =
          '${npc.name} negociou: "Aceito, mas quero descanso depois."';
      npc.loyalty += 1;
    } else if (roll < acceptance + 0.25) {
      s.response = TrainingResponse.ignored;
      s.responseDetail = '${npc.name} ignorou a sugestao.';
    } else {
      s.response = TrainingResponse.refused;
      s.responseDetail = '${npc.name} recusou: "${_refusalReason(npc)}"';
      npc.loyalty -= 1;
    }

    _addEvent(
      GameEventType.trainingSuggestion,
      'Sugestao ${s.response.label}',
      s.responseDetail,
      involvedIds: [npc.id],
    );

    if (npc.trainingSuggestionsReceived > 5 &&
        npc.trainingSuggestionsAccepted <
            npc.trainingSuggestionsReceived * 0.3) {
      npc.loyalty -= 3;
      _addEvent(
        GameEventType.politicalEvent,
        'Resistencia ao Favoritismo',
        '${npc.name} esta irritado com as constantes sugestoes.',
        involvedIds: [npc.id],
      );
    }
  }

  String _refusalReason(Npc npc) {
    if (npc.isExhausted) return 'Mal consigo ficar de pe. Me deixe descansar.';
    if (npc.fatigue >= 50) return 'Estou cansado demais.';
    if (npc.traits.contains(PersonalityTrait.coward)) {
      return 'E perigoso demais.';
    }
    if (npc.attributes.mentalStability < 40) {
      return 'Nao estou em condicoes de treinar.';
    }
    if (npc.traits.contains(PersonalityTrait.loner)) {
      return 'Prefiro treinar sozinho.';
    }
    return 'Nao me parece necessario agora.';
  }

  void _processGroupTrainingSuggestion(TrainingSuggestion s) {
    final group = groups.firstWhereOrNull((g) => g.id == s.targetId);
    if (group == null) return;

    final members = group.memberIds
        .map((id) => npcs.firstWhereOrNull((n) => n.id == id && n.alive))
        .whereType<Npc>()
        .toList();
    if (members.isEmpty) return;

    int accepted = 0, refused = 0;
    final acceptedIds = <String>[];

    for (final npc in members) {
      npc.trainingSuggestionsReceived++;
      if (npc.isIncapacitated) {
        refused++;
        continue;
      }
      if (_rng.nextDouble() <
          npc.trainingAcceptanceChance(
            hasTrainingField: hasTrainingField && s.floorNumber == -1,
          )) {
        accepted++;
        npc.trainingSuggestionsAccepted++;
        acceptedIds.add(npc.id);
      } else {
        refused++;
      }
    }

    if (accepted > refused) {
      s.response = TrainingResponse.accepted;
      s.responseDetail =
          'Grupo ${group.name}: $accepted aceitaram, $refused recusaram.';
      if (s.floorNumber == -1 && hasTrainingField) {
        _trainInTrainingField(
          acceptedIds.map((id) => npcs.firstWhere((n) => n.id == id)).toList(),
        );
      } else if (s.floorNumber > 0) {
        trainOnFloor(s.floorNumber, acceptedIds);
      }
    } else {
      s.response = TrainingResponse.refused;
      s.responseDetail =
          'Grupo ${group.name} recusou ($refused contra $accepted).';
    }

    _addEvent(
      GameEventType.trainingSuggestion,
      'Sugestao ao Grupo ${group.name}',
      s.responseDetail,
      involvedIds: acceptedIds,
    );
  }

  void _trainInTrainingField(List<Npc> participants) {
    for (final npc in participants) {
      final gain = 0.08 + _rng.nextDouble() * 0.12;
      npc.attributes.strength += gain;
      npc.attributes.endurance += gain * 0.8;
      npc.attributes.agility += gain * 0.5;
      npc.history.add('Treinou no Campo de Treino (Dia ${state.currentDay})');
      if (_rng.nextDouble() < 0.005) {
        npc.attributes.endurance -= 0.2;
        npc.traumas.add('Ferimento leve no Campo de Treino');
      }
    }
    citadel.resources.food -= participants.length * 1.5;
    _addEvent(
      GameEventType.training,
      'Treino no Campo',
      '${participants.length} membros treinaram no Campo de Treino.',
      involvedIds: participants.map((n) => n.id).toList(),
    );
  }

  TrainingSuggestion suggestTrainingWithBuilding(
    String groupId,
    BuildingType buildingType,
    int durationDays,
  ) {
    final suggestion = TrainingSuggestion(
      id: _nextSuggestionId(),
      day: state.currentDay,
      targetType: 'group',
      targetId: groupId,
      floorNumber: -1, // não usa mais floorNumber
    );

    final group = groups.firstWhereOrNull((g) => g.id == groupId);
    final refusedIds = <String>[];
    if (group == null) {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail = 'Grupo não encontrado.';
      suggestion.acceptedIds = [];
      suggestion.refusedIds = refusedIds;
      trainingSuggestions.add(suggestion);
      return suggestion;
    }

    // Verifica se edifício existe
    if (!citadel.hasBuilding(buildingType)) {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail = 'Edificio necessário não está construído.';
      suggestion.acceptedIds = [];
      suggestion.refusedIds = refusedIds;
      trainingSuggestions.add(suggestion);
      return suggestion;
    }

    final members = group.memberIds
        .map((id) => npcs.firstWhereOrNull((n) => n.id == id && n.alive))
        .whereType<Npc>()
        .toList();

    if (members.isEmpty) {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail = 'Nenhum membro disponível.';
      suggestion.acceptedIds = [];
      suggestion.refusedIds = refusedIds;
      trainingSuggestions.add(suggestion);
      return suggestion;
    }

    // Já em treino ativo?
    if (activeTrainings.any((m) => m.groupId == groupId)) {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail =
          '${group.name} já está em missão de treino ativa.';
      suggestion.acceptedIds = [];
      suggestion.refusedIds = refusedIds;
      trainingSuggestions.add(suggestion);
      return suggestion;
    }

    if (_isGroupBusyOnQuest(groupId)) {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail = '${group.name} está em missão ativa.';
      suggestion.acceptedIds = [];
      suggestion.refusedIds = group.memberIds;
      trainingSuggestions.add(suggestion);
      return suggestion;
    }
    int accepted = 0;
    int refused = 0;
    final participantIds = <String>[];

    for (final npc in members) {
      npc.trainingSuggestionsReceived++;
      if (npc.isIncapacitated || npc.isExhausted) {
        refused++;
        refusedIds.add(npc.id);
        continue;
      }

      final apt = _trainingAptitude(npc, buildingType);
      // Aptitude alta = mais chance de aceitar
      final acceptChance =
          (npc.trainingAcceptanceChance(hasTrainingField: false) * (apt * 0.5))
              .clamp(0.1, 0.9);

      if (_rng.nextDouble() < acceptChance) {
        accepted++;
        npc.trainingSuggestionsAccepted++;
        participantIds.add(npc.id);
      } else {
        refused++;
        refusedIds.add(npc.id);
      }
    }

    final buildingName = Building(type: buildingType).name;

    if (accepted == 0) {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail =
          'Ninguém do ${group.name} aceitou treinar em $buildingName.';
      suggestion.acceptedIds = [];
      suggestion.refusedIds = refusedIds;
    } else if (accepted > refused) {
      suggestion.response = TrainingResponse.accepted;
      suggestion.responseDetail =
          '$accepted de ${members.length} membros iniciaram $durationDays dias de treino em $buildingName.';
      suggestion.acceptedIds = participantIds;
      suggestion.refusedIds = refusedIds;

      activeTrainings.add(
        TrainingMission(
          id: _nextMissionId(),
          groupId: groupId,
          participantIds: participantIds,
          buildingType: buildingType,
          startDay: state.currentDay,
          durationDays: durationDays,
        ),
      );
    } else {
      suggestion.response = TrainingResponse.negotiated;
      suggestion.responseDetail =
          'Apenas $accepted aceitaram ($refused recusaram). Treino iniciado com quem aceitou.';
      suggestion.acceptedIds = participantIds;
      suggestion.refusedIds = refusedIds;

      if (participantIds.isNotEmpty) {
        activeTrainings.add(
          TrainingMission(
            id: _nextMissionId(),
            groupId: groupId,
            participantIds: participantIds,
            buildingType: buildingType,
            startDay: state.currentDay,
            durationDays: durationDays,
          ),
        );
      }
    }

    trainingSuggestions.add(suggestion);
    return suggestion;
  }

  void _processActiveTrainings() {
    final completed = <TrainingMission>[];

    for (final mission in activeTrainings) {
      final building = citadel.getBuilding(mission.buildingType);
      final level = building?.level ?? 1;

      final participants = mission.participantIds
          .map((id) => npcs.firstWhereOrNull((n) => n.id == id && n.alive))
          .whereType<Npc>()
          .toList();

      if (participants.isEmpty) {
        completed.add(mission);
        continue;
      }

      for (final npc in participants) {
        final gains = _dailyTrainingGains(npc, mission.buildingType, level);
        final npcGains = mission.gainsPerNpc.putIfAbsent(npc.id, () => {});

        gains.forEach((attr, value) {
          npcGains[attr] = (npcGains[attr] ?? 0) + value;
          _applyAttributeGain(npc, attr, value);
        });

        // Fadiga por treino (menos que expedição)
        npc.fatigue = (npc.fatigue + 8.0).clamp(0, 100);
      }

      // Custo de comida diário
      citadel.resources.food -= participants.length * 1.0;

      mission.completedDays++;

      if (mission.isComplete) {
        completed.add(mission);
        _onTrainingMissionComplete(mission, participants);
      }
    }

    activeTrainings.removeWhere((m) => completed.contains(m));
  }

  void _applyAttributeGain(Npc npc, String attr, double value) {
    switch (attr) {
      case 'strength':
        npc.attributes.strength = (npc.attributes.strength + value).clamp(
          1,
          20,
        );
      case 'endurance':
        npc.attributes.endurance = (npc.attributes.endurance + value).clamp(
          1,
          20,
        );
      case 'agility':
        npc.attributes.agility = (npc.attributes.agility + value).clamp(1, 20);
      case 'intelligence':
        npc.attributes.intelligence = (npc.attributes.intelligence + value)
            .clamp(1, 20);
      case 'charisma':
        npc.attributes.charisma = (npc.attributes.charisma + value).clamp(
          1,
          20,
        );
      case 'mentalStability':
        npc.attributes.mentalStability =
            (npc.attributes.mentalStability + value).clamp(0, 100);
    }
  }

  void _onTrainingMissionComplete(
    TrainingMission mission,
    List<Npc> participants,
  ) {
    final group = groups.firstWhereOrNull((g) => g.id == mission.groupId);
    final buildingName = Building(type: mission.buildingType).name;

    // Resumo de ganhos totais
    final summaryParts = <String>[];
    for (final npc in participants) {
      final gains = mission.gainsPerNpc[npc.id];
      if (gains == null || gains.isEmpty) continue;
      final gainStr = gains.entries
          .map((e) => '${_attrLabel(e.key)}+${e.value.toStringAsFixed(2)}')
          .join(', ');
      summaryParts.add('${npc.name}: $gainStr');
      npc.history.add(
        'Completou ${mission.durationDays} dias de treino em $buildingName '
        '(Dia ${state.currentDay})',
      );
    }

    if (group != null) {
      group.cohesion = (group.cohesion + 3).clamp(0, 100);
    }

    _addEvent(
      GameEventType.training,
      'Treino Completo: $buildingName',
      '${participants.length} membros completaram ${mission.durationDays} dias de treino.\n'
          '${summaryParts.join('\n')}',
      involvedIds: participants.map((n) => n.id).toList(),
      isMajor: true,
    );
  }

  String _attrLabel(String attr) => switch (attr) {
    'strength' => 'FOR',
    'endurance' => 'RES',
    'agility' => 'AGI',
    'intelligence' => 'INT',
    'charisma' => 'CAR',
    'mentalStability' => 'SAN',
    _ => attr,
  };

  // ─────────────────────────────────────────────
  // INVOCAÇÃO EMERGENCIAL
  // ─────────────────────────────────────────────

  void _processEmergencySummon() {
    if (aliveNpcs.length > 5 || state.currentDay % 14 != 0) return;

    final numToSummon = min(3, 6 - aliveNpcs.length);
    if (numToSummon <= 0) return;

    for (int i = 0; i < numToSummon; i++) {
      npcs.add(Npc.generateRandom(state.generateNpcId(), 1, _rng));
    }

    _addEvent(
      GameEventType.emergencySummon,
      'INVOCACAO EMERGENCIAL!',
      'Populacao critica (${aliveNpcs.length} restantes). '
          '$numToSummon novos humanos foram trazidos pela Torre. Vigiar com atencao.',
      isMajor: true,
    );

    final startIndex = npcs.length - numToSummon;
    for (int i = startIndex; i < npcs.length; i++) {
      if (npcs[i].origin.isDarkOrigin) {
        npcs[i] = npcs[i].copyWith(isSuspicious: true);
        _addEvent(
          GameEventType.system,
          'Alerta: Invocado Suspeito',
          '${npcs[i].name} (${npcs[i].origin.label}) tem passado sombrio.',
          involvedIds: [npcs[i].id],
        );
      }
    }
  }

  void _processPrisonSystem() {
    // 1. Processa votos dos jurados nos julgamentos pendentes
    final trialEvents = _prisonService.processTrialVotes(
      allNpcs: npcs,
      currentDay: state.currentDay,
      rng: _rng,
      generateEventId: () => state.eventIdCounter++,
    );

    // Registra eventos gerados pelo serviço de prisão
    for (final event in trialEvents) {
      events.add(event);
      _dayEvents.add(event);
      if (events.length > _maxRawEvents) {
        events.removeRange(0, events.length - _maxRawEvents);
      }
      _maybeCreateRecord(event);
    }

    // 2. Aplica efeitos diários nos presos
    for (final cell in _prisonService.cells) {
      final npc = npcs.firstWhereOrNull((n) => n.id == cell.npcId);
      if (npc == null) continue;
      npc.attributes.mentalStability = (npc.attributes.mentalStability - 1.5)
          .clamp(0, 100);
      npc.loyalty = (npc.loyalty - 0.5).clamp(0, 100);
      npc.profession = Profession.idle;
    }

    // 3. Solta presos que cumpriram a pena
    final released = _prisonService.processReleases(state.currentDay);
    for (final npcId in released) {
      final npc = npcs.firstWhereOrNull((n) => n.id == npcId);
      if (npc == null) continue;
      npc.loyalty = (npc.loyalty - 5).clamp(0, 100);
      npc.traumas.add('Cumpriu pena de prisao no dia ${state.currentDay}');
      _addEvent(
        GameEventType.politicalEvent,
        'Liberado: ${npc.name}',
        '${npc.name} cumpriu sua pena e foi solto. '
            'Reintegracao a cidadela pode ser turbulenta.',
        involvedIds: [npcId],
        isMajor: false,
      );
    }

    // 4. Verifica se algum NPC atingiu threshold sem julgamento aberto
    for (final npc in aliveNpcs) {
      if (_prisonService.isImprisoned(npc.id) ||
          _prisonService.isOnTrial(npc.id)) {
        continue;
      }
      if (!_prisonService.shouldOpenTrial(npc.id)) continue;
      if (!citadel.hasBuilding(BuildingType.councilHall)) continue;
      if (!citadel.hasBuilding(BuildingType.prison)) continue;

      final (result, trial) = _prisonService.openTrial(
        npcId: npc.id,
        allNpcs: npcs,
        citadel: citadel,
        currentDay: state.currentDay,
        rng: _rng,
      );
      if (result == ArrestResult.trialOpened && trial != null) {
        _addEvent(
          GameEventType.politicalEvent,
          'JULGAMENTO CONVOCADO: ${npc.name}',
          'Evidencias acumuladas levaram o conselho a convocar '
              'o julgamento de ${npc.name} por ${trial.primaryCrime.label}.',
          involvedIds: [npc.id, ...trial.jurorIds],
          isMajor: true,
        );
      }
    }
  }

  /// Ação do jogador: inicia julgamento de um NPC manualmente
  ArrestResult arrestNpc(String npcId) {
    if (!citadel.hasBuilding(BuildingType.councilHall)) {
      return ArrestResult.noCouncilHall;
    }
    if (!citadel.hasBuilding(BuildingType.prison)) {
      return ArrestResult.noPrison;
    }
    if (_prisonService.isImprisoned(npcId)) {
      return ArrestResult.alreadyImprisoned;
    }
    if (_prisonService.isOnTrial(npcId)) return ArrestResult.alreadyOnTrial;
    final evidence = _prisonService.allCrimes
        .where((c) => c.npcId == npcId && c.witnessed)
        .toList();
    if (evidence.isEmpty) return ArrestResult.noCrimeEvidence;

    final (result, trial) = _prisonService.openTrial(
      npcId: npcId,
      allNpcs: npcs,
      citadel: citadel,
      currentDay: state.currentDay,
      rng: _rng,
    );

    if (result == ArrestResult.trialOpened && trial != null) {
      final accused = npcs.firstWhereOrNull((n) => n.id == npcId);
      _addEvent(
        GameEventType.politicalEvent,
        'JULGAMENTO ABERTO: ${accused?.name ?? npcId}',
        'O lider convocou o conselho para julgar ${accused?.name ?? npcId}.',
        involvedIds: [npcId, ...trial.jurorIds],
        isMajor: true,
      );
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // SOLICITAR NOVOS MORADORES
  // ─────────────────────────────────────────────

  String requestNewSettlers() {
    final daysSince = state.currentDay - state.lastSettlersRequestDay;
    if (daysSince < 7) {
      return 'Aguarde ${7 - daysSince} dia(s) para nova solicitacao.';
    }

    if (citadel.resources.morale < 60) {
      return 'Moral muito baixa '
          '(${citadel.resources.morale.toStringAsFixed(0)}/100). '
          'Novos moradores nao virao.';
    }

    if (population >= citadel.totalPopulationCapacity) {
      return 'Sem espaco! Construa mais moradias.';
    }

    final spacesAvailable = citadel.totalPopulationCapacity - population;

    const foodPerDay = 1.5;
    const daysBuffer = 10;

    final maxByFood = (citadel.resources.food / (foodPerDay * daysBuffer))
        .floor();

    final canReceive = min(spacesAvailable, maxByFood);

    if (canReceive <= 0) {
      return maxByFood <= 0
          ? 'Comida insuficiente! Precisa de '
                '${(foodPerDay * daysBuffer).toStringAsFixed(0)} por morador.'
          : 'Sem espaco disponivel.';
    }

    final newSettlers = _generateSettlers(canReceive);

    state.lastSettlersRequestDay = state.currentDay;
    npcs.addAll(newSettlers);

    final couples = newSettlers.where((n) => n.partnerId != null).length ~/ 2;

    final families = newSettlers
        .where((n) => n.relationships.any((r) => r.type == 'familiar'))
        .length;

    final darkCount = newSettlers.where((n) => n.origin.isDarkOrigin).length;

    _addEvent(
      GameEventType.system,
      'Novos Moradores!',
      '${newSettlers.length} novos moradores chegaram!'
          '${couples > 0 ? " $couples casal(is)." : ""}'
          '${families > 0 ? " $families com lacos familiares." : ""}'
          '${darkCount > 0 ? " ⚠️ $darkCount com passado obscuro." : ""}'
          ' Nem todos trazem apenas esperanca...',
      involvedIds: newSettlers.map((n) => n.id).toList(),
      isMajor: true,
    );

    return 'Sucesso! ${newSettlers.length} moradores '
        '($couples casais, $families familiares'
        '${darkCount > 0 ? ", $darkCount suspeitos" : ""}). '
        'Proxima solicitacao em 7 dias.';
  }

  List<Npc> _generateSettlers(int count) {
    final settlers = <Npc>[];
    var remaining = count;

    while (remaining > 0) {
      final roll = _rng.nextDouble();

      if (roll < 0.05 && remaining >= 2) {
        final couple = _spawnCouple();
        settlers.addAll(couple.take(remaining));
        remaining -= min(remaining, couple.length);
      } else if (roll < 0.15 && remaining >= 2) {
        final familySize = min(remaining, _rng.nextInt(2) + 2).toInt();

        final family = _spawnFamily(familySize);
        settlers.addAll(family);
        remaining -= family.length;
      } else {
        settlers.add(Npc.generateRandom(state.generateNpcId(), 1, _rng));
        remaining--;
      }
    }

    return settlers;
  }

  List<Npc> _spawnCouple() {
    final id1 = state.generateNpcId();
    final id2 = state.generateNpcId();

    final a = Npc.generateRandom(id1, 1, _rng);
    final b = Npc.generateRandom(id2, 1, _rng);

    a.partnerId = id2;
    b.partnerId = id1;

    a.relationships.add(
      Relationship(targetId: id2, type: 'parceiro', affinity: 0.85),
    );

    b.relationships.add(
      Relationship(targetId: id1, type: 'parceiro', affinity: 0.85),
    );

    return [a, b];
  }

  List<Npc> _spawnFamily(int size) {
    final members = List.generate(size, (_) {
      return Npc.generateRandom(state.generateNpcId(), 1, _rng);
    });

    for (int i = 0; i < members.length; i++) {
      for (int j = i + 1; j < members.length; j++) {
        members[i].relationships.add(
          Relationship(
            targetId: members[j].id,
            type: 'familiar',
            affinity: 0.6,
          ),
        );
        members[j].relationships.add(
          Relationship(
            targetId: members[i].id,
            type: 'familiar',
            affinity: 0.6,
          ),
        );
      }
    }

    return members;
  }
  // ─────────────────────────────────────────────
  // EVENTOS ALEATÓRIOS
  // ─────────────────────────────────────────────

  void _processRandomEvents() {
    if (_rng.nextDouble() >= 0.08) return;

    switch (_rng.nextInt(8)) {
      case 0:
        final amount = 5 + _rng.nextInt(15);
        citadel.resources.food += amount;
        _addEvent(
          GameEventType.resourceGain,
          'Descoberta',
          'Exploradores encontraram suprimentos: +$amount comida',
        );
        break;
      case 1:
        final candidate = aliveNpcs.firstWhereOrNull(
          (n) => !n.talentDiscovered && n.hiddenTalent != HiddenTalent.none,
        );
        if (candidate != null) {
          candidate.talentDiscovered = true;
          _addEvent(
            GameEventType.discovery,
            'Talento Oculto Revelado!',
            '${candidate.name} revelou ${candidate.hiddenTalent.label}! ${candidate.hiddenTalent.description}',
            involvedIds: [candidate.id],
            isMajor: true,
          );
        }
        break;
      case 2:
        citadel.resources.morale += 5;
        for (final npc in aliveNpcs) {
          npc.loyalty += 1;
        }
        _addEvent(
          GameEventType.celebration,
          'Celebracao',
          'Os moradores organizaram uma festa. Moral restaurada.',
          isMajor: true,
        );
        break;
      case 3:
        citadel.resources.wood = (citadel.resources.wood - 10).clamp(0, 9999);
        _addEvent(
          GameEventType.resourceLoss,
          'Tempestade',
          'Uma tempestade danificou estruturas. -10 madeira.',
          isMajor: true,
        );
        break;
      case 4:
        if (aliveNpcs.length >= 2) {
          final a = aliveNpcs[_rng.nextInt(aliveNpcs.length)];
          final b = _pickOther(aliveNpcs, a);
          citadel.resources.morale -= 3;
          a.loyalty -= 2;
          b.loyalty -= 2;
          _addEvent(
            GameEventType.crisis,
            'Conflito',
            '${a.name} e ${b.name} entraram em disputa.',
            involvedIds: [a.id, b.id],
            isMajor: true,
          );
        }
        break;
      case 5:
        final amount = 3 + _rng.nextInt(8);
        citadel.resources.knowledge += amount;
        _addEvent(
          GameEventType.discovery,
          'Inscricoes',
          'Simbolos antigos descobertos nas paredes. +$amount conhecimento.',
        );
        break;
      case 6:
        final famous = aliveNpcs.where((n) => n.fame.abs() > 10).toList();
        if (famous.isNotEmpty) {
          final npc = famous[_rng.nextInt(famous.length)];
          if (npc.fame > 0) {
            citadel.resources.morale += 3;
            _addEvent(
              GameEventType.politicalEvent,
              'Lideranca Natural',
              '${npc.name} inspirou os moradores. +3 moral.',
              involvedIds: [npc.id],
            );
          } else {
            citadel.resources.morale -= 2;
            _addEvent(
              GameEventType.politicalEvent,
              'Medo na Cidadela',
              '${npc.name} causa desconforto. -2 moral.',
              involvedIds: [npc.id],
            );
          }
        }
        break;
      case 7:
        if (groups.isNotEmpty) {
          final group = groups[_rng.nextInt(groups.length)];
          group.cohesion = (group.cohesion + 5).clamp(0, 100);
          _addEvent(
            GameEventType.groupFormed,
            'Coesao de Grupo',
            '"${group.name}" fortaleceu seus lacos. Coesao: ${group.cohesion.toStringAsFixed(0)}%.',
          );
        }
        break;
    }
  }

  // ─────────────────────────────────────────────
  // GRAVIDEZ & CRESCIMENTO
  // ─────────────────────────────────────────────

  void _processPregnancies() {
    for (final npc in aliveNpcs) {
      if (npc.partnerId == null) continue;
      final partner = npcs.firstWhereOrNull(
        (n) => n.id == npc.partnerId && n.alive,
      );
      if (partner == null) continue;
      if (npc.id.compareTo(partner.id) > 0) continue;

      final rel = npc.relationships.firstWhereOrNull(
        (r) => r.targetId == partner.id,
      );
      if (rel == null || rel.affinity < 0.6) continue;

      final pregnant = npc.pregnantSince != null
          ? npc
          : partner.pregnantSince != null
          ? partner
          : null;

      if (pregnant != null) {
        _processActivePregnancy(pregnant, partner == pregnant ? npc : partner);
      } else {
        _tryConceive(npc, partner);
      }
    }
  }

  void _processActivePregnancy(Npc pregnant, Npc other) {
    final foodPerCapita = citadel.resources.food / max(1, aliveNpcs.length);
    if (foodPerCapita >= 3.0) {
      pregnant.maternalNutrition = min(100, pregnant.maternalNutrition + 5);
    } else if (foodPerCapita < 1.5) {
      pregnant.maternalNutrition = max(0, pregnant.maternalNutrition - 10);
    }

    double riskOfLoss = 0.0;
    if (pregnant.maternalNutrition < 30) {
      riskOfLoss += 0.25;
    } else if (pregnant.maternalNutrition < 50) {
      riskOfLoss += 0.10;
    }
    if (pregnant.attributes.mentalStability < 30) riskOfLoss += 0.08;
    if (citadel.resources.morale < 30) riskOfLoss += 0.05;
    if (pregnant.traumas.any(
      (t) => t.contains('doenca') || t.contains('ferimento'),
    )) {
      riskOfLoss += 0.12;
    }

    if (riskOfLoss > 0 && _rng.nextDouble() < riskOfLoss) {
      pregnant.pregnantSince = null;
      pregnant.maternalNutrition = 100.0;
      pregnant.attributes.mentalStability -= 15;
      other.attributes.mentalStability -= 10;
      pregnant.traumas.add('Perda de filho nao nascido');
      other.traumas.add('Perda de filho nao nascido');
      citadel.resources.morale -= 5;
      _addEvent(
        GameEventType.death,
        'Tragedia: Perda na Gestacao',
        '${pregnant.name} perdeu o bebe.',
        involvedIds: [pregnant.id, other.id],
        isMajor: true,
      );
      return;
    }

    final daysSince = state.currentDay - pregnant.pregnantSince!;
    if (daysSince < 2) return;

    final deathRisk = pregnant.maternalNutrition < 20
        ? 0.15
        : pregnant.maternalNutrition < 40
        ? 0.05
        : pregnant.maternalNutrition < 60
        ? 0.01
        : 0.0;

    if (deathRisk > 0 && _rng.nextDouble() < deathRisk) {
      _killNpc(pregnant, 'Morreu durante o parto por complicacoes');
      other.attributes.mentalStability -= 25;
      other.traumas.add('Perda da parceira no parto');
      pregnant.pregnantSince = null;
      citadel.resources.morale -= 10;
      _addEvent(
        GameEventType.death,
        'Tragedia Absoluta',
        '${pregnant.name} nao sobreviveu ao parto.',
        involvedIds: [pregnant.id, other.id],
        isMajor: true,
      );
      return;
    }

    _birthChild(pregnant, other);
  }

  void _birthChild(Npc parentA, Npc parentB) {
    final nutrition = parentA.maternalNutrition;
    final childId = state.generateNpcId();
    final child = Npc.generateChild(
      childId,
      parentA,
      parentB,
      _rng,
      state.currentDay,
      maternalNutrition: nutrition,
    );

    npcs.add(child);
    parentA.childrenIds.add(childId);
    parentB.childrenIds.add(childId);
    parentA.pregnantSince = null;
    parentA.maternalNutrition = 100.0;
    parentA.lastBirthDay = state.currentDay;
    parentB.lastBirthDay = state.currentDay;
    state.totalBirths++;

    final nutritionNote = nutrition < 40
        ? ' ⚠️ Bebe nasceu fraco por desnutricao.'
        : nutrition < 70
        ? ' Nutricao materna moderada.'
        : '';

    _addEvent(
      GameEventType.birth,
      'Novo Membro!',
      '${parentA.name} e ${parentB.name} trouxeram ${child.name} ao mundo. G${child.generation}.$nutritionNote',
      involvedIds: [parentA.id, parentB.id, childId],
      isMajor: true,
    );

    citadel.resources.morale += 5;
    for (final n in aliveNpcs) {
      n.loyalty += 0.5;
    }
  }

  void _tryConceive(Npc a, Npc b) {
    if (citadel.resources.food < 20 || citadel.resources.morale < 40) return;

    // Cooldown pós-parto: mínimo 150 dias de jogo (~5 meses)
    const int postBirthCooldown = 150;
    if (a.lastBirthDay > 0 &&
        (state.currentDay - a.lastBirthDay) < postBirthCooldown) {
      return;
    }
    if (b.lastBirthDay > 0 &&
        (state.currentDay - b.lastBirthDay) < postBirthCooldown) {
      return;
    }

    // Chance base baixa
    double chance = 0.03;

    final capacity = citadel.totalPopulationCapacity;
    final pop = aliveNpcs.length;
    if (pop >= capacity) {
      chance = 0.005;
    } else if (pop >= capacity * 0.85) {
      chance *= 0.4;
    }
    final foodPerCapita = citadel.resources.food / pop.clamp(1, 9999);
    if (foodPerCapita < 2.0) chance *= 0.3;

    if (_rng.nextDouble() >= chance) return;

    final mother = _rng.nextBool() ? a : b;
    mother.pregnantSince = state.currentDay;
    mother.maternalNutrition = 100.0;
    _addEvent(
      GameEventType.romance,
      'Nova Vida a Caminho',
      '${a.name} e ${b.name} estão esperando um filho!',
      involvedIds: [a.id, b.id],
    );
    citadel.resources.morale += 2;
  }
  // ─────────────────────────────────────────────
  // MORTALIDADE INFANTIL
  // ─────────────────────────────────────────────

  void _processChildMortality() {
    for (final child
        in aliveNpcs.where((n) => n.isVulnerable(state.currentDay)).toList()) {
      final stage = child.growthStage(state.currentDay);
      double risk = stage == GrowthStage.baby ? 0.08 : 0.03;

      final foodPerCapita = citadel.resources.food / max(1, aliveNpcs.length);
      if (foodPerCapita < 0.5) {
        risk += 0.25;
      } else if (foodPerCapita < 1.0) {
        risk += 0.10;
      }
      if (stage == GrowthStage.baby && child.maternalNutrition < 50) {
        risk += 0.12;
      }

      final sickCount = aliveNpcs
          .where((n) => n.traumas.any((t) => t.contains('doenca')))
          .length;
      risk += min(0.15, sickCount * 0.03);

      if (citadel.resources.morale < 20) {
        risk += 0.08;
      } else if (citadel.resources.morale < 40) {
        risk += 0.04;
      }
      if (citadel.hasBuilding(BuildingType.infirmary)) risk *= 0.5;

      if (risk <= 0 || _rng.nextDouble() >= risk) continue;

      final cause = foodPerCapita < 0.5
          ? 'Morreu de inanicao'
          : sickCount > 2
          ? 'Sucumbiu a doenca'
          : child.maternalNutrition < 30
          ? 'Nasceu muito fraco'
          : 'Faleceu por complicacoes';

      _traumatizeParents(child, 'Perda de filho(a) ${child.name}');
      _killNpc(child, cause);
      citadel.resources.morale -= 8;

      _addEvent(
        GameEventType.death,
        'Tragedia: Morte Infantil',
        'O(A) ${stage.label.toLowerCase()} ${child.name} nao sobreviveu. $cause.',
        involvedIds: [
          child.id,
          if (child.parentAId != null) child.parentAId!,
          if (child.parentBId != null) child.parentBId!,
        ],
        isMajor: true,
      );

      for (final other in aliveNpcs.where(
        (n) => n.isVulnerable(state.currentDay),
      )) {
        other.psychologicalMarks.add('Testemunhou morte de outra crianca');
      }
    }
  }

  void _traumatizeParents(Npc child, String traumaText) {
    for (final parentId in [child.parentAId, child.parentBId]) {
      if (parentId == null) continue;
      final parent = npcs.firstWhereOrNull((n) => n.id == parentId && n.alive);
      if (parent == null) continue;
      parent.attributes.mentalStability -= 20;
      parent.traumas.add(traumaText);
      parent.psychologicalMarks.add('TRAGEDIA: Perda de filho');
    }
  }

  // ─────────────────────────────────────────────
  // TRANSIÇÕES DE CRESCIMENTO
  // ─────────────────────────────────────────────

  void _processGrowthTransitions() {
    for (final npc in aliveNpcs.where((n) => n.birthDay > 0)) {
      final daysAlive = state.currentDay - npc.birthDay;
      final stage = npc.growthStage(state.currentDay);

      if (daysAlive == 7 && stage == GrowthStage.child) {
        _addEvent(
          GameEventType.birth,
          'Crescimento: ${npc.name}',
          '${npc.name} nao e mais um bebe!',
          involvedIds: [npc.id],
        );
      }
      if (daysAlive == 30 && stage == GrowthStage.adolescent) {
        _developPersonalityFromMarks(npc, isFirstTrait: true);
        _addEvent(
          GameEventType.birth,
          'Adolescencia: ${npc.name}',
          '${npc.name} cresceu e sua personalidade comeca a se formar.',
          involvedIds: [npc.id],
        );
      }
      if (daysAlive == 60 && stage == GrowthStage.adult) {
        _developPersonalityFromMarks(npc, isFirstTrait: false);
        final traitNames = npc.traits.map((t) => t.label).join(', ');
        _addEvent(
          GameEventType.birth,
          'Maioridade: ${npc.name}',
          '${npc.name} atingiu a maioridade! Traits: $traitNames',
          involvedIds: [npc.id],
          isMajor: true,
        );
        for (final parentId in [npc.parentAId, npc.parentBId]) {
          if (parentId == null) continue;
          final parent = npcs.firstWhereOrNull(
            (n) => n.id == parentId && n.alive,
          );
          if (parent != null) parent.attributes.mentalStability += 5;
        }
      }
    }
  }

  void _developPersonalityFromMarks(Npc npc, {required bool isFirstTrait}) {
    final marks = npc.psychologicalMarks;
    final tragedies = marks
        .where((m) => m.contains('TRAGEDIA') || m.contains('morte'))
        .length;
    final hunger = marks.where((m) => m.contains('fome')).length;
    final combat = marks.where((m) => m.contains('combate')).length;
    final betrayal = marks.where((m) => m.contains('traicao')).length;
    final victories = marks.where((m) => m.contains('vitoria')).length;

    PersonalityTrait? trait;
    if (tragedies >= 2) {
      trait = isFirstTrait
          ? PersonalityTrait.pessimist
          : PersonalityTrait.compassionate;
    } else if (hunger >= 2) {
      trait = isFirstTrait
          ? PersonalityTrait.pragmatic
          : PersonalityTrait.ruthless;
    } else if (combat >= 2) {
      trait = isFirstTrait
          ? PersonalityTrait.brave
          : PersonalityTrait.aggressive;
    } else if (betrayal >= 1) {
      trait = isFirstTrait
          ? PersonalityTrait.loner
          : PersonalityTrait.treacherous;
    } else if (victories >= 2) {
      trait = isFirstTrait ? PersonalityTrait.optimist : PersonalityTrait.brave;
    } else if (citadel.resources.morale > 70) {
      trait = isFirstTrait
          ? PersonalityTrait.optimist
          : PersonalityTrait.compassionate;
    } else if (citadel.resources.morale < 30) {
      trait = isFirstTrait
          ? PersonalityTrait.pessimist
          : PersonalityTrait.coward;
    } else {
      trait = _inheritedOrRandomTrait(npc);
    }

    if (!npc.traits.contains(trait)) {
      npc.traits.add(trait);
      npc.history.add(
        'Desenvolveu ${trait.label} aos ${state.currentDay - npc.birthDay} dias',
      );
    }
  }

  PersonalityTrait _inheritedOrRandomTrait(Npc npc) {
    final parentTraits = [npc.parentAId, npc.parentBId]
        .whereType<String>()
        .map((id) => npcs.firstWhereOrNull((n) => n.id == id))
        .whereType<Npc>()
        .expand((p) => p.traits)
        .toList();

    if (parentTraits.isNotEmpty) {
      return parentTraits[_rng.nextInt(parentTraits.length)];
    }

    const neutral = [
      PersonalityTrait.calm,
      PersonalityTrait.analytical,
      PersonalityTrait.creative,
      PersonalityTrait.pragmatic,
    ];
    return neutral[_rng.nextInt(neutral.length)];
  }

  void _addPsychologicalMarksToChildren(
    String mark, {
    List<String>? exceptIds,
  }) {
    for (final child in aliveNpcs) {
      if (exceptIds?.contains(child.id) ?? false) continue;
      final stage = child.growthStage(state.currentDay);
      if (stage == GrowthStage.child || stage == GrowthStage.adolescent) {
        child.psychologicalMarks.add(mark);
      }
    }
  }

  // ─────────────────────────────────────────────
  // ENVELHECIMENTO
  // ─────────────────────────────────────────────

  void _processAging() {
    // 1 ano de jogo = 360 dias
    if (state.currentDay % 360 != 0) return;

    for (final npc in aliveNpcs.toList()) {
      npc.age++;

      // Crescimento juvenil (geração 2+, ainda jovem)
      if (npc.age < 18 && npc.generation > 1) {
        npc.attributes.strength += 0.3;
        npc.attributes.agility += 0.3;
        npc.attributes.intelligence += 0.2;
        npc.attributes.endurance += 0.3;
      }

      final maxAge = _lifeExpectancy(npc);

      // Semi-divinos: imortais — só marcamos história
      if (npc.fame >= 600) {
        if (npc.age % 100 == 0) {
          npc.history.add('Atravessou ${npc.age} anos. A Torre o preserva.');
          _addEvent(
            GameEventType.discovery,
            'Imortalidade Confirmada',
            '${npc.name} completou ${npc.age} anos. Nem o tempo o alcança.',
            involvedIds: [npc.id],
            isMajor: true,
          );
        }
        continue;
      }

      // Decaimento físico após 70% da expectativa
      final agingRatio = npc.age / maxAge.clamp(1, 9999);
      if (agingRatio > 0.7) {
        npc.attributes.strength -= 0.3;
        npc.attributes.agility -= 0.3;
        npc.attributes.endurance -= 0.4;
        // Sabedoria cresce com a idade
        npc.attributes.intelligence += 0.1;
        npc.attributes.charisma += 0.05;
      }

      // Risco de morte por velhice — cresce após 70% da expectativa
      if (agingRatio > 0.7) {
        final deathChance = ((agingRatio - 0.7) * 0.15).clamp(0.0, 0.8);
        if (_rng.nextDouble() < deathChance) {
          final flavor = _agingFlavorText(npc);
          _killNpc(npc, 'Faleceu de causas naturais aos ${npc.age} anos');
          _addEvent(
            GameEventType.death,
            'Fim de Uma Era',
            '${npc.name} viveu ${npc.age} anos. $flavor',
            involvedIds: [npc.id],
            isMajor: npc.fame > 30,
          );
        }
      }
    }
  }

  int _lifeExpectancy(Npc npc) {
    if (npc.fame >= 201) return 9999; // imortal
    if (npc.fame >= 101) return 500 + _rng.nextInt(200); // 500–700
    if (npc.fame >= 51) return 300 + _rng.nextInt(150); // 300–450
    if (npc.fame >= 21) return 150 + _rng.nextInt(100); // 150–250
    return 80 + _rng.nextInt(40); // 80–120
  }

  String _agingFlavorText(Npc npc) {
    if (npc.fame > 50) {
      return 'Sua lenda permanece gravada nas paredes da Torre.';
    }
    if (npc.killCount > 10) {
      return 'Sobreviveu a incontáveis batalhas, mas não ao tempo.';
    }
    if (npc.generation > 1) {
      return 'Nascido na Torre, na Torre encontrou seu fim.';
    }
    if (npc.daysSurvived > 300) {
      return 'Resistiu mais que qualquer invocado antes.';
    }
    return 'A Torre segue. Os mortais, não.';
  }

  // ─────────────────────────────────────────────
  // TREINO PROFISSIONAL
  // ─────────────────────────────────────────────

  void _processTraining() {
    final trainedToday = <String, List<String>>{};

    for (final npc in aliveNpcs) {
      final gains = _applyProfessionTraining(npc);
      if (gains.isNotEmpty) {
        npc.history.add(
          'Treinou como ${npc.profession.label}: ${gains.join(", ")}',
        );
        trainedToday
            .putIfAbsent(npc.profession.label, () => [])
            .add('${npc.name} (${gains.join(", ")})');
      }
    }

    if (trainedToday.isNotEmpty) {
      final details = trainedToday.entries
          .map((e) => '${e.key}: ${e.value.join(", ")}')
          .join('\n');
      _addEvent(
        GameEventType.training,
        'Treino Profissional',
        'NPCs progrediram:\\n $details',
      );
    }
  }

  List<String> _applyProfessionTraining(Npc npc) {
    if (_rng.nextDouble() >= 0.1) return [];
    final gains = <String>[];

    switch (npc.profession) {
      case Profession.guard:
      case Profession.explorer:
        npc.attributes.strength += 0.1;
        npc.attributes.endurance += 0.1;
        gains.addAll(['FOR+0.1', 'RES+0.1']);

        final barracks = citadel.getBuilding(BuildingType.barracks);
        if (barracks != null) {
          final level = barracks.level;

          // Garantia de segurança para não estourar array
          final index = (level - 1).clamp(0, 3);

          final strBonus = [0.3, 0.5, 0.8, 1.0][index];
          final agiBonus = [0.0, 0.3, 0.5, 0.7][index];
          npc.attributes.strength += strBonus;
          gains.add('FOR+$strBonus (Barracks)');
          if (agiBonus > 0) {
            npc.attributes.agility += agiBonus;
            gains.add('AGI+$agiBonus (Barracks)');
          }
        }
        break;
      case Profession.scribe:
      case Profession.teacher:
        npc.attributes.intelligence += 0.1;
        gains.add('INT+0.1');
        break;
      case Profession.scout:
        npc.attributes.agility += 0.1;
        gains.add('AGI+0.1');
        break;
      case Profession.trainer:
        npc.attributes.strength += 0.05;
        npc.attributes.endurance += 0.05;
        npc.attributes.intelligence += 0.05;
        gains.addAll(['FOR+0.05', 'RES+0.05', 'INT+0.05']);
        break;
      default:
        break;
    }
    return gains;
  }

  // ─────────────────────────────────────────────
  // CONSTRUÇÃO
  // ─────────────────────────────────────────────

  List<BuildingType> get availableBuildings {
    final currentTier = _currentTier;
    return BuildingType.values.where((type) {
      final b = Building(type: type);
      if (b.isUnique && citadel.hasBuilding(type)) return false;
      if (!b.isUnique &&
          citadel.countBuildings(type) >= citadel.level.maxBuildingCopies) {
        return false;
      }
      if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
      if (b.requiredTier > currentTier) return false;
      return true;
    }).toList();
  }

  bool canBuild(BuildingType type) {
    final b = Building(type: type);
    if (b.isUnique && citadel.hasBuilding(type)) return false;
    if (!b.isUnique &&
        citadel.countBuildings(type) >= citadel.level.maxBuildingCopies) {
      return false;
    }
    if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
    if (b.requiredTier > _currentTier) return false;
    return citadel.resources.canAfford(b.cost.toResources());
  }

  bool buildStructure(BuildingType type) {
    if (!canBuild(type)) return false;

    // Novas cópias de canEvolve já nascem no tier atual da cidadela
    final tier = Building(type: type).canEvolve
        ? citadel.level.buildingTier
        : 0;

    final building = Building(
      type: type,
      tier: tier,
    ); // ← era só Building(type: type)
    citadel.resources.spend(building.cost.toResources());
    citadel.buildings.add(building);

    _addEvent(
      GameEventType.construction,
      'Nova Construcao: ${building.name}',
      '${building.name} foi construido(a). ${building.description}',
    );
    _processNpcBuildReaction(type);
    return true;
  }

  bool canUpgradeBuilding(BuildingType type) {
    final b = citadel.getBuilding(type);
    return b != null &&
        b.level < b.maxLevel &&
        citadel.resources.canAfford(b.upgradeCost);
  }

  bool upgradeBuilding(BuildingType type) {
    final building = citadel.getBuilding(type);
    if (building == null) return false;

    if (!canUpgradeBuilding(type)) return false;

    // 🔥 EVOLUÇÃO DE TIER COM HERANÇA
    if (building.level >= building.maxLevel) {
      building.inheritedBonus += building.levelBonus.round();

      // sobe tier
      building.tier++;

      // reinicia nível
      building.level = 1;
    } else {
      building.level++;
    }

    return true;
  }

  bool canUpgradeAllBuildings(BuildingType type) {
    final buildings = citadel.buildings
        .where((b) => b.type == type && b.level < b.maxLevel)
        .toList();
    if (buildings.isEmpty) return false;
    final totalCost = _calculateBulkUpgradeCost(buildings);
    return citadel.resources.canAfford(totalCost);
  }

  bool upgradeAllBuildings(BuildingType type) {
    final buildings = citadel.buildings
        .where((b) => b.type == type && b.level < b.maxLevel)
        .toList();
    if (buildings.isEmpty) return false;

    final totalCost = _calculateBulkUpgradeCost(buildings);
    if (!citadel.resources.canAfford(totalCost)) return false;

    citadel.resources.spend(totalCost);

    for (final building in buildings) {
      upgradeBuildingWithInheritance(building);
    }
    final count = buildings.length;
    final buildingName = buildings.first.name;

    _addEvent(
      GameEventType.upgrade,
      count > 1
          ? '$count x $buildingName Melhorados!'
          : '$buildingName Melhorado!',
      count > 1
          ? '$count x $buildingName evoluíram!'
          : '$buildingName evoluiu!',
      isMajor: true,
    );

    _processNpcBuildReaction(type, isUpgrade: true);
    return true;
  }

  Resources _calculateBulkUpgradeCost(List<Building> buildings) {
    if (buildings.isEmpty) return Resources();
    return buildings.fold(Resources(), (total, b) {
      final c = b.upgradeCost;
      return Resources(
        food: total.food + c.food,
        wood: total.wood + c.wood,
        stone: total.stone + c.stone,
        iron: total.iron + c.iron,
        knowledge: total.knowledge + c.knowledge,
      );
    });
  }

  void upgradeBuildingWithInheritance(Building building) {
    if (building.level >= building.maxLevel && building.tier < 3) {
      // Soma o bônus do nível antigo ao inheritedBonus
      final values = Building.levelValues[building.type];
      if (values != null && building.level > 1) {
        building.inheritedBonus +=
            values[(building.level - 1).clamp(0, values.length - 1)].round();
      }
      building.tier++;
      building.level = 1; // Reset de nível
    } else if (building.level < building.maxLevel) {
      building.level++;
    }
  }

  bool upgradeCitadel() {
    if (!citadel.canUpgrade) return false;
    if (!citadel.resources.canAfford(citadel.upgradeCost.toResources())) {
      return false;
    }
    if (population < (citadel.nextCitadelLevel?.populationRequired ?? 999)) {
      return false;
    }

    citadel.resources.spend(citadel.upgradeCost.toResources());
    final oldLabel = citadel.level.label;
    citadel.level = citadel.nextCitadelLevel!;

    _addEvent(
      GameEventType.upgrade,
      'Cidadela Evoluiu!',
      'De $oldLabel para ${citadel.level.label}! Max edificios: ${citadel.level.maxBuildings}.',
      isMajor: true,
    );

    final newTier = citadel.level.buildingTier;
    final evolved = <String>[];
    for (final building in citadel.buildings.where(
      (b) => b.canEvolve && b.tier < newTier,
    )) {
      final oldName = building.name;
      // MIGRAÇÃO DE BONUS: soma bônus do nível antigo
      final values = Building.levelValues[building.type];
      if (values != null && building.level > 1) {
        building.inheritedBonus +=
            values[(building.level - 1).clamp(0, values.length - 1)].round();
      }
      building.tier = newTier;
      building.level = 1; // reset de nível
      if (oldName != building.name) evolved.add('$oldName → ${building.name}');
    }
    if (evolved.isNotEmpty) {
      _addEvent(
        GameEventType.upgrade,
        'Edificios Evoluiram!',
        evolved.join(', '),
      );
    }

    for (final npc in aliveNpcs) {
      npc.loyalty += 3;
    }
    return true;
  }

  bool canUpgradeStorage() {
    final next = citadel.storageLevel.nextLevel;
    if (next == null) return false;
    if (!citadel.resources.canAfford(citadel.storageLevel.upgradeCost)) {
      return false;
    }
    return _currentTier >= next.requiredTier;
  }

  bool upgradeStorage() {
    if (!canUpgradeStorage()) return false;
    final next = citadel.storageLevel.nextLevel!;
    citadel.resources.spend(citadel.storageLevel.upgradeCost);
    final oldLabel = citadel.storageLevel.label;
    citadel.storageLevel = next;
    _addEvent(
      GameEventType.upgrade,
      'Armazem Melhorado!',
      'De $oldLabel para ${next.label}! Capacidade: ${next.isInfinite ? "INFINITA" : next.capacity.toStringAsFixed(0)}.',
      isMajor: true,
    );
    return true;
  }

  int get _currentTier =>
      ((state.highestFloorCleared) ~/ 10) +
      (state.highestFloorCleared % 10 > 0 ? 1 : 0);

  void _processNpcBuildReaction(BuildingType type, {bool isUpgrade = false}) {
    final action = isUpgrade ? 'melhoria' : 'construcao';
    switch (type) {
      case BuildingType.barracks:
        final militants = aliveNpcs
            .where(
              (n) =>
                  n.profession == Profession.guard ||
                  n.profession == Profession.explorer ||
                  n.profession == Profession.trainer,
            )
            .toList();
        final lowMorale = citadel.resources.morale < 40;
        final militaryStrong = militants.length > 6;
        final hasThreats = aliveNpcs.any((n) => n.isSuspicious);
        int happyCount = 0, unhappyCount = 0;

        for (final npc in militants) {
          if (lowMorale && !hasThreats) {
            npc.loyalty -= 2;
            unhappyCount++;
          } else if (militaryStrong) {
            npc.loyalty += 5;
            npc.fame += 1;
            happyCount++;
          } else if (hasThreats) {
            npc.loyalty += 4;
            happyCount++;
          } else {
            npc.loyalty += 2;
            happyCount++;
          }
        }
        for (final npc in aliveNpcs.where(
          (n) => n.traits.contains(PersonalityTrait.coward),
        )) {
          npc.loyalty -= 1;
          unhappyCount++;
        }
        if (unhappyCount > happyCount) {
          _addEvent(
            GameEventType.politicalEvent,
            'Barracks ${isUpgrade ? "Melhorado" : "Construido"} - Divisão',
            'A ${isUpgrade ? "melhoria" : "construção"} divide opiniões. ${lowMorale ? "Muitos questionam: 'Armas não nos alimentam!'" : "Alguns temem a militarização."}',
            isMajor: true,
          );
        } else if (militaryStrong) {
          _addEvent(
            GameEventType.politicalEvent,
            'Orgulho Militar!',
            'Com ${militants.length} combatentes, a força militar celebra!',
          );
        } else if (hasThreats) {
          _addEvent(
            GameEventType.politicalEvent,
            'Segurança Reforçada',
            'Diante das ameaças, a ${isUpgrade ? "melhoria" : "construção"} traz alívio.',
          );
        } else {
          _addEvent(
            GameEventType.politicalEvent,
            'Barracks ${isUpgrade ? "Melhorado" : "Construido"}',
            'Guardas e exploradores se sentem mais valorizados.',
          );
        }
        break;
      case BuildingType.trainingField:
        for (final npc in aliveNpcs.where(
          (n) =>
              n.profession == Profession.guard ||
              n.profession == Profession.explorer,
        )) {
          npc.loyalty += 2;
        }
        for (final npc in aliveNpcs.where(
          (n) => n.traits.contains(PersonalityTrait.coward),
        )) {
          npc.loyalty -= 1;
        }
        _addEvent(
          GameEventType.politicalEvent,
          'Reacao: $action Militar',
          'Guardas aprovam. Os mais timidos ficam desconfortaveis.',
        );
        break;
      case BuildingType.temple:
        citadel.resources.morale += 5;
        for (final npc in aliveNpcs) {
          npc.loyalty += 1;
        }
        _addEvent(
          GameEventType.celebration,
          'Fe Renovada',
          'A $action do Templo trouxe esperanca a todos.',
          isMajor: true,
        );
        break;
      case BuildingType.tavern:
        citadel.resources.morale += 3;
        for (int i = 0; i < npcs.length; i++) {
          if (npcs[i].alive &&
              npcs[i].origin.isDarkOrigin &&
              !npcs[i].isSuspicious &&
              _rng.nextDouble() < 0.3) {
            npcs[i] = npcs[i].copyWith(isSuspicious: true);
            _addEvent(
              GameEventType.system,
              'Fofoca na Taverna',
              'Rumores indicam que ${npcs[i].name} tem passado sombrio...',
              involvedIds: [npcs[i].id],
            );
          }
        }
        _addEvent(
          GameEventType.politicalEvent,
          'Taverna Aberta',
          'Fofocas e informacoes fluem livremente.',
        );
        break;
      case BuildingType.arena:
        for (final npc in aliveNpcs.where(
          (n) => n.traits.contains(PersonalityTrait.brave),
        )) {
          npc.loyalty += 3;
          npc.fame += 1;
        }
        _addEvent(
          GameEventType.politicalEvent,
          'Arena Inaugurada!',
          'Os mais bravos ja planejam seus duelos.',
          isMajor: true,
        );
        break;
      case BuildingType.councilHall:
        for (final npc in aliveNpcs) {
          npc.loyalty += 1;
        }
        _addEvent(
          GameEventType.politicalEvent,
          'Democracia Emergente',
          'A Sala do Conselho da voz ao povo.',
          isMajor: true,
        );
        break;
      case BuildingType.promotionHall:
        for (final npc in aliveNpcs.where(
          (n) => n.traits.contains(PersonalityTrait.leader),
        )) {
          npc.loyalty += 3;
        }
        _addEvent(
          GameEventType.politicalEvent,
          'Caminho para Grandeza',
          'Os ambiciosos planejam sua ascensao.',
        );
        break;
      case BuildingType.farm:
      case BuildingType.kitchen:
        if (citadel.resources.food < population * 5) {
          for (final npc in aliveNpcs) {
            npc.loyalty += 1;
          }
          _addEvent(
            GameEventType.celebration,
            'Comida Garantida',
            'A $action traz alivio a todos.',
            isMajor: true,
          );
        }
        break;
      case BuildingType.monument:
        citadel.resources.morale += 10;
        for (final npc in aliveNpcs) {
          npc.loyalty += 3;
          npc.fame += 1;
        }
        _addEvent(
          GameEventType.celebration,
          'MONUMENTO ERGUIDO!',
          'Um simbolo eterno da humanidade na Torre.',
          isMajor: true,
        );
        break;
      case BuildingType.nexus:
        _addEvent(
          GameEventType.discovery,
          'NEXUS ATIVADO!',
          'O Nexus pulsa. Segredos antigos comecam a se revelar...',
          isMajor: true,
        );
        break;
      default:
        if (_rng.nextDouble() < 0.4) {
          _addEvent(
            GameEventType.construction,
            'Progresso',
            'A $action traz satisfacao. A Cidadela cresce.',
          );
        }
    }
  }

  void migrateOldSave(Citadel citadel) {
    for (final building in citadel.buildings) {
      if (building.tier > 1 && building.inheritedBonus == 0) {
        final values = Building.levelValues[building.type];
        if (values != null && building.level > 1) {
          building.inheritedBonus +=
              values[(building.level - 1).clamp(0, values.length - 1)].round();
        }
        // Opcional: resetar nível para 1 se quiser
        // building.level = 1;
      }
    }
  }

  void _processFameGains() {
    for (final npc in aliveNpcs) {
      double gain = 0.0;

      // ✅ Verifica AMBOS os campos para garantir consistência:
      // um NPC é líder se leaderOfGroupId aponta para algum grupo
      // OU se o grupo em que está o lista como leaderId.
      final isLeader =
          npc.leaderOfGroupId != null ||
          (npc.groupId != null &&
              groups.any((g) => g.id == npc.groupId && g.leaderId == npc.id));

      if (isLeader) gain += 0.8;
      if (citadel.hasBuilding(BuildingType.monument)) gain += 0.4;
      if (citadel.hasBuilding(BuildingType.tavern)) gain += 0.3;
      if (npc.daysSurvived > 100) gain += 0.2;

      if (gain > 0) npc.gainFame(gain);
    }
  }

  // ─────────────────────────────────────────────
  // ARENA & TAVERNA
  // ─────────────────────────────────────────────

  void _processArenaEvents() {
    if (!citadel.hasBuilding(BuildingType.arena)) return;
    if (state.currentDay % 7 != 0 || aliveNpcs.length < 2) return;
    if (_rng.nextDouble() >= 0.3) return;
    final fighters = aliveNpcs
        .where(
          (n) =>
              n.attributes.mentalStability > 30 &&
              n.attributes.combatPower > 3.0,
        )
        .toList();
    if (fighters.length < 2) return;
    fighters.shuffle(_rng);
    final a = fighters[0], b = fighters[1];

    // Nível da arena escala os ganhos de fama e stats
    final arenaLevel = citadel.getBuilding(BuildingType.arena)?.level ?? 1;
    final fameMult = arenaLevel; // nível 1: +2 fama, nível 5: +10 fama

    final aWins =
        a.attributes.combatPower + _rng.nextDouble() * 3 >
        b.attributes.combatPower + _rng.nextDouble() * 3;
    final winner = aWins ? a : b;
    final loser = aWins ? b : a;

    // Vencedor: fama escalonada + stat
    final fameGain = (2 * fameMult).toDouble();
    winner.fame += fameGain;
    winner.attributes.strength += 0.1 + (arenaLevel * 0.1);

    // Perdedor: perde fama (metade do ganho do vencedor) + consolação de endurance
    final fameLoss = (fameGain / 2).ceil().toDouble();
    loser.fame = (loser.fame - fameLoss).clamp(-999, 9999);
    loser.attributes.endurance += 0.05;

    _addEvent(
      GameEventType.combat,
      'Duelo na Arena',
      '${winner.name} venceu ${loser.name}! +${fameGain.toInt()} fama. '
          '${loser.name} perdeu ${fameLoss.toInt()} fama.',
      involvedIds: [a.id, b.id],
    );

    // Atualiza contadores dedicados da arena
    winner.arenaWins += 1;
    loser.arenaLosses += 1;

    // Títulos por marco de vitórias na arena
    final wins = winner.arenaWins;
    if (wins == 5 || wins == 10 || wins == 20 || wins == 30) {
      final titulo = wins >= 30
          ? 'Imortal da Arena'
          : wins >= 20
          ? 'Campeão Lendário'
          : wins >= 10
          ? 'Campeão da Arena'
          : 'Lutador Destaque';
      _records.add(
        CitadelRecord(
          id: 'rec_arena_${winner.id}_${state.currentDay}',
          day: state.currentDay,
          category: RecordCategory.honor,
          title: '$titulo: ${winner.name}',
          body:
              '${winner.name} alcançou $wins vitórias na Arena. '
              'A multidão clama o nome. A fama precede os passos.',
          involvedIds: [winner.id],
          isSigned: true,
        ),
      );
    }

    // Moral passiva de Lendários e Imortais (+1/dia aplicado aqui como bônus do duelo)
    for (final npc in aliveNpcs) {
      if (npc.arenaWins >= 20) {
        citadel.resources.morale = (citadel.resources.morale + 1).clamp(0, 100);
      }
    }
  }

  /// Duelo manual disparado pelo jogador. Retorna mensagem de resultado ou erro.
  String runArenaChallenge(String idA, String idB) {
    if (!citadel.hasBuilding(BuildingType.arena))
      return 'Arena não construída.';
    final arenaLevel = citadel.getBuilding(BuildingType.arena)?.level ?? 1;
    final foodCost = 5 + (arenaLevel * 5); // nível 1: 10, nível 5: 30

    final idxA = npcs.indexWhere((n) => n.id == idA);
    final idxB = npcs.indexWhere((n) => n.id == idB);
    if (idxA == -1 || idxB == -1) return 'Habitante não encontrado.';

    final a = npcs[idxA], b = npcs[idxB];
    if (!a.alive || !b.alive) return 'Um dos combatentes está morto.';

    final cooldown = 3;
    if (state.currentDay - a.lastArenaChallengeDay < cooldown ||
        state.currentDay - b.lastArenaChallengeDay < cooldown) {
      return 'Um dos combatentes ainda está em recuperação (cooldown de $cooldown dias).';
    }
    if (citadel.resources.food < foodCost) {
      return 'Comida insuficiente. Custo: $foodCost.';
    }

    citadel.resources.food -= foodCost.toDouble();
    a.lastArenaChallengeDay = state.currentDay;
    b.lastArenaChallengeDay = state.currentDay;

    final aWins =
        a.attributes.combatPower + _rng.nextDouble() * 3 >
        b.attributes.combatPower + _rng.nextDouble() * 3;
    final winner = aWins ? a : b;
    final loser = aWins ? b : a;

    final fameMult = arenaLevel;
    final fameGain = (2 * fameMult).toDouble();
    winner.fame += fameGain;
    winner.arenaWins += 1;
    winner.attributes.strength += 0.1 + (arenaLevel * 0.1);
    final fameLoss = (fameGain / 2).ceil().toDouble();
    loser.fame = (loser.fame - fameLoss).clamp(-999, 9999);
    loser.arenaLosses += 1;
    loser.attributes.endurance += 0.05;

    _addEvent(
      GameEventType.combat,
      'Desafio na Arena',
      '${winner.name} venceu ${loser.name} num desafio! '
          '+${fameGain.toInt()} fama. Custo: $foodCost comida.',
      involvedIds: [idA, idB],
    );

    return '${winner.name} venceu ${loser.name}! +${fameGain.toInt()} fama.';
  }

  void _processTavernEvents() {
    if (!citadel.hasBuilding(BuildingType.tavern) ||
        state.currentDay % 5 != 0) {
      return;
    }
    double baseChance = 0.1;
    if (citadel.hasBuilding(BuildingType.watchtower)) baseChance += 0.15;
    if (_rng.nextDouble() < baseChance) {
      final hidden = aliveNpcs
          .where((n) => n.origin.isDarkOrigin && !n.isSuspicious)
          .toList();
      if (hidden.isNotEmpty) {
        final npc = hidden[_rng.nextInt(hidden.length)];
        final npcIndex = npcs.indexWhere((n) => n.id == npc.id);
        if (npcIndex != -1) {
          npcs[npcIndex] = npcs[npcIndex].copyWith(isSuspicious: true);
        }
        _addEvent(
          GameEventType.system,
          'Boato na Taverna',
          '${npc.name} tem passado questionavel...',
          involvedIds: [npc.id],
        );
      }
      // Rumor expõe um crime oculto de algum NPC suspeito
      final suspects = aliveNpcs.where((n) => n.isSuspicious).toList();
      if (suspects.isNotEmpty) {
        final suspect = suspects[_rng.nextInt(suspects.length)];
        final exposed = _prisonService.spreadRumor(suspect.id, _rng);
        if (exposed != null) {
          _addEvent(
            GameEventType.system,
            'Rumor Expõe Crime!',
            'Fofocas na taverna revelam: ${suspect.name} pode ter cometido '
                '${exposed.type.label}${exposed.witnessed ? " — EVIDENCIA CONFIRMADA!" : " (ainda sem prova concreta)."}',
            involvedIds: [suspect.id],
            isMajor: exposed.witnessed,
          );
          // Abre julgamento automático se threshold atingido
          if (_prisonService.shouldOpenTrial(suspect.id)) {
            final (result, trial) = _prisonService.openTrial(
              npcId: suspect.id,
              allNpcs: npcs,
              citadel: citadel,
              currentDay: state.currentDay,
              rng: _rng,
            );
            if (result == ArrestResult.trialOpened && trial != null) {
              _addEvent(
                GameEventType.politicalEvent,
                'JULGAMENTO ABERTO: ${suspect.name}',
                'Os rumores da taverna acumularam evidencias suficientes. '
                    'O conselho foi convocado para julgar ${suspect.name} '
                    'por ${trial.primaryCrime.label}.',
                involvedIds: [suspect.id, ...trial.jurorIds],
                isMajor: true,
              );
            }
          }
        }
      }
    }

    if (_rng.nextDouble() < 0.2 && aliveNpcs.length >= 2) {
      final a = aliveNpcs[_rng.nextInt(aliveNpcs.length)];
      final b = _pickOther(aliveNpcs, a);
      final relIndex = a.relationships.indexWhere((r) => r.targetId == b.id);
      if (relIndex != -1) {
        a.relationships[relIndex] = a.relationships[relIndex].copyWith(
          affinity: a.relationships[relIndex].affinity + 0.1,
        );
      }
    }
  }

  /// FAMA & AUTO-FORMAÇÃO DE GRUPOS
  void _autonomousGroupFormation() {
    if (aliveNpcs.length < 4) return;

    // ✅ NÃO captura ungrouped antes do loop — reavalia sempre via getter
    List<Npc> ungrouped() => aliveNpcs.where((n) => n.groupId == null).toList();

    if (ungrouped().length < 3) return;

    // 1. Famosos atraem seguidores
    final famous = ungrouped().where((n) => n.isFamous).toList()
      ..sort((a, b) => b.fame.compareTo(a.fame));

    for (final leader in famous) {
      // ✅ Reavalia groupId do líder a cada iteração
      if (leader.groupId != null) continue;

      final potentialFollowers = ungrouped()
          .where((n) => n.id != leader.id)
          .where((n) => _synergyScore(leader, n) >= 68)
          .take(5)
          .toList();

      if (potentialFollowers.length >= 2) {
        final allMembers = [leader.id, ...potentialFollowers.map((f) => f.id)];

        final group = createGroup(
          "${leader.name}'s ${leader.profession == Profession.explorer ? 'Expedição' : 'Equipe'}",
          allMembers,
          _roleFromLeader(leader),
        );

        leader.leaderOfGroupId = group.id;
        // ✅ Sincroniza group.leaderId com leaderOfGroupId do NPC
        group.leaderId = leader.id;
        leader.gainFame(4.0);

        _addEvent(
          GameEventType.groupFormed,
          'Líder Carismático!',
          '${leader.name} (${leader.fame.toStringAsFixed(0)} fama) formou o grupo "${group.name}" '
              'com ${potentialFollowers.length} seguidores espontâneos!',
          involvedIds: allMembers,
          isMajor: true,
        );
      }
    }

    // 2. Formação espontânea com lista atualizada
    // ✅ Passa a lista reavaliada, não a capturada antes do loop
    _formSpontaneousGroups(ungrouped());
  }

  GroupRole _roleFromLeader(Npc leader) {
    // ✅ guard → assault (combate direto)
    if (leader.profession == Profession.guard) {
      return GroupRole.assault;
    }
    // ✅ explorer e scout → recon (exploração e reconhecimento)
    if (leader.profession == Profession.explorer ||
        leader.profession == Profession.scout) {
      return GroupRole.recon;
    }
    return GroupRole.general;
  }

  void _formSpontaneousGroups(List<Npc> initial) {
    // ✅ Filtra logo na entrada para garantir que só processa sem grupo
    final remaining = initial.where((n) => n.groupId == null).toList();
    if (remaining.length < 3) return;

    final rng = Random(state.currentDay * 141);

    while (remaining.length >= 3 && rng.nextDouble() < 0.45) {
      remaining.shuffle();

      // ✅ Refiltra antes de pegar membros (alguém pode ter sido adicionado
      //    a um grupo por outra iteração deste loop)
      final available = remaining.where((n) => n.groupId == null).toList();
      if (available.length < 3) break;

      final size = rng.nextInt(3) + 3; // 3 a 5 pessoas
      final members = available.take(size).toList();

      // ✅ Remove os selecionados da lista remaining imediatamente
      remaining.removeWhere((n) => members.any((m) => m.id == n.id));

      final leader = members.reduce(
        (a, b) =>
            (a.attributes.charisma + a.fame) > (b.attributes.charisma + b.fame)
            ? a
            : b,
      );

      final group = createGroup(
        "Equipe ${leader.name.split(' ').first}",
        members.map((n) => n.id).toList(),
        _roleFromLeader(leader),
      );

      leader.leaderOfGroupId = group.id;
      // ✅ Sincroniza leaderId no grupo
      group.leaderId = leader.id;

      _addEvent(
        GameEventType.groupFormed,
        'Grupo Espontâneo',
        '${members.length} NPCs formaram "${group.name}" por afinidade natural.',
        involvedIds: members.map((n) => n.id).toList(),
      );
    }
  }
  // ─────────────────────────────────────────────
  // COMBATE NA TORRE
  // ─────────────────────────────────────────────

  TowerChallenge attemptFloor(List<String> partyIds) {
    final floor = nextFloor;
    if (floor == null) {
      return TowerChallenge(
        floor: floors.last,
        partyIds: partyIds,
        completed: true,
        victory: false,
        log: ['Não há mais andares para explorar.'],
      );
    }

    final party = _resolveParty(partyIds);
    if (party.any((n) => _isGroupBusyOnQuest(n.groupId))) {
      return TowerChallenge(
        floor: floor,
        partyIds: partyIds,
        completed: true,
        victory: false,
        log: ['Grupo está em missão ativa e não pode explorar a Torre.'],
      );
    }
    final challenge = TowerChallenge(floor: floor, partyIds: partyIds);
    final costPerNpc = expeditionCostPerNpc(floor.number);
    final totalCost = party.length * costPerNpc;
    citadel.resources.food -= totalCost;

    challenge.log.addAll([
      '=== ANDAR ${floor.number}: ${floor.type.label.toUpperCase()} ===',
      floor.description,
      if (floor.specialCondition.isNotEmpty)
        '> Condicao: ${floor.specialCondition}',
      'Custo: ${totalCost.toStringAsFixed(0)} comida (${costPerNpc.toStringAsFixed(1)}/NPC x ${party.length})',
      '',
    ]);

    _applyExpeditionFatigue(party, floor.tier, baseFatigue: 20.0);

    // ── Regra do Andar ──────────────────────────────────────────
    final rule = floor.rule;
    List<Npc> effectiveParty = List.from(party);

    if (rule.type != FloorRuleType.none) {
      challenge.log.addAll([
        '⚖ REGRA: ${rule.description}',
        '  → ${rule.mechanicHint}',
        '',
      ]);
    }

    // soloEntry: apenas o NPC mais forte entra
    if (rule.type == FloorRuleType.soloEntry && party.isNotEmpty) {
      effectiveParty = [
        party.reduce(
          (a, b) =>
              a.effectiveCombatPowerWithGear(_inventory) >=
                  b.effectiveCombatPowerWithGear(_inventory)
              ? a
              : b,
        ),
      ];
      challenge.log.add(
        '  ⚔ Apenas ${effectiveParty.first.name} entra. Os outros aguardam.',
      );
    }

    // tributeRequired: custo extra de comida
    if (rule.type == FloorRuleType.tributeRequired) {
      final tributeCost = totalCost * 0.5;
      citadel.resources.food -= tributeCost;
      challenge.log.add(
        '  💰 Tributo pago: ${tributeCost.toStringAsFixed(0)} comida adicional.',
      );
    }

    // ── Cálculo de Poder do Grupo ────────────────────────────────
    double partyPower = 0;
    for (final npc in effectiveParty) {
      double power;

      // intelligenceOnly: INT substitui combatPower
      if (rule.type == FloorRuleType.intelligenceOnly) {
        power = npc.attributes.intelligence * 1.5;
        // runeReader tem vantagem natural aqui
        if (npc.talentDiscovered &&
            npc.hiddenTalent == HiddenTalent.runeReader) {
          power *= 1.4;
        }
      } else {
        power = npc.effectiveCombatPowerWithGear(_inventory);
        if (npc.talentDiscovered &&
            npc.hiddenTalent == HiddenTalent.combatGenius) {
          power *= 1.5;
        }
      }

      if (npc.traits.contains(PersonalityTrait.brave)) power *= 1.1;
      if (npc.traits.contains(PersonalityTrait.coward)) power *= 0.85;

      // Modificadores por regra
      switch (rule.type) {
        case FloorRuleType.loyaltyTest:
          if (npc.loyalty < 40 ||
              npc.traits.contains(PersonalityTrait.treacherous) ||
              npc.origin.isDarkOrigin) {
            power *= 0.6;
            challenge.log.add(
              '  [⚖] ${npc.name}: lealdade baixa — −40% poder.',
            );
          } else if (npc.loyalty > 70 &&
              npc.traits.contains(PersonalityTrait.loyal)) {
            power *= 1.3;
            challenge.log.add('  [⚖] ${npc.name}: leal — +30% poder.');
          } else if (npc.loyalty > 60) {
            power *= 1.15;
          }
          break;

        case FloorRuleType.silenceRequired:
          if (npc.traits.contains(PersonalityTrait.aggressive)) {
            power *= 0.45;
            challenge.log.add('  [⚖] ${npc.name}: agressivo — −55% poder.');
          }
          break;

        default:
          break;
      }

      partyPower += power;
      challenge.log.add('  ${npc.name} [PWR: ${power.toStringAsFixed(1)}]');
    }

    // weakLeads: NPC mais fraco define o poder total
    if (rule.type == FloorRuleType.weakLeads && effectiveParty.isNotEmpty) {
      final weakestPower = effectiveParty
          .map((n) => n.effectiveCombatPowerWithGear(_inventory))
          .reduce(min);
      partyPower = weakestPower * effectiveParty.length * 0.75;
      challenge.log.add(
        '  [⚖] Mais fraco comanda. Poder efetivo: ${partyPower.toStringAsFixed(1)}',
      );
    }

    // mirrorRule: dificuldade escala com poder do grupo
    final effectiveDifficulty = rule.type == FloorRuleType.mirrorRule
        ? floor.scaledDifficulty + partyPower * 0.25
        : floor.scaledDifficulty;

    // tributeRequired: +10% chance de sucesso como compensação
    final tributeBonus = rule.type == FloorRuleType.tributeRequired ? 0.1 : 0.0;

    double successChance =
        ((partyPower / (effectiveDifficulty * effectiveParty.length) * 0.7) +
                0.1 +
                tributeBonus)
            .clamp(0.05, 0.95);

    double mortalityRate = floor.scaledMortality;

    final factionMods = _processFactionOnAttempt(floor, partyIds);
    successChance += factionMods.successChanceMod;
    mortalityRate += factionMods.mortalityMod;
    citadel.resources.food -= factionMods.foodTribute;

    final hasStrategist = effectiveParty.any(
      (n) => n.talentDiscovered && n.hiddenTalent == HiddenTalent.strategicMind,
    );

    mortalityRate = hasStrategist ? mortalityRate * 0.85 : mortalityRate;

    final infirmaryBonus = citadel.buildings
        .where((b) => b.type == BuildingType.infirmary)
        .fold(0.0, (sum, b) => sum + b.bonus);

    mortalityRate *= (1 - infirmaryBonus);

    challenge.log.addAll([
      '',
      'Poder total: ${partyPower.toStringAsFixed(1)} vs ${effectiveDifficulty.toStringAsFixed(1)}',
      'Chance de sucesso: ${(successChance * 100).toStringAsFixed(0)}%',
      '',
    ]);

    final success = _rng.nextDouble() < successChance;
    if (success) {
      // Passa effectiveParty para resolveVictory (soloEntry)
      _resolveVictoryWithParty(
        challenge,
        effectiveParty,
        party,
        floor,
        mortalityRate,
      );
    } else {
      _resolveDefeatWithParty(
        challenge,
        effectiveParty,
        party,
        floor,
        mortalityRate,
      );
    }

    if (effectiveParty.any(
      (n) =>
          n.alive &&
          n.talentDiscovered &&
          n.hiddenTalent == HiddenTalent.healingTouch,
    )) {
      for (final npc in effectiveParty.where((n) => n.alive)) {
        npc.attributes.endurance += 0.5;
        npc.attributes.mentalStability += 2;
      }
      challenge.log.addAll([
        '',
        '> Toque Curativo ativado: sobreviventes parcialmente curados.',
      ]);
    }

    challenge.completed = true;
    citadel.resources.morale = citadel.resources.morale.clamp(0, 100);
    return challenge;
  }

  // Wrapper para compatibilidade com soloEntry:
  // effectiveParty = quem realmente combateu
  // fullParty      = todos que foram mobilizados (para fatigue/morale)
  void _resolveVictoryWithParty(
    TowerChallenge challenge,
    List<Npc> effectiveParty,
    List<Npc> fullParty,
    TowerFloor floor,
    double mortality,
  ) {
    // Membros que ficaram fora (soloEntry) ganham pequeno bônus por esperar
    for (final npc in fullParty.where((n) => !effectiveParty.contains(n))) {
      npc.loyalty += 1;
    }
    _resolveVictory(challenge, effectiveParty, floor, mortality);
  }

  void _resolveDefeatWithParty(
    TowerChallenge challenge,
    List<Npc> effectiveParty,
    List<Npc> fullParty,
    TowerFloor floor,
    double mortality,
  ) {
    // Membros de fora ficam abalados mesmo sem entrar
    for (final npc in fullParty.where((n) => !effectiveParty.contains(n))) {
      npc.attributes.mentalStability -= 3;
    }
    _resolveDefeat(challenge, effectiveParty, floor, mortality);
  }

  void _resolveVictory(
    TowerChallenge challenge,
    List<Npc> party,
    TowerFloor floor,
    double mortality,
  ) {
    challenge.victory = true;
    challenge.moraleImpact = 5.0;
    challenge.log.add('>> VITÓRIA! O grupo superou o desafio.');

    for (final npc in party) {
      if (_rng.nextDouble() < mortality * 0.75) {
        _killNpc(npc, 'Morreu no Andar ${floor.number}');
        challenge.casualties.add(npc.id);
        challenge.log.add('  [X] ${npc.name} caiu em batalha.');
      } else {
        npc.floorsCleared++;
        npc.fame += 5 + floor.number;
        npc.loyalty += 3;
        npc.attributes.strength += 0.2;
        npc.attributes.endurance += 0.2;
        npc.attributes.mentalStability -= 2;
        npc.history.add(
          'Sobreviveu ao Andar ${floor.number} no Dia ${state.currentDay}',
        );
        challenge.log.add(
          '  [O] ${npc.name} sobreviveu. (+Fama, +Stats, +Lealdade)',
        );
      }
    }

    floor.cleared = true;
    floor.timesCleared++;
    state.highestFloorCleared = floor.number;
    if (floor.number > state.highestFloorReached) {
      state.highestFloorReached = floor.number;
    }

    _applyFloorRewards(floor);
    _addEvent(
      GameEventType.towerCleared,
      'Andar ${floor.number} Conquistado!',
      '${challenge.casualties.length} baixas. ${floor.reward}',
      involvedIds: challenge.partyIds,
      isMajor: true,
    );
  }

  void _resolveDefeat(
    TowerChallenge challenge,
    List<Npc> party,
    TowerFloor floor,
    double mortality,
  ) {
    challenge.victory = false;
    challenge.moraleImpact = -8.0;
    challenge.log.add('>> DERROTA. O grupo foi forçado a recuar.');

    for (final npc in party) {
      if (_rng.nextDouble() < mortality) {
        _killNpc(npc, 'Morreu no Andar ${floor.number}');
        challenge.casualties.add(npc.id);
        challenge.log.add('  [X] ${npc.name} não sobreviveu.');
      } else {
        npc.attributes.mentalStability -= 5;
        npc.attributes.endurance -= 0.3;
        npc.traumas.add('Derrota no Andar ${floor.number}');
        npc.loyalty -= 2;
        challenge.log.add('  [!] ${npc.name} escapou com ferimentos.');
      }
    }

    citadel.resources.morale -= 8;
    _addEvent(
      GameEventType.combat,
      'Derrota no Andar ${floor.number}',
      '${challenge.casualties.length} mortos. Sobreviventes voltaram abalados.',
      involvedIds: challenge.partyIds,
      isMajor: challenge.casualties.isNotEmpty,
    );
  }

  TowerChallenge trainOnFloor(int floorNumber, List<String> partyIds) {
    final floor = floors.firstWhere((f) => f.number == floorNumber);
    final party = _resolveParty(partyIds);
    final challenge = TowerChallenge(floor: floor, partyIds: partyIds);

    challenge.log.addAll(['=== TREINO: ANDAR ${floor.number} ===', '']);

    for (final npc in party) {
      final gain = 0.1 + _rng.nextDouble() * 0.3;
      _trainNpcOnFloor(npc, floor);
      challenge.log.add('  ${npc.name}: ${_gainDescription(gain, floor.type)}');
      npc.history.add(
        'Treinou no Andar ${floor.number} no Dia ${state.currentDay}',
      );
    }

    if (_rng.nextDouble() < 0.03) {
      final victim = party[_rng.nextInt(party.length)];
      victim.attributes.endurance -= 0.5;
      challenge.log.addAll(['', '  [!] ${victim.name} sofreu ferimento leve.']);
    }

    if (_rng.nextDouble() < 0.04 + (floor.timesReexplored * 0.01)) {
      challenge.log.addAll(['', '  [!!] Ameaça oculta reativada!']);
      final victim = party[_rng.nextInt(party.length)];
      if (_rng.nextDouble() < 0.15) {
        _killNpc(
          victim,
          'Morreu em ameaça durante treino no Andar ${floor.number}',
        );
        challenge.casualties.add(victim.id);
        challenge.log.add('  [X] ${victim.name} não sobreviveu!');
      } else {
        victim.attributes.endurance -= 1;
        victim.attributes.mentalStability -= 5;
        challenge.log.add('  [!] ${victim.name} foi ferido, mas sobreviveu.');
      }
    }

    if (_rng.nextDouble() < 0.05) {
      citadel.resources.knowledge += 5;
      challenge.log.addAll(['', '  [*] Descoberta rara! +5 conhecimento.']);
    }

    challenge.completed = true;
    challenge.victory = true;
    citadel.resources.food -= party.length * 2;

    _addEvent(
      GameEventType.training,
      'Treino no Andar ${floor.number}',
      '${party.length} membros treinaram. Custo: ${party.length * 2} comida.',
      involvedIds: partyIds,
    );

    return challenge;
  }

  String _gainDescription(double gain, FloorType type) {
    switch (type) {
      case FloorType.combat:
        return '+${gain.toStringAsFixed(2)} FOR';
      case FloorType.strategic:
        return '+${gain.toStringAsFixed(2)} INT';
      case FloorType.survival:
        return '+${gain.toStringAsFixed(2)} RES';
      case FloorType.moral:
        return '+${(gain * 5).toStringAsFixed(1)} EST.MENTAL';
      default:
        return 'Stats gerais melhorados';
    }
  }

  // ─────────────────────────────────────────────
  // EQUIPAMENTOS [FASE 1]
  // ─────────────────────────────────────────────

  /// Equipa um item em um NPC
  EquipResult equipItem(String npcId, String equipmentId) {
    return _equipmentService.equip(
      npcId: npcId,
      equipmentId: equipmentId,
      npcs: npcs,
      inventory: _inventory,
    );
  }

  /// Desequipa o slot indicado de um NPC
  UnequipResult unequipItem(String npcId, EquipmentSlot slot) {
    return _equipmentService.unequip(
      npcId: npcId,
      slot: slot,
      npcs: npcs,
      inventory: _inventory,
    );
  }

  /// Crafta um equipamento na Forja
  (CraftResult, Equipment?) craftEquipment(
    EquipmentSlot slot,
    EquipmentRarity rarity,
  ) {
    final (result, eq) = _equipmentService.craft(
      slot: slot,
      rarity: rarity,
      citadel: citadel,
      currentDay: state.currentDay,
    );
    if (result == CraftResult.success && eq != null) {
      _inventory.add(eq);
      _addEvent(
        GameEventType.discovery,
        'Item Craftado!',
        '${eq.name} — ${eq.bonusSummary}',
      );
    }
    return (result, eq);
  }

  /// Equipamentos disponíveis para um slot específico (não equipados)
  List<Equipment> availableEquipmentForSlot(EquipmentSlot slot) =>
      _equipmentService.availableForSlot(slot, _inventory);

  /// Equipamentos atualmente equipados em um NPC
  List<Equipment> equippedOn(String npcId) =>
      _equipmentService.equippedOn(npcId, _inventory);

  /// Verifica se há recursos para craftar na raridade indicada
  bool canCraftEquipment(EquipmentRarity rarity) =>
      _equipmentService.canCraft(rarity, citadel.resources);

  /// Drop de equipamento ao conquistar andar [chamado em _applyFloorRewards]
  void _rollEquipmentDrop(int floorNumber, int tier) {
    final dropped = _equipmentService.rollDrop(
      floorNumber: floorNumber,
      tier: tier,
      currentDay: state.currentDay,
    );
    if (dropped == null) return;

    _inventory.add(dropped);

    final isMajor = dropped.rarity.index >= EquipmentRarity.epic.index;
    _addEvent(
      GameEventType.discovery,
      'Item Encontrado!',
      '[${dropped.rarity.label}] ${dropped.name} — ${dropped.bonusSummary}',
      isMajor: isMajor,
    );
  }

  /// Auto-equipamento: NPCs equipam automaticamente o melhor item disponível
  void autoEquipAllNpcs() {
    for (final npc in aliveNpcs) {
      for (final slot in EquipmentSlot.values) {
        // Se já está equipado, pula
        if (npc.hasEquipment(slot)) continue;
        // Filtra itens disponíveis para o slot
        final available = _inventory
            .where((e) => e.slot == slot && !e.isEquipped)
            .toList();
        if (available.isEmpty) continue;
        // Seleciona o melhor item (maior raridade, depois maior bônus principal)
        available.sort((a, b) {
          final rarityDiff = b.rarity.index.compareTo(a.rarity.index);
          if (rarityDiff != 0) return rarityDiff;
          // Prioriza bônus principal conforme profissão
          final mainStat = _mainStatForProfession(npc.profession, slot);
          final bonusA = a.statBonus[mainStat] ?? 0;
          final bonusB = b.statBonus[mainStat] ?? 0;
          return bonusB.compareTo(bonusA);
        });
        final best = available.first;
        equipItem(npc.id, best.id);
      }
    }
  }

  /// Retorna o atributo principal para a profissão e slot
  String _mainStatForProfession(Profession prof, EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.weapon:
        return switch (prof) {
          Profession.guard => 'strength',
          Profession.explorer => 'agility',
          Profession.scribe => 'intelligence',
          Profession.trainer => 'strength',
          Profession.scout => 'agility',
          Profession.teacher => 'intelligence',
          Profession.farmer => 'endurance',
          Profession.builder => 'strength',
          _ => 'strength',
        };
      case EquipmentSlot.armor:
        return 'endurance';
      case EquipmentSlot.accessory:
        return 'luck';
    }
  }

  // ─────────────────────────────────────────────
  // GRUPOS
  // ─────────────────────────────────────────────

  NpcGroup createGroup(String name, List<String> memberIds, GroupRole role) {
    final group = NpcGroup(
      id: _nextGroupId(),
      name: name,
      memberIds: memberIds,
      role: role,
    );

    if (memberIds.isNotEmpty) {
      final members = memberIds
          .map((id) => npcs.firstWhereOrNull((n) => n.id == id))
          .whereType<Npc>()
          .toList();
      members.sort(
        (a, b) => (b.attributes.combatPower + b.attributes.charisma).compareTo(
          a.attributes.combatPower + a.attributes.charisma,
        ),
      );
      if (members.isNotEmpty) group.leaderId = members.first.id;
    }

    for (final id in memberIds) {
      npcs.firstWhereOrNull((n) => n.id == id)?.groupId = group.id;
    }
    groups.add(group);

    final leaderName = group.leaderId != null
        ? npcs.firstWhere((n) => n.id == group.leaderId).name
        : '?';
    _addEvent(
      GameEventType.groupFormed,
      'Grupo "${group.name}" Formado',
      '${memberIds.length} membros em "${group.name}" (${role.label}). Lider: $leaderName.',
      involvedIds: memberIds,
      isMajor: true,
    );

    return group;
  }

  void disbandGroup(String groupId) {
    final group = groups.firstWhereOrNull((g) => g.id == groupId);
    if (group == null) return;
    for (final id in group.memberIds) {
      npcs.firstWhereOrNull((n) => n.id == id)?.groupId = null;
    }
    _addEvent(
      GameEventType.groupDissolved,
      'Grupo "${group.name}" Dissolvido',
      'Membros estao livres.',
      involvedIds: group.memberIds,
    );
    groups.remove(group);
  }

  void addToGroup(String groupId, String npcId) {
    final group = groups.firstWhereOrNull((g) => g.id == groupId);
    final npc = npcs.firstWhereOrNull((n) => n.id == npcId);
    if (group == null || npc == null) return;
    if (npc.groupId != null) {
      groups
          .firstWhereOrNull((g) => g.id == npc.groupId)
          ?.memberIds
          .remove(npcId);
    }
    group.memberIds.add(npcId);
    npc.groupId = groupId;
  }

  void removeFromGroup(String npcId) {
    final npc = npcs.firstWhereOrNull((n) => n.id == npcId);
    if (npc?.groupId == null) return;
    groups
        .firstWhereOrNull((g) => g.id == npc!.groupId)
        ?.memberIds
        .remove(npcId);
    npc!.groupId = null;
  }

  void assignProfession(String npcId, Profession profession) {
    final npc = npcs.firstWhere((n) => n.id == npcId);
    npc.history.add(
      'Profissao: ${npc.profession.label} → ${profession.label} (Dia ${state.currentDay})',
    );
    npc.profession = profession;
  }

  // ─────────────────────────────────────────────
  // RECOMPENSAS DE ANDAR
  // ─────────────────────────────────────────────

  void _applyFloorRewards(TowerFloor floor) {
    final tier = floor.tier;
    final n = floor.number;
    final res = citadel.resources;
    final mult = tier.toDouble();

    if (n % 10 == 0) {
      res.food += 30 * mult;
      res.wood += 30 * mult;
      res.stone += 30 * mult;
      res.iron += 25 * mult;
      res.knowledge += 25 * mult;
      res.morale += (10 + tier * 2).toDouble();

      if (tier >= 5) {
        for (final npc in aliveNpcs.where(
          (n) => !n.talentDiscovered && n.hiddenTalent != HiddenTalent.none,
        )) {
          if (_rng.nextDouble() < 0.4) {
            npc.talentDiscovered = true;
            _addEvent(
              GameEventType.discovery,
              'Talento Revelado!',
              '${npc.name} despertou ${npc.hiddenTalent.label}!',
              involvedIds: [npc.id],
              isMajor: true,
            );
          }
        }
      }
      _addEvent(
        GameEventType.towerCleared,
        'BOSS TIER $tier DERROTADO!',
        'Recompensas massivas! A cidadela evolui!',
        isMajor: true,
      );
      _rollEquipmentDrop(n, tier); // ← [FASE 1] drop garantido em boss
      return;
    }

    if (n % 5 == 0) {
      final m = tier * 0.7;
      res.food += 15 * m;
      res.wood += 10 * m;
      res.stone += 10 * m;
      res.iron += 10 * m;
      res.knowledge += 15 * m;
      res.morale += 5;
      _rollEquipmentDrop(n, tier); // ← [FASE 1] drop em elite
      return;
    }

    final base = 1.0 + (tier - 1) * 0.5;
    switch (floor.type) {
      case FloorType.combat:
      case FloorType.gauntlet:
        res.iron += 5 * base;
        res.stone += 3 * base;
        break;
      case FloorType.survival:
      case FloorType.hunt:
        res.food += 8 * base;
        res.wood += 5 * base;
        break;
      case FloorType.strategic:
      case FloorType.puzzle:
        res.knowledge += 6 * base;
        res.iron += 3 * base;
        break;
      case FloorType.moral:
        res.knowledge += 5 * base;
        res.morale += 3;
        break;
      case FloorType.mystery:
        res.knowledge += 8 * base;
        _tryRevealTalentFromMystery();
        break;
      case FloorType.elite:
        res.food += 4 * base;
        res.wood += 4 * base;
        res.stone += 4 * base;
        res.iron += 4 * base;
        res.knowledge += 4 * base;
        break;
      default:
        break;
    }
    res.morale += 1 + tier * 0.5;
    _rollEquipmentDrop(n, tier); // ← [FASE 1] drop em andar normal
  }

  void _tryRevealTalentFromMystery() {
    if (_rng.nextDouble() >= 0.15) return;
    final candidates = aliveNpcs
        .where(
          (n) => !n.talentDiscovered && n.hiddenTalent != HiddenTalent.none,
        )
        .toList();
    if (candidates.isEmpty) return;
    final lucky = candidates[_rng.nextInt(candidates.length)];
    lucky.talentDiscovered = true;
    _addEvent(
      GameEventType.discovery,
      'Talento Oculto!',
      '${lucky.name} descobriu ${lucky.hiddenTalent.label}!',
      involvedIds: [lucky.id],
      isMajor: true,
    );
  }

  // ─────────────────────────────────────────────
  // MORTE
  // ─────────────────────────────────────────────

  void _killNpc(Npc npc, String cause) {
    npc.alive = false;
    npc.history.add('Morreu: $cause (Dia ${state.currentDay})');
    state.totalDeaths++;

    // ── Desequipa ao morrer [FASE 1] ──────────
    _equipmentService.unequipAll(
      npcId: npc.id,
      npcs: npcs,
      inventory: _inventory,
    );

    if (npc.groupId != null) {
      final group = groups.firstWhereOrNull((g) => g.id == npc.groupId);
      if (group != null) {
        group.memberIds.remove(npc.id);
        group.casualties++;
        if (group.leaderId == npc.id && group.memberIds.isNotEmpty) {
          final remaining =
              group.memberIds
                  .map(
                    (id) => npcs.firstWhereOrNull((n) => n.id == id && n.alive),
                  )
                  .whereType<Npc>()
                  .toList()
                ..sort(
                  (a, b) => b.attributes.combatPower.compareTo(
                    a.attributes.combatPower,
                  ),
                );
          if (remaining.isNotEmpty) group.leaderId = remaining.first.id;
        }
      }
    }

    if (npc.partnerId != null) {
      final partner = npcs.firstWhereOrNull((n) => n.id == npc.partnerId);
      if (partner != null) {
        partner.attributes.mentalStability -= 15;
        partner.traumas.add('Perda de ${npc.name} no dia ${state.currentDay}');
        partner.partnerId = null;
        partner.loyalty -= 5;
      }
    }

    for (final childId in npc.childrenIds) {
      final child = npcs.firstWhereOrNull((n) => n.id == childId && n.alive);
      if (child != null) {
        child.attributes.mentalStability -= 10;
        child.traumas.add(
          'Orfao - ${npc.name} morreu no dia ${state.currentDay}',
        );
      }
    }

    for (final other in aliveNpcs) {
      final rel = other.relationships.firstWhereOrNull(
        (r) => r.targetId == npc.id,
      );
      if (rel != null && rel.affinity > 0.3) {
        other.attributes.mentalStability -= 3;
      }
    }

    citadel.resources.morale -= 5;

    if (npc.fame > 20) {
      _addEvent(
        GameEventType.death,
        'Queda de ${npc.name}',
        '${npc.name} (${npc.origin.label}, G${npc.generation}) morreu. $cause. Fama: ${npc.fame.toStringAsFixed(0)}.',
        involvedIds: [npc.id],
        isMajor: true,
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  ({double power, double intel, double fame, double luck}) _calcPartyStats(
    List<Npc> party,
  ) {
    if (party.isEmpty) return (power: 0.0, intel: 0.0, fame: 0.0, luck: 0.0);
    final len = party.length.toDouble();
    return (
      power: party.fold(0.0, (s, n) => s + n.attributes.combatPower) / len,
      intel: party.fold(0.0, (s, n) => s + n.attributes.intelligence) / len,
      fame: party.fold(0.0, (s, n) => s + n.fame) / len,
      luck: party.fold(0.0, (s, n) => s + n.attributes.luck) / len,
    );
  }

  double _averagePartyPower() => _calcPartyStats(aliveNpcs).power;

  int _countProfession(Profession p) =>
      aliveNpcs.where((n) => n.profession == p).length;

  bool _isGroupBusyOnQuest(String? groupId) {
    if (groupId == null) return false;
    return _questService.busyGroupIds.contains(groupId);
  }

  bool _hasLivingPartner(Npc npc) =>
      npc.partnerId != null &&
      npcs.any((n) => n.id == npc.partnerId && n.alive);
  Npc _pickOther(List<Npc> list, Npc exclude) {
    Npc other;
    do {
      other = list[_rng.nextInt(list.length)];
    } while (other.id == exclude.id);
    return other;
  }

  List<Npc> _resolveParty(List<String> ids) => ids
      .map((id) => npcs.firstWhereOrNull((n) => n.id == id && n.alive))
      .whereType<Npc>()
      .toList();
  double _avg(List<Npc> npcs, double Function(Npc) selector) {
    if (npcs.isEmpty) return 0.0;
    return npcs.map(selector).reduce((a, b) => a + b) / npcs.length;
  }

  void _applyExpeditionFatigue(
    List<Npc> party,
    int tier, {
    required double baseFatigue,
  }) {
    for (final npc in party) {
      final fatigue = baseFatigue + tier * 1.5;
      if (npc.lastExpeditionDay == state.currentDay) {
        npc.consecutiveExpeditions++;
        npc.fatigue =
            (npc.fatigue + fatigue + 10 + npc.consecutiveExpeditions * 2).clamp(
              0,
              100,
            );
      } else {
        npc.consecutiveExpeditions = 1;
        npc.fatigue = (npc.fatigue + fatigue).clamp(0, 100);
      }
      npc.lastExpeditionDay = state.currentDay;
    }
  }

  void _addEvent(
    GameEventType type,
    String title,
    String description, {
    List<String>? involvedIds,
    bool isMajor = false,
  }) {
    final event = GameEvent(
      id: state.generateEventId(),
      day: state.currentDay,
      type: type,
      title: title,
      description: description,
      involvedNpcIds: involvedIds ?? [],
      isMajor: isMajor,
    );
    events.add(event);
    _dayEvents.add(event);
    // Pruning: mantém apenas os últimos 200 eventos brutos
    if (events.length > _maxRawEvents) {
      events.removeRange(0, events.length - _maxRawEvents);
    }
    // Gera CitadelRecord para eventos relevantes
    _maybeCreateRecord(event);

    ToastController().show(event);
    if (isCrisisEvent(event)) {
      CrisisFlagService.instance.writePending(event);
    }
  }

  void _maybeCreateRecord(GameEvent event) {
    RecordCategory? cat;
    String? verdict;
    bool signed = false;
    switch (event.type) {
      case GameEventType.death:
        cat = RecordCategory.death;
        signed = event.isMajor;
        break;

      case GameEventType.birth:
        if (event.title.contains('Maior') ||
            event.title.contains('Novo Membro')) {
          cat = RecordCategory.birth;
          signed = true;
        }
        break;

      case GameEventType.betrayalAttempt:
        cat = RecordCategory.crime;
        verdict = event.title.contains('ASSASSINATO')
            ? 'Assassinato confirmado. Individuo considerado perigo publico.'
            : event.title.contains('Roubo')
            ? 'Roubo de suprimentos. Penalidade a ser determinada.'
            : event.title.contains('Sabotagem')
            ? 'Sabotagem intencional. Investigar cumplices.'
            : 'Tentativa criminosa registrada.';
        signed = true;
        break;

      case GameEventType.betrayal:
        if (event.title.contains('Rebeliao')) {
          cat = RecordCategory.crime;
          verdict = 'Rebeliao violenta. Restricao de acesso temporaria.';
          signed = true;
        }
        break;

      case GameEventType.recruitment:
        cat = RecordCategory.honor; // ou uma categoria específica
        signed = true;
        break;

      case GameEventType.construction:
        cat = RecordCategory.construction;
        signed = false;
        break;

      case GameEventType.upgrade:
        if (event.isMajor) {
          cat = RecordCategory.construction;
          signed = true;
        }
        break;

      case GameEventType.towerCleared:
        cat = RecordCategory.towerConquest;
        signed = true;
        break;

      case GameEventType.politicalEvent:
        if (event.isMajor ||
            event.title.contains('Democracia') ||
            event.title.contains('Decreto') ||
            event.title.contains('Divisao') ||
            event.title.contains('Divisão')) {
          cat = RecordCategory.political;
          signed = event.isMajor;
        }
        break;

      case GameEventType.discovery:
        if (event.isMajor && event.title.contains('Lore')) {
          cat = RecordCategory.lore;
          signed = false;
        } else if (event.title.contains('Talento')) {
          cat = RecordCategory.honor;
          signed = true;
        }
        break;

      case GameEventType.warEvent:
        if (event.isMajor) {
          cat = RecordCategory.war;
          signed = true;
        }
        break;

      case GameEventType.mentalBreak:
        if (event.title.contains('Sacrificio') ||
            event.title.contains('Colapso')) {
          cat = RecordCategory.punishment;
          verdict = 'Individuo necessita de acompanhamento medico.';
          signed = false;
        }
        break;

      case GameEventType.crisis:
        if (event.isMajor) {
          cat = RecordCategory.decree;
          signed = false;
        }
        break;

      default:
        break;
    }

    if (cat == null) return;

    _recordIdCounter++;
    _records.add(
      CitadelRecord(
        id: 'rec_$_recordIdCounter',
        day: state.currentDay,
        category: cat,
        title: event.title,
        body: event.description,
        involvedIds: event.involvedNpcIds,
        isSigned: signed,
        verdict: verdict,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SERIALIZAÇÃO
  // ─────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'state': state.toJson(),
    'npcs': npcs.map((n) => n.toJson()).toList(),
    'citadel': citadel.toJson(),
    'floors': floors.map((f) => f.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'groups': groups.map((g) => g.toJson()).toList(),
    'trainingSuggestions': trainingSuggestions.map((s) => s.toJson()).toList(),
    'groupIdCounter': _groupIdCounter,
    'suggestionIdCounter': _suggestionIdCounter,
    // ── Equipamentos [FASE 1] ──
    'inventory': _inventory.map((e) => e.toJson()).toList(),
    // ── Registros Oficiais ──
    'records': _records.map((r) => r.toJson()).toList(),
    'recordIdCounter': _recordIdCounter,
    // ── Prisão ──
    'prison': _prisonService.toJson(),
    'activeTrainings': activeTrainings.map((m) => m.toJson()).toList(),
    'trainingMissionCounter': _trainingMissionCounter,
    'pendingRecruits': _pendingRecruits.map((r) => r.toJson()).toList(),
    // ── Novos serviços ──
    'factionService': _factionService.toJson(),
    'warService': _warService.toJson(),
    'tradeService': _tradeService.toJson(),
    'questService': _questService.toJson(),
  };

  void loadFromJson(Map<String, dynamic> json) {
    state = GameState.fromJson(json['state'] as Map<String, dynamic>);
    npcs = (json['npcs'] as List)
        .map((n) => Npc.fromJson(n as Map<String, dynamic>))
        .toList();
    citadel = Citadel.fromJson(json['citadel'] as Map<String, dynamic>);
    floors = (json['floors'] as List)
        .map((f) => TowerFloor.fromJson(f as Map<String, dynamic>))
        .toList();
    events = (json['events'] as List)
        .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    groups =
        (json['groups'] as List?)
            ?.map((g) => NpcGroup.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [];
    trainingSuggestions =
        (json['trainingSuggestions'] as List?)
            ?.map((s) => TrainingSuggestion.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    _groupIdCounter = json['groupIdCounter'] as int? ?? 0;
    _suggestionIdCounter = json['suggestionIdCounter'] as int? ?? 0;
    // ── Equipamentos [FASE 1] ── null = inventário vazio (compatível com saves antigos) ✓
    final rawInv = json['inventory'] as List<dynamic>? ?? [];
    _inventory
      ..clear()
      ..addAll(
        rawInv.map((e) => Equipment.fromJson(e as Map<String, dynamic>)),
      );
    // ── Registros Oficiais ── compatível com saves antigos ✓
    final rawRec = json['records'] as List<dynamic>? ?? [];
    _records
      ..clear()
      ..addAll(
        rawRec.map((e) => CitadelRecord.fromJson(e as Map<String, dynamic>)),
      );
    _recordIdCounter = json['recordIdCounter'] as int? ?? 0;
    final prisonJson = json['prison'] as Map<String, dynamic>?;
    if (prisonJson != null) _prisonService.loadFromJson(prisonJson);
    activeTrainings =
        (json['activeTrainings'] as List?)
            ?.map((m) => TrainingMission.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];
    _trainingMissionCounter = json['trainingMissionCounter'] as int? ?? 0;
    // pendingRecruits
    final rawRecruits = json['pendingRecruits'] as List<dynamic>? ?? [];
    _pendingRecruits
      ..clear()
      ..addAll(
        rawRecruits.map(
          (e) => FloorInhabitant.fromJson(e as Map<String, dynamic>),
        ),
      );
    // ── Novos serviços (compatível com saves antigos — campos ausentes = estado limpo) ──
    final factionJson = json['factionService'] as Map<String, dynamic>?;
    if (factionJson != null) _factionService.loadFromJson(factionJson);
    final warJson = json['warService'] as Map<String, dynamic>?;
    if (warJson != null) _warService.loadFromJson(warJson);
    final tradeJson = json['tradeService'] as Map<String, dynamic>?;
    if (tradeJson != null) _tradeService.loadFromJson(tradeJson);
    final questJson = json['questService'] as Map<String, dynamic>?;
    if (questJson != null) _questService.loadFromJson(questJson);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SISTEMA DE SINERGIA
  // ═══════════════════════════════════════════════════════════════════════════
  double _synergyScore(Npc a, Npc b) {
    double score = 50.0;

    // Mesma profissão = forte atração
    if (a.profession == b.profession) score += 25;

    // Traços compatíveis
    final sharedTraits = a.traits.where((t) => b.traits.contains(t)).length * 9;
    score += sharedTraits;

    // Atributos parecidos
    if ((a.attributes.combatPower - b.attributes.combatPower).abs() < 4) {
      score += 15;
    }
    if ((a.attributes.mentalStability - b.attributes.mentalStability).abs() <
        25) {
      score += 12;
    }
    if ((a.attributes.charisma - b.attributes.charisma).abs() < 5) score += 10;

    // Opostos complementares
    if (a.traits.contains(PersonalityTrait.lazy) &&
        b.traits.contains(PersonalityTrait.calm)) {
      score += 18;
    }
    if (a.traits.contains(PersonalityTrait.brave) &&
        b.traits.contains(PersonalityTrait.cautious)) {
      score += 15;
    }

    return score.clamp(0.0, 100.0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SISTEMA DE FORTALECIMENTO PASSIVO
  // ═══════════════════════════════════════════════════════════════════════════

  void _processPassiveEnvironmentalTraining() {
    final aliveAdults = npcs
        .where((n) => n.alive && n.canTrain(state.currentDay))
        .toList();
    if (aliveAdults.isEmpty) return;

    final buildings = citadel.buildings;
    final hasTrainingGround = buildings.any(
      (b) =>
          b.type == BuildingType.trainingField ||
          b.type == BuildingType.barracks,
    );
    final hasLibrary = buildings.any(
      (b) => b.type == BuildingType.library || b.type == BuildingType.school,
    );
    final hasInfirmary = buildings.any((b) => b.type == BuildingType.infirmary);
    final hasTemple = buildings.any((b) => b.type == BuildingType.temple);
    final hasArena = buildings.any((b) => b.type == BuildingType.arena);

    final rng = Random(state.currentDay * 97);
    final trained = <String>[];

    for (final npc in aliveAdults) {
      bool improved = false;
      final gains = <String>[];

      if (hasTrainingGround && rng.nextDouble() < 0.3) {
        npc.attributes.strength = (npc.attributes.strength + 0.05).clamp(1, 20);
        npc.attributes.agility = (npc.attributes.agility + 0.05).clamp(1, 20);
        gains.add('FOR+0.05, AGI+0.05');
        improved = true;
      }

      if (hasLibrary &&
          (npc.profession == Profession.scribe ||
              npc.profession == Profession.teacher ||
              npc.profession == Profession.idle) &&
          rng.nextDouble() < 0.25) {
        npc.attributes.intelligence = (npc.attributes.intelligence + 0.05)
            .clamp(1, 20);
        gains.add('INT+0.05');
        improved = true;
      }

      if (hasInfirmary && rng.nextDouble() < 0.2) {
        npc.attributes.endurance = (npc.attributes.endurance + 0.05).clamp(
          1,
          20,
        );
        gains.add('RES+0.05');
        improved = true;
      }

      if (hasTemple && rng.nextDouble() < 0.15) {
        npc.attributes.mentalStability = (npc.attributes.mentalStability + 0.5)
            .clamp(1, 100);
        npc.attributes.charisma = (npc.attributes.charisma + 0.03).clamp(1, 20);
        gains.add('SAN+0.5, CAR+0.03');
        improved = true;
      }

      if (hasArena &&
          (npc.profession == Profession.guard ||
              npc.profession == Profession.explorer ||
              npc.profession == Profession.trainer) &&
          rng.nextDouble() < 0.4) {
        npc.attributes.strength = (npc.attributes.strength + 0.1).clamp(1, 20);
        npc.attributes.agility = (npc.attributes.agility + 0.08).clamp(1, 20);
        npc.attributes.endurance = (npc.attributes.endurance + 0.08).clamp(
          1,
          20,
        );
        gains.add('FOR+0.1, AGI+0.08, RES+0.08');
        improved = true;
      }

      if (improved) trained.add('${npc.name} (${gains.join(', ')})');
    }

    if (trained.isNotEmpty) {
      _addEvent(
        GameEventType.training,
        'Treinamento Ambiental',
        'NPCs se desenvolveram através das instalações da cidadela:\n${trained.take(8).join('\n')}',
      );
    }
  }

  void _processSurvivalGrowth() {
    final aliveNpcs = npcs.where((n) => n.alive).toList();
    if (aliveNpcs.isEmpty) return;

    final rng = Random(state.currentDay * 103);

    for (final npc in aliveNpcs) {
      if (npc.daysSurvived >= 50 && npc.daysSurvived % 50 == 0) {
        npc.attributes.mentalStability = (npc.attributes.mentalStability + 2)
            .clamp(1, 100);
        npc.attributes.endurance = (npc.attributes.endurance + 0.2).clamp(
          1,
          20,
        );
        npc.history.add('Sobrevivente veterano - ganhou resistência');
        _addEvent(
          GameEventType.system,
          'Veterano Resiliente',
          '${npc.name} sobreviveu ${npc.daysSurvived} dias. Resistência permanente aumentada.',
          involvedIds: [npc.id],
        );
      }

      if (npc.traumas.length >= 3 &&
          npc.attributes.mentalStability > 40 &&
          rng.nextDouble() < 0.25) {
        npc.attributes.mentalStability = (npc.attributes.mentalStability + 5)
            .clamp(1, 100);
        npc.attributes.endurance = (npc.attributes.endurance + 0.3).clamp(
          1,
          20,
        );
        npc.traits.add(PersonalityTrait.pragmatic);
        npc.traumas.clear();
        npc.history.add('Superou traumas do passado - ficou mais forte');
        _addEvent(
          GameEventType.system,
          'Crescimento Pós-Traumático',
          '${npc.name} enfrentou traumas e emergiu mais forte! Resiliência mental e física aumentada.',
          involvedIds: [npc.id],
        );
      }

      if (npc.fatigue >= 85 && rng.nextDouble() < 0.15) {
        npc.attributes.endurance = (npc.attributes.endurance + 0.15).clamp(
          1,
          20,
        );
        npc.history.add('Sobreviveu à exaustão - resistência melhorada');
      }

      if (npc.floorsCleared >= 10 && npc.floorsCleared % 10 == 0) {
        npc.attributes.strength = (npc.attributes.strength + 0.3).clamp(1, 20);
        npc.attributes.agility = (npc.attributes.agility + 0.25).clamp(1, 20);
        npc.attributes.luck = (npc.attributes.luck + 0.1).clamp(1, 20);
        npc.history.add('Veterano de ${npc.floorsCleared} andares');
        _addEvent(
          GameEventType.system,
          'Veterano da Torre',
          '${npc.name} conquistou ${npc.floorsCleared} andares. Poderes de combate aumentados!',
        );
      }
    }
  }

  void _processMoraleBonus() {
    final moral = citadel.resources.morale;
    if (moral < 70) return;

    final aliveNpcs = npcs
        .where((n) => n.alive && n.canTrain(state.currentDay))
        .toList();
    if (aliveNpcs.isEmpty) return;

    final rng = Random(state.currentDay * 109);
    final growthRate = ((moral - 70) / 30).clamp(0, 1);
    final trained = <String>[];

    for (final npc in aliveNpcs) {
      if (rng.nextDouble() < growthRate * 0.3) {
        final attr = rng.nextInt(5);
        double gain = 0.05 + (growthRate * 0.05);
        switch (attr) {
          case 0:
            npc.attributes.strength = (npc.attributes.strength + gain).clamp(
              1,
              20,
            );
            trained.add('${npc.name} (FOR+${gain.toStringAsFixed(2)})');
          case 1:
            npc.attributes.agility = (npc.attributes.agility + gain).clamp(
              1,
              20,
            );
            trained.add('${npc.name} (AGI+${gain.toStringAsFixed(2)})');
          case 2:
            npc.attributes.intelligence = (npc.attributes.intelligence + gain)
                .clamp(1, 20);
            trained.add('${npc.name} (INT+${gain.toStringAsFixed(2)})');
          case 3:
            npc.attributes.endurance = (npc.attributes.endurance + gain).clamp(
              1,
              20,
            );
            trained.add('${npc.name} (RES+${gain.toStringAsFixed(2)})');
          case 4:
            npc.attributes.charisma = (npc.attributes.charisma + gain).clamp(
              1,
              20,
            );
            trained.add('${npc.name} (CAR+${gain.toStringAsFixed(2)})');
        }
      }
    }

    if (trained.isNotEmpty && rng.nextDouble() < 0.5) {
      _addEvent(
        GameEventType.resourceGain,
        'Moral Alta Inspira Crescimento',
        'A felicidade da cidadela (${moral.toStringAsFixed(0)}) impulsiona o desenvolvimento:\n${trained.take(5).join(', ')}',
      );
    }
  }

  void _processTalentDiscovery() {
    final undiscovered = npcs
        .where(
          (n) =>
              n.alive &&
              !n.talentDiscovered &&
              n.hiddenTalent != HiddenTalent.none &&
              n.canTrain(state.currentDay),
        )
        .toList();
    if (undiscovered.isEmpty) return;

    final rng = Random(state.currentDay * 113);

    for (final npc in undiscovered) {
      double discoveryChance = 0.02;
      if (npc.floorsCleared >= 5) discoveryChance += 0.03;
      if (npc.daysSurvived >= 30) discoveryChance += 0.02;
      if (npc.killCount >= 10) discoveryChance += 0.03;
      if (npc.attributes.luck > 8) discoveryChance += 0.02;
      if (citadel.resources.morale > 80) discoveryChance += 0.02;
      if (npc.profession != Profession.idle) discoveryChance += 0.02;
      if (citadel.buildings.any((b) => b.type == BuildingType.arena)) {
        discoveryChance += 0.03;
      }
      if (citadel.buildings.any((b) => b.type == BuildingType.library)) {
        discoveryChance += 0.02;
      }
      if (citadel.buildings.any((b) => b.type == BuildingType.temple)) {
        discoveryChance += 0.02;
      }

      if (rng.nextDouble() < discoveryChance) {
        npc.talentDiscovered = true;
        npc.fame += 5;
        npc.history.add('Talento descoberto: ${npc.hiddenTalent.label}');
        _applyTalentDiscoveryBonus(npc);
        _addEvent(
          GameEventType.discovery,
          'Talento Oculto Revelado!',
          '${npc.name} revelou seu talento: ${npc.hiddenTalent.label}\n${npc.hiddenTalent.description}',
          involvedIds: [npc.id],
          isMajor: true,
        );
        citadel.resources.morale = (citadel.resources.morale + 2).clamp(0, 100);
      }
    }
  }

  void _applyTalentDiscoveryBonus(Npc npc) {
    switch (npc.hiddenTalent) {
      case HiddenTalent.hollyWarrior:
        npc.attributes.strength += 4;
        npc.attributes.endurance += 1.5;
        npc.attributes.charisma += 1.5;
        break;
      case HiddenTalent.combatGenius:
        npc.attributes.strength += 2;
        npc.attributes.agility += 2;
        npc.attributes.combatPowerMultiplier = 1.5; // 50% poder de combate
        break;
      case HiddenTalent.healingTouch:
        npc.attributes.intelligence += 1.5;
        npc.attributes.charisma += 1;
        npc.attributes.canHealAfterBattle = true; // cura aliados após batalha
        break;
      case HiddenTalent.strategicMind:
        npc.attributes.intelligence += 3;
        npc.attributes.groupMortalityReduction =
            0.15; // reduz mortalidade do grupo em 15%
        break;
      case HiddenTalent.naturalLeader:
        npc.attributes.charisma += 3;
        npc.loyalty += 10;
        npc.attributes.groupMoraleBonus = 0.2; // +20% moral do grupo
        npc.attributes.groupSynergyBonus = 0.15; // +15% sinergia
        break;
      case HiddenTalent.ironWill:
        npc.attributes.mentalStability += 15;
        npc.attributes.endurance += 2;
        npc.attributes.immuneToSanityLoss = true;
        break;
      case HiddenTalent.forgemaster:
        npc.attributes.strength += 1.5;
        npc.attributes.intelligence += 1.5;
        npc.attributes.equipmentBonusMultiplier =
            2.0; // equipamentos 2x eficientes
        break;
      case HiddenTalent.shadowWalker:
        npc.attributes.agility += 3;
        npc.attributes.luck += 1.5;
        npc.attributes.canEvadeCombat = true;
        break;
      case HiddenTalent.herbalist:
        npc.attributes.intelligence += 2;
        npc.attributes.canCraftMedicine = true;
        break;
      case HiddenTalent.beastWhisperer:
        npc.attributes.charisma += 2;
        npc.attributes.luck += 1;
        npc.attributes.canTameCreatures = true;
        break;
      case HiddenTalent.runeReader:
        npc.attributes.intelligence += 2.5;
        npc.attributes.luck += 1.5;
        npc.attributes.canRevealSecrets = true;
        break;
      default:
        break;
    }
  }
}

import 'dart:math';
import 'package:collection/collection.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/tower.dart';
import '../models/game_event.dart';
import '../models/group_model.dart';

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
  int _groupIdCounter = 0;
  int _suggestionIdCounter = 0;

  GameEngine({int? seed})
    : _rng = Random(seed),
      state = GameState(),
      npcs = [],
      citadel = Citadel(),
      floors = TowerFloor.generateMvpFloors(),
      events = [],
      groups = [],
      trainingSuggestions = [];

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
        food: 60,
        wood: 40,
        stone: 15,
        iron: 0,
        knowledge: 5,
        morale: 65,
      ),
    );
    floors = TowerFloor.generateMvpFloors();
    events = [];
    npcs = [];
    groups = [];
    trainingSuggestions = [];
    _groupIdCounter = 0;
    _suggestionIdCounter = 0;

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

    // Alertar sobre NPCs suspeitos
    for (final npc in npcs.where((n) => n.origin.isDarkOrigin)) {
      npc.isSuspicious = true;
      _addEvent(
        GameEventType.system,
        'Invocado Suspeito',
        '${npc.name} (${npc.origin.label}) demonstra comportamento inquietante.',
        involvedIds: [npc.id],
      );
    }
  }

  /// Atribui profissões iniciais baseadas em atributos
  void _assignInitialProfessions() {
    final alive = aliveNpcs;
    if (alive.isEmpty) return;

    // Por força → guarda/explorador
    final byStrength = [...alive]
      ..sort((a, b) => b.attributes.strength.compareTo(a.attributes.strength));
    if (byStrength.isNotEmpty) byStrength[0].profession = Profession.guard;
    if (byStrength.length > 1) byStrength[1].profession = Profession.explorer;

    // Por inteligência → escriba
    final byInt = [...alive]
      ..sort(
        (a, b) =>
            b.attributes.intelligence.compareTo(a.attributes.intelligence),
      );
    if (byInt.length > 2) byInt[2].profession = Profession.scribe;

    // Por carisma → mercador
    final byCharisma = [...alive]
      ..sort((a, b) => b.attributes.charisma.compareTo(a.attributes.charisma));
    if (byCharisma.length > 3) byCharisma[3].profession = Profession.merchant;

    // Restantes: por origem
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
    _dayEvents = [];
    if (state.gameOver) return _dayEvents;

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
    _processAutoReexploration();
    _processPassiveEnvironmentalTraining();
    _processSurvivalGrowth();
    _processMoraleBonus();
    _processTalentDiscovery();
    _processArenaEvents();
    _processTavernEvents();
    _processEmergencySummon();

    // Clampa recursos à capacidade do armazém
    final overflow = citadel.resources.clampToCapacity(citadel.storageLevel);
    if (overflow.totalLost > 0) {
      _addEvent(
        GameEventType.resourceLoss,
        'Armazem Cheio!',
        'Recursos excedentes perdidos: '
            '${_formatOverflow(overflow)}\nAmplie o Armazem para evitar perdas.',
      );
    }

    // Atualiza estado diário de cada NPC
    for (final npc in aliveNpcs) {
      npc.daysSurvived++;
      npc.mentalCondition = npc.calculatedMentalCondition;
      npc.betrayalRisk = npc.calculatedBetrayalRisk;
    }

    return _dayEvents;
  }

  String _formatOverflow(overflow) {
    final parts = <String>[];
    if (overflow.food > 0)
      parts.add('Comida:${overflow.food.toStringAsFixed(0)}');
    if (overflow.wood > 0)
      parts.add('Madeira:${overflow.wood.toStringAsFixed(0)}');
    if (overflow.stone > 0)
      parts.add('Pedra:${overflow.stone.toStringAsFixed(0)}');
    if (overflow.iron > 0)
      parts.add('Ferro:${overflow.iron.toStringAsFixed(0)}');
    if (overflow.knowledge > 0)
      parts.add('Conhec.:${overflow.knowledge.toStringAsFixed(0)}');
    return parts.join(' ');
  }

  // ─────────────────────────────────────────────
  // PRODUCAO & CONSUMO
  // ─────────────────────────────────────────────

  void _processResourceProduction() {
    final res = citadel.resources;
    final farmers = _countProfession(Profession.farmer);
    final builders = _countProfession(Profession.builder);
    final scribes = _countProfession(Profession.scribe);

    // Produção base por profissão
    res.food += 2.0 + farmers * 3.0;
    res.wood += 1.0 + builders * 2.0;
    res.stone += 0.5 + builders * 1.0;
    res.knowledge += 0.2 + scribes * 1.5;

    // Produção de edifícios
    for (final building in citadel.buildings) {
      _applyBuildingProduction(building, res);
    }
  }

  void _applyBuildingProduction(Building building, Resources res) {
    final t = building.tier.clamp(0, 3);
    switch (building.type) {
      case BuildingType.farm:
        res.food += [5.0, 12.0, 25.0, 25.0][t];
        break;
      case BuildingType.kitchen:
        final chefs = _countProfession(Profession.chef);
        res.food += chefs * [3.0, 8.0, 15.0, 15.0][t];
        break;
      case BuildingType.workshop:
        if (t == 0) {
          res.iron += 1.0;
        } else if (t == 1) {
          res.iron += 3.0;
          res.wood += 2.0;
        } else {
          res.iron += 6.0;
          res.wood += 5.0;
        }
        break;
      case BuildingType.forge:
        res.iron += [2.0, 5.0, 10.0, 10.0][t];
        break;
      case BuildingType.library:
        res.knowledge += 3.0;
        break;
      case BuildingType.temple:
        res.morale += 2.0;
        for (final npc in aliveNpcs) {
          npc.attributes.mentalStability =
              (npc.attributes.mentalStability + 0.5).clamp(0, 100);
        }
        break;
      case BuildingType.firepit:
        res.morale += [1.0, 2.0, 3.0, 5.0][t];
        break;
      default:
        break;
    }
  }

  void _processResourceConsumption() {
    final consumption = population * 1.5;
    citadel.resources.food -= consumption;

    if (citadel.resources.food < 0) {
      citadel.resources.food = 0;
      citadel.resources.morale -= 5;
      _addEvent(
        GameEventType.crisis,
        'Fome!',
        'Nao ha comida suficiente. A fome se espalha. Moral despenca.',
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
      // Expedição hoje → apenas 30% de recuperação
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
      // 8% chance de colapso físico permanente
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
    final affinity =
        (a.attributes.charisma + b.attributes.charisma) /
        20.0 *
        _rng.nextDouble();
    a.relationships.add(
      Relationship(targetId: b.id, type: 'amigo', affinity: affinity),
    );
    b.relationships.add(
      Relationship(targetId: a.id, type: 'amigo', affinity: affinity),
    );
    // Mesmo grupo acelera aproximação
    if (a.groupId != null && a.groupId == b.groupId) {
      a.relationships.last.affinity += 0.1;
      b.relationships.last.affinity += 0.1;
    }
  }

  void _evolveRelationship(Npc a, Npc b, Relationship rel) {
    rel.affinity = (rel.affinity + _rng.nextDouble() * 0.3 - 0.05).clamp(
      -1.0,
      1.0,
    );

    // Threshold para formar casal (reduzido com moral alta)
    final threshold = citadel.resources.morale > 85
        ? 0.55
        : citadel.resources.morale > 70
        ? 0.6
        : 0.7;

    if (rel.affinity > threshold &&
        a.partnerId == null &&
        b.partnerId == null) {
      a.partnerId = b.id;
      b.partnerId = a.id;
      rel.type = 'parceiro';
      b.relationships.firstWhereOrNull((r) => r.targetId == a.id)?.type =
          'parceiro';
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
          '${npc.name} se trancou em isolamento total.',
          involvedIds: [npc.id],
        );
        break;
      case 1:
        citadel.resources.food -= 10;
        citadel.resources.morale -= 5;
        npc.loyalty -= 10;
        npc.fame -= 5;
        npc.traumas.add('Rebeliao no dia ${state.currentDay}');
        _addEvent(
          GameEventType.betrayal,
          'Rebeliao',
          '${npc.name} se revoltou e destruiu suprimentos!',
          involvedIds: [npc.id],
        );
        break;
      case 2:
        if (_rng.nextDouble() < 0.3) {
          _killNpc(npc, 'Sacrificio suicida - partiu sozinho para a Torre');
          _addEvent(
            GameEventType.death,
            'Sacrificio Suicida',
            '${npc.name} partiu sozinho para a Torre. Nao voltou.',
            involvedIds: [npc.id],
            isMajor: true,
          );
        } else {
          npc.attributes.endurance -= 2;
          npc.traumas.add('Tentativa de fuga no dia ${state.currentDay}');
          _addEvent(
            GameEventType.mentalBreak,
            'Tentativa de Fuga',
            '${npc.name} tentou escalar as paredes. Encontrado inconsciente.',
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
          '${npc.name} parou de comer e falar.',
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
          '${npc.name} atacou outros moradores.',
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

  /// Processa penalidades progressivas para NPCs ociosos.
  /// NPCs idle por muito tempo sofrem consequências naturais.
  void _processIdleness() {
    for (final npc in aliveNpcs) {
      // Crianças e adolescentes não contam como ociosos
      final stage = npc.growthStage(state.currentDay);
      if (stage == GrowthStage.baby ||
          stage == GrowthStage.child ||
          stage == GrowthStage.adolescent) {
        npc.daysIdle = 0;
        continue;
      }

      // Atualiza contador de dias ociosos
      if (npc.profession == Profession.idle) {
        npc.daysIdle++;
      } else {
        npc.daysIdle = 0;
        continue;
      }

      // Penalidades progressivas baseadas em tempo ocioso
      if (npc.daysIdle >= 7) {
        _applyIdlenessPenalties(npc);
      }
    }
  }

  void _applyIdlenessPenalties(Npc npc) {
    final weeksIdle = npc.daysIdle ~/ 7;

    // Penalidade de moral (ociosos se sentem inúteis)
    if (npc.traits.contains(PersonalityTrait.ambitious) ||
        npc.traits.contains(PersonalityTrait.leader)) {
      npc.attributes.mentalStability -= 0.5 * weeksIdle;
    } else {
      npc.attributes.mentalStability -= 0.2 * weeksIdle;
    }

    // Redução de lealdade (sentem que não são valorizados)
    npc.loyalty -= 0.3 * weeksIdle;

    // Preguiçosos não sofrem tanto
    if (npc.traits.contains(PersonalityTrait.lazy)) {
      return;
    }

    // Deterioração de atributos físicos por inatividade
    if (npc.daysIdle >= 14) {
      npc.attributes.strength -= 0.05;
      npc.attributes.endurance -= 0.05;
    }

    // Eventos especiais de ociosidade prolongada
    if (npc.daysIdle == 21 && _rng.nextDouble() < 0.6) {
      _triggerIdlenessEvent(npc);
    }
  }

  void _triggerIdlenessEvent(Npc npc) {
    final roll = _rng.nextInt(3);

    switch (roll) {
      case 0: // Reclamação pública
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

      case 1: // Aumento de risco de traição
        npc.betrayalRisk += 5;
        npc.loyalty -= 5;
        _addEvent(
          GameEventType.mentalBreak,
          'Descontentamento Crescente',
          '${npc.name} esta visivelmente frustrado com a ociosidade prolongada. '
              'Alguns moradores notam olhares ressentidos.',
          involvedIds: [npc.id],
        );
        break;

      case 2: // Deterioração mental
        npc.attributes.mentalStability -= 5;
        if (npc.attributes.mentalStability < 40) {
          npc.mentalCondition = MentalCondition.depressed;
        }
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

  /// NPCs ociosos adultos escolhem profissões autonomamente baseado em
  /// suas características, personalidade e necessidades da cidadela.
  void _processAutonomousProfessionChoice() {
    // Roda a cada 3 dias para dar tempo de pensar
    if (state.currentDay % 3 != 0) return;

    for (final npc in aliveNpcs) {
      // Apenas adultos ociosos podem escolher profissão
      final stage = npc.growthStage(state.currentDay);
      if (stage != GrowthStage.adult || npc.profession != Profession.idle) {
        continue;
      }

      // Chance de escolher baseada em personalidade e tempo ocioso
      final choiceChance = _calculateProfessionChoiceChance(npc);
      if (_rng.nextDouble() > choiceChance) continue;

      // Escolhe profissão baseada em necessidades e aptidões
      final chosen = _chooseProfessionFor(npc);
      if (chosen != null && chosen != Profession.idle) {
        npc.profession = chosen;
        npc.daysIdle = 0;
        npc.loyalty += 2; // Pequeno boost por tomar iniciativa

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
    double baseChance = 0.15; // 15% base a cada 3 dias

    // Ambiciosos/líderes escolhem mais rápido
    if (npc.traits.contains(PersonalityTrait.ambitious)) baseChance += 0.15;
    if (npc.traits.contains(PersonalityTrait.leader)) baseChance += 0.10;

    // Preguiçosos resistem
    if (npc.traits.contains(PersonalityTrait.lazy)) baseChance -= 0.20;

    // Leais querem ajudar
    if (npc.traits.contains(PersonalityTrait.loyal)) baseChance += 0.10;

    // Tempo ocioso aumenta pressão
    if (npc.daysIdle >= 14) baseChance += 0.15;
    if (npc.daysIdle >= 21) baseChance += 0.25;

    // Moral baixa reduz iniciativa
    if (citadel.resources.morale < 40) baseChance -= 0.10;

    return baseChance.clamp(0.0, 0.8);
  }

  Profession? _chooseProfessionFor(Npc npc) {
    // Analisa necessidades da cidadela
    final needs = _analyzeCitadelNeeds();

    // Cria lista de profissões candidatas com scores
    final candidates = <Profession, double>{};

    for (final profession in Profession.values) {
      if (profession == Profession.idle) continue;

      final score = _calculateProfessionScore(npc, profession, needs);
      if (score > 0) candidates[profession] = score;
    }

    if (candidates.isEmpty) return null;

    // Escolhe baseado em probabilidades ponderadas
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
    double score = 0.5; // Score base

    // Compatibilidade com origem
    if (_professionFromOrigin(npc.origin) == profession) {
      score += 0.4;
    }

    // Compatibilidade com atributos
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

    // Personalidade afeta escolhas
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

  /// Checagem semanal de possíveis traições
  void _processBetrayalAttempts() {
    if (state.currentDay % 7 != 0) return;

    for (final npc in aliveNpcs) {
      if (npc.calculatedBetrayalRisk < 30) continue;
      if (_rng.nextDouble() * 100 > npc.calculatedBetrayalRisk) continue;
      _executeBetrayal(npc);
    }
  }

  void _executeBetrayal(Npc npc) {
    switch (_rng.nextInt(4)) {
      case 0: // Roubo
        final stolen = 5.0 + _rng.nextDouble() * 15;
        citadel.resources.food = (citadel.resources.food - stolen).clamp(
          0,
          9999,
        );
        npc.fame -= 10;
        npc.loyalty -= 5;
        _addPsychologicalMarksToChildren(
          'Testemunhou traicao: roubo de comida',
        );
        _addEvent(
          GameEventType.betrayalAttempt,
          'Roubo de Suprimentos!',
          '${npc.name} roubou ${stolen.toStringAsFixed(0)} de comida!',
          involvedIds: [npc.id],
          isMajor: true,
        );
        break;
      case 1: // Sabotagem
        if (citadel.resources.morale > 20) {
          citadel.resources.morale -= 8;
          npc.fame -= 8;
          _addEvent(
            GameEventType.betrayalAttempt,
            'Sabotagem!',
            '${npc.name} sabotou equipamentos durante a noite. -8 moral.',
            involvedIds: [npc.id],
            isMajor: true,
          );
        }
        break;
      case 2: // Manipulação
        final targets = aliveNpcs
            .where((n) => n.id != npc.id && n.loyalty < 60)
            .toList();
        if (targets.isNotEmpty) {
          final target = targets[_rng.nextInt(targets.length)];
          target.loyalty -= 5;
          npc.fame -= 5;
          _addEvent(
            GameEventType.politicalEvent,
            'Manipulacao',
            '${npc.name} espalhando rumores para ${target.name}.',
            involvedIds: [npc.id, target.id],
          );
        }
        break;
      case 3: // Assassinato (apenas assassinos, 30% chance)
        if (npc.origin != NpcOrigin.assassin || _rng.nextDouble() >= 0.3) break;
        final targets = aliveNpcs
            .where((n) => n.id != npc.id && n.fame > 15)
            .toList();
        if (targets.isEmpty) break;
        final target = targets[_rng.nextInt(targets.length)];
        if (_rng.nextDouble() < 0.4) {
          _killNpc(target, 'Assassinado por ${npc.name}');
          npc.killCount++;
          npc.fame -= 30;
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
        } else {
          npc.fame -= 15;
          npc.isSuspicious = true;
          _addEvent(
            GameEventType.betrayalAttempt,
            'Tentativa de Assassinato Frustrada',
            '${npc.name} tentou matar ${target.name}, mas foi impedido!',
            involvedIds: [npc.id, target.id],
            isMajor: true,
          );
        }
    }
  }

  // ─────────────────────────────────────────────
  // TREINO AUTÔNOMO
  // ─────────────────────────────────────────────

  /// A cada 5 dias, NPCs de combate podem treinar espontaneamente
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

  /// Aplica ganhos de treino para um NPC em um andar
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

    // Risco de acidente (2%)
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

    // 3% de chance de reativar ameaça
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

  /// A cada 14 dias, 40% de chance de re-explorar automaticamente
  void _processAutoReexploration() {
    if (state.currentDay % 14 != 0 || clearedFloors.isEmpty) return;
    if (_rng.nextDouble() > 0.4) return;

    final explorers = aliveNpcs
        .where(
          (n) =>
              (n.profession == Profession.explorer ||
                  n.profession == Profession.scout) &&
              n.attributes.mentalStability > 35 &&
              n.fatigue < 50,
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

  // ─────────────────────────────────────────────
  // SISTEMA DE EXPEDIÇÃO HARDCORE
  // ─────────────────────────────────────────────

  /// Custo de comida por NPC em expedição para novo andar (tier 1: 4, tier 5: 8, tier 10: 13)
  double expeditionCostPerNpc(int floorNumber) {
    final tier = ((floorNumber - 1) ~/ 10) + 1;
    return 3.0 + tier * 1.0;
  }

  /// Custo de comida por NPC em re-exploração (tier 1: 2.6, tier 10: 8)
  double reexploreCostPerNpc(int floorNumber) {
    final tier = ((floorNumber - 1) ~/ 10) + 1;
    return 2.0 + tier * 0.6;
  }

  // ── Preview de métricas para UI ────────────────

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

  /// Estimativa de chances de eventos negativos para exibição na UI
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

    // Todos do mesmo grupo: bônus por coesão
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

    // Relações entre membros
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

    // Traits de sinergia
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
    if (leader == 1) synergy += 0.1; // 1 líder é ideal
    if (leader > 1) synergy -= 0.05; // líderes demais conflitam

    // Talento Natural Leader
    if (party.any(
      (n) => n.talentDiscovered && n.hiddenTalent == HiddenTalent.naturalLeader,
    )) {
      synergy += 0.15;
    }

    return synergy.clamp(-0.3, 0.6);
  }

  /// Modificador de recompensa baseado em personalidade individual
  double _personalityRewardMod(Npc npc) {
    double mod = 0.0;
    // Traits conservadores (menor teto, menor risco)
    if (npc.traits.contains(PersonalityTrait.cautious)) mod -= 0.12;
    if (npc.traits.contains(PersonalityTrait.calm)) mod -= 0.05;
    // Traits agressivos (maior teto, maior risco)
    if (npc.traits.contains(PersonalityTrait.ambitious)) mod += 0.15;
    if (npc.traits.contains(PersonalityTrait.impulsive)) mod += 0.08;
    if (npc.traits.contains(PersonalityTrait.brave)) mod += 0.05;
    // Penalidades de eficiência
    if (npc.traits.contains(PersonalityTrait.lazy)) mod -= 0.15;
    if (npc.traits.contains(PersonalityTrait.coward)) mod -= 0.10;
    if (npc.traits.contains(PersonalityTrait.pessimist)) mod -= 0.05;
    if (npc.traits.contains(PersonalityTrait.individualist)) mod -= 0.05;
    // Bônus estáveis
    if (npc.traits.contains(PersonalityTrait.analytical)) mod += 0.06;
    if (npc.traits.contains(PersonalityTrait.pragmatic)) mod += 0.04;
    if (npc.traits.contains(PersonalityTrait.creative)) mod += 0.03;
    return mod;
  }

  /// Rendimento de coleta baseado em atributos e tipo de andar
  double _attributeYield(Npc npc, FloorType floorType) {
    double yield =
        1.0 +
        (npc.attributes.strength - 5) * 0.05 +
        (npc.attributes.intelligence - 5) * 0.04 +
        (npc.attributes.endurance - 5) * 0.025 +
        (npc.attributes.agility - 5) * 0.025 +
        (npc.attributes.luck - 5) * 0.025 -
        npc.fatigue * 0.004; // Exausto (100) = -40%

    if (npc.traits.contains(PersonalityTrait.lazy)) yield *= 0.80;

    // Bônus por tipo de andar
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

    return yield.clamp(0.2, 3.5);
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
    final tier = floor.tier;

    final result = FloorExplorationResult(
      floorNumber: floorNumber,
      day: state.currentDay,
      partyIds: partyIds,
    );

    // Custo fixo pago ANTES do resultado
    final costPerNpc = reexploreCostPerNpc(floorNumber);
    final totalCost = party.length * costPerNpc;
    result.foodCost = totalCost;
    citadel.resources.food -= totalCost;
    floor.timesReexplored++;

    _applyExpeditionFatigue(party, tier, baseFatigue: 15.0);

    // Calculo de recompensa
    final synergy = _calculateGroupSynergy(party);
    for (final entry in floor.farmableResources.entries) {
      double totalYield = 0;
      for (final npc in party) {
        totalYield +=
            entry.value *
            _attributeYield(npc, floor.type) *
            (1.0 + _personalityRewardMod(npc));
      }
      // Sinergia, variância e diminishing returns
      totalYield *=
          (1.0 + synergy) *
          (0.85 + _rng.nextDouble() * 0.30) *
          (1.0 / (1.0 + floor.timesReexplored * 0.05));

      // 1 NPC sozinho garante retorno mínimo viável
      if (party.length == 1) {
        totalYield = totalYield.clamp(costPerNpc * 0.5, double.infinity);
      }

      result.resourcesGained[entry.key] = totalYield;
    }

    // Eventos aleatórios (podem modificar result.resourcesGained)
    final eventLogs = _processExpeditionEvents(party, floor, result);

    // Aplica recursos ao estoque
    _applyResourcesToStock(result.resourcesGained);

    // Ameaça reativada
    final threatChance = 0.05 + (floor.timesReexplored * 0.02);
    if (_rng.nextDouble() < threatChance) {
      for (final npc in party) {
        if (_rng.nextDouble() < floor.scaledMortality * 0.3) {
          _killNpc(npc, 'Morreu em ameaca reativada no Andar ${floor.number}');
          result.casualties.add(npc.id);
        } else {
          npc.attributes.mentalStability -= 5;
          npc.attributes.endurance -= 0.2;
        }
      }
      if (result.casualties.isNotEmpty) {
        _addPsychologicalMarksToChildren(
          'Testemunhou combate violento - ${result.casualties.length} mortos',
          exceptIds: result.casualties,
        );
      }
      _addEvent(
        GameEventType.floorReexplore,
        'Re-Exploracao PERIGOSA - Andar $floorNumber',
        'AMEACA REATIVADA! ${result.casualties.length} baixas. ${eventLogs.join(' | ')}',
        involvedIds: partyIds,
        isMajor: result.casualties.isNotEmpty,
      );
    } else {
      final resStr = result.resourcesGained.entries
          .map((e) => '${e.key}: +${e.value.toStringAsFixed(0)}')
          .join(', ');
      _addEvent(
        GameEventType.floorReexplore,
        'Re-Exploracao - Andar $floorNumber',
        'Custo: ${totalCost.toStringAsFixed(0)} comida. Recursos: $resStr. '
            'Sinergia: ${(synergy * 100).toStringAsFixed(0)}%. ${eventLogs.join(' | ')}',
        involvedIds: partyIds,
      );
    }

    for (final npc in party.where((n) => n.alive)) npc.fame += 1;
    return result;
  }

  // ── Eventos aleatórios de expedição ────────────

  List<String> _processExpeditionEvents(
    List<Npc> party,
    TowerFloor floor,
    FloorExplorationResult result,
  ) {
    final logs = <String>[];
    final tier = floor.tier;

    // Acidente
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

    // Doença
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

    // Conflito interno
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

    // Traição
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
      if (_rng.nextDouble() >= 0.04 + traitor.calculatedBetrayalRisk * 0.001)
        continue;
      final stolenPct = 0.15 + _rng.nextDouble() * 0.25;
      for (final key in result.resourcesGained.keys.toList()) {
        final stolen = (result.resourcesGained[key] ?? 0) * stolenPct;
        result.resourcesGained[key] =
            (result.resourcesGained[key] ?? 0) - stolen;
      }
      traitor.fame -= 8;
      traitor.loyalty -= 5;
      traitor.isSuspicious = true;
      citadel.resources.morale -= 4;
      logs.add(
        '[TRAICAO] ${traitor.name} roubou ${(stolenPct * 100).toStringAsFixed(0)}% dos recursos!',
      );
      result.expeditionEvents.add('Traicao: ${traitor.name}');
      break; // Apenas uma traição por expedição
    }

    // Evento raro positivo (sem traição ativa)
    if (result.expeditionEvents.none((e) => e.startsWith('Traicao'))) {
      final avgLuck = _avg(
        party.where((n) => n.alive).toList(),
        (n) => n.attributes.luck,
      );
      final rareChance = (0.05 + avgLuck * 0.005).clamp(0.03, 0.15);
      if (_rng.nextDouble() < rareChance) {
        for (final key in result.resourcesGained.keys.toList()) {
          result.resourcesGained[key] =
              (result.resourcesGained[key] ?? 0) * 2.0;
        }
        citadel.resources.morale += 3;
        logs.add('[RARO] Descoberta excepcional! Recompensa DOBRADA!');
        result.expeditionEvents.add('Evento raro');

        // Chance de revelar talento
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

    // Incapacitado: recusa automática
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
      // Aceita
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
      // Negocia
      s.response = TrainingResponse.negotiated;
      s.responseDetail =
          '${npc.name} negociou: "Aceito, mas quero descanso depois."';
      npc.loyalty += 1;
    } else if (roll < acceptance + 0.25) {
      // Ignora
      s.response = TrainingResponse.ignored;
      s.responseDetail = '${npc.name} ignorou a sugestao.';
    } else {
      // Recusa
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

    // Resistência ao favoritismo excessivo
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
    if (npc.traits.contains(PersonalityTrait.coward))
      return 'E perigoso demais.';
    if (npc.attributes.mentalStability < 40)
      return 'Nao estou em condicoes de treinar.';
    if (npc.traits.contains(PersonalityTrait.loner))
      return 'Prefiro treinar sozinho.';
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
      // Risco quase nulo (0.5%)
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

    for (final npc
        in npcs.reversed
            .take(numToSummon)
            .where((n) => n.origin.isDarkOrigin)) {
      npc.isSuspicious = true;
      _addEvent(
        GameEventType.system,
        'Alerta: Invocado Suspeito',
        '${npc.name} (${npc.origin.label}) tem passado sombrio.',
        involvedIds: [npc.id],
      );
    }
  }

  // ─────────────────────────────────────────────
  // SOLICITAR NOVOS MORADORES
  // ─────────────────────────────────────────────

  String requestNewSettlers() {
    final daysSince = state.currentDay - state.lastSettlersRequestDay;
    if (daysSince < 7)
      return 'Aguarde ${7 - daysSince} dia(s) para nova solicitacao.';
    if (citadel.resources.morale < 60) {
      return 'Moral muito baixa (${citadel.resources.morale.toStringAsFixed(0)}/100). Novos moradores nao virarao.';
    }
    if (population >= citadel.totalPopulationCapacity) {
      return 'Sem espaco! Construa mais moradias.';
    }

    final spacesAvailable = citadel.totalPopulationCapacity - population;
    const foodPerDay = 1.5, daysBuffer = 10;
    final maxByFood = (citadel.resources.food / (foodPerDay * daysBuffer))
        .floor();
    final canReceive = min(spacesAvailable, maxByFood);

    if (canReceive <= 0) {
      return maxByFood <= 0
          ? 'Comida insuficiente! Precisa de ${(foodPerDay * daysBuffer).toStringAsFixed(0)} por morador.'
          : 'Sem espaco disponivel.';
    }

    final newSettlers = _generateSettlers(canReceive);
    state.lastSettlersRequestDay = state.currentDay;

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

    return 'Sucesso! ${newSettlers.length} moradores ($couples casais, $families familiares'
        '${darkCount > 0 ? ", $darkCount suspeitos" : ""}). Proxima solicitacao em 7 dias.';
  }

  List<Npc> _generateSettlers(int count) {
    final settlers = <Npc>[];
    var remaining = count;

    while (remaining > 0) {
      final roll = _rng.nextDouble();
      if (roll < 0.05 && remaining >= 2) {
        settlers.addAll(_spawnCouple());
        remaining -= 2;
      } else if (roll < 0.15 && remaining >= 2) {
        final family = _spawnFamily(min(remaining, _rng.nextInt(2) + 2));
        settlers.addAll(family);
        remaining -= family.length;
      } else {
        final npc = Npc.generateRandom(state.generateNpcId(), 1, _rng);
        settlers.add(npc);
        npcs.add(npc);
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
    npcs.addAll([a, b]);
    return [a, b];
  }

  List<Npc> _spawnFamily(int size) {
    final members = List.generate(size, (_) {
      final npc = Npc.generateRandom(state.generateNpcId(), 1, _rng);
      npcs.add(npc);
      return npc;
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
      case 1: // Talento revelado
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
        for (final npc in aliveNpcs) npc.loyalty += 1;
        _addEvent(
          GameEventType.celebration,
          'Celebracao',
          'Os moradores organizaram uma festa. Moral restaurada.',
        );
        break;
      case 3:
        citadel.resources.wood = (citadel.resources.wood - 10).clamp(0, 9999);
        _addEvent(
          GameEventType.resourceLoss,
          'Tempestade',
          'Uma tempestade danificou estruturas. -10 madeira.',
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
      case 6: // Fama
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
      case 7: // Coesão de grupo
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
      // Processa apenas uma vez por casal
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
    // Atualiza nutrição materna
    final foodPerCapita = citadel.resources.food / max(1, aliveNpcs.length);
    if (foodPerCapita >= 3.0) {
      pregnant.maternalNutrition = min(100, pregnant.maternalNutrition + 5);
    } else if (foodPerCapita < 1.5) {
      pregnant.maternalNutrition = max(0, pregnant.maternalNutrition - 10);
    }

    // Risco de perda
    double riskOfLoss = 0.0;
    if (pregnant.maternalNutrition < 30)
      riskOfLoss += 0.25;
    else if (pregnant.maternalNutrition < 50)
      riskOfLoss += 0.10;
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

    // Risco de morte no parto
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

    // Nascimento bem-sucedido
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
    for (final n in aliveNpcs) n.loyalty += 0.5;
  }

  void _tryConceive(Npc a, Npc b) {
    if (citadel.resources.food < 20 || citadel.resources.morale < 40) return;
    if (_rng.nextDouble() >= 0.08) return;

    final mother = _rng.nextBool() ? a : b;
    mother.pregnantSince = state.currentDay;
    mother.maternalNutrition = 100.0;
    _addEvent(
      GameEventType.romance,
      'Nova Vida a Caminho',
      '${a.name} e ${b.name} estao esperando um filho!',
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
      if (foodPerCapita < 0.5)
        risk += 0.25;
      else if (foodPerCapita < 1.0)
        risk += 0.10;
      if (stage == GrowthStage.baby && child.maternalNutrition < 50)
        risk += 0.12;

      final sickCount = aliveNpcs
          .where((n) => n.traumas.any((t) => t.contains('doenca')))
          .length;
      risk += min(0.15, sickCount * 0.03);

      if (citadel.resources.morale < 20)
        risk += 0.08;
      else if (citadel.resources.morale < 40)
        risk += 0.04;
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

      if (daysAlive == 1 && stage == GrowthStage.child) {
        _addEvent(
          GameEventType.birth,
          'Crescimento: ${npc.name}',
          '${npc.name} nao e mais um bebe!',
          involvedIds: [npc.id],
        );
      }

      if (daysAlive == 3 && stage == GrowthStage.adolescent) {
        _developPersonalityFromMarks(npc, isFirstTrait: true);
        _addEvent(
          GameEventType.birth,
          'Adolescencia: ${npc.name}',
          '${npc.name} cresceu e sua personalidade comeca a se formar.',
          involvedIds: [npc.id],
        );
      }

      if (daysAlive == 5 && stage == GrowthStage.adult) {
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

    if (parentTraits.isNotEmpty)
      return parentTraits[_rng.nextInt(parentTraits.length)];

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
    if (state.currentDay % 30 != 0) return;
    for (final npc in aliveNpcs) {
      npc.age++;
      if (npc.age < 16 && npc.generation > 1) {
        npc.attributes.strength += 0.3;
        npc.attributes.agility += 0.3;
        npc.attributes.intelligence += 0.2;
        npc.attributes.endurance += 0.3;
      }
      if (npc.age > 60) {
        npc.attributes.strength -= 0.2;
        npc.attributes.agility -= 0.2;
        npc.attributes.endurance -= 0.3;
        if (_rng.nextDouble() < 0.02) {
          _killNpc(npc, 'Faleceu de causas naturais aos ${npc.age} anos');
        }
      }
    }
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
        'NPCs progrediram:\n$details',
      );
    }
  }

  /// Retorna lista de ganhos do treino ou vazia se não treinou
  List<String> _applyProfessionTraining(Npc npc) {
    if (_rng.nextDouble() >= 0.1) return [];
    final gains = <String>[];

    switch (npc.profession) {
      case Profession.guard:
      case Profession.explorer:
        npc.attributes.strength += 0.1;
        npc.attributes.endurance += 0.1;
        gains.addAll(['FOR+0.1', 'RES+0.1']);
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
          citadel.countBuildings(type) >= citadel.level.maxBuildingCopies)
        return false;
      if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
      if (b.requiredTier > currentTier) return false;
      // Esconde tier 0 se já existe versão evoluída
      if (b.canEvolve) {
        final existing = citadel.buildings
            .where((bd) => bd.type == type)
            .toList();
        if (existing.any((bd) => bd.tier > 0)) return false;
      }
      return true;
    }).toList();
  }

  bool canBuild(BuildingType type) {
    final b = Building(type: type);
    if (b.isUnique && citadel.hasBuilding(type)) return false;
    if (!b.isUnique &&
        citadel.countBuildings(type) >= citadel.level.maxBuildingCopies)
      return false;
    if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
    if (b.requiredTier > _currentTier) return false;
    return citadel.resources.canAfford(b.cost);
  }

  bool buildStructure(BuildingType type) {
    if (!canBuild(type)) return false;
    final building = Building(type: type);
    citadel.resources.spend(building.cost);
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
    final b = citadel.getBuilding(type);
    if (b == null || b.level >= b.maxLevel) return false;
    if (!citadel.resources.canAfford(b.upgradeCost)) return false;
    citadel.resources.spend(b.upgradeCost);
    b.level++;
    _addEvent(
      GameEventType.upgrade,
      '${b.name} Melhorado!',
      '${b.name} evoluiu para nivel ${b.level}!',
      isMajor: true,
    );
    _processNpcBuildReaction(type, isUpgrade: true);
    return true;
  }

  bool upgradeCitadel() {
    if (!citadel.canUpgrade) return false;
    if (!citadel.resources.canAfford(citadel.upgradeCost)) return false;
    if (population < (citadel.nextLevel?.populationRequired ?? 999))
      return false;

    citadel.resources.spend(citadel.upgradeCost);
    final oldLabel = citadel.level.label;
    citadel.level = citadel.nextLevel!;

    _addEvent(
      GameEventType.upgrade,
      'Cidadela Evoluiu!',
      'De $oldLabel para ${citadel.level.label}! Max edificios: ${citadel.level.maxBuildings}.',
      isMajor: true,
    );

    // Evoluir edifícios automaticamente
    final newTier = citadel.level.buildingTier;
    final evolved = <String>[];
    for (final building in citadel.buildings.where(
      (b) => b.canEvolve && b.tier < newTier,
    )) {
      final oldName = building.name;
      building.tier = newTier;
      if (oldName != building.name) evolved.add('$oldName → ${building.name}');
    }
    if (evolved.isNotEmpty) {
      _addEvent(
        GameEventType.upgrade,
        'Edificios Evoluiram!',
        evolved.join(', '),
      );
    }

    for (final npc in aliveNpcs) npc.loyalty += 3;
    return true;
  }

  bool canUpgradeStorage() {
    final next = citadel.storageLevel.nextLevel;
    if (next == null) return false;
    if (!citadel.resources.canAfford(citadel.storageLevel.upgradeCost))
      return false;
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

  /// Reações dos NPCs a construções
  void _processNpcBuildReaction(BuildingType type, {bool isUpgrade = false}) {
    final action = isUpgrade ? 'melhoria' : 'construcao';
    switch (type) {
      case BuildingType.barracks:
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
        for (final npc in aliveNpcs) npc.loyalty += 1;
        _addEvent(
          GameEventType.celebration,
          'Fe Renovada',
          'A $action do Templo trouxe esperanca a todos.',
        );
        break;
      case BuildingType.tavern:
        citadel.resources.morale += 3;
        for (final npc in aliveNpcs.where(
          (n) => n.origin.isDarkOrigin && !n.isSuspicious,
        )) {
          if (_rng.nextDouble() < 0.3) {
            npc.isSuspicious = true;
            _addEvent(
              GameEventType.system,
              'Fofoca na Taverna',
              'Rumores indicam que ${npc.name} tem passado sombrio...',
              involvedIds: [npc.id],
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
        );
        break;
      case BuildingType.councilHall:
        for (final npc in aliveNpcs) npc.loyalty += 1;
        _addEvent(
          GameEventType.politicalEvent,
          'Democracia Emergente',
          'A Sala do Conselho da voz ao povo.',
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
          for (final npc in aliveNpcs) npc.loyalty += 1;
          _addEvent(
            GameEventType.celebration,
            'Comida Garantida',
            'A $action traz alivio a todos.',
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
    final aWins =
        a.attributes.combatPower + _rng.nextDouble() * 3 >
        b.attributes.combatPower + _rng.nextDouble() * 3;

    final winner = aWins ? a : b;
    final loser = aWins ? b : a;
    winner.fame += 2;
    winner.attributes.strength += 0.2;
    loser.attributes.endurance += 0.1;

    _addEvent(
      GameEventType.combat,
      'Duelo na Arena',
      '${winner.name} venceu ${loser.name}! +Fama, +Stats.',
      involvedIds: [a.id, b.id],
    );
  }

  void _processTavernEvents() {
    if (!citadel.hasBuilding(BuildingType.tavern) || state.currentDay % 5 != 0)
      return;

    // Revelar traidor via boato (10%)
    if (_rng.nextDouble() < 0.1) {
      final hidden = aliveNpcs
          .where((n) => n.origin.isDarkOrigin && !n.isSuspicious)
          .toList();
      if (hidden.isNotEmpty) {
        final npc = hidden[_rng.nextInt(hidden.length)];
        npc.isSuspicious = true;
        _addEvent(
          GameEventType.system,
          'Boato na Taverna',
          '${npc.name} tem passado questionavel...',
          involvedIds: [npc.id],
        );
      }
    }

    // Fortalecer relação (20%)
    if (_rng.nextDouble() < 0.2 && aliveNpcs.length >= 2) {
      final a = aliveNpcs[_rng.nextInt(aliveNpcs.length)];
      final b = _pickOther(aliveNpcs, a);
      a.relationships.firstWhereOrNull((r) => r.targetId == b.id)?.affinity +=
          0.1;
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
        log: ['Nao ha mais andares para explorar.'],
      );
    }

    final party = _resolveParty(partyIds);
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

    double partyPower = 0;
    for (final npc in party) {
      double power = npc.attributes.combatPower;
      if (npc.talentDiscovered && npc.hiddenTalent == HiddenTalent.combatGenius)
        power *= 1.5;
      if (npc.traits.contains(PersonalityTrait.brave)) power *= 1.1;
      if (npc.traits.contains(PersonalityTrait.coward)) power *= 0.85;
      partyPower += power;
      challenge.log.add('  ${npc.name} [PWR: ${power.toStringAsFixed(1)}]');
    }

    final successChance =
        ((partyPower / (floor.scaledDifficulty * party.length) * 0.6) + 0.2)
            .clamp(0.1, 0.95);
    final hasStrategist = party.any(
      (n) => n.talentDiscovered && n.hiddenTalent == HiddenTalent.strategicMind,
    );
    final adjustedMortality = hasStrategist
        ? floor.scaledMortality * 0.85
        : floor.scaledMortality;

    challenge.log.addAll([
      '',
      'Poder total: ${partyPower.toStringAsFixed(1)} vs ${floor.scaledDifficulty.toStringAsFixed(1)}',
      'Chance de sucesso: ${(successChance * 100).toStringAsFixed(0)}%',
      '',
    ]);

    final success = _rng.nextDouble() < successChance;
    if (success) {
      _resolveVictory(challenge, party, floor, adjustedMortality);
    } else {
      _resolveDefeat(challenge, party, floor, adjustedMortality);
    }

    // Healing Touch pós-batalha
    if (party.any(
      (n) =>
          n.alive &&
          n.talentDiscovered &&
          n.hiddenTalent == HiddenTalent.healingTouch,
    )) {
      for (final npc in party.where((n) => n.alive)) {
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

  void _resolveVictory(
    TowerChallenge challenge,
    List<Npc> party,
    TowerFloor floor,
    double mortality,
  ) {
    challenge.victory = true;
    challenge.moraleImpact = 5.0;
    challenge.log.add('>> VITORIA! O grupo superou o desafio.');

    for (final npc in party) {
      if (_rng.nextDouble() < mortality * 0.5) {
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
    if (floor.number > state.highestFloorReached)
      state.highestFloorReached = floor.number;

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
    challenge.log.add('>> DERROTA. O grupo foi forcado a recuar.');

    for (final npc in party) {
      if (_rng.nextDouble() < mortality) {
        _killNpc(npc, 'Morreu no Andar ${floor.number}');
        challenge.casualties.add(npc.id);
        challenge.log.add('  [X] ${npc.name} nao sobreviveu.');
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

    // Acidente (3%)
    if (_rng.nextDouble() < 0.03) {
      final victim = party[_rng.nextInt(party.length)];
      victim.attributes.endurance -= 0.5;
      challenge.log.addAll(['', '  [!] ${victim.name} sofreu ferimento leve.']);
    }

    // Ameaça reativada (4%+)
    if (_rng.nextDouble() < 0.04 + (floor.timesReexplored * 0.01)) {
      challenge.log.addAll(['', '  [!!] Ameaca oculta reativada!']);
      final victim = party[_rng.nextInt(party.length)];
      if (_rng.nextDouble() < 0.15) {
        _killNpc(
          victim,
          'Morreu em ameaca durante treino no Andar ${floor.number}',
        );
        challenge.casualties.add(victim.id);
        challenge.log.add('  [X] ${victim.name} nao sobreviveu!');
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
  // GRUPOS
  // ─────────────────────────────────────────────

  NpcGroup createGroup(String name, List<String> memberIds, GroupRole role) {
    final group = NpcGroup(
      id: _nextGroupId(),
      name: name,
      memberIds: memberIds,
      role: role,
    );

    // Líder = maior combatPower + carisma
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
      GameEventType.groupFormed,
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
      // Boss floor
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
      return;
    }

    if (n % 5 == 0) {
      // Elite floor
      final m = tier * 0.7;
      res.food += 15 * m;
      res.wood += 10 * m;
      res.stone += 10 * m;
      res.iron += 10 * m;
      res.knowledge += 15 * m;
      res.morale += 5;
      return;
    }

    // Andar normal
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

    // Remove do grupo e elege novo líder se necessário
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

    // Impacto no parceiro
    if (npc.partnerId != null) {
      final partner = npcs.firstWhereOrNull((n) => n.id == npc.partnerId);
      if (partner != null) {
        partner.attributes.mentalStability -= 15;
        partner.traumas.add('Perda de ${npc.name} no dia ${state.currentDay}');
        partner.partnerId = null;
        partner.loyalty -= 5;
      }
    }

    // Impacto nos filhos
    for (final childId in npc.childrenIds) {
      final child = npcs.firstWhereOrNull((n) => n.id == childId && n.alive);
      if (child != null) {
        child.attributes.mentalStability -= 10;
        child.traumas.add(
          'Orfao - ${npc.name} morreu no dia ${state.currentDay}',
        );
      }
    }

    // Impacto em quem o conhecia
    for (final other in aliveNpcs) {
      final rel = other.relationships.firstWhereOrNull(
        (r) => r.targetId == npc.id,
      );
      if (rel != null && rel.affinity > 0.3)
        other.attributes.mentalStability -= 3;
    }

    citadel.resources.morale -= 5;

    if (npc.fame > 20) {
      _addEvent(
        GameEventType.death,
        'Queda de ${npc.name}',
        '${npc.name} (${npc.origin.label}, G${npc.generation}) morreu. $cause. '
            'Fama: ${npc.fame.toStringAsFixed(0)}.',
        involvedIds: [npc.id],
        isMajor: true,
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  int _countProfession(Profession p) =>
      aliveNpcs.where((n) => n.profession == p).length;

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

  void _applyResourcesToStock(Map<String, double> resources) {
    for (final entry in resources.entries) {
      switch (entry.key) {
        case 'food':
          citadel.resources.food += entry.value;
          break;
        case 'wood':
          citadel.resources.wood += entry.value;
          break;
        case 'stone':
          citadel.resources.stone += entry.value;
          break;
        case 'iron':
          citadel.resources.iron += entry.value;
          break;
        case 'knowledge':
          citadel.resources.knowledge += entry.value;
          break;
      }
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SISTEMA DE FORTALECIMENTO PASSIVO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Treinamento passivo baseado em edifícios construídos
  void _processPassiveEnvironmentalTraining() {
    final aliveAdults = npcs
        .where((n) => n.alive && n.canTrain(state.currentDay))
        .toList();
    if (aliveAdults.isEmpty) return;

    final buildings = citadel.buildings;

    // Academia/Campo de Treino: +0.05 FOR/AGI por dia
    final hasTrainingGround = buildings.any(
      (b) =>
          b.type == BuildingType.trainingField ||
          b.type == BuildingType.barracks,
    );

    // Biblioteca/Escola: +0.05 INT por dia
    final hasLibrary = buildings.any(
      (b) => b.type == BuildingType.library || b.type == BuildingType.school,
    );

    // Enfermaria/Hospital: +0.05 RES por dia
    final hasInfirmary = buildings.any((b) => b.type == BuildingType.infirmary);

    // Templo: +0.05 mentalStability e +0.05 charisma por dia
    final hasTemple = buildings.any((b) => b.type == BuildingType.temple);

    // Arena: +0.1 FOR/AGI/RES para guerreiros específicos
    final hasArena = buildings.any((b) => b.type == BuildingType.arena);

    final rng = Random(state.currentDay * 97);
    final trained = <String>[];

    for (final npc in aliveAdults) {
      bool improved = false;
      final gains = <String>[];

      // Academia: todos ganham força/agilidade
      if (hasTrainingGround && rng.nextDouble() < 0.3) {
        npc.attributes.strength = (npc.attributes.strength + 0.05).clamp(1, 20);
        npc.attributes.agility = (npc.attributes.agility + 0.05).clamp(1, 20);
        gains.add('FOR+0.05, AGI+0.05');
        improved = true;
      }

      // Biblioteca: passivos ganham inteligência
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

      // Enfermaria: todos ganham resistência lentamente
      if (hasInfirmary && rng.nextDouble() < 0.2) {
        npc.attributes.endurance = (npc.attributes.endurance + 0.05).clamp(
          1,
          20,
        );
        gains.add('RES+0.05');
        improved = true;
      }

      // Templo: melhora saúde mental e carisma
      if (hasTemple && rng.nextDouble() < 0.15) {
        npc.attributes.mentalStability = (npc.attributes.mentalStability + 0.5)
            .clamp(1, 100);
        npc.attributes.charisma = (npc.attributes.charisma + 0.03).clamp(1, 20);
        gains.add('SAN+0.5, CAR+0.03');
        improved = true;
      }

      // Arena: guerreiros/exploradores ganham bônus maior
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

      if (improved) {
        trained.add('${npc.name} (${gains.join(', ')})');
      }
    }

    if (trained.isNotEmpty) {
      events.add(
        GameEvent(
          id: 'train_env_${state.currentDay}',
          day: state.currentDay,
          type: GameEventType.training,
          title: 'Treinamento Ambiental',
          description:
              'NPCs se desenvolveram através das instalações da cidadela:\\n${trained.take(8).join('\\n')}',
        ),
      );
    }
  }

  /// Crescimento por sobrevivência - eventos críticos fortalecem NPCs
  void _processSurvivalGrowth() {
    final aliveNpcs = npcs.where((n) => n.alive).toList();
    if (aliveNpcs.isEmpty) return;

    final rng = Random(state.currentDay * 103);

    // Sobreviventes de longo prazo ganham resistência mental
    for (final npc in aliveNpcs) {
      if (npc.daysSurvived >= 50 && npc.daysSurvived % 50 == 0) {
        npc.attributes.mentalStability = (npc.attributes.mentalStability + 2)
            .clamp(1, 100);
        npc.attributes.endurance = (npc.attributes.endurance + 0.2).clamp(
          1,
          20,
        );
        npc.history.add('Sobrevivente veterano - ganhou resistência');

        events.add(
          GameEvent(
            id: 'vet_${npc.id}_${state.currentDay}',
            day: state.currentDay,
            type: GameEventType.discovery,
            title: 'Veterano Resiliente',
            description:
                '${npc.name} sobreviveu ${npc.daysSurvived} dias. Resistência permanente aumentada.',
          ),
        );
      }

      // Traumas acumulados podem gerar crescimento pós-traumático (25% chance)
      if (npc.traumas.length >= 3 &&
          npc.attributes.mentalStability > 40 &&
          rng.nextDouble() < 0.25) {
        // Crescimento pós-traumático
        npc.attributes.mentalStability = (npc.attributes.mentalStability + 5)
            .clamp(1, 100);
        npc.attributes.endurance = (npc.attributes.endurance + 0.3).clamp(
          1,
          20,
        );
        npc.traits.add(PersonalityTrait.pragmatic);
        npc.traumas.clear(); // Superou os traumas
        npc.history.add('Superou traumas do passado - ficou mais forte');

        events.add(
          GameEvent(
            id: 'ptg_${npc.id}_${state.currentDay}',
            day: state.currentDay,
            type: GameEventType.mentalBreak,
            title: 'Crescimento Pós-Traumático',
            description: '${npc.name} superou traumas e emergiu mais forte!',
          ),
        );
      }

      // Sobreviver a fadiga extrema desenvolve endurance
      if (npc.fatigue >= 85 && rng.nextDouble() < 0.15) {
        npc.attributes.endurance = (npc.attributes.endurance + 0.15).clamp(
          1,
          20,
        );
        npc.history.add('Sobreviveu à exaustão - resistência melhorada');
      }

      // Combatentes veteranos (10+ andares) ganham atributos de combate
      if (npc.floorsCleared >= 10 && npc.floorsCleared % 10 == 0) {
        npc.attributes.strength = (npc.attributes.strength + 0.3).clamp(1, 20);
        npc.attributes.agility = (npc.attributes.agility + 0.25).clamp(1, 20);
        npc.attributes.luck = (npc.attributes.luck + 0.1).clamp(1, 20);
        npc.history.add('Veterano de ${npc.floorsCleared} andares');

        events.add(
          GameEvent(
            id: 'tower_vet_${npc.id}_${state.currentDay}',
            day: state.currentDay,
            type: GameEventType.discovery,
            title: 'Veterano da Torre',
            description:
                '${npc.name} conquistou ${npc.floorsCleared} andares. Poderes de combate aumentados!',
          ),
        );
      }
    }
  }

  /// Bônus de moral alta - população feliz cresce mais forte
  void _processMoraleBonus() {
    final moral = citadel.resources.morale;
    if (moral < 70) return; // Só funciona com moral alta

    final aliveNpcs = npcs
        .where((n) => n.alive && n.canTrain(state.currentDay))
        .toList();
    if (aliveNpcs.isEmpty) return;

    final rng = Random(state.currentDay * 109);
    final growthRate = ((moral - 70) / 30).clamp(
      0,
      1,
    ); // 0-1 baseado em moral 70-100
    final trained = <String>[];

    for (final npc in aliveNpcs) {
      if (rng.nextDouble() < growthRate * 0.3) {
        // Moral alta aumenta chance de treino bem-sucedido
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
      events.add(
        GameEvent(
          id: 'morale_bonus_${state.currentDay}',
          day: state.currentDay,
          type: GameEventType.resourceGain,
          title: 'Moral Alta Inspira Crescimento',
          description:
              'A felicidade da cidadela (${moral.toStringAsFixed(0)}) impulsiona o desenvolvimento:\\n${trained.take(5).join(', ')}',
        ),
      );
    }
  }

  /// Descoberta proativa de talentos ocultos
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
      double discoveryChance = 0.02; // 2% base por dia

      // Fatores que aumentam descoberta
      if (npc.floorsCleared >= 5) discoveryChance += 0.03;
      if (npc.daysSurvived >= 30) discoveryChance += 0.02;
      if (npc.killCount >= 10) discoveryChance += 0.03;
      if (npc.attributes.luck > 8) discoveryChance += 0.02;
      if (citadel.resources.morale > 80) discoveryChance += 0.02;
      if (npc.profession != Profession.idle) discoveryChance += 0.02;

      // Arena, Biblioteca e Templo aumentam descoberta
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

        // Talento descoberto dá boost imediato
        _applyTalentDiscoveryBonus(npc);

        events.add(
          GameEvent(
            id: 'talent_disc_${npc.id}_${state.currentDay}',
            day: state.currentDay,
            type: GameEventType.discovery,
            title: 'Talento Oculto Revelado!',
            description:
                '${npc.name} revelou seu talento: ${npc.hiddenTalent.label}\\n${npc.hiddenTalent.description}',
          ),
        );

        citadel.resources.morale = (citadel.resources.morale + 2).clamp(0, 100);
      }
    }
  }

  /// Aplica bônus imediato quando talento é descoberto
  void _applyTalentDiscoveryBonus(Npc npc) {
    switch (npc.hiddenTalent) {
      case HiddenTalent.combatGenius:
        npc.attributes.strength += 2;
        npc.attributes.agility += 2;
      case HiddenTalent.healingTouch:
        npc.attributes.intelligence += 1.5;
        npc.attributes.charisma += 1;
      case HiddenTalent.strategicMind:
        npc.attributes.intelligence += 3;
      case HiddenTalent.naturalLeader:
        npc.attributes.charisma += 3;
        npc.loyalty += 10;
      case HiddenTalent.ironWill:
        npc.attributes.mentalStability += 15;
        npc.attributes.endurance += 2;
      case HiddenTalent.forgemaster:
        npc.attributes.strength += 1.5;
        npc.attributes.intelligence += 1.5;
      case HiddenTalent.shadowWalker:
        npc.attributes.agility += 3;
        npc.attributes.luck += 1.5;
      case HiddenTalent.herbalist:
        npc.attributes.intelligence += 2;
      case HiddenTalent.beastWhisperer:
        npc.attributes.charisma += 2;
        npc.attributes.luck += 1;
      case HiddenTalent.runeReader:
        npc.attributes.intelligence += 2.5;
        npc.attributes.luck += 1.5;
      default:
        break;
    }
  }
}

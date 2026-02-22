import 'dart:math';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/tower.dart';
import '../models/game_event.dart';

class GameEngine {
  final Random _rng;
  GameState state;
  List<Npc> npcs;
  Citadel citadel;
  List<TowerFloor> floors;
  List<GameEvent> events;
  List<GameEvent> _dayEvents = [];

  GameEngine({int? seed})
      : _rng = Random(seed),
        state = GameState(),
        npcs = [],
        citadel = Citadel(),
        floors = TowerFloor.generateMvpFloors(),
        events = [];

  List<Npc> get aliveNpcs => npcs.where((n) => n.alive).toList();
  List<Npc> get deadNpcs => npcs.where((n) => !n.alive).toList();
  int get population => aliveNpcs.length;
  TowerFloor get currentFloor => floors[state.highestFloorCleared.clamp(0, floors.length - 1)];
  TowerFloor? get nextFloor {
    final idx = state.highestFloorCleared;
    if (idx >= floors.length) return null;
    return floors[idx];
  }

  void initNewGame() {
    state = GameState();
    citadel = Citadel(
      buildings: [Building(type: BuildingType.firepit)],
      resources: Resources(food: 60, wood: 40, stone: 15, iron: 0, knowledge: 5, morale: 65),
    );
    floors = TowerFloor.generateMvpFloors();
    events = [];
    npcs = [];

    for (int i = 0; i < 15; i++) {
      final id = state.generateNpcId();
      npcs.add(Npc.generateRandom(id, 1, _rng));
    }

    _assignInitialProfessions();

    _addEvent(GameEventType.system, 'A Invocacao',
        '15 humanos comuns foram arrancados de suas vidas e jogados na base de uma torre impossivel. Ninguem sabe por que estao aqui. Mas a Torre observa.',
        isMajor: true);
  }

  void _assignInitialProfessions() {
    final alive = aliveNpcs;
    if (alive.isEmpty) return;
    alive.sort((a, b) => b.attributes.strength.compareTo(a.attributes.strength));
    if (alive.isNotEmpty) alive[0].profession = Profession.guard;
    if (alive.length > 1) alive[1].profession = Profession.explorer;
    alive.sort((a, b) => b.attributes.intelligence.compareTo(a.attributes.intelligence));
    if (alive.length > 2) alive[2].profession = Profession.scribe;
    alive.sort((a, b) => b.attributes.charisma.compareTo(a.attributes.charisma));
    if (alive.length > 3) alive[3].profession = Profession.merchant;
    for (final npc in alive) {
      if (npc.profession == Profession.idle) {
        if (npc.origin == NpcOrigin.chef || npc.origin == NpcOrigin.farmer) {
          npc.profession = Profession.farmer;
        } else if (npc.origin == NpcOrigin.doctor || npc.origin == NpcOrigin.nurse) {
          npc.profession = Profession.doctor;
        } else if (npc.origin == NpcOrigin.soldier || npc.origin == NpcOrigin.firefighter) {
          npc.profession = Profession.guard;
        } else if (npc.origin == NpcOrigin.teacher) {
          npc.profession = Profession.teacher;
        }
      }
    }
  }

  List<GameEvent> simulateDay() {
    _dayEvents = [];

    if (state.gameOver) return _dayEvents;
    if (aliveNpcs.isEmpty) {
      state.gameOver = true;
      state.gameOverReason = 'Todos morreram. A humanidade falhou.';
      _addEvent(GameEventType.death, 'EXTINCAO',
          'O ultimo humano caiu. A Torre devora os restos em silencio. A Segunda Humanidade nao sobreviveu.',
          isMajor: true);
      return _dayEvents;
    }

    state.currentDay++;

    _processResourceProduction();
    _processResourceConsumption();
    _processRelationships();
    _processMentalHealth();
    _processRandomEvents();
    _processPregnancies();
    _processAging();
    _processTraining();

    citadel.resources.clampAll();

    for (final npc in aliveNpcs) {
      npc.daysSurvived++;
      npc.mentalCondition = npc.calculatedMentalCondition;
    }

    return _dayEvents;
  }

  void _processResourceProduction() {
    final res = citadel.resources;
    int farmers = aliveNpcs.where((n) => n.profession == Profession.farmer).length;
    int builders = aliveNpcs.where((n) => n.profession == Profession.builder).length;
    int scribes = aliveNpcs.where((n) => n.profession == Profession.scribe).length;

    res.food += 2.0 + (farmers * 3.0);
    res.wood += 1.0 + (builders * 2.0);
    res.stone += 0.5 + (builders * 1.0);
    res.knowledge += 0.2 + (scribes * 1.5);

    if (citadel.hasBuilding(BuildingType.farm)) res.food += 5.0;
    if (citadel.hasBuilding(BuildingType.kitchen)) {
      int chefs = aliveNpcs.where((n) => n.profession == Profession.chef).length;
      res.food += chefs * 3.0;
    }
    if (citadel.hasBuilding(BuildingType.library)) res.knowledge += 3.0;
    if (citadel.hasBuilding(BuildingType.forge)) res.iron += 1.0;
    if (citadel.hasBuilding(BuildingType.temple)) {
      res.morale += 2.0;
      for (final npc in aliveNpcs) {
        npc.attributes.mentalStability = (npc.attributes.mentalStability + 0.5).clamp(0, 100);
      }
    }
    if (citadel.hasBuilding(BuildingType.firepit)) res.morale += 1.0;
  }

  void _processResourceConsumption() {
    final pop = population;
    final consumption = pop * 1.5;
    citadel.resources.food -= consumption;

    if (citadel.resources.food < 0) {
      citadel.resources.food = 0;
      citadel.resources.morale -= 5;
      _addEvent(GameEventType.crisis, 'Fome!',
          'Nao ha comida suficiente para todos. A fome se espalha pelo acampamento. Moral despenca.');

      for (final npc in aliveNpcs) {
        npc.attributes.mentalStability -= 3;
        npc.attributes.endurance -= 0.2;
        if (_rng.nextDouble() < 0.05) {
          _killNpc(npc, 'Morreu de fome');
        }
      }
    }
  }

  void _processRelationships() {
    final alive = aliveNpcs;
    if (alive.length < 2) return;

    if (_rng.nextDouble() < 0.15) {
      final a = alive[_rng.nextInt(alive.length)];
      Npc b;
      do {
        b = alive[_rng.nextInt(alive.length)];
      } while (b.id == a.id);

      final existingRel = a.relationships.where((r) => r.targetId == b.id);
      if (existingRel.isEmpty) {
        final affinity = (a.attributes.charisma + b.attributes.charisma) / 20.0 * _rng.nextDouble();
        a.relationships.add(Relationship(targetId: b.id, type: 'amigo', affinity: affinity));
        b.relationships.add(Relationship(targetId: a.id, type: 'amigo', affinity: affinity));
      } else {
        final rel = existingRel.first;
        rel.affinity += (_rng.nextDouble() * 0.3 - 0.05);
        rel.affinity = rel.affinity.clamp(-1.0, 1.0);

        if (rel.affinity > 0.7 && a.partnerId == null && b.partnerId == null) {
          a.partnerId = b.id;
          b.partnerId = a.id;
          rel.type = 'parceiro';
          final bRel = b.relationships.where((r) => r.targetId == a.id);
          if (bRel.isNotEmpty) bRel.first.type = 'parceiro';

          _addEvent(GameEventType.romance, 'Novo Vinculo',
              '${a.name} e ${b.name} formaram uma uniao. Na escuridao da Torre, encontraram luz um no outro.',
              involvedIds: [a.id, b.id]);
        }
      }
    }
  }

  void _processMentalHealth() {
    for (final npc in aliveNpcs) {
      double modifier = 0;
      if (citadel.resources.morale > 70) modifier += 0.5;
      if (citadel.resources.morale < 30) modifier -= 2.0;
      if (npc.traumas.length > 3) modifier -= 1.0;
      if (npc.partnerId != null) modifier += 0.3;
      if (npc.traits.contains(PersonalityTrait.optimist)) modifier += 0.5;
      if (npc.traits.contains(PersonalityTrait.pessimist)) modifier -= 0.5;

      npc.attributes.mentalStability = (npc.attributes.mentalStability + modifier).clamp(0, 100);

      if (npc.attributes.mentalStability < 15 && _rng.nextDouble() < 0.1) {
        _processMentalBreak(npc);
      }
    }
  }

  void _processMentalBreak(Npc npc) {
    final breakType = _rng.nextInt(5);
    switch (breakType) {
      case 0:
        _addEvent(GameEventType.mentalBreak, 'Colapso Mental',
            '${npc.name} se trancou em isolamento total. Nao fala com ninguem. Seus olhos estao vazios.',
            involvedIds: [npc.id]);
        npc.profession = Profession.idle;
        npc.traumas.add('Colapso mental no dia ${state.currentDay}');
        break;
      case 1:
        _addEvent(GameEventType.betrayal, 'Rebeliao',
            '${npc.name} se revoltou contra a lideranca! Destruiu suprimentos em um acesso de furia.',
            involvedIds: [npc.id]);
        citadel.resources.food -= 10;
        citadel.resources.morale -= 5;
        npc.traumas.add('Rebeliao no dia ${state.currentDay}');
        break;
      case 2:
        if (_rng.nextDouble() < 0.3) {
          _addEvent(GameEventType.death, 'Sacrificio Suicida',
              '${npc.name} partiu sozinho para a Torre, em um ato de sacrificio desesperado. Nao voltou.',
              involvedIds: [npc.id], isMajor: true);
          _killNpc(npc, 'Sacrificio suicida - partiu sozinho para a Torre');
        } else {
          _addEvent(GameEventType.mentalBreak, 'Tentativa de Fuga',
              '${npc.name} tentou escalar as paredes da Torre para escapar. Foi encontrado inconsciente.',
              involvedIds: [npc.id]);
          npc.attributes.endurance -= 2;
          npc.traumas.add('Tentativa de fuga no dia ${state.currentDay}');
        }
        break;
      case 3:
        _addEvent(GameEventType.mentalBreak, 'Depressao Profunda',
            '${npc.name} parou de comer e falar. Permanece sentado, olhando para o vazio.',
            involvedIds: [npc.id]);
        npc.profession = Profession.idle;
        npc.attributes.strength -= 1;
        npc.traumas.add('Depressao severa no dia ${state.currentDay}');
        break;
      default:
        _addEvent(GameEventType.mentalBreak, 'Surto Agressivo',
            '${npc.name} atacou outros moradores em um surto de violencia. Precisou ser contido.',
            involvedIds: [npc.id]);
        citadel.resources.morale -= 3;
        npc.traumas.add('Surto violento no dia ${state.currentDay}');
    }
  }

  void _processRandomEvents() {
    if (_rng.nextDouble() < 0.08) {
      final eventRoll = _rng.nextInt(6);
      switch (eventRoll) {
        case 0:
          final amount = 5 + _rng.nextInt(15);
          citadel.resources.food += amount;
          _addEvent(GameEventType.resourceGain, 'Descoberta',
              'Exploradores encontraram um deposito de suprimentos: +$amount comida');
          break;
        case 1:
          final alive = aliveNpcs;
          if (alive.isNotEmpty) {
            final npc = alive[_rng.nextInt(alive.length)];
            if (!npc.talentDiscovered && npc.hiddenTalent != HiddenTalent.none) {
              npc.talentDiscovered = true;
              _addEvent(GameEventType.discovery, 'Talento Oculto Revelado!',
                  '${npc.name} revelou um talento oculto: ${npc.hiddenTalent.label}! ${npc.hiddenTalent.description}',
                  involvedIds: [npc.id], isMajor: true);
            }
          }
          break;
        case 2:
          citadel.resources.morale += 5;
          _addEvent(GameEventType.celebration, 'Celebracao',
              'Os moradores organizaram uma pequena festa ao redor da fogueira. Moral restaurada.');
          break;
        case 3:
          citadel.resources.wood -= 10;
          citadel.resources.wood = citadel.resources.wood.clamp(0, 9999);
          _addEvent(GameEventType.resourceLoss, 'Tempestade',
              'Uma tempestade misteriosa danificou estruturas. -10 madeira.');
          break;
        case 4:
          final alive = aliveNpcs;
          if (alive.length >= 2) {
            final a = alive[_rng.nextInt(alive.length)];
            Npc b;
            do { b = alive[_rng.nextInt(alive.length)]; } while (b.id == a.id);
            _addEvent(GameEventType.crisis, 'Conflito',
                '${a.name} e ${b.name} entraram em uma disputa acalorada. A tensao cresce na Cidadela.',
                involvedIds: [a.id, b.id]);
            citadel.resources.morale -= 3;
          }
          break;
        case 5:
          final amount = 3 + _rng.nextInt(8);
          citadel.resources.knowledge += amount;
          _addEvent(GameEventType.discovery, 'Inscricoes',
              'Simbolos antigos foram descobertos nas paredes da Torre. +$amount conhecimento.');
          break;
      }
    }
  }

  void _processPregnancies() {
    final alive = aliveNpcs;
    for (final npc in alive) {
      if (npc.partnerId == null) continue;
      final partner = npcs.where((n) => n.id == npc.partnerId && n.alive).firstOrNull;
      if (partner == null) continue;
      if (npc.id.compareTo(partner.id) > 0) continue;

      if (citadel.resources.food < 20) continue;
      if (citadel.resources.morale < 40) continue;
      if (population >= citadel.populationCapacity) continue;

      final rel = npc.relationships.where((r) => r.targetId == partner.id).firstOrNull;
      if (rel == null || rel.affinity < 0.6) continue;

      if (_rng.nextDouble() < 0.03) {
        final childId = state.generateNpcId();
        final child = Npc.generateChild(childId, npc, partner, _rng);
        npcs.add(child);
        npc.childrenIds.add(childId);
        partner.childrenIds.add(childId);
        state.totalBirths++;

        _addEvent(GameEventType.birth, 'Novo Membro!',
            '${npc.name} e ${partner.name} trouxeram ${child.name} ao mundo. Geracao ${child.generation}. A humanidade persiste.',
            involvedIds: [npc.id, partner.id, childId], isMajor: true);

        citadel.resources.morale += 5;
      }
    }
  }

  void _processAging() {
    for (final npc in aliveNpcs) {
      if (state.currentDay % 30 == 0) {
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
  }

  void _processTraining() {
    for (final npc in aliveNpcs) {
      if (npc.profession == Profession.guard || npc.profession == Profession.explorer) {
        if (_rng.nextDouble() < 0.1) {
          npc.attributes.strength += 0.1;
          npc.attributes.endurance += 0.1;
        }
      }
      if (npc.profession == Profession.scribe || npc.profession == Profession.teacher) {
        if (_rng.nextDouble() < 0.1) {
          npc.attributes.intelligence += 0.1;
        }
      }
      if (npc.profession == Profession.scout) {
        if (_rng.nextDouble() < 0.1) {
          npc.attributes.agility += 0.1;
        }
      }
    }
  }

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

    final party = partyIds.map((id) => npcs.firstWhere((n) => n.id == id)).toList();
    final challenge = TowerChallenge(floor: floor, partyIds: partyIds);

    challenge.log.add('=== ANDAR ${floor.number}: ${floor.type.label.toUpperCase()} ===');
    challenge.log.add(floor.description);
    if (floor.specialCondition.isNotEmpty) {
      challenge.log.add('> Condicao: ${floor.specialCondition}');
    }
    challenge.log.add('');

    double partyPower = 0;
    for (final npc in party) {
      double power = npc.attributes.combatPower;
      if (npc.talentDiscovered && npc.hiddenTalent == HiddenTalent.combatGenius) power *= 1.5;
      if (npc.traits.contains(PersonalityTrait.brave)) power *= 1.1;
      if (npc.traits.contains(PersonalityTrait.coward)) power *= 0.85;
      partyPower += power;
      challenge.log.add('  ${npc.name} [PWR: ${power.toStringAsFixed(1)}]');
    }
    challenge.log.add('');
    challenge.log.add('Poder total: ${partyPower.toStringAsFixed(1)} vs Dificuldade: ${floor.scaledDifficulty.toStringAsFixed(1)}');

    final powerRatio = partyPower / (floor.scaledDifficulty * party.length);
    final successChance = (powerRatio * 0.6 + 0.2).clamp(0.1, 0.95);

    bool hasStrategist = party.any((n) => n.talentDiscovered && n.hiddenTalent == HiddenTalent.strategicMind);
    double adjustedMortality = floor.scaledMortality;
    if (hasStrategist) adjustedMortality *= 0.85;

    final roll = _rng.nextDouble();
    final success = roll < successChance;

    challenge.log.add('Chance de sucesso: ${(successChance * 100).toStringAsFixed(0)}%');
    challenge.log.add('');

    if (success) {
      challenge.victory = true;
      challenge.log.add('>> VITORIA! O grupo superou o desafio.');

      for (final npc in party) {
        if (_rng.nextDouble() < adjustedMortality * 0.5) {
          _killNpc(npc, 'Morreu no Andar ${floor.number}');
          challenge.casualties.add(npc.id);
          challenge.log.add('  [X] ${npc.name} caiu em batalha.');
        } else {
          npc.floorsCleared++;
          npc.fame += 5 + floor.number;
          npc.attributes.strength += 0.2;
          npc.attributes.endurance += 0.2;
          npc.attributes.mentalStability -= 2;
          npc.history.add('Sobreviveu ao Andar ${floor.number} no Dia ${state.currentDay}');
          challenge.log.add('  [O] ${npc.name} sobreviveu. (+Fama, +Stats)');
        }
      }

      floor.cleared = true;
      floor.timesCleared++;
      state.highestFloorCleared = floor.number;
      if (floor.number > state.highestFloorReached) {
        state.highestFloorReached = floor.number;
      }

      _applyFloorRewards(floor);

      _addEvent(GameEventType.towerCleared, 'Andar ${floor.number} Conquistado!',
          'O grupo superou "${floor.description.split('.').first}". ${challenge.casualties.length} baixas. ${floor.reward}',
          involvedIds: partyIds, isMajor: true);

    } else {
      challenge.victory = false;
      challenge.log.add('>> DERROTA. O grupo foi forcado a recuar.');

      for (final npc in party) {
        if (_rng.nextDouble() < adjustedMortality) {
          _killNpc(npc, 'Morreu no Andar ${floor.number}');
          challenge.casualties.add(npc.id);
          challenge.log.add('  [X] ${npc.name} nao sobreviveu.');
        } else {
          npc.attributes.mentalStability -= 5;
          npc.attributes.endurance -= 0.3;
          npc.traumas.add('Derrota no Andar ${floor.number}');
          challenge.log.add('  [!] ${npc.name} escapou com ferimentos.');
        }
      }

      citadel.resources.morale -= 8;

      _addEvent(GameEventType.combat, 'Derrota no Andar ${floor.number}',
          'O grupo falhou na tentativa. ${challenge.casualties.length} mortos. Os sobreviventes voltaram abalados.',
          involvedIds: partyIds, isMajor: challenge.casualties.isNotEmpty);
    }

    challenge.completed = true;
    challenge.moraleImpact = success ? 5.0 : -8.0;
    citadel.resources.morale = citadel.resources.morale.clamp(0, 100);

    if (party.any((n) => n.alive && n.talentDiscovered && n.hiddenTalent == HiddenTalent.healingTouch)) {
      for (final npc in party.where((n) => n.alive)) {
        npc.attributes.endurance += 0.5;
        npc.attributes.mentalStability += 2;
      }
      challenge.log.add('');
      challenge.log.add('> Toque Curativo ativado: Sobreviventes parcialmente curados.');
    }

    return challenge;
  }

  TowerChallenge trainOnFloor(int floorNumber, List<String> partyIds) {
    final floor = floors.firstWhere((f) => f.number == floorNumber);
    final party = partyIds.map((id) => npcs.firstWhere((n) => n.id == id)).toList();
    final challenge = TowerChallenge(floor: floor, partyIds: partyIds);

    challenge.log.add('=== TREINO: ANDAR ${floor.number} ===');
    challenge.log.add('Dificuldade reduzida para treinamento.');
    challenge.log.add('');

    for (final npc in party) {
      final statGain = 0.1 + (_rng.nextDouble() * 0.3);
      switch (floor.type) {
        case FloorType.combat:
          npc.attributes.strength += statGain;
          npc.attributes.endurance += statGain * 0.5;
          challenge.log.add('  ${npc.name}: +${statGain.toStringAsFixed(2)} FOR');
          break;
        case FloorType.strategic:
          npc.attributes.intelligence += statGain;
          challenge.log.add('  ${npc.name}: +${statGain.toStringAsFixed(2)} INT');
          break;
        case FloorType.survival:
          npc.attributes.endurance += statGain;
          npc.attributes.agility += statGain * 0.5;
          challenge.log.add('  ${npc.name}: +${statGain.toStringAsFixed(2)} RES');
          break;
        case FloorType.moral:
          npc.attributes.mentalStability += statGain * 5;
          npc.attributes.charisma += statGain * 0.5;
          challenge.log.add('  ${npc.name}: +${(statGain * 5).toStringAsFixed(1)} EST.MENTAL');
          break;
        default:
          npc.attributes.intelligence += statGain * 0.5;
          npc.attributes.agility += statGain * 0.5;
          challenge.log.add('  ${npc.name}: Stats gerais melhorados');
      }
      npc.history.add('Treinou no Andar ${floor.number} no Dia ${state.currentDay}');
    }

    if (_rng.nextDouble() < 0.03) {
      final unlucky = party[_rng.nextInt(party.length)];
      unlucky.attributes.endurance -= 0.5;
      challenge.log.add('');
      challenge.log.add('  [!] ${unlucky.name} sofreu um ferimento leve durante o treino.');
    }

    challenge.completed = true;
    challenge.victory = true;
    citadel.resources.food -= party.length * 2;

    _addEvent(GameEventType.training, 'Treino no Andar ${floor.number}',
        '${party.length} membros treinaram no andar ${floor.number}. Custo: ${party.length * 2} comida.',
        involvedIds: partyIds);

    return challenge;
  }

  void _applyFloorRewards(TowerFloor floor) {
    switch (floor.number) {
      case 1:
        citadel.resources.wood += 15;
        citadel.resources.stone += 10;
        break;
      case 2:
        citadel.resources.food += 20;
        citadel.resources.iron += 5;
        break;
      case 3:
        citadel.resources.knowledge += 15;
        citadel.resources.morale += 10;
        break;
      case 4:
        citadel.resources.iron += 10;
        citadel.resources.knowledge += 10;
        break;
      case 5:
        citadel.resources.iron += 15;
        break;
      case 6:
        citadel.resources.food += 25;
        citadel.resources.knowledge += 5;
        break;
      case 7:
        citadel.resources.knowledge += 30;
        final alive = aliveNpcs;
        for (final npc in alive) {
          if (!npc.talentDiscovered && npc.hiddenTalent != HiddenTalent.none && _rng.nextDouble() < 0.3) {
            npc.talentDiscovered = true;
          }
        }
        break;
      case 8:
        citadel.resources.morale += 10;
        break;
      case 9:
        citadel.resources.iron += 15;
        citadel.resources.stone += 15;
        break;
      case 10:
        citadel.resources.food += 50;
        citadel.resources.wood += 50;
        citadel.resources.stone += 50;
        citadel.resources.iron += 50;
        citadel.resources.knowledge += 50;
        citadel.resources.morale += 20;
        citadel.populationCapacity += 10;
        break;
    }
  }

  void _killNpc(Npc npc, String cause) {
    npc.alive = false;
    npc.history.add('Morreu: $cause (Dia ${state.currentDay})');
    state.totalDeaths++;

    if (npc.partnerId != null) {
      final partner = npcs.where((n) => n.id == npc.partnerId).firstOrNull;
      if (partner != null) {
        partner.attributes.mentalStability -= 15;
        partner.traumas.add('Perda de ${npc.name} no dia ${state.currentDay}');
        partner.partnerId = null;
      }
    }

    for (final childId in npc.childrenIds) {
      final child = npcs.where((n) => n.id == childId && n.alive).firstOrNull;
      if (child != null) {
        child.attributes.mentalStability -= 10;
        child.traumas.add('Orfao - ${npc.name} morreu no dia ${state.currentDay}');
      }
    }

    citadel.resources.morale -= 5;

    for (final other in aliveNpcs) {
      final rel = other.relationships.where((r) => r.targetId == npc.id).firstOrNull;
      if (rel != null && rel.affinity > 0.3) {
        other.attributes.mentalStability -= 3;
      }
    }

    if (npc.fame > 20) {
      _addEvent(GameEventType.death, 'Queda de ${npc.name}',
          '${npc.name} (${npc.origin.label}, G${npc.generation}) morreu. $cause. Fama: ${npc.fame.toStringAsFixed(0)}. '
          'A Cidadela chora a perda de um de seus mais conhecidos.',
          involvedIds: [npc.id], isMajor: true);
    }
  }

  bool buildStructure(BuildingType type) {
    if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
    final building = Building(type: type);
    if (!citadel.resources.canAfford(building.cost)) return false;

    citadel.resources.spend(building.cost);
    citadel.buildings.add(building);

    _addEvent(GameEventType.construction, 'Nova Construcao: ${building.name}',
        '${building.name} foi construido(a). ${building.description}');

    return true;
  }

  bool upgradeCitadel() {
    if (!citadel.canUpgrade) return false;
    if (!citadel.resources.canAfford(citadel.upgradeCost)) return false;
    if (population < (citadel.nextLevel?.populationRequired ?? 999)) return false;

    citadel.resources.spend(citadel.upgradeCost);
    final oldLevel = citadel.level;
    citadel.level = citadel.nextLevel!;
    citadel.populationCapacity += 10;

    _addEvent(GameEventType.upgrade, 'Cidadela Evoluiu!',
        'A Cidadela evolui de ${oldLevel.label} para ${citadel.level.label}! '
        'Novas possibilidades se abrem. Capacidade maxima de edificios: ${citadel.level.maxBuildings}.',
        isMajor: true);

    return true;
  }

  void assignProfession(String npcId, Profession profession) {
    final npc = npcs.firstWhere((n) => n.id == npcId);
    final old = npc.profession;
    npc.profession = profession;
    npc.history.add('Profissao mudou: ${old.label} -> ${profession.label} (Dia ${state.currentDay})');
  }

  void _addEvent(GameEventType type, String title, String description,
      {List<String>? involvedIds, bool isMajor = false}) {
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

  Map<String, dynamic> toJson() => {
        'state': state.toJson(),
        'npcs': npcs.map((n) => n.toJson()).toList(),
        'citadel': citadel.toJson(),
        'floors': floors.map((f) => f.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
      };

  void loadFromJson(Map<String, dynamic> json) {
    state = GameState.fromJson(json['state'] as Map<String, dynamic>);
    npcs = (json['npcs'] as List<dynamic>)
        .map((n) => Npc.fromJson(n as Map<String, dynamic>))
        .toList();
    citadel = Citadel.fromJson(json['citadel'] as Map<String, dynamic>);
    floors = (json['floors'] as List<dynamic>)
        .map((f) => TowerFloor.fromJson(f as Map<String, dynamic>))
        .toList();
    events = (json['events'] as List<dynamic>)
        .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

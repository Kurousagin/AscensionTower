import 'dart:math';
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
  // Novos sistemas
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

  List<Npc> get aliveNpcs => npcs.where((n) => n.alive).toList();
  List<Npc> get deadNpcs => npcs.where((n) => !n.alive).toList();
  int get population => aliveNpcs.length;
  TowerFloor get currentFloor => floors[state.highestFloorCleared.clamp(0, floors.length - 1)];
  TowerFloor? get nextFloor {
    final idx = state.highestFloorCleared;
    if (idx >= floors.length) return null;
    return floors[idx];
  }
  List<TowerFloor> get clearedFloors => floors.where((f) => f.cleared).toList();
  bool get hasTrainingField => citadel.hasBuilding(BuildingType.trainingField);

  String _generateGroupId() {
    _groupIdCounter++;
    return 'grp_$_groupIdCounter';
  }

  String _generateSuggestionId() {
    _suggestionIdCounter++;
    return 'sug_$_suggestionIdCounter';
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
    groups = [];
    trainingSuggestions = [];
    _groupIdCounter = 0;
    _suggestionIdCounter = 0;

    for (int i = 0; i < 15; i++) {
      final id = state.generateNpcId();
      npcs.add(Npc.generateRandom(id, 1, _rng));
    }

    _assignInitialProfessions();

    _addEvent(GameEventType.system, 'A Invocacao',
        '15 humanos comuns foram arrancados de suas vidas e jogados na base de uma torre impossivel. '
        'Ninguem sabe por que estao aqui. Mas a Torre observa. '
        'ATENCAO: Alguns invocados podem ter passados obscuros...',
        isMajor: true);

    // Alertar sobre NPCs suspeitos
    for (final npc in npcs) {
      if (npc.origin.isDarkOrigin) {
        npc.isSuspicious = true;
        _addEvent(GameEventType.system, 'Invocado Suspeito',
            '${npc.name} (${npc.origin.label}) demonstra comportamento inquietante. Observar com atencao.',
            involvedIds: [npc.id]);
      }
    }
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
    _processFatigueRecovery();
    _processRelationships();
    _processMentalHealth();
    _processLoyalty();
    _processRandomEvents();
    _processBetrayalAttempts();
    _processPregnancies();
    _processAging();
    _processTraining();
    _processAutonomousTraining();
    _processAutoReexploration();
    // Auto-build e auto-upgrade REMOVIDOS: agora o jogador ORDENA construcoes
    _processArenaEvents();
    _processTavernEvents();
    _processEmergencySummon();

    // Clamp com capacidade do armazem — excedente e PERDIDO
    final overflow = citadel.resources.clampToCapacity(citadel.storageLevel);
    if (overflow.totalLost > 0) {
      _addEvent(GameEventType.resourceLoss, 'Armazem Cheio!',
          'Recursos excedentes foram perdidos por falta de espaco: '
          '${overflow.food > 0 ? "Comida:${overflow.food.toStringAsFixed(0)} " : ""}'
          '${overflow.wood > 0 ? "Madeira:${overflow.wood.toStringAsFixed(0)} " : ""}'
          '${overflow.stone > 0 ? "Pedra:${overflow.stone.toStringAsFixed(0)} " : ""}'
          '${overflow.iron > 0 ? "Ferro:${overflow.iron.toStringAsFixed(0)} " : ""}'
          '${overflow.knowledge > 0 ? "Conhec.:${overflow.knowledge.toStringAsFixed(0)}" : ""}'
          '\nAmplie o Armazem para evitar perdas.');
    }

    for (final npc in aliveNpcs) {
      npc.daysSurvived++;
      npc.mentalCondition = npc.calculatedMentalCondition;
      npc.betrayalRisk = npc.calculatedBetrayalRisk;
    }

    return _dayEvents;
  }

  // ==================== PRODUCAO/CONSUMO ====================

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
        npc.loyalty -= 2; // Fome reduz lealdade
        if (_rng.nextDouble() < 0.05) {
          _killNpc(npc, 'Morreu de fome');
        }
      }
    }
  }

  // ==================== RECUPERACAO DE FADIGA ====================

  void _processFatigueRecovery() {
    for (final npc in aliveNpcs) {
      // Base: 15 + (RES/15 * 10)
      double recovery = 15.0 + (npc.attributes.endurance / 15.0) * 10.0;

      // Enfermaria +5
      if (citadel.hasBuilding(BuildingType.infirmary)) recovery += 5.0;
      // Templo +3
      if (citadel.hasBuilding(BuildingType.temple)) recovery += 3.0;
      // Parceiro +2
      if (npc.partnerId != null) {
        final partner = npcs.where((n) => n.id == npc.partnerId && n.alive).firstOrNull;
        if (partner != null) recovery += 2.0;
      }
      // Grupo +1
      if (npc.groupId != null) recovery += 1.0;

      // Se fez expedicao hoje, apenas 30% da recuperacao
      if (npc.lastExpeditionDay == state.currentDay) {
        recovery *= 0.3;
      }

      npc.fatigue = (npc.fatigue - recovery).clamp(0.0, 100.0);

      // === CONSEQUENCIAS DE FADIGA ALTA ===
      if (npc.fatigue >= 90) {
        // Incapacitado: consequencias graves
        npc.attributes.mentalStability -= 5;
        npc.loyalty -= 1;
        npc.profession = Profession.idle;
        // 8% chance de colapso fisico
        if (_rng.nextDouble() < 0.08) {
          npc.attributes.endurance -= 0.5;
          npc.traumas.add('Colapso fisico por exaustao no dia ${state.currentDay}');
          _addEvent(GameEventType.crisis, 'Colapso Fisico!',
              '${npc.name} colapsou por exaustao extrema. Resistencia permanentemente reduzida.',
              involvedIds: [npc.id], isMajor: true);
        }
      } else if (npc.fatigue >= 70) {
        // Exausto: consequencias moderadas
        npc.attributes.mentalStability -= 3;
        npc.loyalty -= 0.5;
        // Alerta a cada 3 dias
        if (state.currentDay % 3 == 0) {
          _addEvent(GameEventType.crisis, 'NPC Exausto',
              '${npc.name} esta exausto(a). Precisa de descanso urgente.',
              involvedIds: [npc.id]);
        }
      }
    }
  }

  // ==================== RELACIONAMENTOS ====================

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
        // Membros do mesmo grupo se aproximam mais rapido
        if (a.groupId != null && a.groupId == b.groupId) {
          a.relationships.last.affinity += 0.1;
          b.relationships.last.affinity += 0.1;
        }
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

  // ==================== SAUDE MENTAL ====================

  void _processMentalHealth() {
    for (final npc in aliveNpcs) {
      double modifier = 0;
      if (citadel.resources.morale > 70) modifier += 0.5;
      if (citadel.resources.morale < 30) modifier -= 2.0;
      if (npc.traumas.length > 3) modifier -= 1.0;
      if (npc.partnerId != null) modifier += 0.3;
      if (npc.traits.contains(PersonalityTrait.optimist)) modifier += 0.5;
      if (npc.traits.contains(PersonalityTrait.pessimist)) modifier -= 0.5;
      // Grupo ajuda na sanidade
      if (npc.groupId != null) modifier += 0.2;

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
        npc.loyalty -= 10;
        npc.fame -= 5;
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
        npc.fame -= 3;
    }
  }

  // ==================== LEALDADE ====================

  void _processLoyalty() {
    for (final npc in aliveNpcs) {
      double mod = 0;
      // Moral alta = mais lealdade
      if (citadel.resources.morale > 70) mod += 0.1;
      if (citadel.resources.morale < 30) mod -= 0.3;
      // Comida OK
      if (citadel.resources.food > population * 3) mod += 0.05;
      // Leal/traicoeiro
      if (npc.traits.contains(PersonalityTrait.loyal)) mod += 0.1;
      if (npc.traits.contains(PersonalityTrait.treacherous)) mod -= 0.1;
      // Origens obscuras
      if (npc.origin.isDarkOrigin) mod -= 0.05;
      // Grupo aumenta lealdade
      if (npc.groupId != null) mod += 0.05;

      npc.loyalty = (npc.loyalty + mod).clamp(0, 100);
    }
  }

  // ==================== TRAICAO ====================

  void _processBetrayalAttempts() {
    if (state.currentDay % 7 != 0) return; // Checar semanalmente

    for (final npc in aliveNpcs) {
      if (npc.calculatedBetrayalRisk < 30) continue;
      if (_rng.nextDouble() * 100 > npc.calculatedBetrayalRisk) continue;

      // Chance de traicao ativada
      final betrayalType = _rng.nextInt(4);
      switch (betrayalType) {
        case 0: // Roubo de recursos
          final stolen = 5.0 + _rng.nextDouble() * 15;
          citadel.resources.food -= stolen;
          citadel.resources.food = citadel.resources.food.clamp(0, 9999);
          npc.fame -= 10;
          npc.loyalty -= 5;
          _addEvent(GameEventType.betrayalAttempt, 'Roubo de Suprimentos!',
              '${npc.name} (${npc.origin.label}) roubou ${stolen.toStringAsFixed(0)} de comida dos estoques! '
              'Risco de traicao: ${npc.calculatedBetrayalRisk.toStringAsFixed(0)}%',
              involvedIds: [npc.id], isMajor: true);
          break;
        case 1: // Sabotagem
          if (citadel.resources.morale > 20) {
            citadel.resources.morale -= 8;
            npc.fame -= 8;
            _addEvent(GameEventType.betrayalAttempt, 'Sabotagem!',
                '${npc.name} sabotou equipamentos durante a noite. -8 moral. '
                'Comportamento suspeito confirmado.',
                involvedIds: [npc.id], isMajor: true);
          }
          break;
        case 2: // Manipulacao
          final targets = aliveNpcs.where((n) => n.id != npc.id && n.loyalty < 60).toList();
          if (targets.isNotEmpty) {
            final target = targets[_rng.nextInt(targets.length)];
            target.loyalty -= 5;
            npc.fame -= 5;
            _addEvent(GameEventType.politicalEvent, 'Manipulacao',
                '${npc.name} foi visto espalhando rumores contra a lideranca para ${target.name}. '
                'Lealdade de ${target.name} caiu.',
                involvedIds: [npc.id, target.id]);
          }
          break;
        case 3: // Tentativa de assassinato (rara)
          if (npc.origin == NpcOrigin.assassin && _rng.nextDouble() < 0.3) {
            final targets = aliveNpcs.where((n) => n.id != npc.id && n.fame > 15).toList();
            if (targets.isNotEmpty) {
              final target = targets[_rng.nextInt(targets.length)];
              if (_rng.nextDouble() < 0.4) {
                _killNpc(target, 'Assassinado por ${npc.name} durante a noite');
                npc.killCount++;
                npc.fame -= 30;
                _addEvent(GameEventType.betrayalAttempt, 'ASSASSINATO!',
                    '${npc.name} assassinou ${target.name} durante a noite! '
                    'Um crime horrivel que abalou toda a comunidade.',
                    involvedIds: [npc.id, target.id], isMajor: true);
              } else {
                npc.fame -= 15;
                npc.isSuspicious = true;
                _addEvent(GameEventType.betrayalAttempt, 'Tentativa de Assassinato Frustrada',
                    '${npc.name} tentou assassinar ${target.name}, mas foi impedido! '
                    'A comunidade esta em choque.',
                    involvedIds: [npc.id, target.id], isMajor: true);
              }
            }
          }
          break;
      }
    }
  }

  // ==================== TREINO AUTONOMO ====================

  void _processAutonomousTraining() {
    if (state.currentDay % 5 != 0) return;
    if (clearedFloors.isEmpty) return;

    // NPCs decidem por conta propria se querem treinar
    final candidates = aliveNpcs.where((n) =>
        n.profession == Profession.guard ||
        n.profession == Profession.explorer ||
        n.profession == Profession.scout ||
        n.profession == Profession.trainer).toList();

    for (final npc in candidates) {
      if (_rng.nextDouble() > 0.15) continue; // 15% chance por ciclo
      if (npc.attributes.mentalStability < 30) continue;

      // Escolhe um andar cleared para treinar
      final availableFloors = clearedFloors;
      if (availableFloors.isEmpty) continue;
      final floor = availableFloors[_rng.nextInt(availableFloors.length)];

      // Treina sozinho com risco baixo + fadiga leve
      npc.fatigue = (npc.fatigue + 6.0).clamp(0.0, 100.0);
      final statGain = 0.05 + (_rng.nextDouble() * 0.15);
      switch (floor.type) {
        case FloorType.combat:
          npc.attributes.strength += statGain;
          npc.attributes.endurance += statGain * 0.5;
          break;
        case FloorType.strategic:
          npc.attributes.intelligence += statGain;
          break;
        case FloorType.survival:
          npc.attributes.endurance += statGain;
          npc.attributes.agility += statGain * 0.5;
          break;
        case FloorType.moral:
          npc.attributes.mentalStability += statGain * 3;
          npc.attributes.charisma += statGain * 0.5;
          break;
        default:
          npc.attributes.intelligence += statGain * 0.5;
          npc.attributes.agility += statGain * 0.5;
      }

      // Risco de acidente (baixo para treino autonomo)
      if (_rng.nextDouble() < 0.02) {
        npc.attributes.endurance -= 0.3;
        npc.traumas.add('Acidente de treino no andar ${floor.number}, dia ${state.currentDay}');
        _addEvent(GameEventType.training, 'Acidente de Treino',
            '${npc.name} sofreu um acidente treinando sozinho no Andar ${floor.number}.',
            involvedIds: [npc.id]);
      }

      // Chance de reativar ameaca oculta
      if (_rng.nextDouble() < 0.03) {
        floor.timesReexplored++;
        _addEvent(GameEventType.exploration, 'Ameaca Reativada!',
            '${npc.name} encontrou novas criaturas no Andar ${floor.number} durante treino. '
            'O andar nao e tao seguro quanto parecia.',
            involvedIds: [npc.id]);
      }
    }
  }

  // ==================== RE-EXPLORACAO AUTOMATICA ====================

  void _processAutoReexploration() {
    if (state.currentDay % 14 != 0) return;
    if (clearedFloors.isEmpty) return;

    // A cada 14 dias, chance de re-explorar para coletar recursos
    if (_rng.nextDouble() > 0.4) return;

    final explorers = aliveNpcs.where((n) =>
        (n.profession == Profession.explorer || n.profession == Profession.scout) &&
        n.attributes.mentalStability > 35 &&
        n.fatigue < 50).toList();

    if (explorers.isEmpty) return;

    // Escolhe andar
    final floor = clearedFloors[_rng.nextInt(clearedFloors.length)];
    final party = explorers.take(min(3, explorers.length)).toList();
    final partyIds = party.map((n) => n.id).toList();

    reexploreFloor(floor.number, partyIds);
  }

  // ==================== SISTEMA DE EXPEDICAO HARDCORE ====================
  // Custo fixo por NPC, recompensa escalavel, eventos aleatorios,
  // personalidade influencia resultado, sinergia de grupo importa.
  // =====================================================================

  /// Custo base de comida por NPC em expedicao
  /// Tier 1: 4.0 | Tier 5: 8.0 | Tier 10: 13.0
  double expeditionCostPerNpc(int floorNumber) {
    final tier = ((floorNumber - 1) ~/ 10) + 1;
    return 3.0 + tier * 1.0; // Custo mais significativo para punicao real
  }

  /// Custo base de comida por NPC em re-exploracao
  /// Tier 1: 2.5 | Tier 5: 5.0 | Tier 10: 8.0
  double reexploreCostPerNpc(int floorNumber) {
    final tier = ((floorNumber - 1) ~/ 10) + 1;
    return 2.0 + tier * 0.6;
  }

  /// Preview de sinergia para UI (exposto publicamente)
  double previewGroupSynergy(List<String> partyIds) {
    final party = partyIds
        .map((id) => npcs.where((n) => n.id == id && n.alive).firstOrNull)
        .whereType<Npc>()
        .toList();
    if (party.isEmpty) return 0.0;
    return _calculateGroupSynergy(party);
  }

  /// Preview de modificador de personalidade medio para UI
  double previewPartyPersonalityMod(List<String> partyIds) {
    final party = partyIds
        .map((id) => npcs.where((n) => n.id == id && n.alive).firstOrNull)
        .whereType<Npc>()
        .toList();
    if (party.isEmpty) return 0.0;
    return party.fold<double>(0, (s, n) => s + _personalityRewardMod(n)) / party.length;
  }

  /// Preview de eficiencia de atributos medio para UI
  double previewPartyAttributeYield(List<String> partyIds, FloorType floorType) {
    final party = partyIds
        .map((id) => npcs.where((n) => n.id == id && n.alive).firstOrNull)
        .whereType<Npc>()
        .toList();
    if (party.isEmpty) return 0.0;
    return party.fold<double>(0, (s, n) => s + _attributeYield(n, floorType)) / party.length;
  }

  /// Calcula chance estimada de evento negativo para UI
  Map<String, double> previewEventChances(List<String> partyIds, TowerFloor floor) {
    final party = partyIds
        .map((id) => npcs.where((n) => n.id == id && n.alive).firstOrNull)
        .whereType<Npc>()
        .toList();
    if (party.isEmpty) return {};
    final tier = floor.tier;
    final avgEndurance = party.fold<double>(0, (s, n) => s + n.attributes.endurance) / party.length;
    final cautiousCount = party.where((n) => n.traits.contains(PersonalityTrait.cautious)).length;
    final ambitiousCount = party.where((n) => n.traits.contains(PersonalityTrait.ambitious)).length;
    final avgLuck = party.fold<double>(0, (s, n) => s + n.attributes.luck) / party.length;
    return {
      'acidente': (0.12 + tier * 0.01 - avgEndurance * 0.005 - cautiousCount * 0.02 + ambitiousCount * 0.02).clamp(0.02, 0.30),
      'doenca': (0.06 + tier * 0.005).clamp(0.01, 0.20),
      'conflito': party.length >= 2 ? (0.08 + party.where((n) => n.traits.contains(PersonalityTrait.aggressive)).length * 0.05).clamp(0.02, 0.35) : 0.0,
      'traicao': party.any((n) => (n.traits.contains(PersonalityTrait.treacherous) || n.origin.isDarkOrigin) && n.loyalty < 40) ? 0.08 : 0.0,
      'evento_raro': (0.05 + avgLuck * 0.005).clamp(0.03, 0.15),
    };
  }

  /// Calcula sinergia do grupo (0.0 a 1.0)
  double _calculateGroupSynergy(List<Npc> party) {
    if (party.length <= 1) return 0.0;
    double synergy = 0.0;

    // Membros do mesmo grupo = bonus alto
    final groupIds = party.where((n) => n.groupId != null).map((n) => n.groupId!).toSet();
    if (groupIds.length == 1 && party.every((n) => n.groupId == groupIds.first)) {
      // Todos do mesmo grupo
      final group = groups.where((g) => g.id == groupIds.first).firstOrNull;
      if (group != null) {
        synergy += (group.cohesion / 100.0) * 0.3; // Ate +0.3 por coesao
      }
      synergy += 0.1; // bonus base por serem do mesmo grupo
    }

    // Relacoes entre membros
    int positiveRels = 0;
    int negativeRels = 0;
    for (final npc in party) {
      for (final other in party) {
        if (npc.id == other.id) continue;
        final rel = npc.relationships.where((r) => r.targetId == other.id).firstOrNull;
        if (rel != null) {
          if (rel.affinity > 0.3) positiveRels++;
          if (rel.affinity < -0.2) negativeRels++;
        }
      }
    }
    synergy += (positiveRels * 0.03).clamp(0.0, 0.2);
    synergy -= (negativeRels * 0.05).clamp(0.0, 0.3);

    // Traits que afetam sinergia
    final loyalCount = party.where((n) => n.traits.contains(PersonalityTrait.loyal)).length;
    final lonerCount = party.where((n) => n.traits.contains(PersonalityTrait.loner)).length;
    final leaderCount = party.where((n) => n.traits.contains(PersonalityTrait.leader)).length;
    final individualistCount = party.where((n) => n.traits.contains(PersonalityTrait.individualist)).length;
    synergy += loyalCount * 0.05;
    synergy -= lonerCount * 0.08;
    synergy -= individualistCount * 0.10; // Individualistas reduzem bonus de grupo
    if (leaderCount == 1) synergy += 0.1; // 1 lider e ideal
    if (leaderCount > 1) synergy -= 0.05; // lideres demais conflitam

    // Talento Natural Leader
    if (party.any((n) => n.talentDiscovered && n.hiddenTalent == HiddenTalent.naturalLeader)) {
      synergy += 0.15;
    }

    return synergy.clamp(-0.3, 0.6);
  }

  /// Calcula modificador de personalidade para recompensa
  double _personalityRewardMod(Npc npc) {
    double mod = 0.0;
    // Cauteloso: menor falha, menor teto
    if (npc.traits.contains(PersonalityTrait.cautious)) mod -= 0.12;
    if (npc.traits.contains(PersonalityTrait.calm)) mod -= 0.05;
    // Ambicioso/impulsivo: maior teto, maior risco
    if (npc.traits.contains(PersonalityTrait.ambitious)) mod += 0.15;
    if (npc.traits.contains(PersonalityTrait.impulsive)) mod += 0.08;
    if (npc.traits.contains(PersonalityTrait.brave)) mod += 0.05;
    // Preguicoso/covarde: reduz eficiencia
    if (npc.traits.contains(PersonalityTrait.lazy)) mod -= 0.15;
    if (npc.traits.contains(PersonalityTrait.coward)) mod -= 0.10;
    if (npc.traits.contains(PersonalityTrait.pessimist)) mod -= 0.05;
    // Analitico: bonus estavel
    if (npc.traits.contains(PersonalityTrait.analytical)) mod += 0.06;
    if (npc.traits.contains(PersonalityTrait.pragmatic)) mod += 0.04;
    // Criativo: surpresas
    if (npc.traits.contains(PersonalityTrait.creative)) mod += 0.03;
    // Individualista: menos eficaz em grupo
    if (npc.traits.contains(PersonalityTrait.individualist)) mod -= 0.05;
    return mod;
  }

  /// Calcula rendimento de coleta baseado em atributos
  /// Forca: rendimento bruto | INT: reduz desperdicio | RES: resistencia a penalidades
  /// Sorte: eventos positivos | AGI: eficiencia geral
  double _attributeYield(Npc npc, FloorType floorType) {
    double yield = 1.0;
    // Forca: rendimento bruto de coleta (+4% por ponto acima de 5)
    yield += (npc.attributes.strength - 5) * 0.05;
    // Inteligencia: reduz desperdicio e penalidades (+3% por ponto)
    yield += (npc.attributes.intelligence - 5) * 0.04;
    // Resistencia: resistencia a fadiga e acidentes (+2.5% por ponto)
    yield += (npc.attributes.endurance - 5) * 0.025;
    // Agilidade: eficiencia geral de coleta (+2% por ponto)
    yield += (npc.attributes.agility - 5) * 0.025;
    // Sorte: bonus aleatorio de coleta (+2% por ponto)
    yield += (npc.attributes.luck - 5) * 0.025;
    // Fadiga penaliza de forma mais severa
    yield -= npc.fatigue * 0.004; // Exausto (100) = -40%
    // Preguicoso: severa penalidade de rendimento
    if (npc.traits.contains(PersonalityTrait.lazy)) yield *= 0.80;
    // Tipo do andar favorece atributos especificos
    switch (floorType) {
      case FloorType.combat:
      case FloorType.gauntlet:
        // Andares de combate favorecem FORCA acima de tudo
        yield += npc.attributes.strength * 0.025;
        break;
      case FloorType.survival:
      case FloorType.hunt:
        // Sobrevivencia: RESISTENCIA e crucial
        yield += npc.attributes.endurance * 0.025;
        yield += npc.attributes.agility * 0.01;
        break;
      case FloorType.strategic:
      case FloorType.puzzle:
        // Estrategia: INTELIGENCIA domina
        yield += npc.attributes.intelligence * 0.035;
        break;
      case FloorType.mystery:
        // Misterio: INTELIGENCIA + SORTE
        yield += npc.attributes.intelligence * 0.02;
        yield += npc.attributes.luck * 0.025;
        break;
      default:
        // Andares mistos: mediana dos atributos
        yield += (npc.attributes.strength + npc.attributes.intelligence) * 0.01;
        break;
    }
    return yield.clamp(0.2, 3.5); // Pode ser muito ruim com atributos baixos
  }

  /// Processa eventos aleatorios durante expedicao/re-exploracao
  /// Retorna lista de strings de log narrativo
  List<String> _processExpeditionEvents(List<Npc> party, TowerFloor floor, FloorExplorationResult result) {
    final logs = <String>[];
    final tier = floor.tier;

    // === ACIDENTE (perda extra de comida) ===
    // Resistencia do grupo reduz chance; Cautelosos reduzem ainda mais
    final avgEndurance = party.fold<double>(0, (s, n) => s + n.attributes.endurance) / party.length;
    final cautiousCount = party.where((n) => n.traits.contains(PersonalityTrait.cautious)).length;
    final ambitiousCount = party.where((n) => n.traits.contains(PersonalityTrait.ambitious)).length;
    final accidentChance = (0.12 + tier * 0.01 - avgEndurance * 0.005 - cautiousCount * 0.02 + ambitiousCount * 0.02).clamp(0.02, 0.30);
    if (_rng.nextDouble() < accidentChance) {
      final victim = party[_rng.nextInt(party.length)];
      // Resistencia reduz gravidade
      final severity = (1.0 - victim.attributes.endurance * 0.06).clamp(0.3, 1.0);
      final foodLost = (3 + tier * 1.5) * severity;
      citadel.resources.food -= foodLost;
      victim.attributes.endurance -= 0.3 * severity;
      victim.fatigue += 8 * severity;
      logs.add('[ACIDENTE] ${victim.name} sofreu um acidente! -${foodLost.toStringAsFixed(0)} comida extra.');
      result.expeditionEvents.add('Acidente: ${victim.name}');
    }

    // === DOENCA (NPC debilitado) ===
    final diseaseChance = 0.06 + tier * 0.005;
    if (_rng.nextDouble() < diseaseChance) {
      final victim = party.where((n) => n.alive).toList();
      if (victim.isNotEmpty) {
        final sick = victim[_rng.nextInt(victim.length)];
        sick.attributes.endurance -= 1.0;
        sick.attributes.strength -= 0.5;
        sick.attributes.mentalStability -= 5;
        sick.fatigue += 20;
        sick.traumas.add('Doenca contraida no Andar ${floor.number}, dia ${state.currentDay}');
        logs.add('[DOENCA] ${sick.name} contraiu uma doenca! Debilitado severamente.');
        result.expeditionEvents.add('Doenca: ${sick.name}');
      }
    }

    // === CONFLITO INTERNO (reduz rendimento) ===
    if (party.length >= 2) {
      double conflictChance = 0.08;
      final aggressives = party.where((n) => n.traits.contains(PersonalityTrait.aggressive)).length;
      final loners = party.where((n) => n.traits.contains(PersonalityTrait.loner)).length;
      conflictChance += aggressives * 0.05 + loners * 0.03;
      if (_rng.nextDouble() < conflictChance) {
        // Reduz recompensa em 20-40%
        final penalty = 0.2 + _rng.nextDouble() * 0.2;
        for (final entry in result.resourcesGained.keys.toList()) {
          result.resourcesGained[entry] = (result.resourcesGained[entry] ?? 0) * (1 - penalty);
        }
        citadel.resources.morale -= 2;
        logs.add('[CONFLITO] Briga interna reduziu a eficiencia em ${(penalty * 100).toStringAsFixed(0)}%!');
        result.expeditionEvents.add('Conflito interno');
      }
    }

    // === TRAICAO (dependente de personalidade) ===
    final traitors = party.where((n) =>
        n.alive &&
        (n.traits.contains(PersonalityTrait.treacherous) || n.origin.isDarkOrigin) &&
        n.loyalty < 40).toList();
    for (final traitor in traitors) {
      final betrayChance = 0.04 + (traitor.calculatedBetrayalRisk * 0.001);
      if (_rng.nextDouble() < betrayChance) {
        // Trai: rouba parte dos recursos
        final stolenPct = 0.15 + _rng.nextDouble() * 0.25;
        for (final entry in result.resourcesGained.keys.toList()) {
          final stolen = (result.resourcesGained[entry] ?? 0) * stolenPct;
          result.resourcesGained[entry] = (result.resourcesGained[entry] ?? 0) - stolen;
        }
        traitor.fame -= 8;
        traitor.loyalty -= 5;
        traitor.isSuspicious = true;
        citadel.resources.morale -= 4;
        logs.add('[TRAICAO] ${traitor.name} roubou ${(stolenPct * 100).toStringAsFixed(0)}% dos recursos coletados!');
        result.expeditionEvents.add('Traicao: ${traitor.name}');
        break; // So uma traicao por expedicao
      }
    }

    // === EVENTO RARO POSITIVO (dobro de recompensa) ===
    // Sorte do grupo aumenta chance de evento raro
    final avgLuck = party.where((n) => n.alive).fold<double>(0, (s, n) => s + n.attributes.luck) / party.where((n) => n.alive).length.clamp(1, 99);
    final rareChance = (0.05 + avgLuck * 0.005).clamp(0.03, 0.15);
    if (_rng.nextDouble() < rareChance && result.expeditionEvents.where((e) => e.startsWith('Traicao')).isEmpty) {
      for (final entry in result.resourcesGained.keys.toList()) {
        result.resourcesGained[entry] = (result.resourcesGained[entry] ?? 0) * 2.0;
      }
      citadel.resources.morale += 3;
      logs.add('[RARO] Descoberta excepcional! Recompensa DOBRADA!');
      result.expeditionEvents.add('Evento raro: recompensa dobrada');
      // Chance de revelar talento
      final candidates = party.where((n) => n.alive && !n.talentDiscovered && n.hiddenTalent != HiddenTalent.none).toList();
      if (candidates.isNotEmpty && _rng.nextDouble() < 0.3) {
        final lucky = candidates[_rng.nextInt(candidates.length)];
        lucky.talentDiscovered = true;
        logs.add('[TALENTO] ${lucky.name} revelou ${lucky.hiddenTalent.label}!');
      }
    }

    return logs;
  }

  /// Re-explorar um andar conquistado para coletar recursos (SISTEMA HARDCORE)
  FloorExplorationResult reexploreFloor(int floorNumber, List<String> partyIds) {
    final floor = floors.firstWhere((f) => f.number == floorNumber);
    final party = partyIds.map((id) => npcs.firstWhere((n) => n.id == id)).toList();
    final tier = floor.tier;

    final result = FloorExplorationResult(
      floorNumber: floorNumber,
      day: state.currentDay,
      partyIds: partyIds,
    );

    // === CUSTO FIXO POR NPC (pago ANTES, independente do resultado) ===
    final costPerNpc = reexploreCostPerNpc(floorNumber);
    final totalCost = party.length * costPerNpc;
    result.foodCost = totalCost;
    citadel.resources.food -= totalCost;

    floor.timesReexplored++;

    // === FADIGA ===
    for (final npc in party) {
      final baseFatigue = 15.0 + tier * 1.0;
      npc.fatigue = (npc.fatigue + baseFatigue).clamp(0.0, 100.0);
      // Consecutividade
      if (npc.lastExpeditionDay == state.currentDay) {
        npc.consecutiveExpeditions++;
        npc.fatigue = (npc.fatigue + 8.0 + npc.consecutiveExpeditions * 2).clamp(0.0, 100.0);
      } else {
        npc.consecutiveExpeditions = 1;
      }
      npc.lastExpeditionDay = state.currentDay;
    }

    // === CALCULO DE RECOMPENSA ===
    final synergy = _calculateGroupSynergy(party);
    final baseResources = floor.farmableResources;

    // Recompensa por NPC individual, escalonada por atributos
    for (final entry in baseResources.entries) {
      double totalYield = 0;
      for (final npc in party) {
        final attrYield = _attributeYield(npc, floor.type);
        final persYield = 1.0 + _personalityRewardMod(npc);
        // Eficiencia individual = base * atributo * personalidade
        totalYield += entry.value * attrYield * persYield;
      }
      // Aplicar sinergia de grupo ao total
      totalYield *= (1.0 + synergy);
      // Variancia aleatoria (-15% a +15%)
      totalYield *= (0.85 + _rng.nextDouble() * 0.30);
      // Diminishing returns por repeticao
      totalYield *= (1.0 / (1.0 + floor.timesReexplored * 0.05));

      // REGRA HARDCORE: Recompensa NUNCA menor que consumo base de 1 NPC
      // Para 1 NPC: garante retorno minimo viavel (nao e 0 util)
      // Para grupos grandes: composicao ruim pode dar PREJUIZO (intencional)
      final minReward = costPerNpc * 0.5; // 50% do custo por NPC = minimo para 1 NPC
      if (party.length == 1) {
        // 1 NPC sozinho sempre tem retorno > custo base (nunca totalmente inutil)
        totalYield = totalYield.clamp(minReward, double.infinity);
      }
      // Grupos com composicao ruim: sem garantia de lucro (design intencional)

      result.resourcesGained[entry.key] = totalYield;
    }

    // === EVENTOS ALEATORIOS ===
    final eventLogs = _processExpeditionEvents(party, floor, result);

    // Aplicar recursos ao estoque
    for (final entry in result.resourcesGained.entries) {
      final amount = entry.value;
      switch (entry.key) {
        case 'food': citadel.resources.food += amount; break;
        case 'wood': citadel.resources.wood += amount; break;
        case 'stone': citadel.resources.stone += amount; break;
        case 'iron': citadel.resources.iron += amount; break;
        case 'knowledge': citadel.resources.knowledge += amount; break;
      }
    }

    // === AMEACA REATIVADA ===
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
      _addEvent(GameEventType.floorReexplore, 'Re-Exploracao PERIGOSA - Andar $floorNumber',
          'AMEACA REATIVADA! ${result.casualties.length} baixas. '
          '${eventLogs.isNotEmpty ? eventLogs.join(' | ') : 'Sobreviventes abalados.'}',
          involvedIds: partyIds, isMajor: result.casualties.isNotEmpty);
    } else {
      final resStr = result.resourcesGained.entries
          .map((e) => '${e.key}: +${e.value.toStringAsFixed(0)}')
          .join(', ');
      _addEvent(GameEventType.floorReexplore, 'Re-Exploracao - Andar $floorNumber',
          'Custo: ${totalCost.toStringAsFixed(0)} comida. Recursos: $resStr. Sinergia: ${(synergy * 100).toStringAsFixed(0)}%. '
          '${eventLogs.isNotEmpty ? eventLogs.join(' | ') : ''}',
          involvedIds: partyIds);
    }

    // Fama para participantes
    for (final npc in party.where((n) => n.alive)) {
      npc.fame += 1;
    }

    return result;
  }

  // ==================== SUGESTAO DE TREINO (JOGADOR -> NPC) ====================

  /// Jogador sugere treino para um NPC ou grupo
  TrainingSuggestion suggestTraining(String targetId, String targetType, int floorNumber) {
    final suggestion = TrainingSuggestion(
      id: _generateSuggestionId(),
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

  void _processNpcTrainingSuggestion(TrainingSuggestion suggestion) {
    final npc = npcs.firstWhere((n) => n.id == suggestion.targetId);
    npc.trainingSuggestionsReceived++;

    // Incapacitado recusa automaticamente
    if (npc.isIncapacitated) {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail = '${npc.name} esta incapacitado(a) por exaustao. Nao consegue nem se levantar.';
      _addEvent(GameEventType.trainingSuggestion, 'Impossivel Treinar',
          suggestion.responseDetail, involvedIds: [npc.id]);
      return;
    }

    final acceptance = npc.calculateTrainingAcceptance(
      hasTrainingField: hasTrainingField && suggestion.floorNumber == -1,
    );

    final roll = _rng.nextDouble();

    if (roll < acceptance) {
      suggestion.response = TrainingResponse.accepted;
      npc.trainingSuggestionsAccepted++;
      npc.loyalty += 2;

      // Executar treino
      if (suggestion.floorNumber == -1 && hasTrainingField) {
        _trainInTrainingField([npc]);
        suggestion.responseDetail = '${npc.name} aceitou treinar no Campo de Treino.';
      } else if (suggestion.floorNumber > 0) {
        trainOnFloor(suggestion.floorNumber, [npc.id]);
        suggestion.responseDetail = '${npc.name} aceitou treinar no Andar ${suggestion.floorNumber}.';
      }

      _addEvent(GameEventType.trainingSuggestion, 'Sugestao Aceita',
          suggestion.responseDetail,
          involvedIds: [npc.id]);
    } else if (roll < acceptance + 0.15) {
      suggestion.response = TrainingResponse.negotiated;
      suggestion.responseDetail = '${npc.name} negociou: "Aceito, mas quero descanso depois."';
      npc.loyalty += 1;
      _addEvent(GameEventType.trainingSuggestion, 'Negociacao',
          suggestion.responseDetail,
          involvedIds: [npc.id]);
    } else if (roll < acceptance + 0.25) {
      suggestion.response = TrainingResponse.ignored;
      suggestion.responseDetail = '${npc.name} simplesmente ignorou a sugestao.';
      _addEvent(GameEventType.trainingSuggestion, 'Sugestao Ignorada',
          suggestion.responseDetail,
          involvedIds: [npc.id]);
    } else {
      suggestion.response = TrainingResponse.refused;
      npc.loyalty -= 1;

      // Razao da recusa baseada em personalidade e fadiga
      String reason;
      if (npc.isExhausted) {
        reason = '"Mal consigo ficar de pe. Me deixe descansar."';
      } else if (npc.fatigue >= 50) {
        reason = '"Estou cansado demais. Preciso recuperar as energias primeiro."';
      } else if (npc.traits.contains(PersonalityTrait.coward)) {
        reason = '"E perigoso demais. Nao vou arriscar minha vida por um treino."';
      } else if (npc.attributes.mentalStability < 40) {
        reason = '"Nao estou em condicoes de treinar. Preciso de descanso."';
      } else if (npc.traits.contains(PersonalityTrait.loner)) {
        reason = '"Prefiro treinar no meu proprio tempo, do meu jeito."';
      } else {
        reason = '"Nao me parece necessario agora."';
      }
      suggestion.responseDetail = '${npc.name} recusou: $reason';
      _addEvent(GameEventType.trainingSuggestion, 'Sugestao Recusada',
          suggestion.responseDetail,
          involvedIds: [npc.id]);
    }

    // Impacto politico: sugerir treino demais irrita
    if (npc.trainingSuggestionsReceived > 5 && npc.trainingSuggestionsAccepted < npc.trainingSuggestionsReceived * 0.3) {
      npc.loyalty -= 3;
      _addEvent(GameEventType.politicalEvent, 'Resistencia ao Favoritismo',
          '${npc.name} esta irritado com as constantes sugestoes de treino. "Nao sou seu soldado particular."',
          involvedIds: [npc.id]);
    }
  }

  void _processGroupTrainingSuggestion(TrainingSuggestion suggestion) {
    final group = groups.firstWhere((g) => g.id == suggestion.targetId,
        orElse: () => NpcGroup(id: '', name: ''));
    if (group.id.isEmpty) return;

    final members = group.memberIds
        .map((id) => npcs.where((n) => n.id == id && n.alive).firstOrNull)
        .whereType<Npc>()
        .toList();

    if (members.isEmpty) return;

    int accepted = 0;
    int refused = 0;
    final acceptedIds = <String>[];

    for (final npc in members) {
      npc.trainingSuggestionsReceived++;
      // Incapacitado nao pode participar
      if (npc.isIncapacitated) {
        refused++;
        continue;
      }
      final acceptance = npc.calculateTrainingAcceptance(
        hasTrainingField: hasTrainingField && suggestion.floorNumber == -1,
      );

      if (_rng.nextDouble() < acceptance) {
        accepted++;
        npc.trainingSuggestionsAccepted++;
        acceptedIds.add(npc.id);
      } else {
        refused++;
      }
    }

    if (accepted > refused) {
      suggestion.response = TrainingResponse.accepted;
      suggestion.responseDetail = 'Grupo ${group.name}: $accepted aceitaram, $refused recusaram.';

      if (suggestion.floorNumber == -1 && hasTrainingField) {
        _trainInTrainingField(acceptedIds.map((id) => npcs.firstWhere((n) => n.id == id)).toList());
      } else if (suggestion.floorNumber > 0) {
        trainOnFloor(suggestion.floorNumber, acceptedIds);
      }
    } else {
      suggestion.response = TrainingResponse.refused;
      suggestion.responseDetail = 'Grupo ${group.name} recusou: maioria votou contra ($refused contra $accepted).';
    }

    _addEvent(GameEventType.trainingSuggestion, 'Sugestao ao Grupo ${group.name}',
        suggestion.responseDetail,
        involvedIds: acceptedIds);
  }

  void _trainInTrainingField(List<Npc> participants) {
    for (final npc in participants) {
      // Campo de treino: mais seguro, ganhos menores
      final statGain = 0.08 + (_rng.nextDouble() * 0.12);
      npc.attributes.strength += statGain;
      npc.attributes.endurance += statGain * 0.8;
      npc.attributes.agility += statGain * 0.5;
      npc.history.add('Treinou no Campo de Treino (Dia ${state.currentDay})');

      // Risco quase zero no training field
      if (_rng.nextDouble() < 0.005) {
        npc.attributes.endurance -= 0.2;
        npc.traumas.add('Ferimento leve no Campo de Treino, dia ${state.currentDay}');
      }
    }

    citadel.resources.food -= participants.length * 1.5;
    _addEvent(GameEventType.training, 'Treino no Campo',
        '${participants.length} membros treinaram no Campo de Treino. Evolucao lenta mas segura.',
        involvedIds: participants.map((n) => n.id).toList());
  }

  // ==================== INVOCACAO EMERGENCIAL ====================

  void _processEmergencySummon() {
    final alive = aliveNpcs;
    if (alive.length > 5) return;
    if (state.currentDay % 14 != 0) return;

    // Populacao criticamente baixa - invocar emergencialmente
    final numToSummon = min(3, 6 - alive.length);
    if (numToSummon <= 0) return;

    for (int i = 0; i < numToSummon; i++) {
      final id = state.generateNpcId();
      npcs.add(Npc.generateRandom(id, 1, _rng));
    }

    _addEvent(GameEventType.emergencySummon, 'INVOCACAO EMERGENCIAL!',
        'A Torre detectou que a populacao esta criticamente baixa (${ alive.length} restantes). '
        '$numToSummon novos humanos foram arrancados de suas vidas e jogados na Torre. '
        'Mas quem sao eles realmente? Vigiar com atencao.',
        isMajor: true);

    // NPCs novos podem ter origens obscuras
    for (final npc in npcs.reversed.take(numToSummon)) {
      if (npc.origin.isDarkOrigin) {
        npc.isSuspicious = true;
        _addEvent(GameEventType.system, 'Alerta: Invocado Suspeito',
            '${npc.name} (${npc.origin.label}) parece ter um passado sombrio.',
            involvedIds: [npc.id]);
      }
    }
  }

  // ==================== EVENTOS ALEATORIOS ====================

  void _processRandomEvents() {
    if (_rng.nextDouble() < 0.08) {
      final eventRoll = _rng.nextInt(8); // Mais variedade
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
          // Festas aumentam lealdade
          for (final npc in aliveNpcs) { npc.loyalty += 1; }
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
            // Conflito afeta lealdade
            a.loyalty -= 2;
            b.loyalty -= 2;
          }
          break;
        case 5:
          final amount = 3 + _rng.nextInt(8);
          citadel.resources.knowledge += amount;
          _addEvent(GameEventType.discovery, 'Inscricoes',
              'Simbolos antigos foram descobertos nas paredes da Torre. +$amount conhecimento.');
          break;
        case 6:
          // Evento de fama: NPC famoso inspira ou aterroriza
          final famous = aliveNpcs.where((n) => n.fame.abs() > 10).toList();
          if (famous.isNotEmpty) {
            final npc = famous[_rng.nextInt(famous.length)];
            if (npc.fame > 0) {
              citadel.resources.morale += 3;
              _addEvent(GameEventType.politicalEvent, 'Lideranca Natural',
                  '${npc.name} (Fama: ${npc.fame.toStringAsFixed(0)}) inspirou os moradores com uma palestra. +3 moral.',
                  involvedIds: [npc.id]);
            } else {
              citadel.resources.morale -= 2;
              _addEvent(GameEventType.politicalEvent, 'Medo na Cidadela',
                  '${npc.name} (Fama: ${npc.fame.toStringAsFixed(0)}) causa desconforto entre os moradores. -2 moral.',
                  involvedIds: [npc.id]);
            }
          }
          break;
        case 7:
          // Evento de grupo
          if (groups.isNotEmpty) {
            final group = groups[_rng.nextInt(groups.length)];
            group.cohesion += 5;
            group.cohesion = group.cohesion.clamp(0, 100);
            _addEvent(GameEventType.groupFormed, 'Coesao de Grupo',
                'Os membros de "${group.name}" fortaleceram seus lacos. Coesao: ${group.cohesion.toStringAsFixed(0)}%.');
          }
          break;
      }
    }
  }

  // ==================== GRAVIDEZ ====================

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
        // Nascimentos aumentam lealdade geral
        for (final n in aliveNpcs) { n.loyalty += 0.5; }
      }
    }
  }

  // ==================== ENVELHECIMENTO ====================

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

  // ==================== TREINO PROFISSIONAL ====================

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
      if (npc.profession == Profession.trainer) {
        if (_rng.nextDouble() < 0.1) {
          npc.attributes.strength += 0.05;
          npc.attributes.endurance += 0.05;
          npc.attributes.intelligence += 0.05;
        }
      }
    }
  }

  // ==================== CONSTRUCAO MANUAL (JOGADOR DECIDE) ====================

  // Auto-build REMOVIDO. O jogador agora ORDENA construcoes.
  // NPCs reagem com eventos narrativos.

  /// Edificios disponiveis para construir (desbloqueados pelo tier da torre)
  List<BuildingType> get availableBuildings {
    final currentTier = ((state.highestFloorCleared) ~/ 10) + (state.highestFloorCleared % 10 > 0 ? 1 : 0);
    return BuildingType.values.where((type) {
      if (citadel.hasBuilding(type)) return false;
      if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
      final b = Building(type: type);
      return b.requiredTier <= currentTier;
    }).toList();
  }

  /// Verifica se edificio pode ser construido
  bool canBuild(BuildingType type) {
    if (citadel.hasBuilding(type)) return false;
    if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
    final b = Building(type: type);
    final currentTier = ((state.highestFloorCleared) ~/ 10) + (state.highestFloorCleared % 10 > 0 ? 1 : 0);
    if (b.requiredTier > currentTier) return false;
    return citadel.resources.canAfford(b.cost);
  }

  /// Verificar se pode fazer upgrade de edificio
  bool canUpgradeBuilding(BuildingType type) {
    final b = citadel.getBuilding(type);
    if (b == null) return false;
    if (b.level >= b.maxLevel) return false;
    return citadel.resources.canAfford(b.upgradeCost);
  }

  /// Fazer upgrade de edificio
  bool upgradeBuilding(BuildingType type) {
    final b = citadel.getBuilding(type);
    if (b == null || b.level >= b.maxLevel) return false;
    if (!citadel.resources.canAfford(b.upgradeCost)) return false;

    citadel.resources.spend(b.upgradeCost);
    b.level++;

    _addEvent(GameEventType.upgrade, '${b.name} Melhorado!',
        '${b.name} evoluiu para nivel ${b.level}. Eficiencia aumentada!',
        isMajor: true);

    // Reacao NPC ao upgrade
    _processNpcBuildReaction(type, isUpgrade: true);

    return true;
  }

  /// Reacoes dos NPCs quando o jogador constroi algo
  void _processNpcBuildReaction(BuildingType type, {bool isUpgrade = false}) {
    final action = isUpgrade ? 'melhoria' : 'construcao';

    switch (type) {
      case BuildingType.barracks:
      case BuildingType.trainingField:
        // Guardas/exploradores gostam
        for (final npc in aliveNpcs.where((n) =>
            n.profession == Profession.guard || n.profession == Profession.explorer)) {
          npc.loyalty += 2;
        }
        // Medrosos nao gostam
        for (final npc in aliveNpcs.where((n) => n.traits.contains(PersonalityTrait.coward))) {
          npc.loyalty -= 1;
        }
        _addEvent(GameEventType.politicalEvent, 'Reacao: $action Militar',
            'Guardas e exploradores aprovam a $action. Os mais timidos ficam desconfortaveis.');
        break;
      case BuildingType.temple:
        citadel.resources.morale += 5;
        for (final npc in aliveNpcs) { npc.loyalty += 1; }
        _addEvent(GameEventType.celebration, 'Fe Renovada',
            'A $action do Templo trouxe esperanca. Todos se sentem mais seguros.');
        break;
      case BuildingType.tavern:
        citadel.resources.morale += 3;
        // Revela info sobre suspeitos
        for (final npc in aliveNpcs.where((n) => n.origin.isDarkOrigin && !n.isSuspicious)) {
          if (_rng.nextDouble() < 0.3) {
            npc.isSuspicious = true;
            _addEvent(GameEventType.system, 'Fofoca na Taverna',
                'Rumores na Taverna indicam que ${npc.name} pode ter um passado sombrio...',
                involvedIds: [npc.id]);
          }
        }
        _addEvent(GameEventType.politicalEvent, 'Taverna Aberta',
            'A Taverna se tornou o ponto de encontro. Fofocas e informacoes fluem livremente.');
        break;
      case BuildingType.arena:
        for (final npc in aliveNpcs.where((n) => n.traits.contains(PersonalityTrait.brave))) {
          npc.loyalty += 3;
          npc.fame += 1;
        }
        _addEvent(GameEventType.politicalEvent, 'Arena Inaugurada!',
            'Os mais bravos mal podem esperar para provar seu valor. Os medrosos evitam o local.');
        break;
      case BuildingType.councilHall:
        for (final npc in aliveNpcs) { npc.loyalty += 1; }
        _addEvent(GameEventType.politicalEvent, 'Democracia Emergente',
            'A Sala do Conselho da voz ao povo. Todos sentem que suas opinioes importam agora.');
        break;
      case BuildingType.promotionHall:
        for (final npc in aliveNpcs.where((n) => n.traits.contains(PersonalityTrait.leader))) {
          npc.loyalty += 3;
        }
        _addEvent(GameEventType.politicalEvent, 'Caminho para Grandeza',
            'A Sala de Promocao abre novas possibilidades. Os ambiciosos planejam sua ascensao.');
        break;
      case BuildingType.farm:
      case BuildingType.kitchen:
        if (citadel.resources.food < population * 5) {
          for (final npc in aliveNpcs) { npc.loyalty += 1; }
          _addEvent(GameEventType.celebration, 'Comida Garantida',
              'Com fome rondando, a $action traz alivio. O lider pensa no povo.');
        }
        break;
      case BuildingType.monument:
        citadel.resources.morale += 10;
        for (final npc in aliveNpcs) {
          npc.loyalty += 3;
          npc.fame += 1;
        }
        _addEvent(GameEventType.celebration, 'MONUMENTO ERGUIDO!',
            'O Monumento se ergue. Um simbolo eterno de tudo que a humanidade conquistou na Torre. '
            'As geracoes futuras lembrarao deste dia.',
            isMajor: true);
        break;
      case BuildingType.nexus:
        _addEvent(GameEventType.discovery, 'NEXUS ATIVADO!',
            'O Nexus da Torre pulsa com energia. A conexao entre a Cidadela e a Torre se fortalece. '
            'Segredos antigos comecam a se revelar...',
            isMajor: true);
        break;
      default:
        // Reacao generica
        if (_rng.nextDouble() < 0.4) {
          _addEvent(GameEventType.construction, 'Progresso',
              'A $action traz satisfacao. A Cidadela cresce.');
        }
    }
  }

  /// Arena: processar duelos periodicos
  void _processArenaEvents() {
    if (!citadel.hasBuilding(BuildingType.arena)) return;
    if (state.currentDay % 7 != 0) return;
    if (aliveNpcs.length < 2) return;

    // Duelo voluntario
    if (_rng.nextDouble() < 0.3) {
      final fighters = aliveNpcs.where((n) =>
          n.attributes.mentalStability > 30 &&
          n.attributes.combatPower > 3.0).toList();
      if (fighters.length < 2) return;

      fighters.shuffle(_rng);
      final a = fighters[0];
      final b = fighters[1];
      final aWins = a.attributes.combatPower + _rng.nextDouble() * 3 >
          b.attributes.combatPower + _rng.nextDouble() * 3;

      if (aWins) {
        a.fame += 2;
        a.attributes.strength += 0.2;
        b.attributes.endurance += 0.1;
        _addEvent(GameEventType.combat, 'Duelo na Arena',
            '${a.name} venceu ${b.name} em duelo na Arena! +Fama, +Stats.',
            involvedIds: [a.id, b.id]);
      } else {
        b.fame += 2;
        b.attributes.strength += 0.2;
        a.attributes.endurance += 0.1;
        _addEvent(GameEventType.combat, 'Duelo na Arena',
            '${b.name} venceu ${a.name} em duelo na Arena! +Fama, +Stats.',
            involvedIds: [a.id, b.id]);
      }
    }
  }

  /// Taverna: processar eventos sociais
  void _processTavernEvents() {
    if (!citadel.hasBuilding(BuildingType.tavern)) return;
    if (state.currentDay % 5 != 0) return;

    // Chance de revelar traidor
    if (_rng.nextDouble() < 0.1) {
      final hidden = aliveNpcs.where((n) => n.origin.isDarkOrigin && !n.isSuspicious).toList();
      if (hidden.isNotEmpty) {
        final npc = hidden[_rng.nextInt(hidden.length)];
        npc.isSuspicious = true;
        _addEvent(GameEventType.system, 'Boato na Taverna',
            'Depois de muitas bebidas, alguem mencionou que ${npc.name} tem um passado questionavel...',
            involvedIds: [npc.id]);
      }
    }

    // Bonus de relacao
    if (_rng.nextDouble() < 0.2 && aliveNpcs.length >= 2) {
      final a = aliveNpcs[_rng.nextInt(aliveNpcs.length)];
      Npc b;
      do { b = aliveNpcs[_rng.nextInt(aliveNpcs.length)]; } while (b.id == a.id);
      final rel = a.relationships.where((r) => r.targetId == b.id);
      if (rel.isNotEmpty) {
        rel.first.affinity += 0.1;
      }
    }
  }

  // Auto-build/auto-upgrade REMOVIDOS: jogador ordena construcoes

  // ==================== COMBATE NA TORRE ====================

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

    // === CUSTO FIXO POR NPC (pago ANTES, independente do resultado) ===
    final costPerNpc = expeditionCostPerNpc(floor.number);
    final totalCost = party.length * costPerNpc;
    citadel.resources.food -= totalCost;

    challenge.log.add('=== ANDAR ${floor.number}: ${floor.type.label.toUpperCase()} ===');
    challenge.log.add(floor.description);
    if (floor.specialCondition.isNotEmpty) {
      challenge.log.add('> Condicao: ${floor.specialCondition}');
    }
    challenge.log.add('Custo: ${totalCost.toStringAsFixed(0)} comida (${costPerNpc.toStringAsFixed(1)}/NPC x ${party.length})');
    challenge.log.add('');

    // === FADIGA POR EXPEDICAO ===
    for (final npc in party) {
      final baseFatigue = 20.0 + floor.tier * 1.5;
      npc.fatigue = (npc.fatigue + baseFatigue).clamp(0.0, 100.0);
      if (npc.lastExpeditionDay == state.currentDay) {
        npc.consecutiveExpeditions++;
        npc.fatigue = (npc.fatigue + 10.0 + npc.consecutiveExpeditions * 2).clamp(0.0, 100.0);
      } else {
        npc.consecutiveExpeditions = 1;
      }
      npc.lastExpeditionDay = state.currentDay;
    }

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
          npc.loyalty += 3;
          npc.attributes.strength += 0.2;
          npc.attributes.endurance += 0.2;
          npc.attributes.mentalStability -= 2;
          npc.history.add('Sobreviveu ao Andar ${floor.number} no Dia ${state.currentDay}');
          challenge.log.add('  [O] ${npc.name} sobreviveu. (+Fama, +Stats, +Lealdade)');
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
          npc.loyalty -= 2;
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

    // Risco de acidente durante treino em andar
    if (_rng.nextDouble() < 0.03) {
      final unlucky = party[_rng.nextInt(party.length)];
      unlucky.attributes.endurance -= 0.5;
      challenge.log.add('');
      challenge.log.add('  [!] ${unlucky.name} sofreu um ferimento leve durante o treino.');
    }

    // Chance de reativar ameaca oculta durante treino
    if (_rng.nextDouble() < 0.04 + (floor.timesReexplored * 0.01)) {
      challenge.log.add('');
      challenge.log.add('  [!!] Ameaca oculta detectada! Novas criaturas apareceram!');
      final unlucky = party[_rng.nextInt(party.length)];
      if (_rng.nextDouble() < 0.15) {
        _killNpc(unlucky, 'Morreu em ameaca reativada durante treino no Andar ${floor.number}');
        challenge.casualties.add(unlucky.id);
        challenge.log.add('  [X] ${unlucky.name} nao sobreviveu a ameaca!');
      } else {
        unlucky.attributes.endurance -= 1;
        unlucky.attributes.mentalStability -= 5;
        challenge.log.add('  [!] ${unlucky.name} foi ferido pela ameaca, mas sobreviveu.');
      }
    }

    // Chance de descoberta rara durante treino
    if (_rng.nextDouble() < 0.05) {
      challenge.log.add('');
      challenge.log.add('  [*] Descoberta rara durante o treino!');
      citadel.resources.knowledge += 5;
    }

    challenge.completed = true;
    challenge.victory = true;
    citadel.resources.food -= party.length * 2;

    _addEvent(GameEventType.training, 'Treino no Andar ${floor.number}',
        '${party.length} membros treinaram no andar ${floor.number}. Custo: ${party.length * 2} comida.',
        involvedIds: partyIds);

    return challenge;
  }

  // ==================== GRUPOS ====================

  NpcGroup createGroup(String name, List<String> memberIds, GroupRole role) {
    final group = NpcGroup(
      id: _generateGroupId(),
      name: name,
      memberIds: memberIds,
      role: role,
    );

    // Definir lider automaticamente (maior poder + carisma)
    if (memberIds.isNotEmpty) {
      final members = memberIds
          .map((id) => npcs.where((n) => n.id == id).firstOrNull)
          .whereType<Npc>()
          .toList();
      if (members.isNotEmpty) {
        members.sort((a, b) =>
            (b.attributes.combatPower + b.attributes.charisma)
                .compareTo(a.attributes.combatPower + a.attributes.charisma));
        group.leaderId = members.first.id;
      }
    }

    for (final id in memberIds) {
      final npc = npcs.where((n) => n.id == id).firstOrNull;
      if (npc != null) {
        npc.groupId = group.id;
      }
    }

    groups.add(group);

    _addEvent(GameEventType.groupFormed, 'Grupo "${group.name}" Formado',
        '${memberIds.length} membros foram organizados no grupo "${group.name}" (${role.label}). '
        'Lider: ${npcs.firstWhere((n) => n.id == group.leaderId).name}.',
        involvedIds: memberIds, isMajor: true);

    return group;
  }

  void disbandGroup(String groupId) {
    final group = groups.firstWhere((g) => g.id == groupId, orElse: () => NpcGroup(id: '', name: ''));
    if (group.id.isEmpty) return;

    for (final memberId in group.memberIds) {
      final npc = npcs.where((n) => n.id == memberId).firstOrNull;
      if (npc != null) npc.groupId = null;
    }

    _addEvent(GameEventType.groupFormed, 'Grupo "${group.name}" Dissolvido',
        'O grupo "${group.name}" foi dissolvido. Membros estao livres.',
        involvedIds: group.memberIds);

    groups.removeWhere((g) => g.id == groupId);
  }

  void addToGroup(String groupId, String npcId) {
    final group = groups.firstWhere((g) => g.id == groupId, orElse: () => NpcGroup(id: '', name: ''));
    if (group.id.isEmpty) return;
    final npc = npcs.where((n) => n.id == npcId).firstOrNull;
    if (npc == null) return;

    // Remover do grupo anterior
    if (npc.groupId != null) {
      final oldGroup = groups.where((g) => g.id == npc.groupId).firstOrNull;
      if (oldGroup != null) oldGroup.memberIds.remove(npcId);
    }

    group.memberIds.add(npcId);
    npc.groupId = groupId;
  }

  void removeFromGroup(String npcId) {
    final npc = npcs.where((n) => n.id == npcId).firstOrNull;
    if (npc == null || npc.groupId == null) return;

    final group = groups.where((g) => g.id == npc.groupId).firstOrNull;
    if (group != null) {
      group.memberIds.remove(npcId);
    }
    npc.groupId = null;
  }

  // ==================== RECOMPENSAS ====================

  void _applyFloorRewards(TowerFloor floor) {
    final tier = floor.tier;
    final n = floor.number;
    final res = citadel.resources;

    // === BOSS FLOORS (cada 10 andares) - Recompensas massivas ===
    if (n % 10 == 0) {
      final mult = tier.toDouble();
      res.food += 30 * mult;
      res.wood += 30 * mult;
      res.stone += 30 * mult;
      res.iron += 25 * mult;
      res.knowledge += 25 * mult;
      res.morale += (10 + tier * 2).toDouble();
      citadel.populationCapacity += 5 + tier;

      // Boss tier 5+: revelar talentos
      if (tier >= 5) {
        for (final npc in aliveNpcs) {
          if (!npc.talentDiscovered && npc.hiddenTalent != HiddenTalent.none && _rng.nextDouble() < 0.4) {
            npc.talentDiscovered = true;
            _addEvent(GameEventType.discovery, 'Talento Revelado pelo Boss!',
                '${npc.name} despertou ${npc.hiddenTalent.label} apos a batalha contra o Boss do Tier $tier!',
                involvedIds: [npc.id], isMajor: true);
          }
        }
      }

      _addEvent(GameEventType.towerCleared, 'BOSS TIER $tier DERROTADO!',
          'Recompensas massivas! Capacidade +${5 + tier}. A cidadela evolui!',
          isMajor: true);
      return;
    }

    // === ELITE FLOORS (cada 5 andares) - Recompensas boas ===
    if (n % 5 == 0 && n % 10 != 0) {
      final mult = tier * 0.7;
      res.food += 15 * mult;
      res.wood += 10 * mult;
      res.stone += 10 * mult;
      res.iron += 10 * mult;
      res.knowledge += 15 * mult;
      res.morale += 5;
      return;
    }

    // === ANDARES NORMAIS - Recompensas baseadas no tipo ===
    final baseMult = 1.0 + (tier - 1) * 0.5;
    switch (floor.type) {
      case FloorType.combat:
      case FloorType.gauntlet:
        res.iron += 5 * baseMult;
        res.stone += 3 * baseMult;
        break;
      case FloorType.survival:
      case FloorType.hunt:
        res.food += 8 * baseMult;
        res.wood += 5 * baseMult;
        break;
      case FloorType.strategic:
      case FloorType.puzzle:
        res.knowledge += 6 * baseMult;
        res.iron += 3 * baseMult;
        break;
      case FloorType.moral:
        res.knowledge += 5 * baseMult;
        res.morale += 3;
        break;
      case FloorType.mystery:
        res.knowledge += 8 * baseMult;
        // Chance de revelar talento
        if (_rng.nextDouble() < 0.15) {
          final candidates = aliveNpcs.where((n) => !n.talentDiscovered && n.hiddenTalent != HiddenTalent.none).toList();
          if (candidates.isNotEmpty) {
            final lucky = candidates[_rng.nextInt(candidates.length)];
            lucky.talentDiscovered = true;
            _addEvent(GameEventType.discovery, 'Talento Oculto!',
                '${lucky.name} descobriu ${lucky.hiddenTalent.label} no Andar Misterio!',
                involvedIds: [lucky.id], isMajor: true);
          }
        }
        break;
      case FloorType.elite:
        res.food += 4 * baseMult;
        res.wood += 4 * baseMult;
        res.stone += 4 * baseMult;
        res.iron += 4 * baseMult;
        res.knowledge += 4 * baseMult;
        break;
      case FloorType.boss:
        // Ja tratado acima
        break;
    }

    // Bonus de fama para sobreviventes (escala com tier)
    res.morale += (1 + tier * 0.5);
  }

  // ==================== MORTE ====================

  void _killNpc(Npc npc, String cause) {
    npc.alive = false;
    npc.history.add('Morreu: $cause (Dia ${state.currentDay})');
    state.totalDeaths++;

    // Remover do grupo
    if (npc.groupId != null) {
      final group = groups.where((g) => g.id == npc.groupId).firstOrNull;
      if (group != null) {
        group.memberIds.remove(npc.id);
        group.casualties++;
        if (group.leaderId == npc.id && group.memberIds.isNotEmpty) {
          // Eleger novo lider
          final members = group.memberIds
              .map((id) => npcs.where((n) => n.id == id && n.alive).firstOrNull)
              .whereType<Npc>()
              .toList();
          if (members.isNotEmpty) {
            members.sort((a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower));
            group.leaderId = members.first.id;
          }
        }
      }
    }

    if (npc.partnerId != null) {
      final partner = npcs.where((n) => n.id == npc.partnerId).firstOrNull;
      if (partner != null) {
        partner.attributes.mentalStability -= 15;
        partner.traumas.add('Perda de ${npc.name} no dia ${state.currentDay}');
        partner.partnerId = null;
        partner.loyalty -= 5;
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

  // ==================== CONSTRUCAO ====================

  bool buildStructure(BuildingType type) {
    if (citadel.buildings.length >= citadel.level.maxBuildings) return false;
    final building = Building(type: type);
    if (!citadel.resources.canAfford(building.cost)) return false;

    citadel.resources.spend(building.cost);
    citadel.buildings.add(building);

    _addEvent(GameEventType.construction, 'Nova Construcao: ${building.name}',
        '${building.name} foi construido(a). ${building.description}');

    // NPCs reagem a construcao
    _processNpcBuildReaction(type);

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

    // Evolucao aumenta lealdade
    for (final npc in aliveNpcs) { npc.loyalty += 3; }

    return true;
  }

  /// Upgrade do armazem (jogador ordena)
  bool upgradeStorage() {
    final next = citadel.storageLevel.nextLevel;
    if (next == null) return false;
    final cost = citadel.storageLevel.upgradeCost;
    if (!citadel.resources.canAfford(cost)) return false;
    // Verificar tier da torre necessario
    final currentTier = ((state.highestFloorCleared) ~/ 10) + (state.highestFloorCleared % 10 > 0 ? 1 : 0);
    if (currentTier < next.requiredTier) return false;

    citadel.resources.spend(cost);
    final oldLevel = citadel.storageLevel;
    citadel.storageLevel = next;

    _addEvent(GameEventType.upgrade, 'Armazem Melhorado!',
        'Armazem evoluiu de ${oldLevel.label} para ${next.label}! '
        'Capacidade por recurso: ${next.isInfinite ? "INFINITA" : next.capacity.toStringAsFixed(0)}.',
        isMajor: true);

    return true;
  }

  /// Verifica se pode fazer upgrade no armazem
  bool canUpgradeStorage() {
    final next = citadel.storageLevel.nextLevel;
    if (next == null) return false;
    final cost = citadel.storageLevel.upgradeCost;
    if (!citadel.resources.canAfford(cost)) return false;
    final currentTier = ((state.highestFloorCleared) ~/ 10) + (state.highestFloorCleared % 10 > 0 ? 1 : 0);
    if (currentTier < next.requiredTier) return false;
    return true;
  }

  void assignProfession(String npcId, Profession profession) {
    final npc = npcs.firstWhere((n) => n.id == npcId);
    final old = npc.profession;
    npc.profession = profession;
    npc.history.add('Profissao mudou: ${old.label} -> ${profession.label} (Dia ${state.currentDay})');
  }

  // ==================== EVENTOS ====================

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

  // ==================== SERIALIZACAO ====================

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
    groups = (json['groups'] as List<dynamic>?)
        ?.map((g) => NpcGroup.fromJson(g as Map<String, dynamic>))
        .toList() ?? [];
    trainingSuggestions = (json['trainingSuggestions'] as List<dynamic>?)
        ?.map((s) => TrainingSuggestion.fromJson(s as Map<String, dynamic>))
        .toList() ?? [];
    _groupIdCounter = json['groupIdCounter'] as int? ?? 0;
    _suggestionIdCounter = json['suggestionIdCounter'] as int? ?? 0;
  }
}

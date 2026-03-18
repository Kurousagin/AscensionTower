// lib/services/quest_service.dart
//
// QuestService — gerencia missões geradas por habitantes da torre.
// Máximo 3 missões ativas simultaneamente.

import 'dart:math';
import '../models/floor_faction.dart';
import '../models/floor_inhabitant.dart';
import '../models/tower.dart';
import '../models/citadel.dart';
import '../models/game_event.dart';
// ServiceEvent is defined in game_event.dart

class QuestService {
  final Random _rng;
  final List<FloorQuest> _activeQuests = [];
  final List<FloorQuest> _availableQuests = [];
  int _questIdCounter = 0;

  static const int maxActiveQuests = 3;

  QuestService(this._rng);

  // ── Accessors ─────────────────────────────────────────────────────────────

  List<FloorQuest> get activeQuests => List.unmodifiable(_activeQuests);

  Set<String> get busyGroupIds => _activeQuests
      .where((q) => q.assignedGroupId != null)
      .map((q) => q.assignedGroupId!)
      .toSet();
  List<FloorQuest> get availableQuests => List.unmodifiable(_availableQuests);

  List<FloorQuest> questsForFloor(int floorNumber) {
    return [
      ..._activeQuests.where((q) => q.floorNumber == floorNumber),
      ..._availableQuests.where((q) => q.floorNumber == floorNumber),
    ];
  }

  // ── Geração de missões ─────────────────────────────────────────────────────

  void generateQuests({
    required List<TowerFloor> floors,
    required Map<String, FactionRelation> factionRelations,
    required int currentDay,
    List<FactionWar> activeWars = const [],
  }) {
    for (final floor in floors.where((f) => f.cleared)) {
      final faction = floor.controllingFaction;

      // Só gera missões para andares com facção e standing razoável
      if (faction == FloorFaction.none) continue;
      final standing =
          factionRelations[faction.key]?.standing ?? faction.initialStanding;
      if (standing < -20) continue;

      // Evita gerar missão duplicada para o mesmo andar
      final alreadyHas = _availableQuests.any(
        (q) => q.floorNumber == floor.number,
      );
      if (alreadyHas) continue;

      final quest = _generateQuestForFloor(floor, faction, currentDay);
      if (quest != null) _availableQuests.add(quest);

      // War quest — at most 1 per floor
      final alreadyHasWarQuest = _availableQuests.any(
        (q) =>
            q.floorNumber == floor.number &&
            (q.title.startsWith('GUERRA:') ||
                q.title.startsWith('ZONA DE GUERRA:')),
      );
      if (!alreadyHasWarQuest) {
        for (final war in activeWars) {
          if (war.resolved) continue;
          if (war.aggressor == faction ||
              war.defender == faction ||
              war.contestedFloors.contains(floor.number)) {
            final warQuest = _generateWarQuest(floor, faction, currentDay, war);
            if (warQuest != null) {
              _availableQuests.add(warQuest);
              break; // only 1 war quest per floor
            }
          }
        }
      }
    }
  }

  FloorQuest? _generateQuestForFloor(
    TowerFloor floor,
    FloorFaction faction,
    int currentDay,
  ) {
    final roll = _rng.nextInt(5);
    final type = QuestType.values[roll];
    final dayLimit = currentDay + 20 + _rng.nextInt(20);

    _questIdCounter++;
    final id = 'quest_$_questIdCounter';
    final giver = 'inhabitant_${faction.key}_f${floor.number}';

    switch (type) {
      case QuestType.fetch:
        return FloorQuest(
          id: id,
          giverInhabitantId: giver,
          floorNumber: floor.number,
          type: QuestType.fetch,
          title: 'Coleta para ${faction.shortLabel}',
          description:
              '${faction.label} precisa de suprimentos do Andar ${floor.number}. '
              'Re-explore o andar para coletar o que pedem.',
          resourceReward: _rewardForFaction(faction),
          standingReward: 5.0,
          factionReward: faction,
          dayLimit: dayLimit,
          targetFloor: floor.number,
        );

      case QuestType.investigate:
        return FloorQuest(
          id: id,
          giverInhabitantId: giver,
          floorNumber: floor.number,
          type: QuestType.investigate,
          title: 'Investigação no Andar ${floor.number}',
          description:
              '${faction.label} detectou atividade estranha no Andar ${floor.number}. '
              'Investigue re-explorando o andar.',
          resourceReward: _rewardForFaction(faction),
          standingReward: 8.0,
          factionReward: faction,
          dayLimit: dayLimit,
          targetFloor: floor.number,
        );

      case QuestType.escort:
        return FloorQuest(
          id: id,
          giverInhabitantId: giver,
          floorNumber: floor.number,
          type: QuestType.escort,
          title: 'Escolta para ${faction.shortLabel}',
          description:
              '${faction.label} precisa de escolta no Andar ${floor.number}. '
              'Complete uma expedição bem-sucedida neste andar.',
          resourceReward: _rewardForFaction(faction),
          standingReward: 10.0,
          factionReward: faction,
          dayLimit: dayLimit,
          targetFloor: floor.number,
        );

      case QuestType.eliminate:
        return FloorQuest(
          id: id,
          giverInhabitantId: giver,
          floorNumber: floor.number,
          type: QuestType.eliminate,
          title: 'Eliminação no Andar ${floor.number}',
          description:
              '${faction.label} quer que você elimine uma ameaça no Andar ${floor.number}. '
              'Complete uma tentativa bem-sucedida neste andar.',
          resourceReward: {
            'iron': 20,
            'food': 15,
            ..._rewardForFaction(faction),
          },
          standingReward: 12.0,
          factionReward: faction,
          dayLimit: dayLimit,
          targetFloor: floor.number,
        );

      case QuestType.deliver:
        final cost = _costForFaction(faction);
        return FloorQuest(
          id: id,
          giverInhabitantId: giver,
          floorNumber: floor.number,
          type: QuestType.deliver,
          title: 'Entrega para ${faction.shortLabel}',
          description:
              '${faction.label} solicita uma entrega de recursos. '
              'Forneça os itens pedidos para completar a missão.',
          resourceReward: _rewardForFaction(faction),
          standingReward: 8.0,
          factionReward: faction,
          dayLimit: dayLimit,
          resourceCost: cost,
        );
    }
  }

  FloorQuest? _generateWarQuest(
    TowerFloor floor,
    FloorFaction faction,
    int currentDay,
    FactionWar war,
  ) {
    _questIdCounter++;
    final id = 'quest_$_questIdCounter';
    final giver = 'war_${faction.key}_f${floor.number}';

    // Contested zone takes priority
    if (war.contestedFloors.contains(floor.number)) {
      return FloorQuest(
        id: id,
        giverInhabitantId: giver,
        floorNumber: floor.number,
        type: QuestType.investigate,
        title: 'ZONA DE GUERRA: Andar ${floor.number}',
        description:
            'Este andar está sendo disputado. Investigue e relate o que encontrar.',
        resourceReward: {'knowledge': 25, 'iron': 10},
        standingReward: 20.0,
        factionReward: faction,
        dayLimit: currentDay + 5,
        targetFloor: floor.number,
      );
    }

    if (faction == war.aggressor) {
      return FloorQuest(
        id: id,
        giverInhabitantId: giver,
        floorNumber: floor.number,
        type: QuestType.eliminate,
        title: 'GUERRA: Ataque para ${faction.shortLabel}',
        description:
            '${faction.label} está em guerra. Elimine resistência no Andar ${floor.number} para avançar.',
        resourceReward: {'iron': 30, 'food': 20},
        standingReward: 15.0,
        factionReward: faction,
        dayLimit: currentDay + 7,
        targetFloor: floor.number,
      );
    }

    if (faction == war.defender) {
      return FloorQuest(
        id: id,
        giverInhabitantId: giver,
        floorNumber: floor.number,
        type: QuestType.escort,
        title: 'GUERRA: Defesa do Andar ${floor.number}',
        description:
            '${faction.label} sob ataque. Escolte civis do Andar ${floor.number} para segurança.',
        resourceReward: {'food': 35, 'knowledge': 15},
        standingReward: 18.0,
        factionReward: faction,
        dayLimit: currentDay + 7,
        targetFloor: floor.number,
      );
    }

    return null;
  }

  Map<String, int> _rewardForFaction(FloorFaction faction) {
    switch (faction) {
      case FloorFaction.ironPact:
        return {'ironOre': 25, 'food': 10};
      case FloorFaction.bloodMarket:
        return {'food': 35, 'ironOre': 10};
      case FloorFaction.voidChildren:
        return {'food': 20, 'stoneRaw': 15, 'knowledge': 10};
      case FloorFaction.towerServants:
        return {'ironOre': 30, 'knowledge': 20, 'stoneRaw': 15};
      case FloorFaction.silentOrder:
        return {'knowledge': 30, 'food': 5};
      case FloorFaction.none:
        return {'food': 15};
    }
  }

  Map<String, int> _costForFaction(FloorFaction faction) {
    switch (faction) {
      case FloorFaction.ironPact:
        return {'iron': 15};
      case FloorFaction.silentOrder:
        return {'knowledge': 20};
      case FloorFaction.bloodMarket:
        return {'food': 25};
      case FloorFaction.voidChildren:
        return {'food': 10};
      case FloorFaction.towerServants:
        return {'iron': 20, 'knowledge': 15};
      case FloorFaction.none:
        return {'food': 10};
    }
  }

  // ── Aceitar missão ────────────────────────────────────────────────────────

  String acceptQuest(
    String questId,
    int currentDay, {
    String? groupId,
    List<String>? npcIds,
    double groupPower = 0,
    double groupIntelligence = 0,
    double groupLuck = 0,
  }) {
    if (_activeQuests.length >= maxActiveQuests) {
      return 'Máximo de $_maxActiveQuestsText missões ativas atingido.';
    }

    final idx = _availableQuests.indexWhere((q) => q.id == questId);
    if (idx == -1) return 'Missão não encontrada.';

    final quest = _availableQuests.removeAt(idx);
    quest.acceptedDay = currentDay;
    quest.assignedGroupId = groupId;
    quest.assignedNpcIds = npcIds ?? [];

    // Calcula chance de falha baseada no tipo e atributos do grupo
    quest.failureChance = _calculateFailureChance(
      quest.type,
      groupPower: groupPower,
      groupIntelligence: groupIntelligence,
      groupLuck: groupLuck,
    );

    _activeQuests.add(quest);

    final failureStr = quest.failureChance > 0
        ? ' (Risco de falha: ${(quest.failureChance * 100).toStringAsFixed(0)}%)'
        : '';
    return 'Missão "${quest.title}" aceita!$failureStr';
  }

  /// Versão pública de _calculateFailureChance para uso na UI (preview antes de aceitar).
  double previewFailureChance(
    QuestType type, {
    required double groupPower,
    required double groupIntelligence,
    required double groupLuck,
  }) => _calculateFailureChance(
    type,
    groupPower: groupPower,
    groupIntelligence: groupIntelligence,
    groupLuck: groupLuck,
  );

  double _calculateFailureChance(
    QuestType type, {
    required double groupPower,
    required double groupIntelligence,
    required double groupLuck,
  }) {
    // Base por tipo
    double base = switch (type) {
      QuestType.fetch => 0.10,
      QuestType.deliver => 0.05,
      QuestType.investigate => 0.20,
      QuestType.escort => 0.25,
      QuestType.eliminate => 0.30,
    };

    // Grupo forte reduz chance de falha
    if (groupPower >= 15) {
      base -= 0.10;
    } else if (groupPower >= 8) {
      base -= 0.05;
    } else if (groupPower < 4) {
      base += 0.15;
    }
    if (groupIntelligence >= 10) base -= 0.05;
    if (groupLuck >= 8) base -= 0.05;

    return base.clamp(0.02, 0.70);
  }

  static const String _maxActiveQuestsText =
      '3'; // deve ser igual a maxActiveQuests

  // ── Verificar completude ───────────────────────────────────────────────────

  /// Verifica missões que podem ser completadas por ação no andar.
  /// Chamado após reexploreFloor ou attemptFloor.
  List<ServiceEvent> checkCompletion({
    required int floorNumber,
    required int currentDay,
    required Map<String, FactionRelation> factionRelations,
    required Citadel citadel,
    required bool wasSuccessfulAttempt, // true = tentativa vitoriosa
    required bool wasReexploration, // true = re-exploração
  }) {
    final events = <ServiceEvent>[];

    final toComplete = <FloorQuest>[];

    for (final quest in _activeQuests) {
      if (quest.targetFloor != floorNumber) continue;

      final shouldComplete = switch (quest.type) {
        QuestType.fetch => wasReexploration,
        QuestType.investigate => wasReexploration,
        QuestType.escort => wasSuccessfulAttempt,
        QuestType.eliminate => wasSuccessfulAttempt,
        QuestType.deliver => false, // completado via recurso separado
      };

      if (shouldComplete) toComplete.add(quest);
    }

    for (final quest in toComplete) {
      _activeQuests.remove(quest);
      quest.completed = true;

      // Aplica recompensas
      _applyResourceReward(quest.resourceReward, citadel);

      // Aplica standing
      if (quest.factionReward != null && quest.standingReward > 0) {
        final rel = factionRelations[quest.factionReward!.key];
        if (rel != null) {
          rel.standing = (rel.standing + quest.standingReward).clamp(
            -100.0,
            100.0,
          );
        }
      }

      final rewardStr = quest.resourceReward.entries
          .map((e) => '+${e.value} ${e.key}')
          .join(', ');

      events.add(
        ServiceEvent(
          type: GameEventType.questEvent,
          title: 'Missão Concluída: ${quest.title}',
          description:
              'Você completou "${quest.title}". '
              'Recompensas: $rewardStr'
              '${quest.standingReward > 0 ? ', +${quest.standingReward.toStringAsFixed(0)} standing com ${quest.factionReward?.label ?? "facção"}.' : "."}',
          isMajor: false,
        ),
      );
    }

    return events;
  }

  /// Verifica completude de missão de entrega quando recursos são gastos.
  List<ServiceEvent> checkDeliveryCompletion({
    required int currentDay,
    required Citadel citadel,
    required Map<String, FactionRelation> factionRelations,
  }) {
    final events = <ServiceEvent>[];
    final toComplete = <FloorQuest>[];

    for (final quest in _activeQuests) {
      if (quest.type != QuestType.deliver) continue;
      final cost = quest.resourceCost;
      if (cost == null) continue;

      // Verifica se o jogador tem os recursos
      bool canDeliver = true;
      for (final entry in cost.entries) {
        if (_getResource(citadel, entry.key) < entry.value) {
          canDeliver = false;
          break;
        }
      }
      if (canDeliver) toComplete.add(quest);
    }

    for (final quest in toComplete) {
      final cost = quest.resourceCost!;
      // Debita custo
      for (final entry in cost.entries) {
        _adjustResource(citadel, entry.key, -entry.value.toDouble());
      }

      _activeQuests.remove(quest);
      quest.completed = true;
      _applyResourceReward(quest.resourceReward, citadel);

      if (quest.factionReward != null && quest.standingReward > 0) {
        final rel = factionRelations[quest.factionReward!.key];
        if (rel != null) {
          rel.standing = (rel.standing + quest.standingReward).clamp(
            -100.0,
            100.0,
          );
        }
      }

      events.add(
        ServiceEvent(
          type: GameEventType.questEvent,
          title: 'Entrega Concluída: ${quest.title}',
          description:
              'Entrega para ${quest.factionReward?.label ?? "facção"} concluída.',
          isMajor: false,
        ),
      );
    }

    return events;
  }

  // ── Expiração de missões ───────────────────────────────────────────────────

  List<ServiceEvent> processExpiration(int currentDay) {
    final events = <ServiceEvent>[];
    final expired = _activeQuests
        .where((q) => currentDay > q.dayLimit)
        .toList();

    for (final quest in expired) {
      _activeQuests.remove(quest);
      quest.failed = true;
      events.add(
        ServiceEvent(
          type: GameEventType.questEvent,
          title: 'Missão Expirada: ${quest.title}',
          description:
              'A missão "${quest.title}" expirou sem ser completada. '
              '${quest.factionReward != null ? "${quest.factionReward!.label} está desapontado." : ""}',
          standingDelta: quest.standingReward * -0.5, // penalidade de standing
          affectedFaction: quest.factionReward,
          isMajor: false,
        ),
      );
    }

    // Remove também missões disponíveis muito antigas
    _availableQuests.removeWhere((q) => currentDay - q.dayLimit > 10);

    return events;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _applyResourceReward(Map<String, int> reward, Citadel citadel) {
    for (final entry in reward.entries) {
      _adjustResource(citadel, entry.key, entry.value.toDouble());
    }
  }

  double _getResource(Citadel citadel, String key) {
    switch (key) {
      case 'food':
        return citadel.resources.food;
      case 'ironOre':
        return citadel.resources.ironOre;
      case 'woodLog':
        return citadel.resources.woodLog;
      case 'stoneRaw':
        return citadel.resources.stoneRaw;
      case 'ironBar':
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
      case 'iron':
        citadel.resources.ironOre += amount;
      case 'wood':
        citadel.resources.woodLog += amount;
      case 'stone':
        citadel.resources.stoneRaw += amount;
      case 'knowledge':
        citadel.resources.knowledge += amount;
    }
  }

  // ── Serialização ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'activeQuests': _activeQuests.map((q) => q.toJson()).toList(),
    'availableQuests': _availableQuests.map((q) => q.toJson()).toList(),
    'questIdCounter': _questIdCounter,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _activeQuests
      ..clear()
      ..addAll(
        (json['activeQuests'] as List<dynamic>? ?? []).map(
          (e) => FloorQuest.fromJson(e as Map<String, dynamic>),
        ),
      );
    _availableQuests
      ..clear()
      ..addAll(
        (json['availableQuests'] as List<dynamic>? ?? []).map(
          (e) => FloorQuest.fromJson(e as Map<String, dynamic>),
        ),
      );
    _questIdCounter = json['questIdCounter'] as int? ?? 0;
  }

  void clear() {
    _activeQuests.clear();
    _availableQuests.clear();
    _questIdCounter = 0;
  }
}

// ── Extensão de conveniência para FloorQuest ──────────────────────────────
//
// Adicione estas propriedades diretamente na classe FloorQuest (no seu model):
//
//   bool get isAvailable => !completed && !failed && acceptedDay == null;
//   bool get isActive    => !completed && !failed && acceptedDay != null;
//
// Se preferir não alterar o model, use esta extensão aqui:

extension FloorQuestStatus on FloorQuest {
  /// true enquanto a missão ainda não foi aceita (está em _availableQuests).
  // ignore: unnecessary_null_comparison
  bool get isAvailable => !completed && !failed && acceptedDay == null;

  /// true quando a missão foi aceita e ainda não concluída/falhada.
  bool get isActive => !completed && !failed;
}

// ServiceEvent is defined in game_event.dart

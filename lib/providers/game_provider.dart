import 'dart:async';
//import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:tower_ascension/models/floor_faction.dart';
import 'package:tower_ascension/models/floor_inhabitant.dart';
import 'package:tower_ascension/models/npc_enums.dart';
import 'package:tower_ascension/models/prison.dart';
import 'package:tower_ascension/models/simulacrum_battle.dart';
import 'package:tower_ascension/services/events/notification_service.dart';
import '../services/game_engine.dart';
import '../services/save_service.dart';
import '../services/crisis_flag_service.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/tower.dart';
import '../models/game_event.dart';
import '../models/group_model.dart';
import '../models/equipment.dart'; // ← ADICIONADO [FASE 1]
import '../services/equipment_service.dart'; // ← ADICIONADO [FASE 1]
import '../models/citadel_record.dart';
import '../widgets/event_toast.dart';
import '../services/prison_service.dart';
import '../services/war_service.dart';
import '../services/trade_service.dart';
import '../services/quest_service.dart';

class GameProvider extends ChangeNotifier {
  final GameEngine _engine = GameEngine();
  bool _isLoading = false;
  bool _hasSave = false;
  List<GameEvent> _recentEvents = [];
  TowerChallenge? _lastChallenge;
  Timer? _updateTimer;
  bool _simRunning = false;
  bool _paused = false;
  int _speedMultiplier = 1;
  String _currentSlot = '1';

  // ═══════════════════════════════════════════════════════════════
  // SISTEMA TEMPORAL CONTINUO
  // ═══════════════════════════════════════════════════════════════
  //
  // CONCEITO:
  //   24h no mundo real = 48h na Torre
  //   => 1 segundo real = 2 segundos na Torre
  //   => timeRatio = 2.0
  //
  // MECANISMO:
  //   1. Salva-se lastRealTimestamp (epoch ms) e gameSeconds (s acumulados)
  //   2. Ao processar: deltaReal = agora - lastRealTimestamp
  //   3. deltaGame = deltaReal * timeRatio * speedMultiplier
  //   4. gameSeconds += deltaGame
  //   5. Enquanto gameSeconds >= 86400: simulateDay(), gameSeconds -= 86400
  //   6. Funciona mesmo com o jogo fechado (offline progress)
  //
  // VELOCIDADES:
  //   1x  → 24h real = 48h jogo (2 dias)    | 1 dia jogo = 12h real
  //   2x  → 24h real = 96h jogo (4 dias)    | 1 dia jogo = 6h real
  //   5x  → 24h real = 240h jogo (10 dias)  | 1 dia jogo = 2.4h real
  //   10x → 24h real = 480h jogo (20 dias)  | 1 dia jogo = 72 min real
  //   25x → 24h real = 1200h jogo (50 dias) | 1 dia jogo = ~29 min real
  //   50x → 24h real = 2400h jogo (100 dias)| 1 dia jogo = ~14 min real
  //
  // ═══════════════════════════════════════════════════════════════

  /// Ratio de distorcao dimensional: 1s real = 2s na Torre
  static const double timeRatio = 2.0;

  /// Intervalo do timer de atualizacao UI (ms).
  static const int uiRefreshMs = 1000;

  /// Limite maximo de dias processados por ciclo de update (anti-travamento).
  static const int maxDaysPerUpdate = 30;

  /// Velocidades disponiveis
  static const List<int> availableSpeeds = [1, 100, 500, 10000];

  // ===== GETTERS PUBLICOS =====

  GameEngine get engine => _engine;
  bool get isLoading => _isLoading;
  bool get hasSave => _hasSave;
  List<GameEvent> get lastWeekEvents => _recentEvents;
  TowerChallenge? get lastChallenge => _lastChallenge;
  bool get simRunning => _simRunning;
  bool get paused => _paused;
  int get simSpeed => _speedMultiplier;

  GameState get state => _engine.state;
  List<Npc> get allNpcs => _engine.npcs;
  List<Npc> get aliveNpcs => _engine.aliveNpcs;
  List<Npc> get deadNpcs => _engine.deadNpcs;
  Citadel get citadel => _engine.citadel;
  List<TowerFloor> get floors => _engine.floors;
  List<GameEvent> get events => _engine.events;
  List<CitadelRecord> get citadelRecords => engine.records;
  PrisonService get prison => engine.prison;
  int get population => _engine.population;
  TowerFloor? get nextFloor => _engine.nextFloor;
  List<TowerFloor> get clearedFloors => _engine.clearedFloors;
  List<NpcGroup> get groups => _engine.groups;
  List<TrainingSuggestion> get trainingSuggestions =>
      _engine.trainingSuggestions;
  bool get hasTrainingField => _engine.hasTrainingField;

  // NPCs suspeitos
  List<Npc> get suspiciousNpcs =>
      aliveNpcs.where((n) => n.isSuspicious || n.betrayalRisk > 30).toList();

  // NPCs exaustos ou incapacitados
  List<Npc> get exhaustedNpcs => aliveNpcs.where((n) => n.isExhausted).toList();

  List<Npc> get incapacitatedNpcs =>
      aliveNpcs.where((n) => n.isIncapacitated).toList();

  // ── Sistema de Habitantes ─────────────────────────────
  /// Survivors encontrados em andares, aguardando recrutamento.
  /// Requer Abrigo de Viajantes para confirmar.
  List<FloorInhabitant> get pendingRecruits => _engine.pendingRecruits;

  // ── Sistema de Facções ────────────────────────────────
  /// Relações com cada facção da torre. Chave = FloorFaction.key (extensão).
  Map<String, FactionRelation> get factionRelations =>
      _engine.state.factionRelations;

  // ── Novos serviços ────────────────────────────────────
  WarService get warService => _engine.warService;
  TradeService get tradeService => _engine.tradeService;
  QuestService get questService => _engine.questService;

  List<FactionWar> get activeWars => _engine.warService.activeWars;
  List<TradeOffer> get allTradeOffers => _engine.tradeService.allOffers;
  List<FloorQuest> get activeQuests => _engine.questService.activeQuests;
  List<FloorQuest> get availableQuests => _engine.questService.availableQuests;

  /// Custo estimado de comida para expedicao ao proximo andar
  double expeditionCostEstimate(int npcCount) {
    final floor = _engine.nextFloor;
    if (floor == null) return 0;
    return _engine.expeditionCostPerNpc(floor.number) * npcCount;
  }

  /// Custo estimado de re-exploracao
  double reexploreCostEstimate(int floorNumber, int npcCount) {
    return _engine.reexploreCostPerNpc(floorNumber) * npcCount;
  }

  // ===== DISPLAY DE TEMPO =====

  int get currentHour => state.currentHour;
  int get currentMinute => state.currentMinute;
  String get dayPeriod => state.dayPeriod;
  String get formattedTime => state.formattedTime;

  /// Display temporal completo: "Dia X, HH:MM"
  String get timeDisplay {
    final day = state.currentDay;
    final time = formattedTime;

    if (day <= 7) return 'Dia $day, $time';

    final weeks = (day / 7).ceil();
    if (weeks < 4) return 'Sem $weeks, Dia ${((day - 1) % 7) + 1}, $time';

    final months = weeks ~/ 4;
    final remainWeeks = weeks % 4;
    if (months < 12) {
      return remainWeeks > 0
          ? 'Mes $months, Sem $remainWeeks, $time'
          : 'Mes $months, $time';
    }
    final years = months ~/ 12;
    final remainMonths = months % 12;
    return 'Ano $years, Mes $remainMonths, $time';
  }

  /// Descricao da velocidade atual
  String get speedDescription {
    final daysPerRealDay = timeRatio * _speedMultiplier * 86400 / 86400;
    return '24h real = ${daysPerRealDay.toStringAsFixed(0)} dias jogo';
  }

  /// Tempo real estimado para 1 dia in-game
  String get realTimePerDay {
    final realSecondsPerGameDay = 86400.0 / (timeRatio * _speedMultiplier);
    if (realSecondsPerGameDay >= 3600) {
      return '~${(realSecondsPerGameDay / 3600).toStringAsFixed(1)}h reais/dia';
    }
    return '~${(realSecondsPerGameDay / 60).toStringAsFixed(0)}min reais/dia';
  }

  // ===== LIFECYCLE =====

  void setSlot(String slot) {
    _currentSlot = slot;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await SaveService.hasSave(_currentSlot);
    _hasSave = await SaveService.hasSave(_currentSlot);
    _isLoading = false;
    notifyListeners();
  }

  bool get anySave => SaveService.listSlots().isNotEmpty;

  void newGame() {
    final slots = _getSortedSlots();

    if (slots.length >= maxSaves) {
      throw Exception('Limite máximo de saves atingido');
    }

    _currentSlot = _generateNextSlot();
    _engine.initNewGame();
    _saveGame();
    _startSimulation();
    notifyListeners();
  }

  Future<void> saveGame() async {
    await SaveService.saveGame(_engine, _currentSlot);
    _hasSave = true;
    notifyListeners();
  }

  String _generateNextSlot() {
    final slots = SaveService.listSlots();
    if (slots.isEmpty) return '1';

    final numbers = slots.map(int.tryParse).whereType<int>().toList();

    final next = numbers.isEmpty
        ? 1
        : (numbers.reduce((a, b) => a > b ? a : b) + 1);
    return next.toString();
  }

  static const int maxSaves = 5;

  List<int> _getSortedSlots() {
    final slots = SaveService.listSlots();

    return slots.map(int.tryParse).whereType<int>().toList()..sort();
  }

  bool canCreateNewSave() {
    return _getSortedSlots().length < maxSaves;
  }

  Future<bool> loadGame() async {
    _isLoading = true;
    notifyListeners();
    final success = await SaveService.loadGame(_engine, _currentSlot);
    _isLoading = false;
    _hasSave = success;
    if (success) {
      state.gameSeconds = (state.gameSeconds as num).toDouble();
      _processOfflineProgress();
      _startSimulation();
      // Consome crise que ocorreu com app fechado e exibe in-app
      _consumePendingCrisis();
    }
    notifyListeners();
    return success;
  }

  /// Consome crise persistida enquanto o app estava fechado e exibe o
  /// CrisisDialog normalmente na próxima frame.
  Future<void> _consumePendingCrisis() async {
    final pending = await CrisisFlagService.instance.consumePending();
    if (pending == null) return;

    // Cancela a notificação da barra — app já está aberto
    await NotificationService.instance.cancelAll();

    // Reconstrói um GameEvent mínimo para o CrisisDialog
    final type = _crisisTypeFromKey(pending.type);
    final event = GameEvent(
      id: state.generateEventId(),
      day: pending.day,
      type: type,
      title: pending.title,
      description: pending.body,
      isMajor: true,
    );

    // Enfileira no ToastController para exibir após a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastController().show(event);
    });
  }

  GameEventType _crisisTypeFromKey(String key) {
    switch (key) {
      case 'war':
        return GameEventType.warEvent;
      case 'mentalBreak':
        return GameEventType.mentalBreak;
      case 'emergencySummon':
        return GameEventType.emergencySummon;
      default:
        return GameEventType.crisis;
    }
  }

  /// Processa o tempo que passou enquanto o jogo estava fechado
  void _processOfflineProgress() {
    if (state.gameOver) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final deltaRealMs = now - state.lastRealTimestamp;

    if (deltaRealMs <= 0) {
      state.lastRealTimestamp = now;
      return;
    }

    final deltaRealSeconds = deltaRealMs / 1000.0;
    final deltaGameSeconds = deltaRealSeconds * timeRatio;

    state.gameSeconds =
        (state.gameSeconds as num).toDouble() + deltaGameSeconds;

    int daysProcessed = 0;
    _recentEvents = [];

    final allDayEvents = <GameEvent>[];
    while (state.gameSeconds >= 86400.0 && daysProcessed < maxDaysPerUpdate) {
      state.gameSeconds -= 86400.0;
      final dayEvents = _engine.simulateDay();
      allDayEvents.addAll(dayEvents);
      _recentEvents.addAll(dayEvents);
      daysProcessed++;
      if (state.gameOver) break;

      if (state.currentDay % 28 == 0 && !state.gameOver) {
        _autoTowerAttempt();
      }
    }

    if (allDayEvents.isNotEmpty) {
      // Progresso offline: só mostra eventos muito importantes (mortes, crises)
      final eventsToShow = allDayEvents
          .where(
            (e) =>
                e.isMajor &&
                (e.type == GameEventType.death ||
                    e.type == GameEventType.crisis ||
                    e.type == GameEventType.towerCleared ||
                    e.type == GameEventType.warEvent),
          )
          .toList();
      if (eventsToShow.isNotEmpty) ToastController().showBatch(eventsToShow);
    }

    if (state.gameSeconds >= 86400.0) {
      state.gameSeconds = state.gameSeconds % 86400.0;
    }

    state.lastRealTimestamp = now;

    if (daysProcessed > 0) {
      _saveGame();
    }
  }

  // ==== Consumo de comida ==== //
  double get dailyFoodConsumption {
    final reductionMultiplier = _granaryReductionMultiplier();

    return aliveNpcs.fold(0.0, (total, npc) {
      final baseConsumption = _baseConsumption(npc).clamp(0.5, 3.0);
      final finalConsumption = baseConsumption * reductionMultiplier;

      return total + finalConsumption;
    });
  }

  double _granaryReductionMultiplier() {
    final granary = citadel.getBuilding(BuildingType.granary);

    if (granary == null) return 1.0;

    final reduction = granary.foodConsumptionReduction.clamp(0.0, 0.9);

    return 1 - reduction;
  }

  double _baseConsumption(Npc npc) {
    double base = 1.5;

    // ===== Traços =====
    if (npc.traits.contains(PersonalityTrait.lazy)) base += 0.3;
    if (npc.traits.contains(PersonalityTrait.gluttonous)) base += 0.7;
    if (npc.traits.contains(PersonalityTrait.frugal)) base -= 0.5;

    // ===== Estágio de crescimento =====
    switch (npc.growthStage(state.currentDay)) {
      case GrowthStage.baby:
        base *= 0.3;
        break;
      case GrowthStage.child:
        base *= 0.6;
        break;
      case GrowthStage.adolescent:
        base *= 0.85;
        break;
      default:
        break;
    }

    return base;
  }
  // ===== SIMULACAO CONTINUA =====

  void _startSimulation() {
    _updateTimer?.cancel();
    _simRunning = true;
    _paused = false;
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    _scheduleUpdate();
  }

  void _scheduleUpdate() {
    if (!_simRunning || _paused || state.gameOver) return;
    _updateTimer = Timer(
      const Duration(milliseconds: uiRefreshMs),
      _processTimeStep,
    );
  }

  /// Pausa a simulação para uma ação do jogador.
  /// Retorna se já estava pausado antes (para restaurar o estado correto).
  bool pauseForPlayerAction() {
    if (_paused) return true; // já estava pausado, não precisa restaurar
    _paused = true;
    _updateTimer?.cancel();
    notifyListeners();
    return false;
  }

  /// Retoma simulação se [wasPausedBefore] for false.
  void resumeAfterPlayerAction(bool wasPausedBefore) {
    if (!wasPausedBefore && _paused && !_pausedByCrisis) {
      _paused = false;
      state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
      _scheduleUpdate();
      notifyListeners();
    }
  }

  void _processTimeStep() {
    if (!_simRunning || _paused || state.gameOver) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final deltaRealMs = now - state.lastRealTimestamp;
    state.lastRealTimestamp = now;

    if (deltaRealMs <= 0) {
      _scheduleUpdate();
      return;
    }

    final deltaRealSeconds = deltaRealMs / 1000.0;
    final deltaGameSeconds = deltaRealSeconds * timeRatio * _speedMultiplier;

    state.gameSeconds =
        (state.gameSeconds as num).toDouble() + deltaGameSeconds;

    bool dayAdvanced = false;
    int daysThisCycle = 0;

    while (state.gameSeconds >= 86400.0 && daysThisCycle < maxDaysPerUpdate) {
      state.gameSeconds -= 86400.0;
      final dayEvents = _engine.simulateDay();
      ToastController().showBatch(dayEvents);

      _recentEvents = [..._recentEvents, ...dayEvents];
      dayAdvanced = true;
      daysThisCycle++;
      if (state.gameOver) break;

      if (state.currentDay % 28 == 0 && !state.gameOver) {
        _autoTowerAttempt();
      }
    }

    if (_recentEvents.length > 100) {
      _recentEvents = _recentEvents.sublist(_recentEvents.length - 100);
    }

    if (dayAdvanced) {
      _saveGame();
    }

    notifyListeners();
    _scheduleUpdate();
  }

  void _autoTowerAttempt() {
    final nextFlr = _engine.nextFloor;
    if (nextFlr == null) return;

    final candidates = _engine.aliveNpcs
        .where(
          (n) =>
              n.attributes.mentalStability > 25 &&
              n.fatigue < 60 &&
              (n.profession == Profession.guard ||
                  n.profession == Profession.explorer ||
                  n.profession == Profession.scout),
        )
        .toList();

    if (candidates.length < 3) {
      final extras = _engine.aliveNpcs
          .where(
            (n) =>
                n.attributes.mentalStability > 30 &&
                n.attributes.combatPower > 4.0 &&
                !candidates.contains(n),
          )
          .toList();
      extras.sort(
        (a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower),
      );
      candidates.addAll(
        extras.take(nextFlr.recommendedPartySize - candidates.length),
      );
    }

    if (candidates.length < 2) return;

    candidates.sort(
      (a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower),
    );
    final partySize = nextFlr.recommendedPartySize.clamp(2, candidates.length);
    final party = candidates.take(partySize).map((n) => n.id).toList();

    double partyPower = 0;
    for (final id in party) {
      final npc = _engine.npcs.firstWhereOrNull((n) => n.id == id);
      if (npc != null) partyPower += npc.attributes.combatPower;
    }

    if (partyPower < nextFlr.recommendedPower * 0.6) return;
    if (partyPower < nextFlr.recommendedPower * 0.6) return;
    // Salva estado de fadiga para não contaminar com penalidade de consecutivas
    final fatigueSnapshot = Map.fromEntries(
      candidates
          .take(partySize)
          .map((n) => MapEntry(n.id, n.lastExpeditionDay)),
    );

    _lastChallenge = _engine.attemptFloor(party);

    // Restaura lastExpeditionDay para que o player não leve penalidade dupla
    for (final n in _engine.npcs) {
      if (fatigueSnapshot.containsKey(n.id)) {
        n.lastExpeditionDay = fatigueSnapshot[n.id]!;
      }
    }
  }

  // ==================== GETTER DE BONUS DIARIO ====================
  // Produção diária real — usa a mesma lógica do engine (fazendeiros,
  // sinergia, população, tier). Garante que UI e simulação mostrem
  // sempre o mesmo valor.
  Resources get _dailyProduction => _engine.previewDailyProduction();

  double get dailyFoodBonus => _dailyProduction.food;
  double get dailyWoodLogBonus => _dailyProduction.woodLog;
  double get dailyLumberBonus => _dailyProduction.lumber;
  double get dailyStoneRawBonus => _dailyProduction.stoneRaw;
  double get dailyStoneBrickBonus => _dailyProduction.stoneBrick;
  double get dailyIronOreBonus => _dailyProduction.ironOre;
  double get dailyIronBarBonus => _dailyProduction.ironBar;
  double get dailyResearchBonus => _dailyProduction.knowledge;
  double get dailyMoraleBonus => _dailyProduction.morale;

  // Mantido por compatibilidade com código existente
  double get dailyWoodBonus => _dailyProduction.woodLog;
  double get dailyIronBonus => _dailyProduction.ironOre;
  // ==================== ACOES DO JOGADOR (PRINCIPAL) ====================

  /// ACAO PRINCIPAL: Enviar expedição ao proximo andar
  /// Retorna null com feedback via [onFailure] se não foi possível executar.
  TowerChallenge? sendExpedition(
    List<String> partyIds, {
    void Function(String reason)? onFailure,
  }) {
    final floor = _engine.nextFloor;
    if (floor == null) {
      onFailure?.call('Nenhum andar disponível para explorar.');
      return null;
    }
    if (partyIds.length < 2) {
      onFailure?.call('Selecione ao menos 2 habitantes.');
      return null;
    }

    final validPartyIds = partyIds.where((id) {
      final npc = _engine.npcs.firstWhereOrNull((n) => n.id == id);
      return npc != null && !npc.isIncapacitated;
    }).toList();

    if (validPartyIds.isEmpty) {
      onFailure?.call(
        'Todos os habitantes selecionados estão incapacitados (fadiga ≥ 90).',
      );
      return null;
    }
    if (validPartyIds.length < 2) {
      onFailure?.call(
        '${partyIds.length - validPartyIds.length} habitante(s) incapacitado(s). '
        'Menos de 2 aptos — expedição cancelada.',
      );
      return null;
    }

    _lastChallenge = _engine.attemptFloor(validPartyIds);

    final partyNpcs = partyIds
        .map((id) => _engine.npcs.firstWhereOrNull((n) => n.id == id))
        .whereType<Npc>()
        .toList();

    _updateGroupStats(
      partyNpcs,
      victory: _lastChallenge!.victory,
      missionBonus: 0,
    );

    _saveGame();
    notifyListeners();
    return _lastChallenge;
  }

  /// ACAO PRINCIPAL: Re-explorar andar conquistado para coletar recursos
  FloorExplorationResult? sendReexploration(
    int floorNumber,
    List<String> partyIds, {
    void Function(String reason)? onFailure,
  }) {
    if (partyIds.isEmpty) {
      onFailure?.call('Nenhum habitante selecionado.');
      return null;
    }

    final floor = _engine.floors.firstWhereOrNull(
      (f) => f.number == floorNumber && f.cleared,
    );
    if (floor == null) {
      onFailure?.call('Andar $floorNumber não está conquistado.');
      return null;
    }

    final validIds = partyIds.where((id) {
      final npc = _engine.npcs.firstWhereOrNull((n) => n.id == id);
      return npc != null && !npc.isIncapacitated;
    }).toList();

    if (validIds.isEmpty) {
      onFailure?.call(
        'Todos os habitantes selecionados estão incapacitados (fadiga ≥ 90). '
        'Aguarde a recuperação.',
      );
      return null;
    }

    final result = _engine.reexploreFloor(floorNumber, validIds);

    final rePartyNpcs = validIds
        .map((id) => _engine.npcs.firstWhereOrNull((n) => n.id == id))
        .whereType<Npc>()
        .toList();

    _updateGroupStats(rePartyNpcs, victory: true, missionBonus: 2);

    _saveGame();
    notifyListeners();
    return result;
  }

  /// Helper: atualiza missoes e coesao de grupos envolvidos numa expedicao.
  void _updateGroupStats(
    List<Npc> npcs, {
    required bool victory,
    required int missionBonus,
  }) {
    final groupIds = npcs
        .where((n) => n.groupId != null)
        .map((n) => n.groupId!)
        .toSet();
    for (final gid in groupIds) {
      final group = _engine.groups.firstWhereOrNull((g) => g.id == gid);
      if (group != null) {
        group.missionsCompleted++;
        if (victory) {
          group.cohesion = (group.cohesion + 5 + missionBonus).clamp(0, 100);
        } else {
          group.cohesion = (group.cohesion - 3).clamp(0, 100);
        }
      }
    }
  }

  /// Enviar grupo inteiro para expedição no proximo andar
  TowerChallenge? sendGroupExpedition(String groupId) {
    final group = _engine.groups.firstWhereOrNull((g) => g.id == groupId);
    if (group == null || group.memberIds.isEmpty) return null;

    final aliveMembers = group.memberIds
        .where((id) => _engine.npcs.any((n) => n.id == id && n.alive))
        .toList();
    if (aliveMembers.length < 2) return null;

    return sendExpedition(aliveMembers);
  }

  /// Enviar grupo inteiro para re-explorar andar conquistado
  FloorExplorationResult? sendGroupReexploration(
    String groupId,
    int floorNumber,
  ) {
    final group = _engine.groups.firstWhereOrNull((g) => g.id == groupId);
    if (group == null || group.memberIds.isEmpty) return null;

    final aliveMembers = group.memberIds
        .where((id) => _engine.npcs.any((n) => n.id == id && n.alive))
        .toList();
    if (aliveMembers.isEmpty) return null;

    return sendReexploration(floorNumber, aliveMembers);
  }

  // ==================== GRUPOS ====================

  NpcGroup createGroup(String name, List<String> memberIds, GroupRole role) {
    final group = _engine.createGroup(name, memberIds, role);
    _saveGame();
    notifyListeners();
    return group;
  }

  void disbandGroup(String groupId) {
    _engine.disbandGroup(groupId);
    _saveGame();
    notifyListeners();
  }

  void addToGroup(String groupId, String npcId) {
    _engine.addToGroup(groupId, npcId);
    _saveGame();
    notifyListeners();
  }

  void removeFromGroup(String npcId) {
    _engine.removeFromGroup(npcId);
    _saveGame();
    notifyListeners();
  }

  // ==================== EQUIPAMENTOS [FASE 1] ====================

  // ── Getters ─────────────────────────────────

  /// Inventário global de equipamentos
  List<Equipment> get inventory => _engine.inventory;

  /// Equipamentos disponíveis para um slot específico (não equipados)
  List<Equipment> availableForSlot(EquipmentSlot slot) =>
      _engine.availableEquipmentForSlot(slot);

  /// Equipamentos atualmente equipados em um NPC
  List<Equipment> equippedOn(String npcId) => _engine.equippedOn(npcId);

  /// Verifica se é possível craftar dado a raridade (recursos + forja)
  bool canCraft(EquipmentRarity rarity) => _engine.canCraftEquipment(rarity);

  /// Verifica se a Forja está construída
  bool get hasForge => _engine.citadel.hasBuilding(BuildingType.forge);

  /// Custo de craft para uma raridade específica
  ({double ironBar, double knowledge, double stoneBrick}) craftCostFor(
    EquipmentRarity rarity,
  ) => EquipmentFactory.craftCost(rarity);

  // ── Ações do jogador ────────────────────────

  /// Equipa um item em um NPC.
  /// Retorna true se bem-sucedido.
  bool equipItem(String npcId, String equipmentId) {
    final result = _engine.equipItem(npcId, equipmentId);
    if (result == EquipResult.success) {
      _saveGame();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Desequipa o item do slot indicado de um NPC.
  /// Retorna true se bem-sucedido.
  bool unequipItem(String npcId, EquipmentSlot slot) {
    final result = _engine.unequipItem(npcId, slot);
    if (result == UnequipResult.success) {
      _saveGame();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Tenta craftar um equipamento na Forja.
  /// Retorna o Equipment criado, ou null em caso de falha.
  Equipment? craftEquipment(EquipmentSlot slot, EquipmentRarity rarity) {
    final (result, eq) = _engine.craftEquipment(slot, rarity);
    if (result == CraftResult.success && eq != null) {
      _saveGame();
      notifyListeners();
      return eq;
    }
    return null;
  }

  // ==================== CONSTRUCAO MANUAL ====================

  /// Edificios disponiveis para construir
  List<BuildingType> get availableBuildings => _engine.availableBuildings;

  /// Verifica se pode construir
  bool canBuild(BuildingType type) => _engine.canBuild(type);

  /// Verifica se pode fazer upgrade
  bool canUpgradeBuilding(BuildingType type) =>
      _engine.canUpgradeBuilding(type);

  /// ACAO DO JOGADOR: Construir edificio
  bool buildStructure(BuildingType type) {
    if (!_engine.canBuild(type)) return false;
    final result = _engine.buildStructure(type);
    if (result) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  /// ACAO DO JOGADOR: Fazer upgrade de edificio
  bool upgradeBuilding(BuildingType type) {
    final result = _engine.upgradeBuilding(type);
    if (result) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  /// Verifica se pode fazer upgrade de TODOS os edifícios de um tipo
  bool canUpgradeAllBuildings(BuildingType type) =>
      _engine.canUpgradeAllBuildings(type);

  /// ACAO DO JOGADOR: Fazer upgrade de TODOS os edifícios de um tipo
  bool upgradeAllBuildings(BuildingType type) {
    final result = _engine.upgradeAllBuildings(type);
    if (result) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  /// ACAO DO JOGADOR: Evoluir cidadela
  bool upgradeCitadel() {
    final result = _engine.upgradeCitadel();
    if (result) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  /// ACAO DO JOGADOR: Solicitar novos moradores
  String requestNewSettlers() {
    final result = _engine.requestNewSettlers();
    _saveGame();
    notifyListeners();
    return result;
  }

  /// ACAO DO JOGADOR: Fazer upgrade do armazem
  bool upgradeStorage() {
    final result = _engine.upgradeStorage();
    if (result) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  /// Verifica se pode fazer upgrade do armazem
  bool get canUpgradeStorage => _engine.canUpgradeStorage();

  /// Verifica se pode evoluir cidadela
  bool get canUpgradeCitadel {
    if (!_engine.citadel.canUpgrade) return false;
    if (!_engine.citadel.resources.canAfford(
      _engine.citadel.upgradeCost.toResources(),
    )) {
      return false;
    }
    final next = _engine.citadel.nextCitadelLevel;
    if (next == null) return false;
    if (population < next.populationRequired) return false;
    final currentTier =
        ((_engine.state.highestFloorCleared) ~/ 10) +
        (_engine.state.highestFloorCleared % 10 > 0 ? 1 : 0);
    if (currentTier < next.requiredTowerTier) return false;
    return true;
  }

  String confirmRecruitSurvivor(String survivorId) {
    final result = _engine.confirmRecruitSurvivor(survivorId);
    if (result.contains('juntou')) {
      _saveGame(); // persiste imediatamente
      notifyListeners(); // atualiza a UI
    }
    return result;
  }

  void rejectRecruit(String survivorId) {
    _engine.rejectRecruit(survivorId);
    _saveGame();
    notifyListeners();
  }
  // ==================== GUERRAS ====================

  String sideWithFaction(String warId, FloorFaction faction) {
    final result = _engine.warService.sideWithFaction(
      warId: warId,
      faction: faction,
      factionRelations: _engine.state.factionRelations,
    );
    _saveGame();
    notifyListeners();
    return result;
  }

  // ==================== COMERCIO ====================

  TradeResult executeTrade(String offerId) {
    final marketLevel =
        _engine.citadel.getBuilding(BuildingType.market)?.level ?? 1;
    final result = _engine.tradeService.executeTrade(
      offerId: offerId,
      citadel: _engine.citadel,
      factionRelations: _engine.state.factionRelations,
      marketLevel: marketLevel,
    );
    if (result.success) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  List<TradeOffer> tradeOffersForFloor(int floorNumber) =>
      _engine.tradeService.offersForFloor(floorNumber);

  // ==================== MISSOES ====================

  String acceptQuest(String questId, int currentDay) {
    final result = _engine.questService.acceptQuest(
      questId,
      _engine.state.currentDay,
    );
    _saveGame();
    notifyListeners();
    return result;
  }

  List<FloorQuest> questsForFloor(int floorNumber) =>
      _engine.questService.questsForFloor(floorNumber);

  // ==================== NPC ACTIONS ====================

  void assignProfession(String npcId, Profession profession) {
    _engine.assignProfession(npcId, profession);
    _saveGame();
    notifyListeners();
  }

  String arrestNpc(String npcId) {
    final result = _engine.arrestNpc(npcId);
    _saveGame();
    notifyListeners();
    switch (result) {
      case ArrestResult.trialOpened:
        return 'Julgamento aberto.';
      case ArrestResult.noPrison:
        return 'Prisão não construída.';
      case ArrestResult.noCouncilHall:
        return 'Câmara do Conselho necessária.';
      case ArrestResult.alreadyImprisoned:
        return 'Já está preso.';
      case ArrestResult.alreadyOnTrial:
        return 'Já está em julgamento.';
      case ArrestResult.noCrimeEvidence:
        return 'Sem evidências de crime.';
      default:
        return 'Ação não permitida.';
    }
  }

  // ==================== SIMULACRO ====================

  String? canStartSimulacrum(String npcId) => _engine.canStartSimulacrum(npcId);

  SimulacrumBattle? startSimulacrumBattle(String npcId, int floorNumber) =>
      _engine.startSimulacrumBattle(npcId, floorNumber);

  List<ZoneStrategy> getAvailableStrategies(String npcId) =>
      _engine.getAvailableStrategies(npcId);

  String resolveSimulacrumBattle(SimulacrumBattle battle) {
    final result = _engine.resolveSimulacrumBattle(battle);
    _saveGame();
    notifyListeners();
    return result;
  }

  List<TowerFloor> get strategicClearedFloors => _engine.clearedFloors
      .where((f) => f.type == FloorType.strategic)
      .toList();

  // ==================== RANK UP ====================
  String addStar(String targetId, String sacrificeId) {
    final result = _engine.addStar(targetId, sacrificeId);
    _saveGame();
    notifyListeners();
    return result;
  }

  String attemptPromotion(String targetId, List<String> sacrificeIds) {
    final result = _engine.attemptPromotion(targetId, sacrificeIds);
    _saveGame();
    notifyListeners();
    return result;
  }

  void toggleFavorite(String npcId) {
    final npc = _engine.npcs.firstWhereOrNull((n) => n.id == npcId);
    if (npc != null) {
      npc.isFavorite = !npc.isFavorite;
      _saveGame();
      notifyListeners();
    }
  }

  // ==================== ARENA ====================
  String runArenaChallenge(String idA, String idB) {
    final result = _engine.runArenaChallenge(idA, idB);
    _saveGame();
    notifyListeners();
    return result;
  }

  // ==================== DIPLOMACIA ====================

  /// Retorna as ofertas diplomáticas disponíveis para uma facção.
  /// Lista vazia indica: já aliado, em cooldown ou sem relação estabelecida.
  List<DiplomacyOffer> getDiplomacyOffers(FloorFaction faction) {
    return _engine.getDiplomacyOffers(faction);
  }

  /// Executa uma oferta diplomática e retorna texto narrativo do resultado.
  String executeDiplomacy(FloorFaction faction, DiplomacyOfferType offerType) {
    final result = _engine.executeDiplomacy(faction, offerType);
    _saveGame();
    notifyListeners();
    return result;
  }

  /// Dias restantes de cooldown para negociar com a facção (0 = disponível).
  int diplomacyCooldownDays(FloorFaction faction) {
    final rel = _engine.state.factionRelations[faction.key];
    if (rel == null) return 0;
    final elapsed = _engine.state.currentDay - rel.lastDiplomacyDay;
    return (7 - elapsed).clamp(0, 7);
  }

  // ==================== HISTÓRICO DE FACÇÃO ====================

  /// Eventos do log filtrados por facção — usados na timeline de histórico.
  /// Inclui eventos políticos, descobertas, crises e recrutamentos que
  /// mencionem o label da facção no título ou descrição.
  List<GameEvent> eventsForFaction(FloorFaction faction) {
    if (faction == FloorFaction.none) return [];
    final label = faction.label;
    return _engine.events
        .where(
          (e) =>
              (e.type == GameEventType.politicalEvent ||
                  e.type == GameEventType.discovery ||
                  e.type == GameEventType.crisis ||
                  e.type == GameEventType.recruitment ||
                  e.type == GameEventType.exploration ||
                  e.type == GameEventType.combat) &&
              (e.title.contains(label) || e.description.contains(label)),
        )
        .toList()
      ..sort((a, b) => b.day.compareTo(a.day));
  }

  // ==================== SUGESTAO DE TREINO ====================

  TrainingSuggestion suggestTraining(
    String targetId,
    String targetType,
    int floorNumber,
  ) {
    final suggestion = _engine.suggestTraining(
      targetId,
      targetType,
      floorNumber,
    );
    _saveGame();
    notifyListeners();
    return suggestion;
  }

  List<TrainingMission> get activeTrainings => _engine.activeTrainings;

  // Edifícios militares disponíveis para treino
  List<BuildingType> get trainingBuildings {
    const supported = [
      BuildingType.trainingField,
      BuildingType.barracks,
      BuildingType.arena,
      BuildingType.temple,
      BuildingType.library,
    ];
    return supported.where((b) => _engine.citadel.hasBuilding(b)).toList();
  }

  TrainingSuggestion suggestGroupTraining(
    String groupId,
    BuildingType buildingType,
    int durationDays,
  ) {
    final result = _engine.suggestTrainingWithBuilding(
      groupId,
      buildingType,
      durationDays,
    );
    _saveGame();
    notifyListeners();
    return result;
  }

  Map<String, Map<String, double>> previewTrainingGains(
    List<String> npcIds,
    BuildingType buildingType,
    int durationDays,
  ) => _engine.previewTrainingGains(npcIds, buildingType, durationDays);

  double previewNpcAptitude(String npcId, BuildingType building) =>
      _engine.previewNpcAptitude(npcId, building);

  // ==================== CONTROLES ====================

  void togglePause() {
    _paused = !_paused;
    if (_paused) {
      _updateTimer?.cancel();
      _saveGame();
    } else {
      state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
      _scheduleUpdate();
    }
    notifyListeners();
  }

  void setSpeed(int speed) {
    if (!availableSpeeds.contains(speed)) {
      _speedMultiplier = availableSpeeds.reduce(
        (a, b) => (a - speed).abs() < (b - speed).abs() ? a : b,
      );
    } else {
      _speedMultiplier = speed;
    }
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  void stopSimulation() {
    _updateTimer?.cancel();
    _simRunning = false;
    _paused = false;
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    _saveGame();
    notifyListeners();
  }

  Future<void> deleteSave() async {
    stopSimulation();
    await SaveService.deleteSave(_currentSlot);
    _hasSave = false;
    notifyListeners();
  }

  Future<void> _saveGame() async {
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    await SaveService.saveGame(_engine, _currentSlot);
    _hasSave = true;
  }

  // ── PAUSA AUTOMÁTICA POR CRISE ─────────────────────────────────────
  bool _pausedByCrisis = false;

  void pauseForCrisis() {
    if (!_paused) {
      _pausedByCrisis = true;
      _paused = true;
      _updateTimer?.cancel();
      notifyListeners();
    }
  }

  void resumeIfCrisisPaused() {
    if (_pausedByCrisis) {
      _pausedByCrisis = false;
      _paused = false;
      _startSimulation(); // retoma o timer normalmente
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void refresh() => notifyListeners();

  // //================++=================================++++================DEBUG=================================

  // /// DEBUG ONLY — adiciona +200 de cada recurso
  // void debugAddResources() {
  //   final res = _engine.citadel.resources;
  //   res.food += 200;
  //   res.wood += 200;
  //   res.stone += 200;
  //   res.iron += 200;
  //   res.knowledge += 200;
  //   notifyListeners();
  // }

  // /// DEBUG ONLY — remove antes de publicar
  // void debugForceCouple() {
  //   final id1 = state.generateNpcId();
  //   final id2 = state.generateNpcId();

  //   final a = Npc.generateRandom(id1, 1, Random())
  //     ..profession = Profession.farmer;
  //   final b = Npc.generateRandom(id2, 1, Random())
  //     ..profession = Profession.farmer;

  //   // Vincula como casal
  //   a.partnerId = id2;
  //   b.partnerId = id1;
  //   a.relationships.add(
  //     Relationship(targetId: id2, type: 'parceiro', affinity: 0.95),
  //   );
  //   b.relationships.add(
  //     Relationship(targetId: id1, type: 'parceiro', affinity: 0.95),
  //   );

  //   _engine.npcs.addAll([a, b]);

  //   // Força gravidez imediata
  //   a.pregnantSince = state.currentDay;
  //   a.maternalNutrition = 100.0;

  //   // Garante moral e comida suficiente para o parto acontecer
  //   _engine.citadel.resources.morale = 80;
  //   _engine.citadel.resources.food = 200;

  //   _saveGame();
  //   notifyListeners();
  // }

  // /// DEBUG ONLY — avança N dias instantaneamente
  // void debugAdvanceDays(int days) {
  //   for (int i = 0; i < days; i++) {
  //     _engine.simulateDay();
  //     if (state.gameOver) break;
  //   }
  //   _saveGame();
  //   notifyListeners();
  // }
}

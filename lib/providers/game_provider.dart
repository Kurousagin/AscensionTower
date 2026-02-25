import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../services/game_engine.dart';
import '../services/save_service.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/tower.dart';
import '../models/game_event.dart';
import '../models/group_model.dart';
import '../models/equipment.dart'; // ← ADICIONADO [FASE 1]
import '../services/equipment_service.dart'; // ← ADICIONADO [FASE 1]

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
    }
    notifyListeners();
    return success;
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
    while (state.gameSeconds >= 86400.0 && daysProcessed < maxDaysPerUpdate) {
      state.gameSeconds -= 86400.0;
      final dayEvents = _engine.simulateDay();
      _recentEvents.addAll(dayEvents);
      daysProcessed++;
      if (state.gameOver) break;

      if (state.currentDay % 28 == 0 && !state.gameOver) {
        _autoTowerAttempt();
      }
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

    _lastChallenge = _engine.attemptFloor(party);
  }

  // ==================== GETTER DE BONUS DIARIO ====================
  double get dailyFoodBonus {
    double total = 0.0;
    for (final farm in citadel.buildings.where(
      (b) => b.type == BuildingType.farm,
    )) {
      total += farm.bonus;
    }
    // Adicione outros edifícios que dão comida, se houver
    return total;
  }

  double get dailyWoodBonus {
    double total = 0.0;
    for (final wood in citadel.buildings.where(
      (b) => b.type == BuildingType.woodworking,
    )) {
      total += wood.bonus;
    }
    return total;
  }

  double get dailyIronBonus {
    double total = 0.0;
    for (final forge in citadel.buildings.where(
      (b) => b.type == BuildingType.forge,
    )) {
      total += forge.bonus;
    }
    return total;
  }

  double get dailyAdvancedBonus {
    double total = 0.0;
    for (final adv in citadel.buildings.where(
      (b) => b.type == BuildingType.workshop,
    )) {
      total += adv.bonus;
    }
    return total;
  }

  double get dailyResearchBonus {
    double total = 0.0;
    for (final lab in citadel.buildings.where(
      (b) => b.type == BuildingType.library,
    )) {
      total += lab.bonus;
    }
    return total;
  }

  // ==================== ACOES DO JOGADOR (PRINCIPAL) ====================

  /// ACAO PRINCIPAL: Enviar expedição ao proximo andar
  TowerChallenge? sendExpedition(List<String> partyIds) {
    final floor = _engine.nextFloor;
    if (floor == null) return null;
    if (partyIds.length < 2) return null;

    final validPartyIds = partyIds.where((id) {
      final npc = _engine.npcs.firstWhereOrNull((n) => n.id == id);
      return npc != null && !npc.isIncapacitated;
    }).toList();

    if (validPartyIds.length < 2) return null;

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
    List<String> partyIds,
  ) {
    if (partyIds.isEmpty) return null;
    final floor = _engine.floors.firstWhereOrNull(
      (f) => f.number == floorNumber && f.cleared,
    );
    if (floor == null) return null;

    final validIds = partyIds.where((id) {
      final npc = _engine.npcs.firstWhereOrNull((n) => n.id == id);
      return npc != null && !npc.isIncapacitated;
    }).toList();
    if (validIds.isEmpty) return null;

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
  ({double iron, double knowledge, double stone}) craftCostFor(
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
  List<BuildingType> get availableBuildings {
    final currentTier =
        ((state.highestFloorCleared) ~/ 10) +
        (state.highestFloorCleared % 10 > 0 ? 1 : 0);

    return BuildingType.values
        .where((type) => citadel.canBuild(type, currentTier))
        .toList();
  }

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

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

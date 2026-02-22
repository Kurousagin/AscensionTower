import 'dart:async';
import 'package:flutter/material.dart';
import '../services/game_engine.dart';
import '../services/save_service.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/tower.dart';
import '../models/game_event.dart';
import '../models/group_model.dart';

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
  /// Nao e um "tick de simulacao" — e apenas a frequencia com que
  /// processamos delta real e redesenhamos a UI.
  static const int uiRefreshMs = 1000;

  /// Limite maximo de dias processados por ciclo de update (anti-travamento).
  /// Previne que o jogo fique travado processando anos de offline.
  static const int maxDaysPerUpdate = 30;

  /// Velocidades disponiveis
  static const List<int> availableSpeeds = [1, 2, 5, 10, 25, 50];

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
  List<TrainingSuggestion> get trainingSuggestions => _engine.trainingSuggestions;
  bool get hasTrainingField => _engine.hasTrainingField;

  // NPCs suspeitos
  List<Npc> get suspiciousNpcs =>
      aliveNpcs.where((n) => n.isSuspicious || n.calculatedBetrayalRisk > 30).toList();

  // NPCs exaustos ou incapacitados
  List<Npc> get exhaustedNpcs =>
      aliveNpcs.where((n) => n.isExhausted).toList();

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

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await SaveService.init();
    _hasSave = await SaveService.hasSave();
    _isLoading = false;
    notifyListeners();
  }

  void newGame() {
    _engine.initNewGame();
    // Setar timestamp inicial
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    state.gameSeconds = 6.0 * 3600; // Comeca as 06:00 da manha
    _recentEvents = _engine.events.toList();
    _lastChallenge = null;
    _saveGame();
    _startSimulation();
    notifyListeners();
  }

  Future<bool> loadGame() async {
    _isLoading = true;
    notifyListeners();
    final success = await SaveService.loadGame(_engine);
    _isLoading = false;
    _hasSave = success;
    if (success) {
      // Processar tempo offline acumulado
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
    // Offline progress usa velocidade 1x (ratio base) para nao explodir
    final deltaGameSeconds = deltaRealSeconds * timeRatio;

    state.gameSeconds += deltaGameSeconds;

    // Processar dias acumulados (com limite para evitar travamento)
    int daysProcessed = 0;
    _recentEvents = [];
    while (state.gameSeconds >= 86400.0 && daysProcessed < maxDaysPerUpdate) {
      state.gameSeconds -= 86400.0;
      final dayEvents = _engine.simulateDay();
      _recentEvents.addAll(dayEvents);
      daysProcessed++;
      if (state.gameOver) break;

      // Auto-torre a cada 28 dias
      if (state.currentDay % 28 == 0 && !state.gameOver) {
        _autoTowerAttempt();
      }
    }

    // Se ainda sobram dias alem do limite, clampar gameSeconds
    // (evita acumular meses de simulacao)
    if (state.gameSeconds >= 86400.0 * maxDaysPerUpdate) {
      state.gameSeconds = state.gameSeconds % 86400.0;
    }

    state.lastRealTimestamp = now;

    if (daysProcessed > 0) {
      _saveGame();
    }
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
    _updateTimer = Timer(const Duration(milliseconds: uiRefreshMs), _processTimeStep);
  }

  /// Processamento principal: calcula delta real, converte para game time,
  /// e executa simulateDay() para cada dia completo acumulado.
  void _processTimeStep() {
    if (!_simRunning || _paused || state.gameOver) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final deltaRealMs = now - state.lastRealTimestamp;
    state.lastRealTimestamp = now;

    if (deltaRealMs <= 0) {
      _scheduleUpdate();
      return;
    }

    // Converter tempo real em tempo na Torre
    final deltaRealSeconds = deltaRealMs / 1000.0;
    final deltaGameSeconds = deltaRealSeconds * timeRatio * _speedMultiplier;

    state.gameSeconds += deltaGameSeconds;

    // Processar dias completos
    bool dayAdvanced = false;
    int daysThisCycle = 0;

    while (state.gameSeconds >= 86400.0 && daysThisCycle < maxDaysPerUpdate) {
      state.gameSeconds -= 86400.0;
      final dayEvents = _engine.simulateDay();
      _recentEvents = [..._recentEvents, ...dayEvents];
      dayAdvanced = true;
      daysThisCycle++;
      if (state.gameOver) break;

      // Auto-torre a cada 28 dias
      if (state.currentDay % 28 == 0 && !state.gameOver) {
        _autoTowerAttempt();
      }
    }

    // Limitar eventos recentes para nao explodir memoria
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
        .where((n) =>
            n.attributes.mentalStability > 25 &&
            n.fatigue < 60 && // Nao enviar cansados automaticamente
            (n.profession == Profession.guard ||
                n.profession == Profession.explorer ||
                n.profession == Profession.scout))
        .toList();

    if (candidates.length < 3) {
      final extras = _engine.aliveNpcs
          .where((n) =>
              n.attributes.mentalStability > 30 &&
              n.attributes.combatPower > 4.0 &&
              !candidates.contains(n))
          .toList();
      extras.sort((a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower));
      candidates.addAll(extras.take(nextFlr.recommendedPartySize - candidates.length));
    }

    if (candidates.length < 2) return;

    candidates.sort((a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower));
    final partySize = nextFlr.recommendedPartySize.clamp(2, candidates.length);
    final party = candidates.take(partySize).map((n) => n.id).toList();

    double partyPower = 0;
    for (final id in party) {
      final npc = _engine.npcs.firstWhere((n) => n.id == id);
      partyPower += npc.attributes.combatPower;
    }

    if (partyPower < nextFlr.recommendedPower * 0.6) return;

    _lastChallenge = _engine.attemptFloor(party);
  }

  // ==================== ACOES DO JOGADOR (PRINCIPAL) ====================

  /// ACAO PRINCIPAL: Enviar expedição ao proximo andar
  /// Esta é a UNICA ação direta do jogador - decidir quem sobe.
  TowerChallenge? sendExpedition(List<String> partyIds) {
    final floor = _engine.nextFloor;
    if (floor == null) return null;
    if (partyIds.length < 2) return null;

    // Verificar incapacitados e alertar sobre exaustos
    final incapacitated = partyIds.where((id) {
      final npc = _engine.npcs.where((n) => n.id == id).firstOrNull;
      return npc?.isIncapacitated ?? false;
    }).toList();
    // Remover incapacitados da expedicao automaticamente
    final validPartyIds = partyIds.where((id) => !incapacitated.contains(id)).toList();
    if (validPartyIds.length < 2) return null;

    _lastChallenge = _engine.attemptFloor(validPartyIds);

    // Atualizar missoes do grupo se todos forem do mesmo grupo
    final partyNpcs = partyIds
        .map((id) => _engine.npcs.where((n) => n.id == id).firstOrNull)
        .whereType<Npc>()
        .toList();
    final groupIds = partyNpcs
        .where((n) => n.groupId != null)
        .map((n) => n.groupId!)
        .toSet();
    for (final gid in groupIds) {
      final group = _engine.groups.where((g) => g.id == gid).firstOrNull;
      if (group != null) {
        group.missionsCompleted++;
        if (_lastChallenge!.victory) {
          group.cohesion = (group.cohesion + 5).clamp(0, 100);
        } else {
          group.cohesion = (group.cohesion - 3).clamp(0, 100);
        }
      }
    }

    _saveGame();
    notifyListeners();
    return _lastChallenge;
  }

  /// ACAO PRINCIPAL: Re-explorar andar conquistado para coletar recursos
  FloorExplorationResult? sendReexploration(int floorNumber, List<String> partyIds) {
    if (partyIds.isEmpty) return null;
    final floor = _engine.floors.where((f) => f.number == floorNumber && f.cleared).firstOrNull;
    if (floor == null) return null;

    // Remover incapacitados
    final validIds = partyIds.where((id) {
      final npc = _engine.npcs.where((n) => n.id == id).firstOrNull;
      return npc != null && !npc.isIncapacitated;
    }).toList();
    if (validIds.isEmpty) return null;

    final result = _engine.reexploreFloor(floorNumber, validIds);

    // Atualizar missoes do grupo
    final rePartyNpcs = validIds
        .map((id) => _engine.npcs.where((n) => n.id == id).firstOrNull)
        .whereType<Npc>()
        .toList();
    final groupIds = rePartyNpcs
        .where((n) => n.groupId != null)
        .map((n) => n.groupId!)
        .toSet();
    for (final gid in groupIds) {
      final group = _engine.groups.where((g) => g.id == gid).firstOrNull;
      if (group != null) {
        group.missionsCompleted++;
        group.cohesion = (group.cohesion + 2).clamp(0, 100);
      }
    }

    _saveGame();
    notifyListeners();
    return result;
  }

  /// Enviar grupo inteiro para expedição no proximo andar
  TowerChallenge? sendGroupExpedition(String groupId) {
    final group = _engine.groups.where((g) => g.id == groupId).firstOrNull;
    if (group == null || group.memberIds.isEmpty) return null;

    final aliveMembers = group.memberIds
        .where((id) => _engine.npcs.any((n) => n.id == id && n.alive))
        .toList();
    if (aliveMembers.length < 2) return null;

    return sendExpedition(aliveMembers);
  }

  /// Enviar grupo inteiro para re-explorar andar conquistado
  FloorExplorationResult? sendGroupReexploration(String groupId, int floorNumber) {
    final group = _engine.groups.where((g) => g.id == groupId).firstOrNull;
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

  // ==================== CONSTRUCAO MANUAL ====================

  /// Edificios disponiveis para construir
  List<BuildingType> get availableBuildings => _engine.availableBuildings;

  /// Verifica se pode construir
  bool canBuild(BuildingType type) => _engine.canBuild(type);

  /// Verifica se pode fazer upgrade
  bool canUpgradeBuilding(BuildingType type) => _engine.canUpgradeBuilding(type);

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

  /// ACAO DO JOGADOR: Evoluir cidadela
  bool upgradeCitadel() {
    final result = _engine.upgradeCitadel();
    if (result) {
      _saveGame();
      notifyListeners();
    }
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
    if (!_engine.citadel.resources.canAfford(_engine.citadel.upgradeCost)) return false;
    final next = _engine.citadel.nextLevel;
    if (next == null) return false;
    if (population < next.populationRequired) return false;
    // Verificar tier da torre necessario
    final currentTier = ((_engine.state.highestFloorCleared) ~/ 10) + (_engine.state.highestFloorCleared % 10 > 0 ? 1 : 0);
    if (currentTier < next.requiredTowerTier) return false;
    return true;
  }

  // ==================== SUGESTAO DE TREINO ====================

  TrainingSuggestion suggestTraining(String targetId, String targetType, int floorNumber) {
    final suggestion = _engine.suggestTraining(targetId, targetType, floorNumber);
    _saveGame();
    notifyListeners();
    return suggestion;
  }

  // ==================== CONTROLES ====================

  void togglePause() {
    _paused = !_paused;
    if (_paused) {
      _updateTimer?.cancel();
      // Salvar estado ao pausar
      _saveGame();
    } else {
      // Ao retomar, atualizar timestamp para evitar salto temporal
      state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
      _scheduleUpdate();
    }
    notifyListeners();
  }

  void setSpeed(int speed) {
    if (!availableSpeeds.contains(speed)) {
      _speedMultiplier = availableSpeeds.reduce(
          (a, b) => (a - speed).abs() < (b - speed).abs() ? a : b);
    } else {
      _speedMultiplier = speed;
    }
    // Resetar timestamp para evitar salto com nova velocidade
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  void stopSimulation() {
    _updateTimer?.cancel();
    _simRunning = false;
    _paused = false;
    // Salvar timestamp ao parar
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    _saveGame();
    notifyListeners();
  }

  Future<void> deleteSave() async {
    stopSimulation();
    await SaveService.deleteSave();
    _hasSave = false;
    notifyListeners();
  }

  Future<void> _saveGame() async {
    // Atualizar timestamp antes de salvar
    state.lastRealTimestamp = DateTime.now().millisecondsSinceEpoch;
    await SaveService.saveGame(_engine);
    _hasSave = true;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

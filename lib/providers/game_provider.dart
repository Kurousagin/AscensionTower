import 'package:flutter/material.dart';
import '../services/game_engine.dart';
import '../services/save_service.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/tower.dart';
import '../models/game_event.dart';

class GameProvider extends ChangeNotifier {
  final GameEngine _engine = GameEngine();
  bool _isLoading = false;
  bool _hasSave = false;
  List<GameEvent> _lastDayEvents = [];
  TowerChallenge? _lastChallenge;
  bool _autoSimulating = false;

  GameEngine get engine => _engine;
  bool get isLoading => _isLoading;
  bool get hasSave => _hasSave;
  List<GameEvent> get lastDayEvents => _lastDayEvents;
  TowerChallenge? get lastChallenge => _lastChallenge;
  bool get autoSimulating => _autoSimulating;

  GameState get state => _engine.state;
  List<Npc> get allNpcs => _engine.npcs;
  List<Npc> get aliveNpcs => _engine.aliveNpcs;
  List<Npc> get deadNpcs => _engine.deadNpcs;
  Citadel get citadel => _engine.citadel;
  List<TowerFloor> get floors => _engine.floors;
  List<GameEvent> get events => _engine.events;
  int get population => _engine.population;
  TowerFloor? get nextFloor => _engine.nextFloor;

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
    _lastDayEvents = _engine.events.toList();
    _lastChallenge = null;
    _saveGame();
    notifyListeners();
  }

  Future<bool> loadGame() async {
    _isLoading = true;
    notifyListeners();
    final success = await SaveService.loadGame(_engine);
    _isLoading = false;
    _hasSave = success;
    notifyListeners();
    return success;
  }

  void advanceDay() {
    _lastDayEvents = _engine.simulateDay();
    _saveGame();
    notifyListeners();
  }

  Future<void> advanceMultipleDays(int count) async {
    _autoSimulating = true;
    notifyListeners();

    for (int i = 0; i < count; i++) {
      _lastDayEvents = _engine.simulateDay();
      if (_engine.state.gameOver) break;
      if (i % 5 == 0) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 16));
      }
    }

    _autoSimulating = false;
    _saveGame();
    notifyListeners();
  }

  TowerChallenge attemptFloor(List<String> partyIds) {
    _lastChallenge = _engine.attemptFloor(partyIds);
    _saveGame();
    notifyListeners();
    return _lastChallenge!;
  }

  TowerChallenge trainOnFloor(int floorNumber, List<String> partyIds) {
    _lastChallenge = _engine.trainOnFloor(floorNumber, partyIds);
    _saveGame();
    notifyListeners();
    return _lastChallenge!;
  }

  bool buildStructure(BuildingType type) {
    final result = _engine.buildStructure(type);
    if (result) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  bool upgradeCitadel() {
    final result = _engine.upgradeCitadel();
    if (result) {
      _saveGame();
      notifyListeners();
    }
    return result;
  }

  void assignProfession(String npcId, Profession profession) {
    _engine.assignProfession(npcId, profession);
    _saveGame();
    notifyListeners();
  }

  Future<void> deleteSave() async {
    await SaveService.deleteSave();
    _hasSave = false;
    notifyListeners();
  }

  Future<void> _saveGame() async {
    await SaveService.saveGame(_engine);
    _hasSave = true;
  }
}

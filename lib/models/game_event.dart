enum GameEventType {
  combat,
  death,
  birth,
  discovery,
  crisis,
  celebration,
  betrayal,
  romance,
  construction,
  exploration,
  mentalBreak,
  towerCleared,
  upgrade,
  resourceGain,
  resourceLoss,
  training,
  system,
  // Novos tipos
  groupFormed,
  trainingSuggestion,
  betrayalAttempt,
  emergencySummon,
  floorReexplore,
  loyaltyChange,
  politicalEvent,
}

extension GameEventTypeExt on GameEventType {
  String get tag {
    switch (this) {
      case GameEventType.combat:
        return 'Combate';
      case GameEventType.death:
        return 'Morte';
      case GameEventType.birth:
        return 'Nascimento';
      case GameEventType.discovery:
        return 'Descoberta';
      case GameEventType.crisis:
        return 'Crise';
      case GameEventType.celebration:
        return 'Celebracao';
      case GameEventType.betrayal:
        return 'Traicao';
      case GameEventType.romance:
        return 'Romance';
      case GameEventType.construction:
        return 'Construcao';
      case GameEventType.exploration:
        return 'Exploracao';
      case GameEventType.mentalBreak:
        return 'Colapso Mental';
      case GameEventType.towerCleared:
        return 'Torre Conquistada';
      case GameEventType.upgrade:
        return 'Evolucao';
      case GameEventType.resourceGain:
        return 'Recursos +';
      case GameEventType.resourceLoss:
        return 'Recursos -';
      case GameEventType.training:
        return 'Treino';
      case GameEventType.system:
        return 'Sistema';
      case GameEventType.groupFormed:
        return 'Grupo Formado';
      case GameEventType.trainingSuggestion:
        return 'Sugestao de Treino';
      case GameEventType.betrayalAttempt:
        return 'Tentativa de Traicao';
      case GameEventType.emergencySummon:
        return 'Invocacao Emergencial';
      case GameEventType.floorReexplore:
        return 'Re-Exploracao';
      case GameEventType.loyaltyChange:
        return 'Lealdade';
      case GameEventType.politicalEvent:
        return 'Politica Interna';
    }
  }

  String get colorHex {
    switch (this) {
      case GameEventType.combat:
        return '#FF4444';
      case GameEventType.death:
        return '#CC0000';
      case GameEventType.birth:
        return '#44FF88';
      case GameEventType.discovery:
        return '#44DDFF';
      case GameEventType.crisis:
        return '#FF8800';
      case GameEventType.celebration:
        return '#FFDD44';
      case GameEventType.betrayal:
        return '#FF44FF';
      case GameEventType.romance:
        return '#FF88AA';
      case GameEventType.construction:
        return '#88AAFF';
      case GameEventType.exploration:
        return '#44FFDD';
      case GameEventType.mentalBreak:
        return '#AA44FF';
      case GameEventType.towerCleared:
        return '#00FF88';
      case GameEventType.upgrade:
        return '#88FF44';
      case GameEventType.resourceGain:
        return '#44CC88';
      case GameEventType.resourceLoss:
        return '#CC8844';
      case GameEventType.training:
        return '#88CCFF';
      case GameEventType.system:
        return '#888888';
      case GameEventType.groupFormed:
        return '#66BBFF';
      case GameEventType.trainingSuggestion:
        return '#88DDAA';
      case GameEventType.betrayalAttempt:
        return '#FF2244';
      case GameEventType.emergencySummon:
        return '#FFAA00';
      case GameEventType.floorReexplore:
        return '#44DDBB';
      case GameEventType.loyaltyChange:
        return '#AABB88';
      case GameEventType.politicalEvent:
        return '#DDAA66';
    }
  }
}

class GameEvent {
  final String id;
  final int day;
  final GameEventType type;
  final String title;
  final String description;
  final List<String> involvedNpcIds;
  final bool isMajor;
  final int timestamp;

  GameEvent({
    required this.id,
    required this.day,
    required this.type,
    required this.title,
    required this.description,
    this.involvedNpcIds = const [],
    this.isMajor = false,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  String get formattedLog => '${type.tag} DIA $day | $title';
  String get fullLog => '${type.tag} DIA $day\n> $title\n$description';

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'type': type.index,
    'title': title,
    'description': description,
    'involvedNpcIds': involvedNpcIds,
    'isMajor': isMajor,
    'timestamp': timestamp,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    id: json['id'] as String? ?? '',
    day: json['day'] as int? ?? 0,
    type: GameEventType.values[json['type'] as int? ?? 0],
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    involvedNpcIds:
        (json['involvedNpcIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    isMajor: json['isMajor'] as bool? ?? false,
    timestamp: json['timestamp'] as int?,
  );
}

class GameState {
  int currentDay;
  int highestFloorCleared;
  int highestFloorReached;
  int totalDeaths;
  int totalBirths;
  int npcIdCounter;
  int eventIdCounter;
  bool gameOver;
  String gameOverReason;
  int lastSettlersRequestDay; // Ultimo dia que solicitou moradores

  /// Tempo acumulado na Torre em segundos (tempo in-game total dentro do dia atual).
  /// Quando >= 86400 (24h in-game), um dia completo e processado.
  /// Range: 0.0 .. 86399.999...
  double gameSeconds;

  /// Timestamp real (epoch ms) da ultima vez que o tempo foi processado.
  /// Usado para calcular deltaRealSeconds ao retomar o jogo (offline progress).
  int lastRealTimestamp;

  GameState({
    this.currentDay = 1,
    this.highestFloorCleared = 0,
    this.highestFloorReached = 0,
    this.totalDeaths = 0,
    this.totalBirths = 0,
    this.npcIdCounter = 0,
    this.eventIdCounter = 0,
    this.gameOver = false,
    this.gameOverReason = '',
    this.lastSettlersRequestDay = 0,
    this.gameSeconds = 0.0,
    int? lastRealTimestamp,
  }) : lastRealTimestamp =
           lastRealTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  // ===== DERIVADOS DO TEMPO =====

  /// Hora atual in-game (0-23), derivada de gameSeconds
  int get currentHour => (gameSeconds / 3600.0).floor().clamp(0, 23);

  /// Minuto atual in-game (0-59)
  int get currentMinute => ((gameSeconds % 3600) / 60).floor().clamp(0, 59);

  /// Periodo do dia baseado na hora in-game
  String get dayPeriod {
    final h = currentHour;
    if (h >= 6 && h < 12) return 'Manha';
    if (h >= 12 && h < 18) return 'Tarde';
    if (h >= 18 && h < 22) return 'Noite';
    return 'Madrugada';
  }

  /// Hora formatada HH:MM
  String get formattedTime {
    return '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}';
  }

  /// Tempo total em dias in-game (fracional)
  double get totalGameDays => (currentDay - 1) + (gameSeconds / 86400.0);

  String generateNpcId() {
    npcIdCounter++;
    return 'npc_$npcIdCounter';
  }

  String generateEventId() {
    eventIdCounter++;
    return 'evt_$eventIdCounter';
  }

  Map<String, dynamic> toJson() => {
    'currentDay': currentDay,
    'highestFloorCleared': highestFloorCleared,
    'highestFloorReached': highestFloorReached,
    'totalDeaths': totalDeaths,
    'totalBirths': totalBirths,
    'npcIdCounter': npcIdCounter,
    'eventIdCounter': eventIdCounter,
    'gameOver': gameOver,
    'gameOverReason': gameOverReason,
    'lastSettlersRequestDay': lastSettlersRequestDay,
    'gameSeconds': gameSeconds,
    'lastRealTimestamp': lastRealTimestamp,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    currentDay: json['currentDay'] as int? ?? 1,
    highestFloorCleared: json['highestFloorCleared'] as int? ?? 0,
    highestFloorReached: json['highestFloorReached'] as int? ?? 0,
    totalDeaths: json['totalDeaths'] as int? ?? 0,
    totalBirths: json['totalBirths'] as int? ?? 0,
    npcIdCounter: json['npcIdCounter'] as int? ?? 0,
    eventIdCounter: json['eventIdCounter'] as int? ?? 0,
    gameOver: json['gameOver'] as bool? ?? false,
    gameOverReason: json['gameOverReason'] as String? ?? '',
    lastSettlersRequestDay: json['lastSettlersRequestDay'] as int? ?? 0,
    gameSeconds:
        (json['gameSeconds'] as num?)?.toDouble() ??
        ((json['inGameHoursAccumulated'] as num?)?.toDouble() ?? 0.0) * 3600.0,
    lastRealTimestamp: json['lastRealTimestamp'] as int?,
  );
}

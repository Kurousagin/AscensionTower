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
}

extension GameEventTypeExt on GameEventType {
  String get tag {
    switch (this) {
      case GameEventType.combat: return '[COMBATE]';
      case GameEventType.death: return '[MORTE]';
      case GameEventType.birth: return '[NASC]';
      case GameEventType.discovery: return '[DESC]';
      case GameEventType.crisis: return '[CRISE]';
      case GameEventType.celebration: return '[CELEB]';
      case GameEventType.betrayal: return '[TRAIC]';
      case GameEventType.romance: return '[AMOR]';
      case GameEventType.construction: return '[CONST]';
      case GameEventType.exploration: return '[EXPL]';
      case GameEventType.mentalBreak: return '[MENTAL]';
      case GameEventType.towerCleared: return '[TORRE]';
      case GameEventType.upgrade: return '[UP]';
      case GameEventType.resourceGain: return '[+REC]';
      case GameEventType.resourceLoss: return '[-REC]';
      case GameEventType.training: return '[TREINO]';
      case GameEventType.system: return '[SYS]';
    }
  }

  String get colorHex {
    switch (this) {
      case GameEventType.combat: return '#FF4444';
      case GameEventType.death: return '#CC0000';
      case GameEventType.birth: return '#44FF88';
      case GameEventType.discovery: return '#44DDFF';
      case GameEventType.crisis: return '#FF8800';
      case GameEventType.celebration: return '#FFDD44';
      case GameEventType.betrayal: return '#FF44FF';
      case GameEventType.romance: return '#FF88AA';
      case GameEventType.construction: return '#88AAFF';
      case GameEventType.exploration: return '#44FFDD';
      case GameEventType.mentalBreak: return '#AA44FF';
      case GameEventType.towerCleared: return '#00FF88';
      case GameEventType.upgrade: return '#88FF44';
      case GameEventType.resourceGain: return '#44CC88';
      case GameEventType.resourceLoss: return '#CC8844';
      case GameEventType.training: return '#88CCFF';
      case GameEventType.system: return '#888888';
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
        involvedNpcIds: (json['involvedNpcIds'] as List<dynamic>?)
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
  });

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
      );
}

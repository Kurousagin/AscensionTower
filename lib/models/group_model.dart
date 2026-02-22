/// Modelo de grupo/esquadrao de NPCs
class NpcGroup {
  final String id;
  String name;
  List<String> memberIds;
  String? leaderId;
  GroupRole role;
  int missionsCompleted;
  int casualties;
  double cohesion; // 0-100: coesao do grupo

  NpcGroup({
    required this.id,
    required this.name,
    List<String>? memberIds,
    this.leaderId,
    this.role = GroupRole.general,
    this.missionsCompleted = 0,
    this.casualties = 0,
    this.cohesion = 50.0,
  }) : memberIds = memberIds ?? [];

  int get size => memberIds.length;
  bool get isEmpty => memberIds.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberIds': memberIds,
        'leaderId': leaderId,
        'role': role.index,
        'missionsCompleted': missionsCompleted,
        'casualties': casualties,
        'cohesion': cohesion,
      };

  factory NpcGroup.fromJson(Map<String, dynamic> json) => NpcGroup(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Grupo',
        memberIds: (json['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        leaderId: json['leaderId'] as String?,
        role: GroupRole.values[(json['role'] as int? ?? 0).clamp(0, GroupRole.values.length - 1)],
        missionsCompleted: json['missionsCompleted'] as int? ?? 0,
        casualties: json['casualties'] as int? ?? 0,
        cohesion: (json['cohesion'] as num?)?.toDouble() ?? 50.0,
      );
}

enum GroupRole {
  general,
  assault,
  recon,
  training,
  defense,
}

extension GroupRoleExt on GroupRole {
  String get label {
    switch (this) {
      case GroupRole.general: return 'Geral';
      case GroupRole.assault: return 'Assalto';
      case GroupRole.recon: return 'Reconhecimento';
      case GroupRole.training: return 'Treinamento';
      case GroupRole.defense: return 'Defesa';
    }
  }
}

/// Registro de sugestao de treino feita pelo jogador
class TrainingSuggestion {
  final String id;
  final int day;
  final String targetType; // 'npc' ou 'group'
  final String targetId; // npcId ou groupId
  final int floorNumber; // andar para treinar, ou -1 para training field
  TrainingResponse response;
  String responseDetail;

  TrainingSuggestion({
    required this.id,
    required this.day,
    required this.targetType,
    required this.targetId,
    required this.floorNumber,
    this.response = TrainingResponse.pending,
    this.responseDetail = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'targetType': targetType,
        'targetId': targetId,
        'floorNumber': floorNumber,
        'response': response.index,
        'responseDetail': responseDetail,
      };

  factory TrainingSuggestion.fromJson(Map<String, dynamic> json) => TrainingSuggestion(
        id: json['id'] as String? ?? '',
        day: json['day'] as int? ?? 0,
        targetType: json['targetType'] as String? ?? 'npc',
        targetId: json['targetId'] as String? ?? '',
        floorNumber: json['floorNumber'] as int? ?? 1,
        response: TrainingResponse.values[(json['response'] as int? ?? 0).clamp(0, TrainingResponse.values.length - 1)],
        responseDetail: json['responseDetail'] as String? ?? '',
      );
}

enum TrainingResponse {
  pending,
  accepted,
  refused,
  negotiated,
  ignored,
  persuadedOthers,
}

extension TrainingResponseExt on TrainingResponse {
  String get label {
    switch (this) {
      case TrainingResponse.pending: return 'Pendente';
      case TrainingResponse.accepted: return 'Aceitou';
      case TrainingResponse.refused: return 'Recusou';
      case TrainingResponse.negotiated: return 'Negociou';
      case TrainingResponse.ignored: return 'Ignorou';
      case TrainingResponse.persuadedOthers: return 'Convenceu outros';
    }
  }
}

/// Resultado de re-exploracao de andar
class FloorExplorationResult {
  final int floorNumber;
  final int day;
  final List<String> partyIds;
  final Map<String, double> resourcesGained;
  final List<String> discoveries;
  final List<String> casualties;
  final bool hiddenThreatActivated;
  final String narrative;
  double foodCost;
  final List<String> expeditionEvents;

  FloorExplorationResult({
    required this.floorNumber,
    required this.day,
    required this.partyIds,
    Map<String, double>? resourcesGained,
    List<String>? discoveries,
    List<String>? casualties,
    this.hiddenThreatActivated = false,
    this.narrative = '',
    this.foodCost = 0.0,
    List<String>? expeditionEvents,
  })  : resourcesGained = resourcesGained ?? {},
        discoveries = discoveries ?? [],
        casualties = casualties ?? [],
        expeditionEvents = expeditionEvents ?? [];

  Map<String, dynamic> toJson() => {
        'floorNumber': floorNumber,
        'day': day,
        'partyIds': partyIds,
        'resourcesGained': resourcesGained,
        'discoveries': discoveries,
        'casualties': casualties,
        'hiddenThreatActivated': hiddenThreatActivated,
        'narrative': narrative,
        'foodCost': foodCost,
        'expeditionEvents': expeditionEvents,
      };
}

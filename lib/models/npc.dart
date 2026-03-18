import 'dart:math';
import 'package:collection/collection.dart';
import 'package:tower_ascension/models/name_generator.dart';
import 'package:tower_ascension/models/npc_enums.dart';
export 'package:tower_ascension/models/npc_enums.dart';
import 'equipment.dart'; // ← ADICIONADO: necessário para EquipmentSlot e Equipment

class NpcAttributes {
  double strength;
  double agility;
  double intelligence;
  double endurance;
  double charisma;
  double mentalStability; // 0–100: escala própria, representa sanidade
  double luck;
  double combatPowerMultiplier = 1.0;
  double equipmentBonusMultiplier = 1.0;
  double groupMoraleBonus = 0.0;
  double groupSynergyBonus = 0.0;
  double groupMortalityReduction = 0.0;
  bool canHealAfterBattle = false;
  bool immuneToSanityLoss = false;
  bool canEvadeCombat = false;
  bool canCraftMedicine = false;
  bool canTameCreatures = false;
  bool canRevealSecrets = false;

  NpcAttributes({
    this.strength = 5.0,
    this.agility = 5.0,
    this.intelligence = 5.0,
    this.endurance = 5.0,
    this.charisma = 5.0,
    this.mentalStability = 70.0,
    this.luck = 5.0,
    this.combatPowerMultiplier = 1.0,
    this.equipmentBonusMultiplier = 1.0,
    this.groupMoraleBonus = 0.0,
    this.groupSynergyBonus = 0.0,
    this.groupMortalityReduction = 0.0,
    this.canHealAfterBattle = false,
    this.immuneToSanityLoss = false,
    this.canEvadeCombat = false,
    this.canCraftMedicine = false,
    this.canTameCreatures = false,
    this.canRevealSecrets = false,
  });

  /// Média dos atributos físicos principais (exclui mentalStability e luck)
  double get average =>
      (strength + agility + intelligence + endurance + charisma) / 5.0;

  /// Poder de combate ponderado — alinhado com a fórmula do README
  /// FOR*0.3 + AGI*0.25 + RES*0.25 + INT*0.2
  double get combatPower =>
      strength * 0.3 + agility * 0.25 + endurance * 0.25 + intelligence * 0.2;

  NpcAttributes copyWith({
    double? strength,
    double? agility,
    double? intelligence,
    double? endurance,
    double? charisma,
    double? mentalStability,
    double? luck,
    double? combatPowerMultiplier,
    double? equipmentBonusMultiplier,
    double? groupMoraleBonus,
    double? groupSynergyBonus,
    double? groupMortalityReduction,
    bool? canHealAfterBattle,
    bool? immuneToSanityLoss,
    bool? canEvadeCombat,
    bool? canCraftMedicine,
    bool? canTameCreatures,
    bool? canRevealSecrets,
  }) => NpcAttributes(
    strength: strength ?? this.strength,
    agility: agility ?? this.agility,
    intelligence: intelligence ?? this.intelligence,
    endurance: endurance ?? this.endurance,
    charisma: charisma ?? this.charisma,
    mentalStability: mentalStability ?? this.mentalStability,
    luck: luck ?? this.luck,
    combatPowerMultiplier: combatPowerMultiplier ?? this.combatPowerMultiplier,
    equipmentBonusMultiplier:
        equipmentBonusMultiplier ?? this.equipmentBonusMultiplier,
    groupMoraleBonus: groupMoraleBonus ?? this.groupMoraleBonus,
    groupSynergyBonus: groupSynergyBonus ?? this.groupSynergyBonus,
    groupMortalityReduction:
        groupMortalityReduction ?? this.groupMortalityReduction,
    canHealAfterBattle: canHealAfterBattle ?? this.canHealAfterBattle,
    immuneToSanityLoss: immuneToSanityLoss ?? this.immuneToSanityLoss,
    canEvadeCombat: canEvadeCombat ?? this.canEvadeCombat,
    canCraftMedicine: canCraftMedicine ?? this.canCraftMedicine,
    canTameCreatures: canTameCreatures ?? this.canTameCreatures,
    canRevealSecrets: canRevealSecrets ?? this.canRevealSecrets,
  );

  Map<String, dynamic> toJson() => {
    'strength': strength,
    'agility': agility,
    'intelligence': intelligence,
    'endurance': endurance,
    'charisma': charisma,
    'mentalStability': mentalStability,
    'luck': luck,
    'combatPowerMultiplier': combatPowerMultiplier,
    'equipmentBonusMultiplier': equipmentBonusMultiplier,
    'groupMoraleBonus': groupMoraleBonus,
    'groupSynergyBonus': groupSynergyBonus,
    'groupMortalityReduction': groupMortalityReduction,
    'canHealAfterBattle': canHealAfterBattle,
    'immuneToSanityLoss': immuneToSanityLoss,
    'canEvadeCombat': canEvadeCombat,
    'canCraftMedicine': canCraftMedicine,
    'canTameCreatures': canTameCreatures,
    'canRevealSecrets': canRevealSecrets,
  };

  factory NpcAttributes.fromJson(Map<String, dynamic> json) => NpcAttributes(
    strength: (json['strength'] as num?)?.toDouble() ?? 5.0,
    agility: (json['agility'] as num?)?.toDouble() ?? 5.0,
    intelligence: (json['intelligence'] as num?)?.toDouble() ?? 5.0,
    endurance: (json['endurance'] as num?)?.toDouble() ?? 5.0,
    charisma: (json['charisma'] as num?)?.toDouble() ?? 5.0,
    mentalStability: (json['mentalStability'] as num?)?.toDouble() ?? 70.0,
    luck: (json['luck'] as num?)?.toDouble() ?? 5.0,
    combatPowerMultiplier:
        (json['combatPowerMultiplier'] as num?)?.toDouble() ?? 1.0,
    equipmentBonusMultiplier:
        (json['equipmentBonusMultiplier'] as num?)?.toDouble() ?? 1.0,
    groupMoraleBonus: (json['groupMoraleBonus'] as num?)?.toDouble() ?? 0.0,
    groupSynergyBonus: (json['groupSynergyBonus'] as num?)?.toDouble() ?? 0.0,
    groupMortalityReduction:
        (json['groupMortalityReduction'] as num?)?.toDouble() ?? 0.0,
    canHealAfterBattle: (json['canHealAfterBattle'] as bool?) ?? false,
    immuneToSanityLoss: (json['immuneToSanityLoss'] as bool?) ?? false,
    canEvadeCombat: (json['canEvadeCombat'] as bool?) ?? false,
    canCraftMedicine: (json['canCraftMedicine'] as bool?) ?? false,
    canTameCreatures: (json['canTameCreatures'] as bool?) ?? false,
    canRevealSecrets: (json['canRevealSecrets'] as bool?) ?? false,
  );
}

// ─────────────────────────────────────────────
// ORIGEM
// ─────────────────────────────────────────────

enum NpcOrigin {
  student,
  chef,
  soldier,
  programmer,
  athlete,
  businessOwner,
  doctor,
  teacher,
  artist,
  mechanic,
  farmer,
  musician,
  scientist,
  firefighter,
  nurse,
  bornInTheAbyss,
  bornOfChaos,
  // Origens obscuras — 12% de chance de invocação, risco de traição elevado
  thief,
  assassin,
  fraudster,
  towerDweller, // Habitante da torre
}

extension NpcOriginExt on NpcOrigin {
  String get label => const {
    NpcOrigin.student: 'Estudante',
    NpcOrigin.chef: 'Chef',
    NpcOrigin.soldier: 'Soldado',
    NpcOrigin.programmer: 'Programador',
    NpcOrigin.athlete: 'Atleta',
    NpcOrigin.businessOwner: 'Empresário',
    NpcOrigin.doctor: 'Médico',
    NpcOrigin.teacher: 'Professor',
    NpcOrigin.artist: 'Artista',
    NpcOrigin.mechanic: 'Mecânico',
    NpcOrigin.farmer: 'Fazendeiro',
    NpcOrigin.musician: 'Músico',
    NpcOrigin.scientist: 'Cientista',
    NpcOrigin.firefighter: 'Bombeiro',
    NpcOrigin.nurse: 'Enfermeiro(a)',
    NpcOrigin.thief: 'Ladrão',
    NpcOrigin.assassin: 'Assassino',
    NpcOrigin.fraudster: 'Estelionatário',
    NpcOrigin.bornInTheAbyss: 'Nascido no Abismo',
    NpcOrigin.bornOfChaos: 'Nascido do Caos',
    NpcOrigin.towerDweller: 'Habitante da torre',
  }[this]!;
  bool get isNaturalBorn =>
      this == NpcOrigin.bornInTheAbyss || this == NpcOrigin.bornOfChaos;

  /// Origens com risco inerente de traição
  bool get isDarkOrigin =>
      this == NpcOrigin.thief ||
      this == NpcOrigin.assassin ||
      this == NpcOrigin.fraudster;
}

extension NpcOriginAttrExt on NpcOrigin {
  NpcAttributes get baseAttributes => _AttrPresets.forOrigin(this);
}

// Presets de atributos separados para manter NpcOrigin limpo.
abstract class _AttrPresets {
  static final student = NpcAttributes(
    strength: 3,
    agility: 4,
    intelligence: 8,
    endurance: 3,
    charisma: 5,
    mentalStability: 60,
    luck: 6,
  );
  static final chef = NpcAttributes(
    strength: 4,
    agility: 6,
    intelligence: 6,
    endurance: 5,
    charisma: 7,
    mentalStability: 65,
    luck: 5,
  );
  static final soldier = NpcAttributes(
    strength: 9,
    agility: 7,
    intelligence: 5,
    endurance: 9,
    charisma: 4,
    mentalStability: 75,
    luck: 4,
  );
  static final programmer = NpcAttributes(
    strength: 2,
    agility: 3,
    intelligence: 9,
    endurance: 3,
    charisma: 4,
    mentalStability: 55,
    luck: 5,
  );
  static final athlete = NpcAttributes(
    strength: 8,
    agility: 9,
    intelligence: 4,
    endurance: 8,
    charisma: 6,
    mentalStability: 70,
    luck: 5,
  );
  static final businessOwner = NpcAttributes(
    strength: 4,
    agility: 4,
    intelligence: 7,
    endurance: 5,
    charisma: 9,
    mentalStability: 68,
    luck: 7,
  );
  static final doctor = NpcAttributes(
    strength: 3,
    agility: 5,
    intelligence: 9,
    endurance: 5,
    charisma: 6,
    mentalStability: 72,
    luck: 5,
  );
  static final teacher = NpcAttributes(
    strength: 3,
    agility: 4,
    intelligence: 8,
    endurance: 4,
    charisma: 8,
    mentalStability: 70,
    luck: 5,
  );
  static final artist = NpcAttributes(
    strength: 3,
    agility: 5,
    intelligence: 7,
    endurance: 3,
    charisma: 8,
    mentalStability: 50,
    luck: 7,
  );
  static final mechanic = NpcAttributes(
    strength: 7,
    agility: 6,
    intelligence: 6,
    endurance: 7,
    charisma: 4,
    mentalStability: 65,
    luck: 4,
  );
  static final farmer = NpcAttributes(
    strength: 7,
    agility: 5,
    intelligence: 4,
    endurance: 8,
    charisma: 5,
    mentalStability: 75,
    luck: 5,
  );
  static final musician = NpcAttributes(
    strength: 3,
    agility: 5,
    intelligence: 6,
    endurance: 3,
    charisma: 9,
    mentalStability: 55,
    luck: 6,
  );
  static final scientist = NpcAttributes(
    strength: 2,
    agility: 3,
    intelligence: 10,
    endurance: 4,
    charisma: 4,
    mentalStability: 60,
    luck: 4,
  );
  static final firefighter = NpcAttributes(
    strength: 8,
    agility: 7,
    intelligence: 5,
    endurance: 9,
    charisma: 6,
    mentalStability: 78,
    luck: 5,
  );
  static final nurse = NpcAttributes(
    strength: 4,
    agility: 5,
    intelligence: 7,
    endurance: 6,
    charisma: 7,
    mentalStability: 70,
    luck: 5,
  );
  static final thief = NpcAttributes(
    strength: 4,
    agility: 9,
    intelligence: 7,
    endurance: 5,
    charisma: 6,
    mentalStability: 55,
    luck: 8,
  );
  static final assassin = NpcAttributes(
    strength: 8,
    agility: 10,
    intelligence: 6,
    endurance: 7,
    charisma: 3,
    mentalStability: 45,
    luck: 5,
  );
  static final fraudster = NpcAttributes(
    strength: 3,
    agility: 5,
    intelligence: 9,
    endurance: 3,
    charisma: 10,
    mentalStability: 50,
    luck: 9,
  );
  static final bornInTheAbyss = NpcAttributes(); // atributos padrão (5,5,5...)
  static final bornOfChaos = NpcAttributes();
  static final towerDweller = NpcAttributes(
    strength: 6.0,
    agility: 6.0,
    intelligence: 5.0,
    endurance: 7.0,
    charisma: 4.0,
    mentalStability: 60.0,
    luck: 5.0,
  );

  static final Map<NpcOrigin, NpcAttributes> _map = {
    NpcOrigin.student: student,
    NpcOrigin.chef: chef,
    NpcOrigin.soldier: soldier,
    NpcOrigin.programmer: programmer,
    NpcOrigin.athlete: athlete,
    NpcOrigin.businessOwner: businessOwner,
    NpcOrigin.doctor: doctor,
    NpcOrigin.teacher: teacher,
    NpcOrigin.artist: artist,
    NpcOrigin.mechanic: mechanic,
    NpcOrigin.farmer: farmer,
    NpcOrigin.musician: musician,
    NpcOrigin.scientist: scientist,
    NpcOrigin.firefighter: firefighter,
    NpcOrigin.nurse: nurse,
    NpcOrigin.thief: thief,
    NpcOrigin.assassin: assassin,
    NpcOrigin.fraudster: fraudster,
    NpcOrigin.bornInTheAbyss: bornInTheAbyss,
    NpcOrigin.bornOfChaos: bornOfChaos,
    NpcOrigin.towerDweller: towerDweller,
  };

  static NpcAttributes forOrigin(NpcOrigin origin) => _map[origin]!;
}

// ─────────────────────────────────────────────
// RELACIONAMENTO
// ─────────────────────────────────────────────

class Relationship {
  final String targetId;
  final String type;
  final double affinity;

  const Relationship({
    required this.targetId,
    this.type = 'neutral',
    this.affinity = 0.0,
  });

  Relationship copyWith({String? type, double? affinity}) => Relationship(
    targetId: targetId,
    type: type ?? this.type,
    affinity: affinity ?? this.affinity,
  );

  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'type': type,
    'affinity': affinity,
  };

  factory Relationship.fromJson(Map<String, dynamic> json) => Relationship(
    targetId: json['targetId'] as String? ?? '',
    type: json['type'] as String? ?? 'neutral',
    affinity: (json['affinity'] as num?)?.toDouble() ?? 0.0,
  );
}

// ─────────────────────────────────────────────
// GERADOR DE NOMES — API + fallback local
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// NPC
// ─────────────────────────────────────────────

class Npc {
  String id;
  String name;
  NpcOrigin origin;
  int generation;
  int age;
  bool alive;
  NpcAttributes attributes;
  List<PersonalityTrait> traits;
  HiddenTalent hiddenTalent;
  bool talentDiscovered;
  Profession profession;
  List<Relationship> relationships;
  List<String> traumas;
  double fame;
  String? leaderOfGroupId;
  List<String> history;
  String? partnerId;
  int? pregnantSince;
  List<String> childrenIds;
  String? parentAId;
  String? parentBId;
  int daysSurvived;
  int floorsCleared;
  int killCount;
  int arenaWins;
  int arenaLosses;
  int lastArenaChallengeDay;
  double loyalty;
  String? groupId;
  int trainingSuggestionsReceived;
  int trainingSuggestionsAccepted;
  bool isSuspicious;
  double fatigue;
  int consecutiveExpeditions;
  int lastExpeditionDay;
  int lastBirthDay;
  int birthDay;
  List<String> psychologicalMarks;
  double maternalNutrition;
  int daysIdle;
  
// ── Rank / Raridade ──────────────────────────
  NpcRank rank;

  /// Teto real de atributos — promovidos têm cap levemente reduzido.
  /// Nato: cap do rank. Promovido: cap do rank anterior + 1.
  double get effectiveAttributeCap {
    if (!isPromoted) return rank.attributeCap;
    final prevIndex = (rank.index - 1).clamp(0, NpcRank.values.length - 1);
    return NpcRank.values[prevIndex].attributeCap + 1;
  }

  // ── Deserção ─────────────────────────────────
  bool wantsToLeave;
  int wantsToLeaveDay;

  // ── Narrativa de percepção ────────────────────
  bool awarenessTriggered;

  // ── Sistema de Estrelas e Promoção ───────────
  int stars; // 0–5 dentro do rank atual
  bool isPromoted; // true = chegou aqui via promoção, não por nascimento
  bool isFavorite; // protegido de sacrifício

  // ── Slots de equipamento (null = slot vazio) ── [FASE 1]
  String? equippedWeaponId;
  String? equippedArmorId;
  String? equippedAccessoryId;

  // ── Getters de atributos totais (base + equipamentos) ──
  double totalStrength(List<Equipment> allEquipment) =>
      attributes.strength + gearBonusFor('strength', allEquipment);

  double totalAgility(List<Equipment> allEquipment) =>
      attributes.agility + gearBonusFor('agility', allEquipment);

  double totalIntelligence(List<Equipment> allEquipment) =>
      attributes.intelligence + gearBonusFor('intelligence', allEquipment);

  double totalEndurance(List<Equipment> allEquipment) =>
      attributes.endurance + gearBonusFor('endurance', allEquipment);

  double totalCharisma(List<Equipment> allEquipment) =>
      attributes.charisma + gearBonusFor('charisma', allEquipment);

  double totalLuck(List<Equipment> allEquipment) =>
      attributes.luck + gearBonusFor('luck', allEquipment);

  Npc({
    required this.id,
    required this.name,
    required this.origin,
    this.generation = 1,
    this.age = 25,
    this.alive = true,
    required this.attributes,
    List<PersonalityTrait>? traits,
    this.hiddenTalent = HiddenTalent.none,
    this.talentDiscovered = false,
    this.profession = Profession.idle,
    List<Relationship>? relationships,
    List<String>? traumas,
    this.fame = 0.0,
    this.leaderOfGroupId,
    List<String>? history,
    this.partnerId,
    this.pregnantSince,
    List<String>? childrenIds,
    this.parentAId,
    this.parentBId,
    this.daysSurvived = 0,
    this.floorsCleared = 0,
    this.killCount = 0,
    this.arenaWins = 0,
    this.arenaLosses = 0,
    this.lastArenaChallengeDay = 0,
    this.loyalty = 50.0,
    this.groupId,
    this.trainingSuggestionsReceived = 0,
    this.trainingSuggestionsAccepted = 0,
    this.lastBirthDay = 0,
    this.isSuspicious = false,
    this.fatigue = 0.0,
    this.consecutiveExpeditions = 0,
    this.lastExpeditionDay = 0,
    this.birthDay = 0,
    List<String>? psychologicalMarks,
    this.maternalNutrition = 100.0,
    this.daysIdle = 0,
    // ── Rank / Raridade ──
    this.rank = NpcRank.n,
    // ── Deserção ──
    this.wantsToLeave = false,
    this.wantsToLeaveDay = 0,
    // ── Narrativa de percepção ──
    this.awarenessTriggered = false,
    // ── Estrelas e Promoção ──
    this.stars = 0,
    this.isPromoted = false,
    this.isFavorite = false,
    // ── Equipamentos [FASE 1] ──
    this.equippedWeaponId,
    this.equippedArmorId,
    this.equippedAccessoryId,
  }) : traits = traits ?? [],
       relationships = relationships ?? <Relationship>[],
       traumas = traumas ?? [],
       history = history ?? [],
       childrenIds = childrenIds ?? [],
       psychologicalMarks = psychologicalMarks ?? [];

  // ── Getters de Equipamento [FASE 1] ─────────

  /// IDs de todos os equipamentos equipados (não-nulos)
  List<String> get equippedItemIds => [
    equippedWeaponId,
    equippedArmorId,
    equippedAccessoryId,
  ].whereType<String>().toList();

  /// Retorna true se o slot indicado está ocupado
  bool hasEquipment(EquipmentSlot slot) => switch (slot) {
    EquipmentSlot.weapon => equippedWeaponId != null,
    EquipmentSlot.armor => equippedArmorId != null,
    EquipmentSlot.accessory => equippedAccessoryId != null,
  };

  /// ID do equipamento no slot indicado (null = vazio)
  String? equippedIdForSlot(EquipmentSlot slot) => switch (slot) {
    EquipmentSlot.weapon => equippedWeaponId,
    EquipmentSlot.armor => equippedArmorId,
    EquipmentSlot.accessory => equippedAccessoryId,
  };

  /// Poder de combate REAL incluindo bônus de equipamentos.
  /// Usar este getter em expedições e auto-torre.
  double effectiveCombatPowerWithGear(List<Equipment> allEquipment) {
    double total = attributes.combatPower;
    for (final slotId in equippedItemIds) {
      final eq = allEquipment.firstWhereOrNull((e) => e.id == slotId);
      if (eq == null) continue;
      total += (eq.statBonus['strength'] ?? 0) * 0.30;
      total += (eq.statBonus['agility'] ?? 0) * 0.25;
      total += (eq.statBonus['endurance'] ?? 0) * 0.25;
      total += (eq.statBonus['intelligence'] ?? 0) * 0.20;
    }
    return total;
  }

  /// Bônus total de um atributo específico vindo de todos os equipamentos
  double gearBonusFor(String stat, List<Equipment> allEquipment) {
    double bonus = 0.0;
    for (final slotId in equippedItemIds) {
      final eq = allEquipment.firstWhereOrNull((e) => e.id == slotId);
      bonus += eq?.statBonus[stat] ?? 0.0;
    }
    return bonus;
  }

  // ── copyWith ────────────────────────────────

  Npc copyWith({
    String? name,
    NpcOrigin? origin,
    int? generation,
    int? age,
    bool? alive,
    NpcAttributes? attributes,
    List<PersonalityTrait>? traits,
    HiddenTalent? hiddenTalent,
    bool? talentDiscovered,
    Profession? profession,
    List<Relationship>? relationships,
    List<String>? traumas,
    double? fame,
    List<String>? history,
    String? partnerId,
    bool clearPartner = false,
    int? pregnantSince,
    bool clearPregnancy = false,
    List<String>? childrenIds,
    String? parentAId,
    String? parentBId,
    int? daysSurvived,
    int? floorsCleared,
    int? killCount,
    int? arenaWins,
    int? arenaLosses,
    int? lastArenaChallengeDay,
    double? loyalty,
    String? groupId,
    bool clearGroup = false,
    int? trainingSuggestionsReceived,
    int? trainingSuggestionsAccepted,
    bool? isSuspicious,
    double? fatigue,
    int? consecutiveExpeditions,
    int? lastExpeditionDay,
    int? birthDay,
    List<String>? psychologicalMarks,
    double? maternalNutrition,
    int? daysIdle,
    // ── Rank / Raridade ──
    NpcRank? rank,
    // ── Deserção ──
    bool? wantsToLeave,
    int? wantsToLeaveDay,
    // ── Narrativa de percepção ──
    bool? awarenessTriggered,
    // ── Estrelas e Promoção ──
    int? stars,
    bool? isPromoted,
    bool? isFavorite,
    // ── Equipamentos [FASE 1] ──
    String? equippedWeaponId,
    bool clearWeapon = false,
    String? equippedArmorId,
    bool clearArmor = false,
    String? equippedAccessoryId,
    bool clearAccessory = false,
  }) => Npc(
    id: id,
    name: name ?? this.name,
    origin: origin ?? this.origin,
    generation: generation ?? this.generation,
    age: age ?? this.age,
    alive: alive ?? this.alive,
    attributes: attributes ?? this.attributes,
    traits: traits ?? this.traits,
    hiddenTalent: hiddenTalent ?? this.hiddenTalent,
    talentDiscovered: talentDiscovered ?? this.talentDiscovered,
    profession: profession ?? this.profession,
    relationships: relationships ?? this.relationships,
    traumas: traumas ?? this.traumas,
    fame: fame ?? this.fame,
    history: history ?? this.history,
    partnerId: clearPartner ? null : partnerId ?? this.partnerId,
    pregnantSince: clearPregnancy ? null : pregnantSince ?? this.pregnantSince,
    childrenIds: childrenIds ?? this.childrenIds,
    parentAId: parentAId ?? this.parentAId,
    parentBId: parentBId ?? this.parentBId,
    daysSurvived: daysSurvived ?? this.daysSurvived,
    floorsCleared: floorsCleared ?? this.floorsCleared,
    killCount: killCount ?? this.killCount,
    arenaWins: arenaWins ?? this.arenaWins,
    arenaLosses: arenaLosses ?? this.arenaLosses,
    lastArenaChallengeDay: lastArenaChallengeDay ?? this.lastArenaChallengeDay,
    loyalty: loyalty ?? this.loyalty,
    groupId: clearGroup ? null : groupId ?? this.groupId,
    trainingSuggestionsReceived:
        trainingSuggestionsReceived ?? this.trainingSuggestionsReceived,
    trainingSuggestionsAccepted:
        trainingSuggestionsAccepted ?? this.trainingSuggestionsAccepted,
    isSuspicious: isSuspicious ?? this.isSuspicious,
    fatigue: fatigue ?? this.fatigue,
    consecutiveExpeditions:
        consecutiveExpeditions ?? this.consecutiveExpeditions,
    lastExpeditionDay: lastExpeditionDay ?? this.lastExpeditionDay,
    birthDay: birthDay ?? this.birthDay,
    psychologicalMarks: psychologicalMarks ?? this.psychologicalMarks,
    maternalNutrition: maternalNutrition ?? this.maternalNutrition,
    daysIdle: daysIdle ?? this.daysIdle,
    rank: rank ?? this.rank,
    wantsToLeave: wantsToLeave ?? this.wantsToLeave,
    wantsToLeaveDay: wantsToLeaveDay ?? this.wantsToLeaveDay,
    awarenessTriggered: awarenessTriggered ?? this.awarenessTriggered,
    stars: stars ?? this.stars,
    isPromoted: isPromoted ?? this.isPromoted,
    isFavorite: isFavorite ?? this.isFavorite,
    // ── Equipamentos [FASE 1] ──
    equippedWeaponId: clearWeapon
        ? null
        : equippedWeaponId ?? this.equippedWeaponId,
    equippedArmorId: clearArmor
        ? null
        : equippedArmorId ?? this.equippedArmorId,
    equippedAccessoryId: clearAccessory
        ? null
        : equippedAccessoryId ?? this.equippedAccessoryId,
  );

  // ── Fadiga ─────────────────────────────────

  FatigueState get fatigueState => FatigueStateHelpers.fromValue(fatigue);
  String get fatigueLabel => fatigueState.label;
  bool get isExhausted => fatigue >= 70;
  bool get isIncapacitated => fatigue >= 90;

  /// Poder de combate com penalidade de fadiga (sem gear)
  double get effectiveCombatPower =>
      attributes.combatPower * (1 - fatigueState.combatPowerPenalty);

  // ── Crescimento ────────────────────────────

  GrowthStage growthStage(int currentDay) {
    if (birthDay == 0) return GrowthStage.adult;
    final days = currentDay - birthDay;
    if (days <= 0) return GrowthStage.baby;
    if (days <= 2) return GrowthStage.child;
    if (days <= 4) return GrowthStage.adolescent;
    return GrowthStage.adult;
  }

  bool isVulnerable(int currentDay) {
    final s = growthStage(currentDay);
    return s == GrowthStage.baby || s == GrowthStage.child;
  }

  bool canGoOnExpedition(int currentDay) =>
      growthStage(currentDay) == GrowthStage.adult && !isIncapacitated;

  bool canTrain(int currentDay) {
    final s = growthStage(currentDay);
    return s == GrowthStage.adolescent || s == GrowthStage.adult;
  }

  // ── Condição Mental ────────────────────────

  MentalCondition get mentalCondition {
    final ms = attributes.mentalStability;
    if (ms >= 70) return MentalCondition.stable;
    if (ms >= 55) return MentalCondition.stressed;
    if (ms >= 40) return MentalCondition.depressed;
    if (ms >= 25) return MentalCondition.rebellious;
    if (ms >= 15) return MentalCondition.isolated;
    if (ms >= 5) return MentalCondition.berserk;
    return MentalCondition.broken;
  }

  // ── Traição ────────────────────────────────

  double get betrayalRisk {
    double risk = 0;
    if (origin.isDarkOrigin) risk += 25;
    if (traits.contains(PersonalityTrait.treacherous)) risk += 20;
    if (traits.contains(PersonalityTrait.ruthless)) risk += 10;
    if (traits.contains(PersonalityTrait.loyal)) risk -= 25;
    if (traits.contains(PersonalityTrait.compassionate)) risk -= 10;
    risk += ((50 - loyalty) * 0.3).clamp(0, 30);
    if (attributes.mentalStability < 30) risk += 15;
    if (attributes.mentalStability < 15) risk += 15;
    risk += (traumas.length * 2).clamp(0, 15);
    return risk.clamp(0, 100);
  }

  // ── Fama ───────────────────────────────────
  bool get isFamous => fame >= 80.0;
  bool get isLegendary => fame >= 300.0;

  void gainFame(double amount, {String? reason}) {
    final oldFame = fame;
    fame = (fame + amount).clamp(0.0, 100.0);
    if (fame >= 65.0 && oldFame < 65.0) {
      // Evento épico quando vira famoso
      // (o evento será adicionado no GameEngine)
    }
  }

  String get fameLabel {
    if (fame.abs() < 5) return 'Desconhecido';
    if (fame >= 1000) {
      return 'Divino'; //TODO implementar evento épico de divindade, NPC ganha imunidade a morte e sanidade, mas tem que cumprir tarefa impossível (ex: limpar 100 andares sem morrer)
    }
    if (fame >= 600) return 'Semideus';
    if (fame >= 500) return 'Lenda';
    if (fame >= 250) return 'Ícone';
    if (fame >= 80) return 'Herói';
    if (fame >= 40) return 'Reconhecido';
    if (fame >= 5) return 'Conhecido';
    if (fame <= -30) return 'Infame';
    if (fame <= -15) return 'Temido';
    if (fame <= -5) return 'Suspeito';
    return 'Desconhecido';
  }

  // ── Resumos ────────────────────────────────

  String get statusTag => alive ? '[VIVO]' : '[MORTO]';

  String get shortInfo =>
      '${origin.label} $name | G$generation | ${profession.label} | ${mentalCondition.label}';

  double get survivalScore =>
      attributes.endurance * 0.3 +
      attributes.strength * 0.2 +
      attributes.agility * 0.2 +
      attributes.intelligence * 0.15 +
      (attributes.mentalStability / 100 * 15) * 0.15;

  // ── Treinamento ────────────────────────────

  double trainingAcceptanceChance({required bool hasTrainingField}) {
    double chance = 0.5;
    chance += (loyalty - 50) * 0.005;

    for (final trait in traits) {
      switch (trait) {
        case PersonalityTrait.brave:
          chance += 0.15;
        case PersonalityTrait.coward:
          chance -= 0.15;
        case PersonalityTrait.pragmatic:
          chance += 0.10;
        case PersonalityTrait.impulsive:
          chance += 0.05;
        case PersonalityTrait.loner:
          chance -= 0.10;
        case PersonalityTrait.lazy:
          chance -= 0.15;
        default:
          break;
      }
    }

    if (hasTrainingField) chance += 0.15;
    chance -= fatigue * 0.005;

    if (isIncapacitated) return 0.05;
    if (isExhausted) chance -= 0.30;
    if (attributes.mentalStability < 40) chance -= 0.20;
    if (attributes.mentalStability < 20) chance -= 0.20;

    if (trainingSuggestionsReceived > 0) {
      final acceptRate =
          trainingSuggestionsAccepted / trainingSuggestionsReceived;
      chance = chance * 0.7 + acceptRate * 0.3;
    }

    return chance.clamp(0.05, 0.95);
  }

  // ── Recuperação de Fadiga ──────────────────

  double dailyFatigueRecovery({
    bool hasInfirmary = false,
    bool hasTemple = false,
    bool hasPartner = false,
    bool hasMadeExpeditionToday = false,
  }) {
    double recovery = 15 + (attributes.endurance / 15 * 10);
    if (hasInfirmary) recovery += 5;
    if (hasTemple) recovery += 3;
    if (hasPartner) recovery += 2;
    if (groupId != null) recovery += 1;
    if (hasMadeExpeditionToday) recovery *= 0.3;
    return recovery;
  }

  // ── Serialização ───────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'origin': origin.name,
    'generation': generation,
    'age': age,
    'alive': alive,
    'attributes': attributes.toJson(),
    'traits': traits.map((t) => t.name).toList(),
    'hiddenTalent': hiddenTalent.name,
    'talentDiscovered': talentDiscovered,
    'profession': profession.name,
    'relationships': relationships.map((r) => r.toJson()).toList(),
    'traumas': traumas,
    'fame': fame,
    'leaderOfGroupId': leaderOfGroupId,
    'history': history,
    'partnerId': partnerId,
    'pregnantSince': pregnantSince,
    'childrenIds': childrenIds,
    'parentAId': parentAId,
    'parentBId': parentBId,
    'daysSurvived': daysSurvived,
    'floorsCleared': floorsCleared,
    'killCount': killCount,
    'arenaWins': arenaWins,
    'arenaLosses': arenaLosses,
    'lastArenaChallengeDay': lastArenaChallengeDay,
    'loyalty': loyalty,
    'groupId': groupId,
    'trainingSuggestionsReceived': trainingSuggestionsReceived,
    'trainingSuggestionsAccepted': trainingSuggestionsAccepted,
    'isSuspicious': isSuspicious,
    'fatigue': fatigue,
    'consecutiveExpeditions': consecutiveExpeditions,
    'lastExpeditionDay': lastExpeditionDay,
    'birthDay': birthDay,
    'psychologicalMarks': psychologicalMarks,
    'maternalNutrition': maternalNutrition,
    'daysIdle': daysIdle,
    'rank': rank.name,
    'wantsToLeave': wantsToLeave,
    'wantsToLeaveDay': wantsToLeaveDay,
    'awarenessTriggered': awarenessTriggered,
    'stars': stars,
    'isPromoted': isPromoted,
    'isFavorite': isFavorite,
    // ── Equipamentos [FASE 1] ── saves antigos carregam como null (slot vazio) ✓
    'equippedWeaponId': equippedWeaponId,
    'equippedArmorId': equippedArmorId,
    'equippedAccessoryId': equippedAccessoryId,
    'lastBirthDay': lastBirthDay,
  };

  static Profession _migrateProfession(dynamic raw) {
    if (raw == null) return Profession.idle;
    const legacy = {
      'scout': Profession.scout,
      'trainer': Profession.trainer,
      'merchant': Profession.merchant,
      'scribe': Profession.scribe,
      'teacher': Profession.teacher,
      'doctor': Profession.doctor,
      'blacksmith': Profession.blacksmith,
      'builder': Profession.builder,
      'farmer': Profession.farmer,
      'chef': Profession.chef,
      'guard': Profession.guard,
      'explorer': Profession.explorer,
      'idle': Profession.idle,
    };
    return legacy[raw.toString()] ?? Profession.idle;
  }

  factory Npc.fromJson(Map<String, dynamic> json) {
    T parseEnum<T extends Enum>(List<T> values, Object? raw, T fallback) {
      final name = raw as String?;
      if (name == null) return fallback;
      return values.firstWhere((e) => e.name == name, orElse: () => fallback);
    }

    return Npc(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Desconhecido',
      origin: parseEnum(NpcOrigin.values, json['origin'], NpcOrigin.student),
      generation: json['generation'] as int? ?? 1,
      age: json['age'] as int? ?? 25,
      alive: json['alive'] as bool? ?? true,
      attributes: json['attributes'] != null
          ? NpcAttributes.fromJson(json['attributes'] as Map<String, dynamic>)
          : NpcAttributes(),
      traits:
          (json['traits'] as List<dynamic>?)
              ?.map(
                (t) => parseEnum(
                  PersonalityTrait.values,
                  t,
                  PersonalityTrait.pragmatic,
                ),
              )
              .toList() ??
          [],
      hiddenTalent: parseEnum(
        HiddenTalent.values,
        json['hiddenTalent'],
        HiddenTalent.none,
      ),
      talentDiscovered: json['talentDiscovered'] as bool? ?? false,
      profession: _migrateProfession(json['profession']),
      relationships:
          (json['relationships'] as List<dynamic>?)
              ?.map((r) => Relationship.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      traumas:
          (json['traumas'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      fame: (json['fame'] as num?)?.toDouble() ?? 0.0,
      leaderOfGroupId: json['leaderOfGroupId'] as String?,
      history:
          (json['history'] as List<dynamic>?)
              ?.map((h) => h.toString())
              .toList() ??
          [],
      partnerId: json['partnerId'] as String?,
      pregnantSince: json['pregnantSince'] as int?,
      childrenIds:
          (json['childrenIds'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      parentAId: json['parentAId'] as String?,
      parentBId: json['parentBId'] as String?,
      daysSurvived: json['daysSurvived'] as int? ?? 0,
      floorsCleared: json['floorsCleared'] as int? ?? 0,
      killCount: json['killCount'] as int? ?? 0,
      arenaWins: json['arenaWins'] as int? ?? 0,
      arenaLosses: json['arenaLosses'] as int? ?? 0,
      lastArenaChallengeDay: json['lastArenaChallengeDay'] as int? ?? 0,
      loyalty: (json['loyalty'] as num?)?.toDouble() ?? 50.0,
      groupId: json['groupId'] as String?,
      trainingSuggestionsReceived:
          json['trainingSuggestionsReceived'] as int? ?? 0,
      trainingSuggestionsAccepted:
          json['trainingSuggestionsAccepted'] as int? ?? 0,
      isSuspicious: json['isSuspicious'] as bool? ?? false,
      fatigue: (json['fatigue'] as num?)?.toDouble() ?? 0.0,
      consecutiveExpeditions: json['consecutiveExpeditions'] as int? ?? 0,
      lastExpeditionDay: json['lastExpeditionDay'] as int? ?? 0,
      birthDay: json['birthDay'] as int? ?? 0,
      psychologicalMarks:
          (json['psychologicalMarks'] as List<dynamic>?)
              ?.map((m) => m.toString())
              .toList() ??
          [],
      maternalNutrition:
          (json['maternalNutrition'] as num?)?.toDouble() ?? 100.0,
      daysIdle: json['daysIdle'] as int? ?? 0,
      rank: parseEnum(NpcRank.values, json['rank'], NpcRank.n),
      wantsToLeave: json['wantsToLeave'] as bool? ?? false,
      wantsToLeaveDay: json['wantsToLeaveDay'] as int? ?? 0,
      awarenessTriggered: json['awarenessTriggered'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      isPromoted: json['isPromoted'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      // ── Equipamentos [FASE 1] ── null = slot vazio (compatível com saves antigos) ✓
      equippedWeaponId: json['equippedWeaponId'] as String?,
      equippedArmorId: json['equippedArmorId'] as String?,
      equippedAccessoryId: json['equippedAccessoryId'] as String?,
      lastBirthDay: json['lastBirthDay'] as int? ?? 0,
    );
  }

  // ── Geração ────────────────────────────────

  static Npc generateRandom(
    String id,
    int generation,
    Random rng, {
    bool allowDarkOrigins = true,
  }) {
    final nameGen = NameGenerator(rng);
    final origin = _pickOrigin(rng, allowDarkOrigins);
    final base = origin.baseAttributes;
    final traits = _pickTraits(rng, origin);
    final rank = rollRank(rng);

    return Npc(
      id: id,
      name: nameGen.generateUniqueFullName(),
      origin: origin,
      generation: generation,
      age: 18 + rng.nextInt(30),
      rank: rank,
      attributes: NpcAttributes(
        strength: _vary(base.strength, rng, rank),
        agility: _vary(base.agility, rng, rank),
        intelligence: _vary(base.intelligence, rng, rank),
        endurance: _vary(base.endurance, rng, rank),
        charisma: _vary(base.charisma, rng, rank),
        mentalStability: _varyMental(base.mentalStability, rng),
        luck: _vary(base.luck, rng, rank),
      ),
      traits: traits,
      hiddenTalent: _rollTalent(rng, chance: rank.talentChance),
      loyalty: _initialLoyalty(rng, origin, traits),
      history: ['Invocado para a Torre no Dia 1'],
    );
  }

  static Npc generateChild(
    String id,
    Npc parentA,
    Npc parentB,
    Random rng,
    int birthDay, {
    double maternalNutrition = 100.0,
  }) {
    final generation =
        (parentA.generation > parentB.generation
            ? parentA.generation
            : parentB.generation) +
        1;

    final origin = generation == 2
        ? NpcOrigin.bornInTheAbyss
        : NpcOrigin.bornOfChaos;

    final nameGen = NameGenerator(rng);
    final a = parentA.attributes;
    final b = parentB.attributes;
    final nutritionPenalty = (100 - maternalNutrition) / 100;

    // ── 1. Herança de rank ──────────────────────────────────
    final higherRank = parentA.rank.index >= parentB.rank.index
        ? parentA.rank
        : parentB.rank;
    final rankRoll = rng.nextDouble();
    final NpcRank childRank = rankRoll < 0.60
        ? higherRank
        : rankRoll < 0.85
        ? parentA.rank
        : rollRank(rng);

    // ── 2. Herança de atributos (média ± 15%, capeado pelo rank) ──
    double physicalInherit(double va, double vb) {
      final avg = (va + vb) / 2;
      final variance = 0.85 + rng.nextDouble() * 0.30;
      return (avg * variance * (1 - nutritionPenalty * 0.4)).clamp(
        1.0,
        childRank.attributeCap,
      );
    }

    double mentalInherit(double va, double vb) {
      final avg = (va + vb) / 2;
      return (avg + avg * 0.15 * (rng.nextDouble() * 2 - 1)).clamp(1.0, 100.0);
    }

    // ── 3. Herança de HiddenTalent ──────────────────────────
    double talentChance = childRank.talentChance;
    if (parentA.hiddenTalent != HiddenTalent.none) talentChance += 0.15;
    if (parentB.hiddenTalent != HiddenTalent.none) talentChance += 0.15;
    talentChance = talentChance.clamp(0.0, 1.0);

    HiddenTalent talent = HiddenTalent.none;
    if (rng.nextDouble() < talentChance) {
      final parentTalents = [
        if (parentA.hiddenTalent != HiddenTalent.none) parentA.hiddenTalent,
        if (parentB.hiddenTalent != HiddenTalent.none) parentB.hiddenTalent,
      ];
      if (parentTalents.isNotEmpty && rng.nextDouble() < 0.70) {
        talent = parentTalents[rng.nextInt(parentTalents.length)];
      } else {
        talent = generation >= 3
            ? _rollEvolutionaryTalent(rng, parentA, parentB)
            : _rollTalent(rng, chance: 1.0);
      }
    }

    // ── 4. Herança de traits (40% chance de herdar 1 de cada pai) ──
    final inheritedTraits = <PersonalityTrait>[];
    for (final parent in [parentA, parentB]) {
      if (parent.traits.isNotEmpty && rng.nextDouble() < 0.40) {
        final trait = parent.traits[rng.nextInt(parent.traits.length)];
        if (!inheritedTraits.contains(trait)) inheritedTraits.add(trait);
      }
    }

    final childLoyalty =
        ((parentA.loyalty + parentB.loyalty) / 2 + (rng.nextDouble() * 20 - 10))
            .clamp(20.0, 80.0);

    return Npc(
      id: id,
      name: nameGen.generateChildName(
        parentAName: parentA.name,
        parentBName: parentB.name,
      ),
      origin: origin,
      generation: generation,
      age: 0,
      rank: childRank,
      attributes: NpcAttributes(
        strength: physicalInherit(a.strength, b.strength),
        agility: physicalInherit(a.agility, b.agility),
        intelligence: physicalInherit(a.intelligence, b.intelligence),
        endurance: physicalInherit(a.endurance, b.endurance),
        charisma: physicalInherit(a.charisma, b.charisma),
        mentalStability: mentalInherit(a.mentalStability, b.mentalStability),
        luck: physicalInherit(a.luck, b.luck),
      ),
      traits: inheritedTraits,
      hiddenTalent: talent,
      parentAId: parentA.id,
      parentBId: parentB.id,
      loyalty: childLoyalty,
      birthDay: birthDay,
      maternalNutrition: maternalNutrition,
      history: [
        'Nasceu na Torre — Filho(a) de ${parentA.name} e ${parentB.name}',
      ],
    );
  }

  /// Talento evolutivo para geração 3+ com combinações especiais
  static HiddenTalent _rollEvolutionaryTalent(
    Random rng,
    Npc parentA,
    Npc parentB,
  ) {
    const combinations = {
      'combatGenius+strategicMind': HiddenTalent.hollyWarrior,
      'healingTouch+herbalist': HiddenTalent.ironWill,
      'naturalLeader+runeReader': HiddenTalent.strategicMind,
    };

    final key = [parentA.hiddenTalent.name, parentB.hiddenTalent.name]..sort();
    final combo = '${key[0]}+${key[1]}';
    if (combinations.containsKey(combo)) return combinations[combo]!;

    return _rollTalent(rng, chance: 1.0);
  }

  // ── Helpers privados ───────────────────────

  static NpcOrigin _pickOrigin(Random rng, bool allowDark) {
    if (allowDark && rng.nextDouble() < 0.12) {
      const dark = [NpcOrigin.thief, NpcOrigin.assassin, NpcOrigin.fraudster];
      return dark[rng.nextInt(dark.length)];
    }
    final normal = NpcOrigin.values
        .where(
          (o) => !o.isDarkOrigin && !o.isNaturalBorn,
        ) // ← filtro adicionado
        .toList();
    return normal[rng.nextInt(normal.length)];
  }

  static List<PersonalityTrait> _pickTraits(Random rng, NpcOrigin origin) {
    final shuffled = [...PersonalityTrait.values]..shuffle(rng);
    final traits = shuffled.take(2 + rng.nextInt(2)).toList();
    if (origin.isDarkOrigin &&
        !traits.contains(PersonalityTrait.treacherous) &&
        rng.nextDouble() < 0.4) {
      traits[rng.nextInt(traits.length)] = PersonalityTrait.treacherous;
    }
    return traits;
  }

  static HiddenTalent _rollTalent(Random rng, {required double chance}) {
    if (rng.nextDouble() >= chance) return HiddenTalent.none;
    final options = HiddenTalent.values
        .where((t) => t != HiddenTalent.none)
        .toList();
    return options[rng.nextInt(options.length)];
  }

  static double _initialLoyalty(
    Random rng,
    NpcOrigin origin,
    List<PersonalityTrait> traits,
  ) {
    double l = 50 + (rng.nextDouble() * 20 - 10);
    if (origin.isDarkOrigin) l -= 15;
    if (traits.contains(PersonalityTrait.loyal)) l += 15;
    if (traits.contains(PersonalityTrait.treacherous)) l -= 15;
    return l.clamp(10, 90);
  }

  static double _vary(double base, Random rng, [NpcRank rank = NpcRank.n]) {
    // Bônus de rank sobre o preset de origem: N=+0%, R=+15%, SR=+35%, SSR=+60%
    final rankBonus = switch (rank) {
      NpcRank.n => 0.00,
      NpcRank.r => 0.15,
      NpcRank.sr => 0.35,
      NpcRank.ssr => 0.60,
    };
    final boosted = base * (1.0 + rankBonus);
    return (boosted + (rng.nextDouble() * 4 - 2)).clamp(1, rank.attributeCap);
  }

  static double _varyMental(double base, Random rng) =>
      (base + (rng.nextDouble() * 20 - 10)).clamp(20, 100);
}

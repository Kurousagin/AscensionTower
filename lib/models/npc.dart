import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:tower_ascension/models/name_generator.dart';
import 'equipment.dart'; // ← ADICIONADO: necessário para EquipmentSlot e Equipment

// ─────────────────────────────────────────────
// ATRIBUTOS
// Escala física: 1–15 | Sanidade: 0–100
// ─────────────────────────────────────────────

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
  }[this]!;
  bool get isNaturalBorn =>
      this == NpcOrigin.bornInTheAbyss || this == NpcOrigin.bornOfChaos;

  /// Origens com risco inerente de traição
  bool get isDarkOrigin =>
      this == NpcOrigin.thief ||
      this == NpcOrigin.assassin ||
      this == NpcOrigin.fraudster;

  /// Atributos base de cada origem
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
  };

  static NpcAttributes forOrigin(NpcOrigin origin) => _map[origin]!;
}

// ─────────────────────────────────────────────
// PROFISSÃO
// ─────────────────────────────────────────────

enum Profession {
  idle,
  explorer,
  guard,
  chef,
  doctor,
  teacher,
  blacksmith,
  merchant,
  scribe,
  farmer,
  builder,
  scout,
  trainer,
}

extension ProfessionExt on Profession {
  String get label => const {
    Profession.idle: 'Ocioso',
    Profession.explorer: 'Explorador',
    Profession.guard: 'Guarda',
    Profession.chef: 'Cozinheiro',
    Profession.doctor: 'Médico',
    Profession.teacher: 'Professor',
    Profession.blacksmith: 'Ferreiro',
    Profession.merchant: 'Mercador',
    Profession.scribe: 'Escriba',
    Profession.farmer: 'Fazendeiro',
    Profession.builder: 'Construtor',
    Profession.scout: 'Batedor',
    Profession.trainer: 'Instrutor',
  }[this]!;
}

// ─────────────────────────────────────────────
// TRAÇOS DE PERSONALIDADE
// ─────────────────────────────────────────────

enum PersonalityTrait {
  brave,
  coward,
  leader,
  loner,
  compassionate,
  ruthless,
  optimist,
  pessimist,
  analytical,
  impulsive,
  loyal,
  treacherous,
  calm,
  aggressive,
  creative,
  pragmatic,
  // v5.0 — Sistema de Expedição Hardcore
  cautious, // Menor chance de falha, menor teto de recompensa
  ambitious, // Maior chance de alta recompensa, maior risco
  lazy, // Reduz eficiência geral (–20% yield)
  individualist, // Reduz bônus de sinergia do grupo
  frugal, // Reduz consumo de recursos, mas também recompensas
  gluttonous, // Consome mais recursos, mas tem chance de encontrar itens raros
}

extension PersonalityTraitExt on PersonalityTrait {
  String get label => const {
    PersonalityTrait.brave: 'Corajoso',
    PersonalityTrait.coward: 'Covarde',
    PersonalityTrait.leader: 'Líder',
    PersonalityTrait.loner: 'Solitário',
    PersonalityTrait.compassionate: 'Compassivo',
    PersonalityTrait.ruthless: 'Implacável',
    PersonalityTrait.optimist: 'Otimista',
    PersonalityTrait.pessimist: 'Pessimista',
    PersonalityTrait.analytical: 'Analítico',
    PersonalityTrait.impulsive: 'Impulsivo',
    PersonalityTrait.loyal: 'Leal',
    PersonalityTrait.treacherous: 'Traiçoeiro',
    PersonalityTrait.calm: 'Calmo',
    PersonalityTrait.aggressive: 'Agressivo',
    PersonalityTrait.creative: 'Criativo',
    PersonalityTrait.pragmatic: 'Pragmático',
    PersonalityTrait.cautious: 'Cauteloso',
    PersonalityTrait.ambitious: 'Ambicioso',
    PersonalityTrait.lazy: 'Preguiçoso',
    PersonalityTrait.individualist: 'Individualista',
    PersonalityTrait.frugal: 'Frugal',
    PersonalityTrait.gluttonous: 'Glutão',
  }[this]!;

  /// Modificador de yield na expedição — alinhado com tabela do README v5.0
  double get expeditionYieldModifier =>
      const {
        PersonalityTrait.ambitious: 0.15,
        PersonalityTrait.brave: 0.05,
        PersonalityTrait.analytical: 0.06,
        PersonalityTrait.pragmatic: 0.04,
        PersonalityTrait.loyal: 0.05,
        PersonalityTrait.cautious: -0.12,
        PersonalityTrait.calm: -0.05,
        PersonalityTrait.lazy: -0.20,
        PersonalityTrait.coward: -0.10,
        PersonalityTrait.pessimist: -0.05,
        PersonalityTrait.individualist: -0.05,
        PersonalityTrait.frugal: -0.05,
        PersonalityTrait.gluttonous: 0.10,
      }[this] ??
      0.0;

  /// Modificador de risco de acidente na expedição
  double get expeditionAccidentRiskModifier =>
      const {
        PersonalityTrait.ambitious: 0.02,
        PersonalityTrait.cautious: -0.02,
        PersonalityTrait.gluttonous: 0.01,
      }[this] ??
      0.0;

  /// Modificador de sinergia de grupo
  double get synergyModifier =>
      const {
        PersonalityTrait.loyal: 0.05,
        PersonalityTrait.leader: 0.10,
        PersonalityTrait.loner: -0.08,
        PersonalityTrait.individualist: -0.10,
      }[this] ??
      0.0;
}

// ─────────────────────────────────────────────
// TALENTO OCULTO
// ─────────────────────────────────────────────

enum HiddenTalent {
  none,
  hollyWarrior,
  combatGenius,
  healingTouch,
  strategicMind,
  naturalLeader,
  beastWhisperer,
  forgemaster,
  herbalist,
  runeReader,
  shadowWalker,
  ironWill,
}

extension HiddenTalentExt on HiddenTalent {
  String get label => const {
    HiddenTalent.none: 'Nenhum',
    HiddenTalent.hollyWarrior: 'Guerreiro Sagrado',
    HiddenTalent.combatGenius: 'Gênio do Combate',
    HiddenTalent.healingTouch: 'Toque Curativo',
    HiddenTalent.strategicMind: 'Mente Estratégica',
    HiddenTalent.naturalLeader: 'Líder Natural',
    HiddenTalent.beastWhisperer: 'Sussurrador de Feras',
    HiddenTalent.forgemaster: 'Mestre da Forja',
    HiddenTalent.herbalist: 'Herbalista',
    HiddenTalent.runeReader: 'Leitor de Runas',
    HiddenTalent.shadowWalker: 'Caminhante das Sombras',
    HiddenTalent.ironWill: 'Vontade de Ferro',
  }[this]!;

  String get description => const {
    HiddenTalent.none: 'Sem talento oculto descoberto',
    HiddenTalent.hollyWarrior: '+4 poder de combate e +1.5 de carisma',
    HiddenTalent.combatGenius: '+2 poder de combate',
    HiddenTalent.healingTouch: 'Cura aliados após batalha',
    HiddenTalent.strategicMind: 'Reduz mortalidade do grupo em 15%',
    HiddenTalent.naturalLeader: '+20% moral do grupo, +15% sinergia',
    HiddenTalent.beastWhisperer: 'Chance de domar criaturas',
    HiddenTalent.forgemaster: 'Equipamentos 2x mais eficientes',
    HiddenTalent.herbalist: 'Produz medicamentos naturais',
    HiddenTalent.runeReader: 'Revela segredos dos andares',
    HiddenTalent.shadowWalker: 'Pode evadir qualquer combate',
    HiddenTalent.ironWill: 'Imune a perda de sanidade',
  }[this]!;

  /// Bônus de sinergia para grupos (usado no cálculo de expedição v5.0)
  double get groupSynergyBonus =>
      this == HiddenTalent.naturalLeader ? 0.15 : 0.0;
}

// ─────────────────────────────────────────────
// CONDIÇÃO MENTAL
// ─────────────────────────────────────────────

enum MentalCondition {
  stable,
  stressed,
  depressed,
  rebellious,
  isolated,
  berserk,
  broken,
}

extension MentalConditionExt on MentalCondition {
  String get label => const {
    MentalCondition.stable: 'Estável',
    MentalCondition.stressed: 'Estressado',
    MentalCondition.depressed: 'Deprimido',
    MentalCondition.rebellious: 'Rebelde',
    MentalCondition.isolated: 'Isolado',
    MentalCondition.berserk: 'Descontrolado',
    MentalCondition.broken: 'Quebrado',
  }[this]!;

  Color get color => const {
    MentalCondition.stable: Color(0xFF48BB78),
    MentalCondition.stressed: Color(0xFFECC94B),
    MentalCondition.depressed: Color(0xFF63B3ED),
    MentalCondition.rebellious: Color(0xFFED8936),
    MentalCondition.isolated: Color(0xFF718096),
    MentalCondition.berserk: Color(0xFFFC8181),
    MentalCondition.broken: Color(0xFF9B2335),
  }[this]!;

  /// Impacto diário na lealdade
  double get dailyLoyaltyImpact => const {
    MentalCondition.stable: 0.0,
    MentalCondition.stressed: -0.1,
    MentalCondition.depressed: -0.2,
    MentalCondition.rebellious: -0.3,
    MentalCondition.isolated: -0.1,
    MentalCondition.berserk: -0.5,
    MentalCondition.broken: -1.0,
  }[this]!;
}

// ─────────────────────────────────────────────
// FASE DE CRESCIMENTO
// ─────────────────────────────────────────────

enum GrowthStage { baby, child, adolescent, adult }

extension GrowthStageExt on GrowthStage {
  String get label => const {
    GrowthStage.baby: 'Bebê',
    GrowthStage.child: 'Criança',
    GrowthStage.adolescent: 'Adolescente',
    GrowthStage.adult: 'Adulto',
  }[this]!;

  String get icon => const {
    GrowthStage.baby: '👶',
    GrowthStage.child: '🧒',
    GrowthStage.adolescent: '🧑',
    GrowthStage.adult: '🛡️',
  }[this]!;
}

// ─────────────────────────────────────────────
// ESTADO DE FADIGA
// ─────────────────────────────────────────────

enum FatigueState {
  rested, // 0–29
  lightlyTired, // 30–49
  tired, // 50–69
  exhausted, // 70–89
  incapacitated, // 90–100
}

extension FatigueStateExt on FatigueState {
  String get label => const {
    FatigueState.rested: 'Descansado',
    FatigueState.lightlyTired: 'Levemente cansado',
    FatigueState.tired: 'Cansado',
    FatigueState.exhausted: 'Exausto',
    FatigueState.incapacitated: 'Incapacitado',
  }[this]!;

  /// Penalidade no poder de combate
  double get combatPowerPenalty => const {
    FatigueState.rested: 0.0,
    FatigueState.lightlyTired: 0.0,
    FatigueState.tired: 0.15,
    FatigueState.exhausted: 0.35,
    FatigueState.incapacitated: 0.60,
  }[this]!;

  /// Penalidade diária de sanidade
  double get dailySanityPenalty => const {
    FatigueState.rested: 0.0,
    FatigueState.lightlyTired: 0.0,
    FatigueState.tired: 0.0,
    FatigueState.exhausted: 3.0,
    FatigueState.incapacitated: 5.0,
  }[this]!;

  /// Penalidade diária de lealdade
  double get dailyLoyaltyPenalty => const {
    FatigueState.rested: 0.0,
    FatigueState.lightlyTired: 0.0,
    FatigueState.tired: 0.0,
    FatigueState.exhausted: 0.5,
    FatigueState.incapacitated: 1.0,
  }[this]!;
}

extension FatigueStateHelpers on FatigueState {
  static FatigueState fromValue(double fatigue) {
    if (fatigue >= 90) return FatigueState.incapacitated;
    if (fatigue >= 70) return FatigueState.exhausted;
    if (fatigue >= 50) return FatigueState.tired;
    if (fatigue >= 30) return FatigueState.lightlyTired;
    return FatigueState.rested;
  }
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
    // ── Equipamentos [FASE 1] ──
    this.equippedWeaponId,
    this.equippedArmorId,
    this.equippedAccessoryId,
  }) : traits = traits ?? const [],
       relationships = relationships ?? <Relationship>[],
       traumas = traumas ?? const [],
       history = history ?? const [],
       childrenIds = childrenIds ?? const [],
       psychologicalMarks = psychologicalMarks ?? const [];

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
    // ── Equipamentos [FASE 1] ── saves antigos carregam como null (slot vazio) ✓
    'equippedWeaponId': equippedWeaponId,
    'equippedArmorId': equippedArmorId,
    'equippedAccessoryId': equippedAccessoryId,
    'lastBirthDay': lastBirthDay,
  };

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
      profession: parseEnum(
        Profession.values,
        json['profession'],
        Profession.idle,
      ),
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

    return Npc(
      id: id,
      name: nameGen.generateUniqueFullName(),
      origin: origin,
      generation: generation,
      age: 18 + rng.nextInt(30),
      attributes: NpcAttributes(
        strength: _vary(base.strength, rng),
        agility: _vary(base.agility, rng),
        intelligence: _vary(base.intelligence, rng),
        endurance: _vary(base.endurance, rng),
        charisma: _vary(base.charisma, rng),
        mentalStability: _varyMental(base.mentalStability, rng),
        luck: _vary(base.luck, rng),
      ),
      traits: traits,
      hiddenTalent: _rollTalent(rng, chance: 0.15),
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
    // Determina origem baseada na geração dos pais
    final generation =
        (parentA.generation > parentB.generation
            ? parentA.generation
            : parentB.generation) +
        1;

    // G2 = filho de invocados → Nascido no Abismo
    // G3+ = filho de nascidos na Torre → Nascido do Caos
    final origin = generation == 2
        ? NpcOrigin.bornInTheAbyss
        : NpcOrigin.bornOfChaos;

    final nameGen = NameGenerator(rng);
    final a = parentA.attributes;
    final b = parentB.attributes;
    final nutritionPenalty = (100 - maternalNutrition) / 100;

    double physicalInherit(double va, double vb) =>
        (_inherit(va, vb, rng) * (1 - nutritionPenalty * 0.4)).clamp(1, 20);

    HiddenTalent talent = HiddenTalent.none;
    if (rng.nextDouble() < 0.05) {
      talent = _rollTalent(rng, chance: 1.0);
    } else if (rng.nextDouble() < 0.15) {
      talent = rng.nextBool() ? parentA.hiddenTalent : parentB.hiddenTalent;
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
      generation: max(parentA.generation, parentB.generation) + 1,
      age: 0,
      attributes: NpcAttributes(
        strength: physicalInherit(a.strength, b.strength),
        agility: physicalInherit(a.agility, b.agility),
        intelligence: _inherit(a.intelligence, b.intelligence, rng),
        endurance: physicalInherit(a.endurance, b.endurance),
        charisma: _inherit(a.charisma, b.charisma, rng),
        mentalStability: _inherit(a.mentalStability, b.mentalStability, rng),
        luck: _inherit(a.luck, b.luck, rng),
      ),
      traits: const [],
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

  static double _vary(double base, Random rng) =>
      (base + (rng.nextDouble() * 4 - 2)).clamp(1, 15);

  static double _varyMental(double base, Random rng) =>
      (base + (rng.nextDouble() * 20 - 10)).clamp(20, 100);

  static double _inherit(double va, double vb, Random rng) {
    final avg = (va + vb) / 2;
    return (avg + avg * 0.15 * (rng.nextDouble() * 2 - 1)).clamp(1, 20);
  }
}

// lib/models/npc_enums.dart
//
// Todos os enums e extensões relacionados ao NPC.
// Extraído de npc.dart para manter responsabilidade única.

import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// RANK / RARIDADE DE NPC (N → SSR)
// ─────────────────────────────────────────────

enum NpcRank { n, r, sr, ssr }

extension NpcRankExt on NpcRank {
  String get label => const {
    NpcRank.n: 'N',
    NpcRank.r: 'R',
    NpcRank.sr: 'SR',
    NpcRank.ssr: 'SSR',
  }[this]!;

  String get colorHex => const {
    NpcRank.n: '718096',
    NpcRank.r: '48BB78',
    NpcRank.sr: '00B4D8',
    NpcRank.ssr: 'ECC94B',
  }[this]!;

  /// Teto de atributos físicos para NPCs desta raridade
  double get attributeCap => const {
    NpcRank.n: 12.0,
    NpcRank.r: 15.0,
    NpcRank.sr: 18.0,
    NpcRank.ssr: 20.0,
  }[this]!;

  /// Chance de ter HiddenTalent ao nascer
  double get talentChance => const {
    NpcRank.n: 0.05,
    NpcRank.r: 0.20,
    NpcRank.sr: 0.50,
    NpcRank.ssr: 1.00,
  }[this]!;

  /// Expectativa de vida base (independente da fama)
  int get baseLifeExpectancy => const {
    NpcRank.n: 80,
    NpcRank.r: 90,
    NpcRank.sr: 110,
    NpcRank.ssr: 120,
  }[this]!;
}

/// Sorteia rank com pesos: N 74% · R 20% · SR 5% · SSR 1%
NpcRank rollRank(Random rng) {
  final roll = rng.nextDouble();
  if (roll < 0.01) return NpcRank.ssr;
  if (roll < 0.06) return NpcRank.sr;
  if (roll < 0.26) return NpcRank.r;
  return NpcRank.n;
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
// ─────────────────────────────────────────────
// PROFISSÃO
// ─────────────────────────────────────────────

enum Profession {
  idle,
  // Alimentação
  farmer,
  chef,
  // Coleta de recursos
  lumberjack, // gera woodLog
  quarryman, // gera stoneRaw
  miner, // bônus ironOre em expedições
  // Manufatura
  carpenter, // woodLog → lumber
  mason, // stoneRaw → stoneBrick
  blacksmith, // ironOre → ironBar
  // Construção / Suporte
  builder, // acelera construção
  doctor, // cura NPCs, reduz mortalidade
  teacher, // gera knowledge ativo
  scribe, // knowledge + eventos
  merchant, // morale + trade
  trainer, // acelera atributos
  // Combate / Exploração
  guard,
  explorer,
  scout,
}

extension ProfessionExt on Profession {
  String get label => const {
    Profession.idle: 'Ocioso',
    Profession.farmer: 'Fazendeiro',
    Profession.chef: 'Cozinheiro',
    Profession.lumberjack: 'Lenhador',
    Profession.quarryman: 'Pedreiro',
    Profession.miner: 'Mineiro',
    Profession.carpenter: 'Carpinteiro',
    Profession.mason: 'Canteiro',
    Profession.blacksmith: 'Ferreiro',
    Profession.builder: 'Construtor',
    Profession.doctor: 'Médico',
    Profession.teacher: 'Professor',
    Profession.scribe: 'Escriba',
    Profession.merchant: 'Mercador',
    Profession.trainer: 'Instrutor',
    Profession.guard: 'Guarda',
    Profession.explorer: 'Explorador',
    Profession.scout: 'Batedor',
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

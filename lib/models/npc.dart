import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// ATRIBUTOS
// ─────────────────────────────────────────────

class NpcAttributes {
  double strength;
  double agility;
  double intelligence;
  double endurance;
  double charisma;
  double mentalStability;
  double luck;

  NpcAttributes({
    this.strength = 5.0,
    this.agility = 5.0,
    this.intelligence = 5.0,
    this.endurance = 5.0,
    this.charisma = 5.0,
    this.mentalStability = 70.0,
    this.luck = 5.0,
  });

  /// Média dos atributos principais (excl. mentalStability e luck)
  double get average =>
      (strength + agility + intelligence + endurance + charisma) / 5.0;

  /// Poder de combate ponderado
  double get combatPower =>
      strength * 0.3 +
      agility * 0.25 +
      endurance * 0.25 +
      intelligence * 0.2;

  NpcAttributes clone() => NpcAttributes(
        strength: strength,
        agility: agility,
        intelligence: intelligence,
        endurance: endurance,
        charisma: charisma,
        mentalStability: mentalStability,
        luck: luck,
      );

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'agility': agility,
        'intelligence': intelligence,
        'endurance': endurance,
        'charisma': charisma,
        'mentalStability': mentalStability,
        'luck': luck,
      };

  factory NpcAttributes.fromJson(Map<String, dynamic> json) => NpcAttributes(
        strength: (json['strength'] as num?)?.toDouble() ?? 5.0,
        agility: (json['agility'] as num?)?.toDouble() ?? 5.0,
        intelligence: (json['intelligence'] as num?)?.toDouble() ?? 5.0,
        endurance: (json['endurance'] as num?)?.toDouble() ?? 5.0,
        charisma: (json['charisma'] as num?)?.toDouble() ?? 5.0,
        mentalStability:
            (json['mentalStability'] as num?)?.toDouble() ?? 70.0,
        luck: (json['luck'] as num?)?.toDouble() ?? 5.0,
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
  // Origens obscuras — risco de traição elevado
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
        NpcOrigin.businessOwner: 'Empresario',
        NpcOrigin.doctor: 'Medico',
        NpcOrigin.teacher: 'Professor',
        NpcOrigin.artist: 'Artista',
        NpcOrigin.mechanic: 'Mecanico',
        NpcOrigin.farmer: 'Fazendeiro',
        NpcOrigin.musician: 'Musico',
        NpcOrigin.scientist: 'Cientista',
        NpcOrigin.firefighter: 'Bombeiro',
        NpcOrigin.nurse: 'Enfermeiro(a)',
        NpcOrigin.thief: 'Ladrao',
        NpcOrigin.assassin: 'Assassino',
        NpcOrigin.fraudster: 'Estelionatario',
      }[this]!;

  /// Origens com risco inerente de traição
  bool get isDarkOrigin =>
      this == NpcOrigin.thief ||
      this == NpcOrigin.assassin ||
      this == NpcOrigin.fraudster;

  /// Atributos base de cada origem
  NpcAttributes get baseAttributes =>  {
        NpcOrigin.student: _AttrPresets.student,
        NpcOrigin.chef: _AttrPresets.chef,
        NpcOrigin.soldier: _AttrPresets.soldier,
        NpcOrigin.programmer: _AttrPresets.programmer,
        NpcOrigin.athlete: _AttrPresets.athlete,
        NpcOrigin.businessOwner: _AttrPresets.businessOwner,
        NpcOrigin.doctor: _AttrPresets.doctor,
        NpcOrigin.teacher: _AttrPresets.teacher,
        NpcOrigin.artist: _AttrPresets.artist,
        NpcOrigin.mechanic: _AttrPresets.mechanic,
        NpcOrigin.farmer: _AttrPresets.farmer,
        NpcOrigin.musician: _AttrPresets.musician,
        NpcOrigin.scientist: _AttrPresets.scientist,
        NpcOrigin.firefighter: _AttrPresets.firefighter,
        NpcOrigin.nurse: _AttrPresets.nurse,
        NpcOrigin.thief: _AttrPresets.thief,
        NpcOrigin.assassin: _AttrPresets.assassin,
        NpcOrigin.fraudster: _AttrPresets.fraudster,
      }[this]!;
}

/// Presets de atributos separados para manter NpcOrigin limpo
abstract class _AttrPresets {
  static final student = NpcAttributes(
      strength: 3, agility: 4, intelligence: 8, endurance: 3,
      charisma: 5, mentalStability: 60, luck: 6);
  static final chef = NpcAttributes(
      strength: 4, agility: 6, intelligence: 6, endurance: 5,
      charisma: 7, mentalStability: 65, luck: 5);
  static final soldier = NpcAttributes(
      strength: 9, agility: 7, intelligence: 5, endurance: 9,
      charisma: 4, mentalStability: 75, luck: 4);
  static final programmer = NpcAttributes(
      strength: 2, agility: 3, intelligence: 9, endurance: 3,
      charisma: 4, mentalStability: 55, luck: 5);
  static final athlete = NpcAttributes(
      strength: 8, agility: 9, intelligence: 4, endurance: 8,
      charisma: 6, mentalStability: 70, luck: 5);
  static final businessOwner = NpcAttributes(
      strength: 4, agility: 4, intelligence: 7, endurance: 5,
      charisma: 9, mentalStability: 68, luck: 7);
  static final doctor = NpcAttributes(
      strength: 3, agility: 5, intelligence: 9, endurance: 5,
      charisma: 6, mentalStability: 72, luck: 5);
  static final teacher = NpcAttributes(
      strength: 3, agility: 4, intelligence: 8, endurance: 4,
      charisma: 8, mentalStability: 70, luck: 5);
  static final artist = NpcAttributes(
      strength: 3, agility: 5, intelligence: 7, endurance: 3,
      charisma: 8, mentalStability: 50, luck: 7);
  static final mechanic = NpcAttributes(
      strength: 7, agility: 6, intelligence: 6, endurance: 7,
      charisma: 4, mentalStability: 65, luck: 4);
  static final farmer = NpcAttributes(
      strength: 7, agility: 5, intelligence: 4, endurance: 8,
      charisma: 5, mentalStability: 75, luck: 5);
  static final musician = NpcAttributes(
      strength: 3, agility: 5, intelligence: 6, endurance: 3,
      charisma: 9, mentalStability: 55, luck: 6);
  static final scientist = NpcAttributes(
      strength: 2, agility: 3, intelligence: 10, endurance: 4,
      charisma: 4, mentalStability: 60, luck: 4);
  static final firefighter = NpcAttributes(
      strength: 8, agility: 7, intelligence: 5, endurance: 9,
      charisma: 6, mentalStability: 78, luck: 5);
  static final nurse = NpcAttributes(
      strength: 4, agility: 5, intelligence: 7, endurance: 6,
      charisma: 7, mentalStability: 70, luck: 5);
  static final thief = NpcAttributes(
      strength: 4, agility: 9, intelligence: 7, endurance: 5,
      charisma: 6, mentalStability: 55, luck: 8);
  static final assassin = NpcAttributes(
      strength: 8, agility: 10, intelligence: 6, endurance: 7,
      charisma: 3, mentalStability: 45, luck: 5);
  static final fraudster = NpcAttributes(
      strength: 3, agility: 5, intelligence: 9, endurance: 3,
      charisma: 10, mentalStability: 50, luck: 9);
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
        Profession.doctor: 'Medico',
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
  cautious,      // Menor chance de falha, menor teto de recompensa
  ambitious,     // Maior chance de alta recompensa, maior risco
  lazy,          // Reduz eficiência geral
  individualist, // Reduz bônus de sinergia do grupo
}

extension PersonalityTraitExt on PersonalityTrait {
  String get label => const {
        PersonalityTrait.brave: 'Corajoso',
        PersonalityTrait.coward: 'Covarde',
        PersonalityTrait.leader: 'Lider',
        PersonalityTrait.loner: 'Solitario',
        PersonalityTrait.compassionate: 'Compassivo',
        PersonalityTrait.ruthless: 'Implacavel',
        PersonalityTrait.optimist: 'Otimista',
        PersonalityTrait.pessimist: 'Pessimista',
        PersonalityTrait.analytical: 'Analitico',
        PersonalityTrait.impulsive: 'Impulsivo',
        PersonalityTrait.loyal: 'Leal',
        PersonalityTrait.treacherous: 'Traicoeiro',
        PersonalityTrait.calm: 'Calmo',
        PersonalityTrait.aggressive: 'Agressivo',
        PersonalityTrait.creative: 'Criativo',
        PersonalityTrait.pragmatic: 'Pragmatico',
        PersonalityTrait.cautious: 'Cauteloso',
        PersonalityTrait.ambitious: 'Ambicioso',
        PersonalityTrait.lazy: 'Preguicoso',
        PersonalityTrait.individualist: 'Individualista',
      }[this]!;
}

// ─────────────────────────────────────────────
// TALENTO OCULTO
// ─────────────────────────────────────────────

enum HiddenTalent {
  none,
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
        HiddenTalent.combatGenius: 'Genio do Combate',
        HiddenTalent.healingTouch: 'Toque Curativo',
        HiddenTalent.strategicMind: 'Mente Estrategica',
        HiddenTalent.naturalLeader: 'Lider Natural',
        HiddenTalent.beastWhisperer: 'Sussurrador de Feras',
        HiddenTalent.forgemaster: 'Mestre da Forja',
        HiddenTalent.herbalist: 'Herbalista',
        HiddenTalent.runeReader: 'Leitor de Runas',
        HiddenTalent.shadowWalker: 'Caminhante das Sombras',
        HiddenTalent.ironWill: 'Vontade de Ferro',
      }[this]!;

  String get description => const {
        HiddenTalent.none: 'Sem talento oculto descoberto',
        HiddenTalent.combatGenius: '+50% poder de combate',
        HiddenTalent.healingTouch: 'Cura aliados apos batalha',
        HiddenTalent.strategicMind: 'Reduz mortalidade do grupo em 15%',
        HiddenTalent.naturalLeader: '+20% moral do grupo',
        HiddenTalent.beastWhisperer: 'Chance de domar criaturas',
        HiddenTalent.forgemaster: 'Equipamentos 2x mais eficientes',
        HiddenTalent.herbalist: 'Produz medicamentos naturais',
        HiddenTalent.runeReader: 'Revela segredos dos andares',
        HiddenTalent.shadowWalker: 'Pode evadir qualquer combate',
        HiddenTalent.ironWill: 'Imune a perda de sanidade',
      }[this]!;
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
        MentalCondition.stable: 'Estavel',
        MentalCondition.stressed: 'Estressado',
        MentalCondition.depressed: 'Deprimido',
        MentalCondition.rebellious: 'Rebelde',
        MentalCondition.isolated: 'Isolado',
        MentalCondition.berserk: 'Descontrolado',
        MentalCondition.broken: 'Quebrado',
      }[this]!;

  String get color => const {
        MentalCondition.stable: 'green',
        MentalCondition.stressed: 'yellow',
        MentalCondition.depressed: 'blue',
        MentalCondition.rebellious: 'orange',
        MentalCondition.isolated: 'grey',
        MentalCondition.berserk: 'red',
        MentalCondition.broken: 'darkred',
      }[this]!;
}

// ─────────────────────────────────────────────
// FASE DE CRESCIMENTO
// ─────────────────────────────────────────────

enum GrowthStage { baby, child, adolescent, adult }

extension GrowthStageExt on GrowthStage {
  String get label => const {
        GrowthStage.baby: 'Bebe',
        GrowthStage.child: 'Crianca',
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
// RELACIONAMENTO
// ─────────────────────────────────────────────

class Relationship {
  final String targetId;
  String type;
  double affinity;

  Relationship({
    required this.targetId,
    this.type = 'neutral',
    this.affinity = 0.0,
  });

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

/// Integração com https://gerador-nomes.wolan.net
/// Fallback automático para lista local caso a API esteja indisponível.
class NpcNameGenerator {
  static const _apiUrl = 'https://gerador-nomes.wolan.net/nome/aleatorio';

  // Fallback local com nomes diversificados
  static const _fallbackFirstNames = [
    'Akira', 'Elena', 'Marcus', 'Yuki', 'Sofia', 'Ravi', 'Luna', 'Kai',
    'Aria', 'Davi', 'Mia', 'Chen', 'Nora', 'Leo', 'Zara', 'Omar', 'Iris',
    'Hugo', 'Maya', 'Erik', 'Lina', 'Atlas', 'Vera', 'Theo', 'Jade', 'Ren',
    'Cleo', 'Ivan', 'Rosa', 'Finn', 'Abel', 'Diana', 'Samir', 'Hana',
    'Viktor', 'Mei', 'Dante', 'Suri', 'Boris', 'Kira', 'Rafael', 'Anya',
  ];
  static const _fallbackLastNames = [
    'Nakamura', 'Santos', 'Chen', 'Mueller', 'Kim', 'Silva', 'Park',
    'Okafor', 'Johansson', 'Patel', 'Volkov', 'Costa', 'Tanaka', 'Rivera',
    'Zhang', 'Dubois', 'Petrov', 'Hayashi', 'Torres', 'Andersen', 'Ferreira',
    'Nguyen', 'Bergman', 'Rossi', 'Yamamoto',
  ];

  /// Tenta buscar nome pela API; em caso de erro usa fallback local.
  static Future<String> generate({Random? rng}) async {
    try {
      final response =
          await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        // A API retorna JSON: { "nome": "Firstname Lastname" }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final name = data['nome'] as String?;
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    } catch (_) {
      // Sem conexão ou timeout — segue para fallback
    }
    return _fallbackName(rng ?? Random());
  }

  /// Gera nome localmente (síncrono) como fallback ou uso offline.
  static String generateSync(Random rng) => _fallbackName(rng);

  static String _fallbackName(Random rng) {
    final first = _fallbackFirstNames[rng.nextInt(_fallbackFirstNames.length)];
    final last = _fallbackLastNames[rng.nextInt(_fallbackLastNames.length)];
    return '$first $last';
  }
}

// ─────────────────────────────────────────────
// NPC
// ─────────────────────────────────────────────

class Npc {
  final String id;
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
  double fame; // positivo = herói, negativo = infame
  List<String> history;
  MentalCondition mentalCondition;
  String? partnerId;
  int? pregnantSince; // dia em que ficou grávida (null = não grávida)
  List<String> childrenIds;
  String? parentAId;
  String? parentBId;
  int daysSurvived;
  int floorsCleared;
  int killCount;
  // Sistema social/político
  double loyalty;       // 0–100
  double betrayalRisk;  // 0–100
  String? groupId;
  int trainingSuggestionsReceived;
  int trainingSuggestionsAccepted;
  bool isSuspicious;
  // Sistema de Fadiga
  double fatigue;              // 0=descansado, 100=incapacitado
  int consecutiveExpeditions;
  int lastExpeditionDay;
  // Sistema de Crescimento Brutal
  int birthDay;                // 0 = adulto invocado
  List<String> psychologicalMarks;
  double maternalNutrition;    // 0–100: qualidade nutricional na gestação
  // Sistema de Ociosidade
  int daysIdle;                // Contador de dias consecutivos ocioso

  Npc({
    required this.id,
    required this.name,
    required this.origin,
    this.generation = 1,
    this.age = 25,
    this.alive = true,
    NpcAttributes? attributes,
    List<PersonalityTrait>? traits,
    this.hiddenTalent = HiddenTalent.none,
    this.talentDiscovered = false,
    this.profession = Profession.idle,
    List<Relationship>? relationships,
    List<String>? traumas,
    this.fame = 0.0,
    List<String>? history,
    this.mentalCondition = MentalCondition.stable,
    this.partnerId,
    this.pregnantSince,
    List<String>? childrenIds,
    this.parentAId,
    this.parentBId,
    this.daysSurvived = 0,
    this.floorsCleared = 0,
    this.killCount = 0,
    this.loyalty = 50.0,
    this.betrayalRisk = 0.0,
    this.groupId,
    this.trainingSuggestionsReceived = 0,
    this.trainingSuggestionsAccepted = 0,
    this.isSuspicious = false,
    this.fatigue = 0.0,
    this.consecutiveExpeditions = 0,
    this.lastExpeditionDay = 0,
    this.birthDay = 0,
    List<String>? psychologicalMarks,
    this.maternalNutrition = 100.0,
    this.daysIdle = 0,
  })  : attributes = attributes ?? origin.baseAttributes,
        traits = traits ?? [],
        relationships = relationships ?? [],
        traumas = traumas ?? [],
        history = history ?? [],
        childrenIds = childrenIds ?? [],
        psychologicalMarks = psychologicalMarks ?? [];

  // ── Fadiga ─────────────────────────────────

  String get fatigueLabel {
    if (fatigue >= 90) return 'Incapacitado';
    if (fatigue >= 70) return 'Exausto';
    if (fatigue >= 50) return 'Cansado';
    if (fatigue >= 30) return 'Levemente cansado';
    return 'Descansado';
  }

  bool get isExhausted => fatigue >= 70;
  bool get isIncapacitated => fatigue >= 90;

  // ── Crescimento ────────────────────────────

  /// Fase de crescimento baseada em dias de vida (birthDay=0 = adulto invocado)
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
      growthStage(currentDay) == GrowthStage.adult;

  bool canTrain(int currentDay) {
    final s = growthStage(currentDay);
    return s == GrowthStage.adolescent || s == GrowthStage.adult;
  }

  // ── Condição Mental ────────────────────────

  MentalCondition get calculatedMentalCondition {
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

  double get calculatedBetrayalRisk {
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

  String get fameLabel {
    if (fame.abs() < 5) return 'Desconhecido';
    if (fame >= 50) return 'Lenda';
    if (fame >= 30) return 'Heroi';
    if (fame >= 15) return 'Reconhecido';
    if (fame >= 5) return 'Conhecido';
    if (fame <= -30) return 'Infame';
    if (fame <= -15) return 'Temido';
    if (fame <= -5) return 'Suspeito';
    return 'Desconhecido';
  }

  // ── Resumos ────────────────────────────────

  String get statusTag => alive ? '[VIVO]' : '[MORTO]';
  String get shortInfo =>
      '${origin.label} $name | G$generation | ${profession.label} | ${calculatedMentalCondition.label}';

  double get survivalScore =>
      attributes.endurance * 0.3 +
      attributes.strength * 0.2 +
      attributes.agility * 0.2 +
      attributes.intelligence * 0.15 +
      attributes.mentalStability * 0.15 / 10;

  // ── Treinamento ────────────────────────────

  /// Probabilidade (0.0–1.0) de aceitar sugestão de treinamento
  double trainingAcceptanceChance({required bool hasTrainingField}) {
    double chance = 0.5;
    chance += (loyalty - 50) * 0.005;
    if (traits.contains(PersonalityTrait.brave)) chance += 0.15;
    if (traits.contains(PersonalityTrait.coward)) chance -= 0.15;
    if (traits.contains(PersonalityTrait.pragmatic)) chance += 0.10;
    if (traits.contains(PersonalityTrait.impulsive)) chance += 0.05;
    if (traits.contains(PersonalityTrait.loner)) chance -= 0.10;
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

  // ── Serialização ───────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'origin': origin.index,
        'generation': generation,
        'age': age,
        'alive': alive,
        'attributes': attributes.toJson(),
        'traits': traits.map((t) => t.index).toList(),
        'hiddenTalent': hiddenTalent.index,
        'talentDiscovered': talentDiscovered,
        'profession': profession.index,
        'relationships': relationships.map((r) => r.toJson()).toList(),
        'traumas': traumas,
        'fame': fame,
        'history': history,
        'mentalCondition': mentalCondition.index,
        'partnerId': partnerId,
        'pregnantSince': pregnantSince,
        'childrenIds': childrenIds,
        'parentAId': parentAId,
        'parentBId': parentBId,
        'daysSurvived': daysSurvived,
        'floorsCleared': floorsCleared,
        'killCount': killCount,
        'loyalty': loyalty,
        'betrayalRisk': betrayalRisk,
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
      };

  factory Npc.fromJson(Map<String, dynamic> json) => Npc(
        id: json['id'] as String? ?? 'unknown',
        name: json['name'] as String? ?? 'Desconhecido',
        origin: NpcOrigin.values[
            (json['origin'] as int? ?? 0).clamp(0, NpcOrigin.values.length - 1)],
        generation: json['generation'] as int? ?? 1,
        age: json['age'] as int? ?? 25,
        alive: json['alive'] as bool? ?? true,
        attributes: json['attributes'] != null
            ? NpcAttributes.fromJson(json['attributes'] as Map<String, dynamic>)
            : null,
        traits: (json['traits'] as List<dynamic>?)
                ?.map((t) => PersonalityTrait.values[
                    (t as int).clamp(0, PersonalityTrait.values.length - 1)])
                .toList() ??
            [],
        hiddenTalent: HiddenTalent.values[(json['hiddenTalent'] as int? ?? 0)
            .clamp(0, HiddenTalent.values.length - 1)],
        talentDiscovered: json['talentDiscovered'] as bool? ?? false,
        profession: Profession.values[(json['profession'] as int? ?? 0)
            .clamp(0, Profession.values.length - 1)],
        relationships: (json['relationships'] as List<dynamic>?)
                ?.map((r) => Relationship.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        traumas: (json['traumas'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            [],
        fame: (json['fame'] as num?)?.toDouble() ?? 0.0,
        history: (json['history'] as List<dynamic>?)
                ?.map((h) => h.toString())
                .toList() ??
            [],
        mentalCondition: MentalCondition.values[(json['mentalCondition'] as int? ?? 0)
            .clamp(0, MentalCondition.values.length - 1)],
        partnerId: json['partnerId'] as String?,
        pregnantSince: json['pregnantSince'] as int?,
        childrenIds: (json['childrenIds'] as List<dynamic>?)
                ?.map((c) => c.toString())
                .toList() ??
            [],
        parentAId: json['parentAId'] as String?,
        parentBId: json['parentBId'] as String?,
        daysSurvived: json['daysSurvived'] as int? ?? 0,
        floorsCleared: json['floorsCleared'] as int? ?? 0,
        killCount: json['killCount'] as int? ?? 0,
        loyalty: (json['loyalty'] as num?)?.toDouble() ?? 50.0,
        betrayalRisk: (json['betrayalRisk'] as num?)?.toDouble() ?? 0.0,
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
        psychologicalMarks: (json['psychologicalMarks'] as List<dynamic>?)
                ?.map((m) => m.toString())
                .toList() ??
            [],
        maternalNutrition:
            (json['maternalNutrition'] as num?)?.toDouble() ?? 100.0,
        daysIdle: json['daysIdle'] as int? ?? 0,
      );

  // ── Geração ────────────────────────────────

  /// Gera um NPC aleatório. Use [NpcNameGenerator.generate()] para nome via API.
  /// Este método usa fallback síncrono; para nome assíncrono, chame após criar:
  /// `npc.name = await NpcNameGenerator.generate();`
  static Npc generateRandom(
    String id,
    int generation,
    Random rng, {
    bool allowDarkOrigins = true,
  }) {
    final origin = _pickOrigin(rng, allowDarkOrigins);
    final base = origin.baseAttributes;

    final attributes = NpcAttributes(
      strength: _vary(base.strength, rng),
      agility: _vary(base.agility, rng),
      intelligence: _vary(base.intelligence, rng),
      endurance: _vary(base.endurance, rng),
      charisma: _vary(base.charisma, rng),
      mentalStability: _varyMental(base.mentalStability, rng),
      luck: _vary(base.luck, rng),
    );

    final traits = _pickTraits(rng, origin);
    final talent = _rollTalent(rng, chance: 0.15);
    final loyalty = _initialLoyalty(rng, origin, traits);

    return Npc(
      id: id,
      name: NpcNameGenerator.generateSync(rng),
      origin: origin,
      generation: generation,
      age: 18 + rng.nextInt(30),
      attributes: attributes,
      traits: traits,
      hiddenTalent: talent,
      loyalty: loyalty,
      betrayalRisk: origin.isDarkOrigin
          ? 20 + rng.nextDouble() * 20
          : rng.nextDouble() * 10,
      history: ['Invocado para a Torre no Dia 1'],
    );
  }

  /// Gera um filho com herança genética dos pais.
  static Npc generateChild(
    String id,
    Npc parentA,
    Npc parentB,
    Random rng,
    int birthDay, {
    double maternalNutrition = 100.0,
  }) {
    final a = parentA.attributes;
    final b = parentB.attributes;
    final nutritionPenalty = (100 - maternalNutrition) / 100;

    // Atributos físicos sofrem penalidade por má nutrição materna
    double physical(double va, double vb) =>
        (_inherit(va, vb, rng) * (1 - nutritionPenalty * 0.4)).clamp(1, 20);

    final attributes = NpcAttributes(
      strength: physical(a.strength, b.strength),
      agility: physical(a.agility, b.agility),
      intelligence: _inherit(a.intelligence, b.intelligence, rng),
      endurance: physical(a.endurance, b.endurance),
      charisma: _inherit(a.charisma, b.charisma, rng),
      mentalStability: _inherit(a.mentalStability, b.mentalStability, rng),
      luck: _inherit(a.luck, b.luck, rng),
    );

    // Talentos: 5% aleatório, 15% herdado
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
      name: NpcNameGenerator.generateSync(rng),
      origin: rng.nextBool() ? parentA.origin : parentB.origin,
      generation: max(parentA.generation, parentB.generation) + 1,
      age: 0,
      attributes: attributes,
      traits: [], // traits desenvolvem via eventos de vida
      hiddenTalent: talent,
      parentAId: parentA.id,
      parentBId: parentB.id,
      loyalty: childLoyalty,
      birthDay: birthDay,
      maternalNutrition: maternalNutrition,
      history: ['Nasceu na Torre - Filho(a) de ${parentA.name} e ${parentB.name}'],
    );
  }

  // ── Helpers privados ───────────────────────

  static NpcOrigin _pickOrigin(Random rng, bool allowDark) {
    if (allowDark && rng.nextDouble() < 0.12) {
      const dark = [NpcOrigin.thief, NpcOrigin.assassin, NpcOrigin.fraudster];
      return dark[rng.nextInt(dark.length)];
    }
    final normal = NpcOrigin.values.where((o) => !o.isDarkOrigin).toList();
    return normal[rng.nextInt(normal.length)];
  }

  static List<PersonalityTrait> _pickTraits(Random rng, NpcOrigin origin) {
    final all = PersonalityTrait.values.toList()..shuffle(rng);
    final traits = all.take(2 + rng.nextInt(2)).toList();
    // Origens sombrias têm 40% de chance de ganhar traço traidor
    if (origin.isDarkOrigin &&
        !traits.contains(PersonalityTrait.treacherous) &&
        rng.nextDouble() < 0.4) {
      traits[rng.nextInt(traits.length)] = PersonalityTrait.treacherous;
    }
    return traits;
  }

  static HiddenTalent _rollTalent(Random rng, {required double chance}) {
    if (rng.nextDouble() >= chance) return HiddenTalent.none;
    final options =
        HiddenTalent.values.where((t) => t != HiddenTalent.none).toList();
    return options[rng.nextInt(options.length)];
  }

  static double _initialLoyalty(
      Random rng, NpcOrigin origin, List<PersonalityTrait> traits) {
    double l = 50 + (rng.nextDouble() * 20 - 10);
    if (origin.isDarkOrigin) l -= 15;
    if (traits.contains(PersonalityTrait.loyal)) l += 15;
    if (traits.contains(PersonalityTrait.treacherous)) l -= 15;
    return l.clamp(10, 90);
  }

  /// Variação aleatória de ±2 em atributos físicos, clampado em [1, 15]
  static double _vary(double base, Random rng) =>
      (base + (rng.nextDouble() * 4 - 2)).clamp(1, 15);

  /// Variação de ±10 em sanidade mental, clampado em [20, 100]
  static double _varyMental(double base, Random rng) =>
      (base + (rng.nextDouble() * 20 - 10)).clamp(20, 100);

  /// Herança genética: média dos pais com variação de ±15%
  static double _inherit(double va, double vb, Random rng) {
    final avg = (va + vb) / 2;
    return (avg + avg * 0.15 * (rng.nextDouble() * 2 - 1)).clamp(1, 20);
  }
}
import 'dart:math';

class NpcAttributes {
  double strength;
  double agility;
  double intelligence;
  double endurance;
  double charisma;
  double mentalStability;

  NpcAttributes({
    this.strength = 5.0,
    this.agility = 5.0,
    this.intelligence = 5.0,
    this.endurance = 5.0,
    this.charisma = 5.0,
    this.mentalStability = 70.0,
  });

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'agility': agility,
        'intelligence': intelligence,
        'endurance': endurance,
        'charisma': charisma,
        'mentalStability': mentalStability,
      };

  factory NpcAttributes.fromJson(Map<String, dynamic> json) => NpcAttributes(
        strength: (json['strength'] as num?)?.toDouble() ?? 5.0,
        agility: (json['agility'] as num?)?.toDouble() ?? 5.0,
        intelligence: (json['intelligence'] as num?)?.toDouble() ?? 5.0,
        endurance: (json['endurance'] as num?)?.toDouble() ?? 5.0,
        charisma: (json['charisma'] as num?)?.toDouble() ?? 5.0,
        mentalStability: (json['mentalStability'] as num?)?.toDouble() ?? 70.0,
      );

  double get average =>
      (strength + agility + intelligence + endurance + charisma) / 5.0;

  double get combatPower =>
      (strength * 0.3 + agility * 0.25 + endurance * 0.25 + intelligence * 0.2);

  NpcAttributes clone() => NpcAttributes(
        strength: strength,
        agility: agility,
        intelligence: intelligence,
        endurance: endurance,
        charisma: charisma,
        mentalStability: mentalStability,
      );
}

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
  // Origens obscuras - risco de traicao
  thief,
  assassin,
  fraudster,
}

extension NpcOriginExt on NpcOrigin {
  String get label {
    switch (this) {
      case NpcOrigin.student: return 'Estudante';
      case NpcOrigin.chef: return 'Chef';
      case NpcOrigin.soldier: return 'Soldado';
      case NpcOrigin.programmer: return 'Programador';
      case NpcOrigin.athlete: return 'Atleta';
      case NpcOrigin.businessOwner: return 'Empresario';
      case NpcOrigin.doctor: return 'Medico';
      case NpcOrigin.teacher: return 'Professor';
      case NpcOrigin.artist: return 'Artista';
      case NpcOrigin.mechanic: return 'Mecanico';
      case NpcOrigin.farmer: return 'Fazendeiro';
      case NpcOrigin.musician: return 'Musico';
      case NpcOrigin.scientist: return 'Cientista';
      case NpcOrigin.firefighter: return 'Bombeiro';
      case NpcOrigin.nurse: return 'Enfermeiro(a)';
      case NpcOrigin.thief: return 'Ladrao';
      case NpcOrigin.assassin: return 'Assassino';
      case NpcOrigin.fraudster: return 'Estelionatario';
    }
  }

  String get icon {
    switch (this) {
      case NpcOrigin.student: return 'Estudante';
      case NpcOrigin.chef: return 'Chef';
      case NpcOrigin.soldier: return 'Soldado';
      case NpcOrigin.programmer: return 'Programador';
      case NpcOrigin.athlete: return 'Atleta';
      case NpcOrigin.businessOwner: return 'Empresario';
      case NpcOrigin.doctor: return 'Medico';
      case NpcOrigin.teacher: return 'Professor';
      case NpcOrigin.artist: return 'Artista';
      case NpcOrigin.mechanic: return 'Mecanico';
      case NpcOrigin.farmer: return 'Fazendeiro';
      case NpcOrigin.musician: return 'Musico';
      case NpcOrigin.scientist: return 'Cientista';
      case NpcOrigin.firefighter: return 'Bombeiro';
      case NpcOrigin.nurse: return 'Enfermeiro';
      case NpcOrigin.thief: return 'Ladrao';
      case NpcOrigin.assassin: return 'Assassino';
      case NpcOrigin.fraudster: return 'Estelionatario';
    }
  }

  bool get isDarkOrigin => this == NpcOrigin.thief || this == NpcOrigin.assassin || this == NpcOrigin.fraudster;

  NpcAttributes get baseAttributes {
    switch (this) {
      case NpcOrigin.student:
        return NpcAttributes(strength: 3, agility: 4, intelligence: 8, endurance: 3, charisma: 5, mentalStability: 60);
      case NpcOrigin.chef:
        return NpcAttributes(strength: 4, agility: 6, intelligence: 6, endurance: 5, charisma: 7, mentalStability: 65);
      case NpcOrigin.soldier:
        return NpcAttributes(strength: 9, agility: 7, intelligence: 5, endurance: 9, charisma: 4, mentalStability: 75);
      case NpcOrigin.programmer:
        return NpcAttributes(strength: 2, agility: 3, intelligence: 9, endurance: 3, charisma: 4, mentalStability: 55);
      case NpcOrigin.athlete:
        return NpcAttributes(strength: 8, agility: 9, intelligence: 4, endurance: 8, charisma: 6, mentalStability: 70);
      case NpcOrigin.businessOwner:
        return NpcAttributes(strength: 4, agility: 4, intelligence: 7, endurance: 5, charisma: 9, mentalStability: 68);
      case NpcOrigin.doctor:
        return NpcAttributes(strength: 3, agility: 5, intelligence: 9, endurance: 5, charisma: 6, mentalStability: 72);
      case NpcOrigin.teacher:
        return NpcAttributes(strength: 3, agility: 4, intelligence: 8, endurance: 4, charisma: 8, mentalStability: 70);
      case NpcOrigin.artist:
        return NpcAttributes(strength: 3, agility: 5, intelligence: 7, endurance: 3, charisma: 8, mentalStability: 50);
      case NpcOrigin.mechanic:
        return NpcAttributes(strength: 7, agility: 6, intelligence: 6, endurance: 7, charisma: 4, mentalStability: 65);
      case NpcOrigin.farmer:
        return NpcAttributes(strength: 7, agility: 5, intelligence: 4, endurance: 8, charisma: 5, mentalStability: 75);
      case NpcOrigin.musician:
        return NpcAttributes(strength: 3, agility: 5, intelligence: 6, endurance: 3, charisma: 9, mentalStability: 55);
      case NpcOrigin.scientist:
        return NpcAttributes(strength: 2, agility: 3, intelligence: 10, endurance: 4, charisma: 4, mentalStability: 60);
      case NpcOrigin.firefighter:
        return NpcAttributes(strength: 8, agility: 7, intelligence: 5, endurance: 9, charisma: 6, mentalStability: 78);
      case NpcOrigin.nurse:
        return NpcAttributes(strength: 4, agility: 5, intelligence: 7, endurance: 6, charisma: 7, mentalStability: 70);
      // Origens obscuras - boas em certas areas mas perigosas
      case NpcOrigin.thief:
        return NpcAttributes(strength: 4, agility: 9, intelligence: 7, endurance: 5, charisma: 6, mentalStability: 55);
      case NpcOrigin.assassin:
        return NpcAttributes(strength: 8, agility: 10, intelligence: 6, endurance: 7, charisma: 3, mentalStability: 45);
      case NpcOrigin.fraudster:
        return NpcAttributes(strength: 3, agility: 5, intelligence: 9, endurance: 3, charisma: 10, mentalStability: 50);
    }
  }
}

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
  String get label {
    switch (this) {
      case Profession.idle: return 'Ocioso';
      case Profession.explorer: return 'Explorador';
      case Profession.guard: return 'Guarda';
      case Profession.chef: return 'Cozinheiro';
      case Profession.doctor: return 'Medico';
      case Profession.teacher: return 'Professor';
      case Profession.blacksmith: return 'Ferreiro';
      case Profession.merchant: return 'Mercador';
      case Profession.scribe: return 'Escriba';
      case Profession.farmer: return 'Fazendeiro';
      case Profession.builder: return 'Construtor';
      case Profession.scout: return 'Batedor';
      case Profession.trainer: return 'Instrutor';
    }
  }

  String get tag {
    switch (this) {
      case Profession.idle: return 'Ocioso';
      case Profession.explorer: return 'Explorador';
      case Profession.guard: return 'Guarda';
      case Profession.chef: return 'Cozinheiro';
      case Profession.doctor: return 'Medico';
      case Profession.teacher: return 'Professor';
      case Profession.blacksmith: return 'Ferreiro';
      case Profession.merchant: return 'Mercador';
      case Profession.scribe: return 'Escriba';
      case Profession.farmer: return 'Fazendeiro';
      case Profession.builder: return 'Construtor';
      case Profession.scout: return 'Batedor';
      case Profession.trainer: return 'Instrutor';
    }
  }
}

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
}

extension PersonalityTraitExt on PersonalityTrait {
  String get label {
    switch (this) {
      case PersonalityTrait.brave: return 'Corajoso';
      case PersonalityTrait.coward: return 'Covarde';
      case PersonalityTrait.leader: return 'Lider';
      case PersonalityTrait.loner: return 'Solitario';
      case PersonalityTrait.compassionate: return 'Compassivo';
      case PersonalityTrait.ruthless: return 'Implacavel';
      case PersonalityTrait.optimist: return 'Otimista';
      case PersonalityTrait.pessimist: return 'Pessimista';
      case PersonalityTrait.analytical: return 'Analitico';
      case PersonalityTrait.impulsive: return 'Impulsivo';
      case PersonalityTrait.loyal: return 'Leal';
      case PersonalityTrait.treacherous: return 'Traicoeiro';
      case PersonalityTrait.calm: return 'Calmo';
      case PersonalityTrait.aggressive: return 'Agressivo';
      case PersonalityTrait.creative: return 'Criativo';
      case PersonalityTrait.pragmatic: return 'Pragmatico';
    }
  }
}

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
  String get label {
    switch (this) {
      case HiddenTalent.none: return 'Nenhum';
      case HiddenTalent.combatGenius: return 'Genio do Combate';
      case HiddenTalent.healingTouch: return 'Toque Curativo';
      case HiddenTalent.strategicMind: return 'Mente Estrategica';
      case HiddenTalent.naturalLeader: return 'Lider Natural';
      case HiddenTalent.beastWhisperer: return 'Sussurrador de Feras';
      case HiddenTalent.forgemaster: return 'Mestre da Forja';
      case HiddenTalent.herbalist: return 'Herbalista';
      case HiddenTalent.runeReader: return 'Leitor de Runas';
      case HiddenTalent.shadowWalker: return 'Caminhante das Sombras';
      case HiddenTalent.ironWill: return 'Vontade de Ferro';
    }
  }

  String get description {
    switch (this) {
      case HiddenTalent.none: return 'Sem talento oculto descoberto';
      case HiddenTalent.combatGenius: return '+50% poder de combate';
      case HiddenTalent.healingTouch: return 'Cura aliados apos batalha';
      case HiddenTalent.strategicMind: return 'Reduz mortalidade do grupo em 15%';
      case HiddenTalent.naturalLeader: return '+20% moral do grupo';
      case HiddenTalent.beastWhisperer: return 'Chance de domar criaturas';
      case HiddenTalent.forgemaster: return 'Equipamentos 2x mais eficientes';
      case HiddenTalent.herbalist: return 'Produz medicamentos naturais';
      case HiddenTalent.runeReader: return 'Revela segredos dos andares';
      case HiddenTalent.shadowWalker: return 'Pode evadir qualquer combate';
      case HiddenTalent.ironWill: return 'Imune a perda de sanidade';
    }
  }
}

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
  String get label {
    switch (this) {
      case MentalCondition.stable: return 'Estavel';
      case MentalCondition.stressed: return 'Estressado';
      case MentalCondition.depressed: return 'Deprimido';
      case MentalCondition.rebellious: return 'Rebelde';
      case MentalCondition.isolated: return 'Isolado';
      case MentalCondition.berserk: return 'Descontrolado';
      case MentalCondition.broken: return 'Quebrado';
    }
  }

  String get color {
    switch (this) {
      case MentalCondition.stable: return 'green';
      case MentalCondition.stressed: return 'yellow';
      case MentalCondition.depressed: return 'blue';
      case MentalCondition.rebellious: return 'orange';
      case MentalCondition.isolated: return 'grey';
      case MentalCondition.berserk: return 'red';
      case MentalCondition.broken: return 'darkred';
    }
  }
}

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
  double fame; // positiva = heroi, negativa = vilao
  List<String> history;
  MentalCondition mentalCondition;
  String? partnerId;
  List<String> childrenIds;
  String? parentAId;
  String? parentBId;
  int daysSurvived;
  int floorsCleared;
  int killCount;
  // Novos campos - Sistema social/politico
  double loyalty; // 0-100: lealdade ao jogador/lider
  double betrayalRisk; // 0-100: chance de trair
  String? groupId; // id do grupo/esquadrao
  int trainingSuggestionsReceived; // quantas sugestoes recebeu
  int trainingSuggestionsAccepted; // quantas aceitou
  bool isSuspicious; // marcado como suspeito pelo sistema

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
  })  : attributes = attributes ?? origin.baseAttributes,
        traits = traits ?? [],
        relationships = relationships ?? [],
        traumas = traumas ?? [],
        history = history ?? [],
        childrenIds = childrenIds ?? [];

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

  /// Calcula risco de traicao baseado em fatores multiplos
  double get calculatedBetrayalRisk {
    double risk = 0;
    // Origens obscuras tem risco base
    if (origin.isDarkOrigin) risk += 25;
    // Personalidade traicoeira
    if (traits.contains(PersonalityTrait.treacherous)) risk += 20;
    if (traits.contains(PersonalityTrait.ruthless)) risk += 10;
    if (traits.contains(PersonalityTrait.loyal)) risk -= 25;
    if (traits.contains(PersonalityTrait.compassionate)) risk -= 10;
    // Baixa lealdade aumenta risco
    risk += ((50 - loyalty) * 0.3).clamp(0, 30);
    // Baixa sanidade aumenta risco
    if (attributes.mentalStability < 30) risk += 15;
    if (attributes.mentalStability < 15) risk += 15;
    // Traumas empilhados
    risk += (traumas.length * 2).clamp(0, 15);
    return risk.clamp(0, 100);
  }

  /// Fama formatada: positiva = heroi, negativa = infame
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

  String get statusTag => alive ? '[VIVO]' : '[MORTO]';
  String get shortInfo => '${origin.icon} $name | G$generation | ${profession.tag} | ${calculatedMentalCondition.label}';

  double get survivalScore =>
      (attributes.endurance * 0.3 +
          attributes.strength * 0.2 +
          attributes.agility * 0.2 +
          attributes.intelligence * 0.15 +
          attributes.mentalStability * 0.15 / 10);

  /// Chance de aceitar sugestao de treino (0.0 a 1.0)
  double calculateTrainingAcceptance({required double fatigue, required bool hasTrainingField}) {
    double chance = 0.5;
    // Lealdade alta = aceita mais
    chance += (loyalty - 50) * 0.005;
    // Brave aceita mais, coward menos
    if (traits.contains(PersonalityTrait.brave)) chance += 0.15;
    if (traits.contains(PersonalityTrait.coward)) chance -= 0.15;
    if (traits.contains(PersonalityTrait.pragmatic)) chance += 0.10;
    if (traits.contains(PersonalityTrait.impulsive)) chance += 0.05;
    if (traits.contains(PersonalityTrait.loner)) chance -= 0.10;
    // Training field reduz risco, entao aceita mais
    if (hasTrainingField) chance += 0.15;
    // Fadiga reduz aceitacao
    chance -= fatigue * 0.003;
    // Sanidade baixa = recusa
    if (attributes.mentalStability < 40) chance -= 0.20;
    if (attributes.mentalStability < 20) chance -= 0.20;
    // Experiencia anterior
    if (trainingSuggestionsReceived > 0) {
      final acceptRate = trainingSuggestionsAccepted / trainingSuggestionsReceived;
      chance = chance * 0.7 + acceptRate * 0.3;
    }
    return chance.clamp(0.05, 0.95);
  }

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
      };

  factory Npc.fromJson(Map<String, dynamic> json) => Npc(
        id: json['id'] as String? ?? 'unknown',
        name: json['name'] as String? ?? 'Desconhecido',
        origin: NpcOrigin.values[(json['origin'] as int? ?? 0).clamp(0, NpcOrigin.values.length - 1)],
        generation: json['generation'] as int? ?? 1,
        age: json['age'] as int? ?? 25,
        alive: json['alive'] as bool? ?? true,
        attributes: json['attributes'] != null
            ? NpcAttributes.fromJson(json['attributes'] as Map<String, dynamic>)
            : null,
        traits: (json['traits'] as List<dynamic>?)
                ?.map((t) => PersonalityTrait.values[(t as int).clamp(0, PersonalityTrait.values.length - 1)])
                .toList() ??
            [],
        hiddenTalent: HiddenTalent.values[(json['hiddenTalent'] as int? ?? 0).clamp(0, HiddenTalent.values.length - 1)],
        talentDiscovered: json['talentDiscovered'] as bool? ?? false,
        profession: Profession.values[(json['profession'] as int? ?? 0).clamp(0, Profession.values.length - 1)],
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
        mentalCondition:
            MentalCondition.values[(json['mentalCondition'] as int? ?? 0).clamp(0, MentalCondition.values.length - 1)],
        partnerId: json['partnerId'] as String?,
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
        trainingSuggestionsReceived: json['trainingSuggestionsReceived'] as int? ?? 0,
        trainingSuggestionsAccepted: json['trainingSuggestionsAccepted'] as int? ?? 0,
        isSuspicious: json['isSuspicious'] as bool? ?? false,
      );

  static Npc generateRandom(String id, int generation, Random rng, {bool allowDarkOrigins = true}) {
    List<NpcOrigin> origins;
    if (allowDarkOrigins && rng.nextDouble() < 0.12) {
      // 12% chance de origem obscura
      origins = [NpcOrigin.thief, NpcOrigin.assassin, NpcOrigin.fraudster];
    } else {
      origins = NpcOrigin.values.where((o) => !o.isDarkOrigin).toList();
    }
    final origin = origins[rng.nextInt(origins.length)];
    final base = origin.baseAttributes;

    final attributes = NpcAttributes(
      strength: (base.strength + (rng.nextDouble() * 4 - 2)).clamp(1, 15),
      agility: (base.agility + (rng.nextDouble() * 4 - 2)).clamp(1, 15),
      intelligence: (base.intelligence + (rng.nextDouble() * 4 - 2)).clamp(1, 15),
      endurance: (base.endurance + (rng.nextDouble() * 4 - 2)).clamp(1, 15),
      charisma: (base.charisma + (rng.nextDouble() * 4 - 2)).clamp(1, 15),
      mentalStability: (base.mentalStability + (rng.nextDouble() * 20 - 10)).clamp(20, 100),
    );

    final allTraits = PersonalityTrait.values.toList()..shuffle(rng);
    final numTraits = 2 + rng.nextInt(2);
    final traits = allTraits.take(numTraits).toList();

    // Origens obscuras tem mais chance de traits traicoeiros
    if (origin.isDarkOrigin && !traits.contains(PersonalityTrait.treacherous) && rng.nextDouble() < 0.4) {
      traits[rng.nextInt(traits.length)] = PersonalityTrait.treacherous;
    }

    HiddenTalent talent = HiddenTalent.none;
    if (rng.nextDouble() < 0.15) {
      final talents = HiddenTalent.values.where((t) => t != HiddenTalent.none).toList();
      talent = talents[rng.nextInt(talents.length)];
    }

    // Lealdade inicial baseada na origem
    double initialLoyalty = 50.0 + (rng.nextDouble() * 20 - 10);
    if (origin.isDarkOrigin) initialLoyalty -= 15;
    if (traits.contains(PersonalityTrait.loyal)) initialLoyalty += 15;
    if (traits.contains(PersonalityTrait.treacherous)) initialLoyalty -= 15;
    initialLoyalty = initialLoyalty.clamp(10, 90);

    return Npc(
      id: id,
      name: _generateName(rng),
      origin: origin,
      generation: generation,
      age: 18 + rng.nextInt(30),
      attributes: attributes,
      traits: traits,
      hiddenTalent: talent,
      loyalty: initialLoyalty,
      betrayalRisk: origin.isDarkOrigin ? 20 + rng.nextDouble() * 20 : rng.nextDouble() * 10,
      history: ['Invocado para a Torre no Dia 1'],
    );
  }

  static Npc generateChild(String id, Npc parentA, Npc parentB, Random rng) {
    final mutationChance = 0.1;
    final a = parentA.attributes;
    final b = parentB.attributes;

    double inherit(double va, double vb) {
      double base = (va + vb) / 2;
      if (rng.nextDouble() < mutationChance) {
        base += (rng.nextDouble() * 6 - 3);
      }
      return base.clamp(1, 20);
    }

    final attributes = NpcAttributes(
      strength: inherit(a.strength, b.strength),
      agility: inherit(a.agility, b.agility),
      intelligence: inherit(a.intelligence, b.intelligence),
      endurance: inherit(a.endurance, b.endurance),
      charisma: inherit(a.charisma, b.charisma),
      mentalStability: inherit(a.mentalStability, b.mentalStability),
    );

    final allTraits = [...parentA.traits, ...parentB.traits];
    allTraits.shuffle(rng);
    final traits = allTraits.take(2 + rng.nextInt(2)).toSet().toList();

    HiddenTalent talent = HiddenTalent.none;
    if (rng.nextDouble() < 0.08) {
      final talents = HiddenTalent.values.where((t) => t != HiddenTalent.none).toList();
      talent = talents[rng.nextInt(talents.length)];
    } else if (rng.nextDouble() < 0.2) {
      if (parentA.hiddenTalent != HiddenTalent.none) talent = parentA.hiddenTalent;
      if (parentB.hiddenTalent != HiddenTalent.none && rng.nextBool()) talent = parentB.hiddenTalent;
    }

    // Lealdade do filho influenciada pelos pais
    double childLoyalty = ((parentA.loyalty + parentB.loyalty) / 2) + (rng.nextDouble() * 20 - 10);

    return Npc(
      id: id,
      name: _generateName(rng),
      origin: rng.nextBool() ? parentA.origin : parentB.origin,
      generation: max(parentA.generation, parentB.generation) + 1,
      age: 0,
      attributes: attributes,
      traits: traits,
      hiddenTalent: talent,
      parentAId: parentA.id,
      parentBId: parentB.id,
      loyalty: childLoyalty.clamp(20, 80),
      history: ['Nasceu na Torre - Filho(a) de ${parentA.name} e ${parentB.name}'],
    );
  }

  static String _generateName(Random rng) {
    const firstNames = [
      'Akira', 'Elena', 'Marcus', 'Yuki', 'Sofia', 'Ravi', 'Luna',
      'Kai', 'Aria', 'Davi', 'Mia', 'Chen', 'Nora', 'Leo', 'Zara',
      'Omar', 'Iris', 'Hugo', 'Maya', 'Erik', 'Lina', 'Atlas', 'Vera',
      'Theo', 'Jade', 'Ren', 'Cleo', 'Ivan', 'Rosa', 'Finn',
      'Abel', 'Diana', 'Samir', 'Hana', 'Viktor', 'Mei', 'Dante',
      'Suri', 'Boris', 'Kira', 'Rafael', 'Anya', 'Kenji', 'Freya',
    ];
    const lastNames = [
      'Nakamura', 'Santos', 'Chen', 'Mueller', 'Kim', 'Silva', 'Park',
      'Okafor', 'Johansson', 'Patel', 'Volkov', 'Costa', 'Tanaka',
      'Rivera', 'Zhang', 'Dubois', 'Petrov', 'Hayashi', 'Torres',
      'Andersen', 'Ferreira', 'Nguyen', 'Bergman', 'Rossi', 'Yamamoto',
    ];
    return '${firstNames[rng.nextInt(firstNames.length)]} ${lastNames[rng.nextInt(lastNames.length)]}';
  }
}

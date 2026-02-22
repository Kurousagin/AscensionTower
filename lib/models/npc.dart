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
    }
  }

  String get icon {
    switch (this) {
      case NpcOrigin.student: return '[STU]';
      case NpcOrigin.chef: return '[CHF]';
      case NpcOrigin.soldier: return '[SOL]';
      case NpcOrigin.programmer: return '[PRG]';
      case NpcOrigin.athlete: return '[ATL]';
      case NpcOrigin.businessOwner: return '[BIZ]';
      case NpcOrigin.doctor: return '[DOC]';
      case NpcOrigin.teacher: return '[TCH]';
      case NpcOrigin.artist: return '[ART]';
      case NpcOrigin.mechanic: return '[MEC]';
      case NpcOrigin.farmer: return '[FRM]';
      case NpcOrigin.musician: return '[MUS]';
      case NpcOrigin.scientist: return '[SCI]';
      case NpcOrigin.firefighter: return '[FIR]';
      case NpcOrigin.nurse: return '[NRS]';
    }
  }

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
    }
  }

  String get tag {
    switch (this) {
      case Profession.idle: return 'IDLE';
      case Profession.explorer: return 'EXPL';
      case Profession.guard: return 'GUAR';
      case Profession.chef: return 'CHEF';
      case Profession.doctor: return 'DOCT';
      case Profession.teacher: return 'TEAC';
      case Profession.blacksmith: return 'SMTH';
      case Profession.merchant: return 'MRCH';
      case Profession.scribe: return 'SCRB';
      case Profession.farmer: return 'FARM';
      case Profession.builder: return 'BULD';
      case Profession.scout: return 'SCOT';
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
  double fame;
  List<String> history;
  MentalCondition mentalCondition;
  String? partnerId;
  List<String> childrenIds;
  String? parentAId;
  String? parentBId;
  int daysSurvived;
  int floorsCleared;
  int killCount;

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

  String get statusTag => alive ? '[VIVO]' : '[MORTO]';
  String get shortInfo => '${origin.icon} $name | G$generation | ${profession.tag} | ${calculatedMentalCondition.label}';

  double get survivalScore =>
      (attributes.endurance * 0.3 +
          attributes.strength * 0.2 +
          attributes.agility * 0.2 +
          attributes.intelligence * 0.15 +
          attributes.mentalStability * 0.15 / 10);

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
      };

  factory Npc.fromJson(Map<String, dynamic> json) => Npc(
        id: json['id'] as String? ?? 'unknown',
        name: json['name'] as String? ?? 'Desconhecido',
        origin: NpcOrigin.values[json['origin'] as int? ?? 0],
        generation: json['generation'] as int? ?? 1,
        age: json['age'] as int? ?? 25,
        alive: json['alive'] as bool? ?? true,
        attributes: json['attributes'] != null
            ? NpcAttributes.fromJson(json['attributes'] as Map<String, dynamic>)
            : null,
        traits: (json['traits'] as List<dynamic>?)
                ?.map((t) => PersonalityTrait.values[t as int])
                .toList() ??
            [],
        hiddenTalent: HiddenTalent.values[json['hiddenTalent'] as int? ?? 0],
        talentDiscovered: json['talentDiscovered'] as bool? ?? false,
        profession: Profession.values[json['profession'] as int? ?? 0],
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
            MentalCondition.values[json['mentalCondition'] as int? ?? 0],
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
      );

  static Npc generateRandom(String id, int generation, Random rng) {
    final origins = NpcOrigin.values;
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

    HiddenTalent talent = HiddenTalent.none;
    if (rng.nextDouble() < 0.15) {
      final talents = HiddenTalent.values.where((t) => t != HiddenTalent.none).toList();
      talent = talents[rng.nextInt(talents.length)];
    }

    return Npc(
      id: id,
      name: _generateName(rng),
      origin: origin,
      generation: generation,
      age: 18 + rng.nextInt(30),
      attributes: attributes,
      traits: traits,
      hiddenTalent: talent,
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

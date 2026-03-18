import 'dart:math';
import 'floor_inhabitant.dart';
import 'floor_faction.dart';

enum FloorType {
  combat,
  moral,
  survival,
  strategic,
  mystery,
  boss,
  elite,
  puzzle,
  hunt,
  gauntlet,
}

extension FloorTypeExt on FloorType {
  String get label {
    switch (this) {
      case FloorType.combat:
        return 'Combate';
      case FloorType.moral:
        return 'Moral';
      case FloorType.survival:
        return 'Sobrevivencia';
      case FloorType.strategic:
        return 'Estrategico';
      case FloorType.mystery:
        return 'Misterio';
      case FloorType.boss:
        return 'CHEFE';
      case FloorType.elite:
        return 'Elite';
      case FloorType.puzzle:
        return 'Quebra-cabeca';
      case FloorType.hunt:
        return 'Caca';
      case FloorType.gauntlet:
        return 'Desafio';
    }
  }

  String get icon {
    switch (this) {
      case FloorType.combat:
        return '[!]';
      case FloorType.moral:
        return '[?]';
      case FloorType.survival:
        return '[~]';
      case FloorType.strategic:
        return '[*]';
      case FloorType.mystery:
        return '[.]';
      case FloorType.boss:
        return '[X]';
      case FloorType.elite:
        return '[E]';
      case FloorType.puzzle:
        return '[P]';
      case FloorType.hunt:
        return '[H]';
      case FloorType.gauntlet:
        return '[G]';
    }
  }
}

// ─────────────────────────────────────────────
// REGRAS DO ANDAR
// ─────────────────────────────────────────────

enum FloorRuleType {
  none,
  intelligenceOnly,
  soloEntry,
  loyaltyTest,
  weakLeads,
  silenceRequired,
  tributeRequired,
  mirrorRule,
}

class FloorRule {
  final FloorRuleType type;
  final String description;
  final String mechanicHint;

  const FloorRule({
    required this.type,
    required this.description,
    this.mechanicHint = '',
  });

  static const FloorRule none = FloorRule(
    type: FloorRuleType.none,
    description: '',
  );

  Map<String, dynamic> toJson() => {
    'ruleType': type.name,
    'ruleDescription': description,
    'ruleMechanicHint': mechanicHint,
  };

  factory FloorRule.fromJson(Map<String, dynamic> json) {
    final typeName = json['ruleType'] as String? ?? 'none';
    final type = FloorRuleType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => FloorRuleType.none,
    );
    return FloorRule(
      type: type,
      description: json['ruleDescription'] as String? ?? '',
      mechanicHint: json['ruleMechanicHint'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// TOWER FLOOR
// ─────────────────────────────────────────────

class TowerFloor {
  final int number;
  final FloorType type;
  final double difficulty;
  final double baseMortalityRate;
  final String description;
  final String reward;
  final String specialCondition;
  bool cleared;
  int timesCleared;
  List<String> deadOnFloor;
  int timesReexplored;
  FloorRule rule;

  // ── Sistema de Habitantes ──────────────────────────────────────
  List<FloorInhabitant> inhabitants;
  List<String> temporaryTags; // tags de anomalia, limpas a cada ciclo diário

  // ── Sistema de Facções ─────────────────────────────────────────
  // Preenchido pelo generate100Floors() com floorFaction = factionForFloor(number, tier)
  FloorFaction controllingFaction;

  /// Último dia em que este andar foi re-explorado com sucesso.
  /// -99 = nunca. Usado para calcular o cooldown de re-exploração.
  int lastReexploredDay;

  TowerFloor({
    required this.number,
    required this.type,
    required this.difficulty,
    required this.baseMortalityRate,
    required this.description,
    required this.reward,
    this.specialCondition = '',
    this.cleared = false,
    this.timesCleared = 0,
    List<String>? deadOnFloor,
    this.timesReexplored = 0,
    this.rule = FloorRule.none,
    List<FloorInhabitant>? inhabitants,
    List<String>? temporaryTags,
    this.controllingFaction = FloorFaction.none,
    this.lastReexploredDay = -99,
  }) : deadOnFloor = deadOnFloor ?? [],
       inhabitants = inhabitants ?? [],
       temporaryTags = temporaryTags ?? [];

  // ── Helpers de tags temporárias ───────────────────────────────

  void addTemporaryTag(String tag) {
    if (!temporaryTags.contains(tag)) temporaryTags.add(tag);
  }

  void clearTemporaryTags() => temporaryTags.clear();

  bool hasTag(String tag) => temporaryTags.contains(tag);

  // ── Cooldown de Re-exploração ──────────────────────────────────

  /// Dias mínimos entre re-explorações do mesmo andar.
  /// Tiers baixos (1-2): 1 dia. Tiers altos (7-10): 4 dias.
  int get reexplorationCooldown => (tier / 2).ceil().clamp(1, 4);

  /// Retorna true se o andar pode ser re-explorado no dia informado.
  bool canReexploreOnDay(int day) =>
      day - lastReexploredDay >= reexplorationCooldown;

  /// Quantos dias faltam para o cooldown terminar (0 = disponível).
  int cooldownRemainingOn(int day) =>
      (reexplorationCooldown - (day - lastReexploredDay)).clamp(
        0,
        reexplorationCooldown,
      );

  // ── Propriedades calculadas ────────────────────────────────────

  int get tier => ((number - 1) ~/ 10) + 1;

  double get scaledDifficulty {
    final tierMult = 1.0 + (tier - 1) * 0.4;
    double easyMod = 1.0;
    if (number <= 2) {
      easyMod = 0.6;
    } else if (number <= 5) {
      easyMod = 0.8;
    }
    return difficulty * tierMult * easyMod;
  }

  double get scaledMortality {
    final tierMult = 1.0 + (tier - 1) * 0.25;
    double easyMod = 1.0;
    if (number <= 2) {
      easyMod = 0.3;
    } else if (number <= 5) {
      easyMod = 0.6;
    }
    return (baseMortalityRate * tierMult * easyMod).clamp(0.0, 0.85);
  }

  double get reexplorationDifficulty {
    final base = scaledDifficulty * 0.5;
    final repeats = timesReexplored.clamp(0, 20);
    return base * (1.0 + repeats * 0.06);
  }

  /// Recursos farmáveis com diminishing returns (quanto mais re-explorar, menos ganha)
  Map<String, double> get farmableResources {
    final t = tier.toDouble();
    final base = <String, double>{};

    switch (type) {
      case FloorType.combat:
      case FloorType.gauntlet:
        base['ironOre'] = 3 + t * 2;
        base['stoneRaw'] = 2 + t;
        break;
      case FloorType.survival:
      case FloorType.hunt:
        base['food'] = 5 + t * 3;
        base['woodLog'] = 3 + t * 2;
        break;
      case FloorType.strategic:
      case FloorType.puzzle:
        base['knowledge'] = 4 + t * 3;
        base['ironOre'] = 2 + t;
        break;
      case FloorType.moral:
        base['knowledge'] = 3 + t * 2;
        base['food'] = 3 + t;
        break;
      case FloorType.mystery:
        base['knowledge'] = 5 + t * 3;
        base['food'] = 2 + t;
        break;
      case FloorType.elite:
        base['ironOre'] = 5 + t * 3;
        base['knowledge'] = 3 + t * 2;
        break;
      case FloorType.boss:
        final bossIdx = ((number - 1) ~/ 10) % 5;
        switch (bossIdx) {
          case 0:
            base['ironOre'] = 10 + t * 3;
            base['food'] = 8 + t * 2;
            break;
          case 1:
            base['woodLog'] = 10 + t * 3;
            base['stoneRaw'] = 8 + t * 2;
            break;
          case 2:
            base['knowledge'] = 10 + t * 3;
            base['ironOre'] = 8 + t * 2;
            break;
          case 3:
            base['food'] = 10 + t * 2;
            base['knowledge'] = 10 + t * 2;
            break;
          default:
            base['stoneRaw'] = 10 + t * 3;
            base['woodLog'] = 8 + t * 2;
        }
        break;
    }

    final repeats = timesReexplored.clamp(0, 20);
    final double multiplier = pow(0.90, repeats).clamp(0.15, 1.0).toDouble();
    base.updateAll((key, value) => (value * multiplier).roundToDouble());
    return base;
  }

  String get biome {
    final biomes = [
      'Fungos luminosos, ratos cristalinos, ervas raras',
      'Bestas deformadas, couro resistente, ossos de criatura',
      'Fragmentos de espelho, essencia psiquica, nevoa mental',
      'Engrenagens antigas, metal raro, oleo mecanico',
      'Arenas sangrentas, trofeus de gladiador',
      'Plantas toxicas, ambar pantanoso, raizes curativas',
      'Pergaminhos antigos, tinta magica, runas',
      'Cristais de julgamento, essencia de verdade',
      'Sombras solidificadas, metal sombrio',
      'Fragmentos primordiais, reliquia ancestral',
      'Cristais de mana, bestas elementais',
      'Flora carnivora, esporos venenosos',
      'Golems de pedra, metais encantados',
      'Espiritos errantes, fragmentos de alma',
      'Magma solidificado, salamandras de fogo',
    ];
    return biomes[(number - 1) % biomes.length];
  }

  int get recommendedPartySize {
    if (number <= 5) return 3;
    if (number <= 15) return 4;
    if (number <= 30) return 5;
    if (number <= 50) return 6;
    if (number <= 75) return 7;
    return 8;
  }

  double get recommendedPower => scaledDifficulty * 1.5 + (number * 0.3);

  String get tierLabel => 'Tier $tier';

  String get difficultyTag {
    if (number <= 5) return 'Facil';
    if (number <= 15) return 'Normal';
    if (number <= 30) return 'Dificil';
    if (number <= 50) return 'Brutal';
    if (number <= 75) return 'Infernal';
    return 'Impossivel';
  }

  // ── Serialização ──────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'number': number,
    'type': type.index,
    'difficulty': difficulty,
    'baseMortalityRate': baseMortalityRate,
    'description': description,
    'reward': reward,
    'specialCondition': specialCondition,
    'cleared': cleared,
    'timesCleared': timesCleared,
    'deadOnFloor': deadOnFloor,
    'timesReexplored': timesReexplored,
    'lastReexploredDay': lastReexploredDay,
    ...rule.toJson(),
    // Habitantes (saves antigos: campo ausente → lista vazia ✓)
    'inhabitants': inhabitants.map((i) => i.toJson()).toList(),
    'temporaryTags': temporaryTags,
    // Facção (saves antigos: campo ausente → none ✓)
    'controllingFaction': controllingFaction.key,
  };

  factory TowerFloor.fromJson(Map<String, dynamic> json) {
    // Deserializa facção com fallback para saves antigos
    final factionName = json['controllingFaction'] as String? ?? 'none';
    final faction = FloorFaction.values.firstWhere(
      (e) => e.key == factionName,
      orElse: () => FloorFaction.none,
    );

    return TowerFloor(
      number: json['number'] as int? ?? 1,
      type:
          FloorType.values[(json['type'] as int? ?? 0).clamp(
            0,
            FloorType.values.length - 1,
          )],
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 1.0,
      baseMortalityRate: (json['baseMortalityRate'] as num?)?.toDouble() ?? 0.1,
      description: json['description'] as String? ?? '',
      reward: json['reward'] as String? ?? '',
      specialCondition: json['specialCondition'] as String? ?? '',
      cleared: json['cleared'] as bool? ?? false,
      timesCleared: json['timesCleared'] as int? ?? 0,
      deadOnFloor:
          (json['deadOnFloor'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [],
      timesReexplored: json['timesReexplored'] as int? ?? 0,
      lastReexploredDay: json['lastReexploredDay'] as int? ?? -99,
      rule: json['ruleType'] != null
          ? FloorRule.fromJson(json)
          : FloorRule.none,
      // Habitantes: compatível com saves antigos (campo ausente → [])
      inhabitants:
          (json['inhabitants'] as List<dynamic>?)
              ?.map((i) => FloorInhabitant.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      temporaryTags:
          (json['temporaryTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      controllingFaction: faction,
    );
  }

  // ─────────────────────────────────────────────
  // TABELA DE REGRAS
  // ─────────────────────────────────────────────

  static const Map<int, FloorRule> _bossRules = {
    10: FloorRule(
      type: FloorRuleType.loyaltyTest,
      description: 'A Torre julga o coração de cada um.',
      mechanicHint: 'Leais +30% poder. Traidores −40% poder.',
    ),
    20: FloorRule(
      type: FloorRuleType.soloEntry,
      description: 'Apenas um pode enfrentar o que aguarda além.',
      mechanicHint: 'Somente o NPC mais forte entra. Os outros esperam fora.',
    ),
    30: FloorRule(
      type: FloorRuleType.intelligenceOnly,
      description: 'Força não resolve o que está por vir.',
      mechanicHint: 'INT substitui combatPower completamente.',
    ),
    40: FloorRule(
      type: FloorRuleType.silenceRequired,
      description: 'O silêncio é a única linguagem aceita aqui.',
      mechanicHint: 'NPCs agressivos operam com 45% do poder.',
    ),
    50: FloorRule(
      type: FloorRuleType.tributeRequired,
      description: 'A Torre cobra seu preço antes de qualquer passo.',
      mechanicHint: 'Custo de comida +50%. Chance de sucesso +10%.',
    ),
    60: FloorRule(
      type: FloorRuleType.mirrorRule,
      description: 'O que você é, ele também é. Você luta contra si mesmo.',
      mechanicHint: 'Quanto mais forte seu grupo, maior a dificuldade.',
    ),
    70: FloorRule(
      type: FloorRuleType.weakLeads,
      description: 'O mais fraco carrega o destino de todos.',
      mechanicHint: 'O NPC com menor poder define o resultado da expedição.',
    ),
    80: FloorRule(
      type: FloorRuleType.loyaltyTest,
      description: 'A Torre lembra de todas as traições.',
      mechanicHint: 'Lealdade < 50 resulta em penalidade severa.',
    ),
    90: FloorRule(
      type: FloorRuleType.intelligenceOnly,
      description: 'Neste andar, apenas a mente sobrevive.',
      mechanicHint: 'INT é tudo. Combate é irrelevante.',
    ),
  };

  static FloorRule _generateProceduralRule(
    int number,
    FloorType type,
    Random rng,
  ) {
    if (rng.nextDouble() > 0.35) return FloorRule.none;
    final candidates = _rulesForFloorType(type);
    if (candidates.isEmpty) return FloorRule.none;
    return candidates[rng.nextInt(candidates.length)];
  }

  static List<FloorRule> _rulesForFloorType(FloorType type) {
    switch (type) {
      case FloorType.combat:
      case FloorType.gauntlet:
        return const [
          FloorRule(
            type: FloorRuleType.silenceRequired,
            description: 'As criaturas aqui caçam pelo barulho.',
            mechanicHint: 'Agressivos com 45% do poder.',
          ),
          FloorRule(
            type: FloorRuleType.mirrorRule,
            description: 'A ameaça cresce conforme sua força.',
            mechanicHint: 'Dificuldade escala com poder do grupo.',
          ),
        ];
      case FloorType.strategic:
      case FloorType.puzzle:
        return const [
          FloorRule(
            type: FloorRuleType.intelligenceOnly,
            description: 'Sem raciocínio, não há caminho.',
            mechanicHint: 'INT substitui combatPower.',
          ),
          FloorRule(
            type: FloorRuleType.tributeRequired,
            description: 'O enigma exige um preço para ser revelado.',
            mechanicHint: 'Custo +50%. Chance de sucesso +10%.',
          ),
        ];
      case FloorType.moral:
        return const [
          FloorRule(
            type: FloorRuleType.loyaltyTest,
            description: 'Aqui, intenções são mais visíveis que ações.',
            mechanicHint: 'Lealdade determina modificadores de poder.',
          ),
          FloorRule(
            type: FloorRuleType.weakLeads,
            description: 'O mais humilde encontra o caminho.',
            mechanicHint: 'NPC mais fraco define o poder do grupo.',
          ),
        ];
      case FloorType.survival:
      case FloorType.hunt:
        return const [
          FloorRule(
            type: FloorRuleType.tributeRequired,
            description: 'A selva exige sangue antes de dar passagem.',
            mechanicHint: 'Custo +50%. Chance de sucesso +10%.',
          ),
          FloorRule(
            type: FloorRuleType.silenceRequired,
            description: 'Qualquer som aqui é fatal.',
            mechanicHint: 'Agressivos com 45% do poder.',
          ),
        ];
      case FloorType.mystery:
        return const [
          FloorRule(
            type: FloorRuleType.intelligenceOnly,
            description: 'O mistério não cede à força.',
            mechanicHint: 'INT substitui combatPower.',
          ),
          FloorRule(
            type: FloorRuleType.loyaltyTest,
            description: 'O andar revela quem você realmente é.',
            mechanicHint: 'Lealdade determina modificadores de poder.',
          ),
        ];
      case FloorType.elite:
        return const [
          FloorRule(
            type: FloorRuleType.soloEntry,
            description: 'O guardião só aceita desafios individuais.',
            mechanicHint: 'Apenas o NPC mais forte entra.',
          ),
          FloorRule(
            type: FloorRuleType.mirrorRule,
            description: 'O elite aprende com seus oponentes.',
            mechanicHint: 'Dificuldade escala com poder do grupo.',
          ),
        ];
      default:
        return const [];
    }
  }

  // ─────────────────────────────────────────────
  // CHANCE DE HABITANTE POR ANDAR
  // ─────────────────────────────────────────────

  static double _inhabitantChance(int floorNumber) {
    if (floorNumber <= 5) return 0.30; // tutorial: poucos habitantes
    if (floorNumber <= 20) return 0.55; // andares iniciais: mais densidade
    if (floorNumber <= 50) return 0.65; // meio: gente ficou pelo caminho
    return 0.45; // altos: perigoso demais pra maioria
  }

  // ─────────────────────────────────────────────
  // GERAÇÃO DE 100 ANDARES
  // ─────────────────────────────────────────────

  static List<TowerFloor> generate100Floors() {
    final rng = Random(42);
    final floors = <TowerFloor>[];

    final bossDescriptions = [
      'Uma entidade massiva que testa o valor da humanidade. O primeiro grande desafio.',
      'Uma criatura de muitas cabecas emerge das aguas escuras. Cada cabeca guarda um segredo mortal.',
      'Um ser que enxerga alem da realidade. Seus olhos revelam verdades que destroem a mente.',
      'As proprias paredes estao vivas. O andar inteiro e o boss. Nao ha para onde correr.',
      'Um colossus de metal forjado em sangue de herois caidos. Cada armadura que veste foi de alguem.',
      'A floresta inteira obedece sua vontade. O veneno e tao sutil que voce nao percebe ate ser tarde.',
      'Alimenta-se de memorias e emocoes. Os mais fortes emocionalmente sao os mais vulneraveis.',
      'Reescreve as regras do andar a cada momento. Nada e como parece. A logica e a unica arma.',
      'A encarnacao do medo coletivo de todos que morreram na Torre. Cada heroi caido fortalece a Sombra.',
      'A mente por tras de tudo. Ela criou este jogo. Ela observa. E agora, ela luta.',
    ];

    final tierPatterns = [
      [
        FloorType.survival,
        FloorType.combat,
        FloorType.moral,
        FloorType.strategic,
        FloorType.elite,
        FloorType.hunt,
        FloorType.mystery,
        FloorType.puzzle,
        FloorType.gauntlet,
        FloorType.boss,
      ],
      [
        FloorType.combat,
        FloorType.survival,
        FloorType.puzzle,
        FloorType.hunt,
        FloorType.elite,
        FloorType.moral,
        FloorType.strategic,
        FloorType.mystery,
        FloorType.gauntlet,
        FloorType.boss,
      ],
      [
        FloorType.hunt,
        FloorType.moral,
        FloorType.combat,
        FloorType.mystery,
        FloorType.elite,
        FloorType.survival,
        FloorType.puzzle,
        FloorType.strategic,
        FloorType.gauntlet,
        FloorType.boss,
      ],
      [
        FloorType.strategic,
        FloorType.combat,
        FloorType.hunt,
        FloorType.moral,
        FloorType.elite,
        FloorType.mystery,
        FloorType.survival,
        FloorType.gauntlet,
        FloorType.puzzle,
        FloorType.boss,
      ],
      [
        FloorType.mystery,
        FloorType.gauntlet,
        FloorType.combat,
        FloorType.puzzle,
        FloorType.elite,
        FloorType.hunt,
        FloorType.moral,
        FloorType.strategic,
        FloorType.survival,
        FloorType.boss,
      ],
    ];

    final floorNames = {
      FloorType.combat: [
        'Corredor das Bestas',
        'Arena Sangrenta',
        'Campo de Batalha',
        'Trincheira dos Caidos',
        'Coliseu Sombrio',
        'Patio da Carnificina',
        'Fosso do Gladiador',
        'Planicie Vermelha',
        'Covil do Predador',
        'Fronteira da Morte',
      ],
      FloorType.survival: [
        'Ruinas Silenciosas',
        'Pantano Toxico',
        'Deserto de Cinzas',
        'Floresta Petrificada',
        'Caverna Glacial',
        'Vulcao Adormecido',
        'Mar de Acido',
        'Tundra Infinita',
        'Abismo Sem Fundo',
        'Tempestade Eterna',
      ],
      FloorType.moral: [
        'Sala dos Espelhos',
        'Tribunal dos Pecados',
        'Jardim das Memorias',
        'Santuario do Remorso',
        'Ponte da Escolha',
        'Camera do Julgamento',
        'Altar do Sacrificio',
        'Teatro das Sombras',
        'Lagrimas do Passado',
        'Porta da Verdade',
      ],
      FloorType.strategic: [
        'Labirinto Mecanico',
        'Fortaleza das Sombras',
        'Tabuleiro Gigante',
        'Relogio de Engrenagens',
        'Rede de Armadilhas',
        'Maquina Infernal',
        'Xadrez dos Deuses',
        'Circuito do Caos',
        'Prisao Logica',
        'Dimensao Geometrica',
      ],
      FloorType.mystery: [
        'Biblioteca Proibida',
        'Sala Vazia',
        'Espaco Entre Mundos',
        'Sonho Coletivo',
        'Eco do Futuro',
        'Fragmento de Realidade',
        'Limiar da Loucura',
        'Camera Selada',
        'Portao Invertido',
        'Nexus Temporal',
      ],
      FloorType.elite: [
        'Guarda Avancada',
        'Sentinela do Tier',
        'Portao do Meio',
        'Guardiao Menor',
        'Teste de Elite',
        'Barreira de Poder',
        'Desafio do Forte',
        'Filtro Natural',
        'Muro Vivo',
        'Portao Blindado',
      ],
      FloorType.puzzle: [
        'Enigma das Runas',
        'Cubo Dimensional',
        'Cifra Impossivel',
        'Paradoxo Temporal',
        'Sequencia Mortal',
        'Codigo da Torre',
        'Padroes Ocultos',
        'Matriz de Luz',
        'Equacao do Caos',
        'Quebra-cabeca Final',
      ],
      FloorType.hunt: [
        'Terreno de Caca',
        'Selva Noturna',
        'Caca ao Predador',
        'Trilha das Feras',
        'Covil Subterraneo',
        'Floresta dos Lobos',
        'Pantano dos Repteis',
        'Ninho de Monstros',
        'Savana Perigosa',
        'Toca do Dragao',
      ],
      FloorType.gauntlet: [
        'Desafio Sem Fim',
        'Maratona da Dor',
        'Prova de Resistencia',
        'Corrida Mortal',
        'Sequencia de Ondas',
        'Horda Infinita',
        'Combate Continuo',
        'Escalada Brutal',
        'Teste de Limite',
        'Ultimo Suspiro',
      ],
    };

    final specialConditions = [
      '',
      'Visibilidade reduzida',
      'Espaco estreito',
      'Teste de Estabilidade Mental',
      'Requer INT > 6 no lider',
      'Sem fuga possivel',
      'Dano continuo',
      'Risco de perda de sanidade',
      'Revela traicoes ocultas',
      'Tempo limitado',
      'Gravidade invertida',
      'Veneno no ar',
      'Escuridao total',
      'Silencio absoluto',
      'Ilusoes constantes',
      'Terreno instavel',
      'Frio extremo',
      'Calor sufocante',
    ];

    for (int i = 1; i <= 100; i++) {
      final tierIdx = ((i - 1) ~/ 10);
      final posInTier = (i - 1) % 10;
      final isBoss = posInTier == 9;
      final isElite = posInTier == 4;

      final patternIdx = tierIdx % tierPatterns.length;
      final FloorType type = tierPatterns[patternIdx][posInTier];

      double baseDiff;
      if (i <= 5) {
        baseDiff = 1.0 + i * 0.4;
      } else if (i <= 15) {
        baseDiff = 2.0 + (i - 5) * 0.5;
      } else if (i <= 30) {
        baseDiff = 5.0 + (i - 15) * 0.6;
      } else if (i <= 50) {
        baseDiff = 10.0 + (i - 30) * 0.8;
      } else if (i <= 75) {
        baseDiff = 20.0 + (i - 50) * 1.0;
      } else {
        baseDiff = 35.0 + (i - 75) * 1.5;
      }
      if (isBoss) {
        baseDiff *= 1.8;
      } else if (isElite) {
        baseDiff *= 1.3;
      }

      double mortality;
      if (i <= 5) {
        mortality = 0.04 + i * 0.015;
      } else if (i <= 15) {
        mortality = 0.08 + (i - 5) * 0.018;
      } else if (i <= 30) {
        mortality = 0.14 + (i - 15) * 0.013;
      } else if (i <= 50) {
        mortality = 0.22 + (i - 30) * 0.010;
      } else if (i <= 75) {
        mortality = 0.32 + (i - 50) * 0.008;
      } else {
        mortality = 0.42 + (i - 75) * 0.008;
      }
      if (isBoss) {
        mortality *= 1.5;
      } else if (isElite) {
        mortality *= 1.2;
      }
      mortality = mortality.clamp(0.02, 0.60);

      String desc;
      String reward;
      String condition;

      if (isBoss) {
        desc = bossDescriptions[tierIdx.clamp(0, 9)];
        reward =
            'Tier ${tierIdx + 1} completo! Recompensas massivas. Cidadela evolui.';
        condition = 'BOSS - Requer preparacao maxima';
      } else {
        final nameList = floorNames[type] ?? ['Andar Desconhecido'];
        desc =
            '${nameList[posInTier % nameList.length]}. '
            'Tier ${tierIdx + 1} - Dificuldade ${i <= 5
                ? "introdutoria"
                : i <= 15
                ? "crescente"
                : i <= 30
                ? "seria"
                : i <= 50
                ? "brutal"
                : i <= 75
                ? "infernal"
                : "impossivel"}.';
        reward = _generateReward(i, type, tierIdx);
        condition = isElite
            ? 'ELITE - Mini-boss antes do Boss do Tier'
            : specialConditions[rng.nextInt(specialConditions.length)];
      }

      // ── Facção controladora ──────────────────────────────────
      final faction = FactionProcessor.factionForFloor(i, tierIdx);

      final floor = TowerFloor(
        number: i,
        type: type,
        difficulty: baseDiff,
        baseMortalityRate: mortality,
        description: desc,
        reward: reward,
        specialCondition: condition,
        controllingFaction: faction,
      );

      // ── Regra do andar ───────────────────────────────────────
      floor.rule = isBoss
          ? (_bossRules[i] ?? FloorRule.none)
          : _generateProceduralRule(i, type, rng);

      // ── Habitantes ───────────────────────────────────────────────────────
      final inhabitantSeed = i * 13 + tierIdx * 7;
      if (rng.nextDouble() < _inhabitantChance(i)) {
        final inhabitant = InhabitantFactory.generateForFloor(
          floorNumber: i,
          tier: tierIdx + 1,
          seed: inhabitantSeed,
        );
        // ✅ FIX: vincula o habitante à facção que controla o andar
        if (faction != FloorFaction.none) {
          // Anomalias são entidades neutras — sem afiliação
          // Survivors e residents refletem o ambiente do andar
          if (inhabitant.category != InhabitantCategory.anomaly) {
            inhabitant.factionAffiliation = faction;
          }
        }
        floor.inhabitants.add(inhabitant);
      }

      // Bosses e elites têm chance adicional de survivor
      if ((isBoss || isElite) && rng.nextDouble() < 0.40) {
        final extra = InhabitantFactory.generateForFloor(
          floorNumber: i,
          tier: tierIdx + 1,
          seed: inhabitantSeed + 1,
        );
        if (faction != FloorFaction.none &&
            extra.category != InhabitantCategory.anomaly) {
          extra.factionAffiliation = faction;
        }
        floor.inhabitants.add(extra);
      }
      // Bosses e elites têm chance adicional de survivor
      if ((isBoss || isElite) && rng.nextDouble() < 0.40) {
        floor.inhabitants.add(
          InhabitantFactory.generateForFloor(
            floorNumber: i,
            tier: tierIdx + 1,
            seed: inhabitantSeed + 1,
          ),
        );
      }

      floors.add(floor);
    }

    return floors;
  }

  static String _generateReward(int floor, FloorType type, int tier) {
    final t = tier + 1;
    switch (type) {
      case FloorType.combat:
      case FloorType.gauntlet:
        return '+${5 * t} Ferro, +${3 * t} Pedra, +Fama para sobreviventes';
      case FloorType.survival:
      case FloorType.hunt:
        return '+${8 * t} Comida, +${4 * t} Madeira';
      case FloorType.strategic:
      case FloorType.puzzle:
        return '+${6 * t} Conhecimento, +${3 * t} Ferro';
      case FloorType.moral:
        return '+${5 * t} Conhecimento, +${3 * t} Moral';
      case FloorType.mystery:
        return '+${8 * t} Conhecimento, chance de Talento Oculto';
      case FloorType.elite:
        return '+${4 * t} todos recursos, Material de Promocao';
      case FloorType.boss:
        return '+${10 * t} todos recursos, Expansao, Revelacao';
    }
  }

  static List<TowerFloor> generateMvpFloors() => generate100Floors();
}

// ─────────────────────────────────────────────
// TOWER CHALLENGE
// ─────────────────────────────────────────────

class TowerChallenge {
  final TowerFloor floor;
  final List<String> partyIds;
  bool completed;
  bool victory;
  List<String> casualties;
  List<String> log;
  double moraleImpact;

  TowerChallenge({
    required this.floor,
    required this.partyIds,
    this.completed = false,
    this.victory = false,
    List<String>? casualties,
    List<String>? log,
    this.moraleImpact = 0,
  }) : casualties = casualties != null ? List.from(casualties) : [],
       log = log ?? [];

  Map<String, dynamic> toJson() => {
    'floorNumber': floor.number,
    'partyIds': partyIds,
    'completed': completed,
    'victory': victory,
    'casualties': casualties,
    'log': log,
    'moraleImpact': moraleImpact,
  };
}

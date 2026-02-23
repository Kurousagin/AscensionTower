import 'dart:math';

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
      case FloorType.combat: return 'Combate';
      case FloorType.moral: return 'Moral';
      case FloorType.survival: return 'Sobrevivencia';
      case FloorType.strategic: return 'Estrategico';
      case FloorType.mystery: return 'Misterio';
      case FloorType.boss: return 'CHEFE';
      case FloorType.elite: return 'Elite';
      case FloorType.puzzle: return 'Quebra-cabeca';
      case FloorType.hunt: return 'Caca';
      case FloorType.gauntlet: return 'Desafio';
    }
  }

  String get icon {
    switch (this) {
      case FloorType.combat: return '[!]';
      case FloorType.moral: return '[?]';
      case FloorType.survival: return '[~]';
      case FloorType.strategic: return '[*]';
      case FloorType.mystery: return '[.]';
      case FloorType.boss: return '[X]';
      case FloorType.elite: return '[E]';
      case FloorType.puzzle: return '[P]';
      case FloorType.hunt: return '[H]';
      case FloorType.gauntlet: return '[G]';
    }
  }
}

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
  }) : deadOnFloor = deadOnFloor ?? [];

  /// Tier do andar (1-10), muda a cada 10 andares
  int get tier => ((number - 1) ~/ 10) + 1;

  /// Dificuldade escalonada com tier
  double get scaledDifficulty {
    final tierMult = 1.0 + (tier - 1) * 0.4;
    // Andares 1-2 faceis
    double easyMod = 1.0;
    if (number <= 2) {
      easyMod = 0.6;
    } else if (number <= 5) easyMod = 0.8;
    return difficulty * tierMult * easyMod;
  }

  double get scaledMortality {
    final tierMult = 1.0 + (tier - 1) * 0.25;
    double easyMod = 1.0;
    if (number <= 2) {
      easyMod = 0.3;
    } else if (number <= 5) easyMod = 0.6;
    return (baseMortalityRate * tierMult * easyMod).clamp(0.0, 0.85);
  }

  double get reexplorationDifficulty {
    final base = scaledDifficulty * 0.5;
    final repeats = timesReexplored.clamp(0, 20);
    return base * (1.0 + repeats * 0.06);
  }

  /// Recursos farmaveis escalam com tier
  Map<String, double> get farmableResources {
    final t = tier.toDouble();
    final base = <String, double>{};
    switch (type) {
      case FloorType.combat:
      case FloorType.gauntlet:
        base['iron'] = 3 + t * 2;
        base['stone'] = 2 + t;
        break;
      case FloorType.survival:
      case FloorType.hunt:
        base['food'] = 5 + t * 3;
        base['wood'] = 3 + t * 2;
        break;
      case FloorType.strategic:
      case FloorType.puzzle:
        base['knowledge'] = 4 + t * 3;
        base['iron'] = 2 + t;
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
        base['iron'] = 5 + t * 3;
        base['knowledge'] = 3 + t * 2;
        break;
      case FloorType.boss:
        base['food'] = 5 + t * 2;
        base['wood'] = 5 + t * 2;
        base['stone'] = 5 + t * 2;
        base['iron'] = 5 + t * 2;
        base['knowledge'] = 5 + t * 2;
        break;
    }
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

  double get recommendedPower {
    return scaledDifficulty * 1.5 + (number * 0.3);
  }

  String get tierLabel => 'Tier $tier';

  /// Cor de dificuldade para UI
  String get difficultyTag {
    if (number <= 5) return 'Facil';
    if (number <= 15) return 'Normal';
    if (number <= 30) return 'Dificil';
    if (number <= 50) return 'Brutal';
    if (number <= 75) return 'Infernal';
    return 'Impossivel';
  }

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
      };

  factory TowerFloor.fromJson(Map<String, dynamic> json) => TowerFloor(
        number: json['number'] as int? ?? 1,
        type: FloorType.values[(json['type'] as int? ?? 0).clamp(0, FloorType.values.length - 1)],
        difficulty: (json['difficulty'] as num?)?.toDouble() ?? 1.0,
        baseMortalityRate: (json['baseMortalityRate'] as num?)?.toDouble() ?? 0.1,
        description: json['description'] as String? ?? '',
        reward: json['reward'] as String? ?? '',
        specialCondition: json['specialCondition'] as String? ?? '',
        cleared: json['cleared'] as bool? ?? false,
        timesCleared: json['timesCleared'] as int? ?? 0,
        deadOnFloor: (json['deadOnFloor'] as List<dynamic>?)
                ?.map((d) => d.toString())
                .toList() ??
            [],
        timesReexplored: json['timesReexplored'] as int? ?? 0,
      );

  // ═══════════════════════════════════════════════════════════════
  // GERACAO DE 100 ANDARES
  // Inspirado em Pick Me Up, Infinite Gacha
  //
  // ESTRUTURA:
  //   - 10 Tiers (10 andares cada)
  //   - Boss a cada 10 andares (10, 20, 30... 100)
  //   - Elite a cada 5 andares (5, 15, 25...)
  //   - Spike de dificuldade a cada 5 andares
  //   - Andares 1-5: Tutorial / Facil
  //   - Andares 6-15: Introducao a dificuldade real
  //   - Andares 16-30: Medio - mortes comecam a acontecer
  //   - Andares 31-50: Dificil - preparacao e essencial
  //   - Andares 51-75: Brutal - cada expedição e uma aposta
  //   - Andares 76-100: Infernal/Impossivel - lendario
  // ═══════════════════════════════════════════════════════════════

  static List<TowerFloor> generate100Floors() {
    final rng = Random(42); // seed fixa para consistencia
    final floors = <TowerFloor>[];

    // Nomes de bosses por tier
    // final bossNames = [
    //   'O Guardiao do Primeiro Umbral',
    //   'A Hidra das Profundezas',
    //   'O Oraculo da Loucura',
    //   'A Fortaleza Viva',
    //   'O Imperador de Ferro',
    //   'A Rainha Venenosa',
    //   'O Devorador de Almas',
    //   'O Arquiteto do Caos',
    //   'A Sombra Primordial',
    //   'TEL - A Criadora do Jogo',
    // ];

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

    // Tipos de andar por posicao no tier
    final tierPatterns = [
      [FloorType.survival, FloorType.combat, FloorType.moral, FloorType.strategic, FloorType.elite,
       FloorType.hunt, FloorType.mystery, FloorType.puzzle, FloorType.gauntlet, FloorType.boss],
      [FloorType.combat, FloorType.survival, FloorType.puzzle, FloorType.hunt, FloorType.elite,
       FloorType.moral, FloorType.strategic, FloorType.mystery, FloorType.gauntlet, FloorType.boss],
      [FloorType.hunt, FloorType.moral, FloorType.combat, FloorType.mystery, FloorType.elite,
       FloorType.survival, FloorType.puzzle, FloorType.strategic, FloorType.gauntlet, FloorType.boss],
      [FloorType.strategic, FloorType.combat, FloorType.hunt, FloorType.moral, FloorType.elite,
       FloorType.mystery, FloorType.survival, FloorType.gauntlet, FloorType.puzzle, FloorType.boss],
      [FloorType.mystery, FloorType.gauntlet, FloorType.combat, FloorType.puzzle, FloorType.elite,
       FloorType.hunt, FloorType.moral, FloorType.strategic, FloorType.survival, FloorType.boss],
    ];

    final floorNames = {
      FloorType.combat: [
        'Corredor das Bestas', 'Arena Sangrenta', 'Campo de Batalha', 'Trincheira dos Caidos',
        'Coliseu Sombrio', 'Patio da Carnificina', 'Fosso do Gladiador', 'Planicie Vermelha',
        'Covil do Predador', 'Fronteira da Morte',
      ],
      FloorType.survival: [
        'Ruinas Silenciosas', 'Pantano Toxico', 'Deserto de Cinzas', 'Floresta Petrificada',
        'Caverna Glacial', 'Vulcao Adormecido', 'Mar de Acido', 'Tundra Infinita',
        'Abismo Sem Fundo', 'Tempestade Eterna',
      ],
      FloorType.moral: [
        'Sala dos Espelhos', 'Tribunal dos Pecados', 'Jardim das Memorias', 'Santuario do Remorso',
        'Ponte da Escolha', 'Camera do Julgamento', 'Altar do Sacrificio', 'Teatro das Sombras',
        'Lagrimas do Passado', 'Porta da Verdade',
      ],
      FloorType.strategic: [
        'Labirinto Mecanico', 'Fortaleza das Sombras', 'Tabuleiro Gigante', 'Relogio de Engrenagens',
        'Rede de Armadilhas', 'Maquina Infernal', 'Xadrez dos Deuses', 'Circuito do Caos',
        'Prisao Logica', 'Dimensao Geometrica',
      ],
      FloorType.mystery: [
        'Biblioteca Proibida', 'Sala Vazia', 'Espaco Entre Mundos', 'Sonho Coletivo',
        'Eco do Futuro', 'Fragmento de Realidade', 'Limiar da Loucura', 'Camera Selada',
        'Portao Invertido', 'Nexus Temporal',
      ],
      FloorType.elite: [
        'Guarda Avancada', 'Sentinela do Tier', 'Portao do Meio', 'Guardiao Menor',
        'Teste de Elite', 'Barreira de Poder', 'Desafio do Forte', 'Filtro Natural',
        'Muro Vivo', 'Portao Blindado',
      ],
      FloorType.puzzle: [
        'Enigma das Runas', 'Cubo Dimensional', 'Cifra Impossivel', 'Paradoxo Temporal',
        'Sequencia Mortal', 'Codigo da Torre', 'Padroes Ocultos', 'Matriz de Luz',
        'Equacao do Caos', 'Quebra-cabeca Final',
      ],
      FloorType.hunt: [
        'Terreno de Caca', 'Selva Noturna', 'Caca ao Predador', 'Trilha das Feras',
        'Covil Subterraneo', 'Floresta dos Lobos', 'Pantano dos Repteis', 'Ninho de Monstros',
        'Savana Perigosa', 'Toca do Dragao',
      ],
      FloorType.gauntlet: [
        'Desafio Sem Fim', 'Maratona da Dor', 'Prova de Resistencia', 'Corrida Mortal',
        'Sequencia de Ondas', 'Horda Infinita', 'Combate Contínuo', 'Escalada Brutal',
        'Teste de Limite', 'Ultimo Suspiro',
      ],
    };

    final specialConditions = [
      '', 'Visibilidade reduzida', 'Espaco estreito', 'Teste de Estabilidade Mental',
      'Requer INT > 6 no lider', 'Sem fuga possivel', 'Dano continuo',
      'Risco de perda de sanidade', 'Revela traicoes ocultas', 'Tempo limitado',
      'Gravidade invertida', 'Veneno no ar', 'Escuridao total', 'Silencio absoluto',
      'Ilusoes constantes', 'Terreno instavel', 'Frio extremo', 'Calor sufocante',
    ];

    for (int i = 1; i <= 100; i++) {
      final tierIdx = ((i - 1) ~/ 10); // 0-9
      final posInTier = (i - 1) % 10;  // 0-9
      final isBoss = posInTier == 9;    // a cada 10
      final isElite = posInTier == 4;   // a cada 5 (posicao 5 no tier)

      final patternIdx = tierIdx % tierPatterns.length;
      FloorType type = tierPatterns[patternIdx][posInTier];

      // Dificuldade base escala com andar
      // Formula inspirada em gacha: cresce exponencialmente apos tier 5
      double baseDiff;
      if (i <= 5) {
        baseDiff = 1.0 + i * 0.4; // 1.4 - 3.0
      } else if (i <= 15) {
        baseDiff = 2.0 + (i - 5) * 0.5; // 2.5 - 7.0
      } else if (i <= 30) {
        baseDiff = 5.0 + (i - 15) * 0.6; // 5.6 - 14.0
      } else if (i <= 50) {
        baseDiff = 10.0 + (i - 30) * 0.8; // 10.8 - 26.0
      } else if (i <= 75) {
        baseDiff = 20.0 + (i - 50) * 1.0; // 21.0 - 45.0
      } else {
        baseDiff = 35.0 + (i - 75) * 1.5; // 36.5 - 72.5
      }

      // Bosses e elites sao mais dificeis
      if (isBoss) {
        baseDiff *= 1.8;
      } else if (isElite) baseDiff *= 1.3;

      // Mortalidade escala
      double mortality;
      if (i <= 5) {
        mortality = 0.03 + i * 0.01;
      } else if (i <= 15) {
        mortality = 0.05 + (i - 5) * 0.01;
      } else if (i <= 30) {
        mortality = 0.08 + (i - 15) * 0.008;
      } else if (i <= 50) {
        mortality = 0.12 + (i - 30) * 0.006;
      } else if (i <= 75) {
        mortality = 0.18 + (i - 50) * 0.005;
      } else {
        mortality = 0.25 + (i - 75) * 0.006;
      }
      if (isBoss) {
        mortality *= 1.5;
      } else if (isElite) mortality *= 1.2;
      mortality = mortality.clamp(0.02, 0.60);

      // Descricao
      String desc;
      String reward;
      String condition;

      if (isBoss) {
        desc = bossDescriptions[tierIdx.clamp(0, 9)];
        reward = 'Tier ${tierIdx + 1} completo! Recompensas massivas. Cidadela evolui.';
        condition = 'BOSS - Requer preparacao maxima';
      } else {
        final nameList = floorNames[type] ?? ['Andar Desconhecido'];
        desc = '${nameList[posInTier % nameList.length]}. '
            'Tier ${tierIdx + 1} - Dificuldade ${i <= 5 ? "introdutoria" : i <= 15 ? "crescente" : i <= 30 ? "seria" : i <= 50 ? "brutal" : i <= 75 ? "infernal" : "impossivel"}.';
        reward = _generateReward(i, type, tierIdx);
        condition = isElite
            ? 'ELITE - Mini-boss antes do Boss do Tier'
            : specialConditions[rng.nextInt(specialConditions.length)];
      }

      floors.add(TowerFloor(
        number: i,
        type: type,
        difficulty: baseDiff,
        baseMortalityRate: mortality,
        description: desc,
        reward: reward,
        specialCondition: condition,
      ));
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

  // Manter compatibilidade - alias
  static List<TowerFloor> generateMvpFloors() => generate100Floors();
}

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
  })  : casualties = casualties ?? [],
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

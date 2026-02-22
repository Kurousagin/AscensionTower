enum FloorType {
  combat,
  moral,
  survival,
  strategic,
  mystery,
  boss,
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
    }
  }

  String get description {
    switch (this) {
      case FloorType.combat:
        return 'Criaturas hostis bloqueiam a passagem. Forca e estrategia sao necessarias.';
      case FloorType.moral:
        return 'Um dilema impossivel. Escolhas que definem o carater da humanidade.';
      case FloorType.survival:
        return 'Ambiente hostil. Resistencia e adaptabilidade sao a chave.';
      case FloorType.strategic:
        return 'Puzzles e armadilhas mecanicas. Inteligencia acima de tudo.';
      case FloorType.mystery:
        return 'Algo inexplicavel habita este andar. Cuidado com o desconhecido.';
      case FloorType.boss:
        return 'O guardiao do andar. Uma batalha que exigira tudo de voces.';
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
  }) : deadOnFloor = deadOnFloor ?? [];

  double get scaledDifficulty {
    final tierMultiplier = 1.0 + ((number - 1) ~/ 10) * 0.5;
    return difficulty * tierMultiplier;
  }

  double get scaledMortality {
    final tierMultiplier = 1.0 + ((number - 1) ~/ 10) * 0.3;
    return (baseMortalityRate * tierMultiplier).clamp(0.0, 0.8);
  }

  int get recommendedPartySize {
    if (number <= 3) return 3;
    if (number <= 6) return 4;
    if (number <= 9) return 5;
    return 6;
  }

  double get recommendedPower {
    return difficulty * 1.2 + (number * 0.5);
  }

  String get tierLabel {
    final tier = ((number - 1) ~/ 10) + 1;
    return 'Tier $tier';
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
      };

  factory TowerFloor.fromJson(Map<String, dynamic> json) => TowerFloor(
        number: json['number'] as int? ?? 1,
        type: FloorType.values[json['type'] as int? ?? 0],
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
      );

  static List<TowerFloor> generateMvpFloors() {
    return [
      TowerFloor(
        number: 1,
        type: FloorType.survival,
        difficulty: 2.0,
        baseMortalityRate: 0.05,
        description: 'As Ruinas Silenciosas. Um campo devastado com restos de civilizacao. Criaturas rastejantes espreitam nas sombras.',
        reward: '+15 Madeira, +10 Pedra',
        specialCondition: 'Visibilidade reduzida',
      ),
      TowerFloor(
        number: 2,
        type: FloorType.combat,
        difficulty: 3.0,
        baseMortalityRate: 0.08,
        description: 'O Corredor das Bestas. Criaturas deformadas patrulham corredores estreitos.',
        reward: '+20 Comida, +5 Ferro',
        specialCondition: 'Espaco estreito - max 4 no grupo',
      ),
      TowerFloor(
        number: 3,
        type: FloorType.moral,
        difficulty: 2.5,
        baseMortalityRate: 0.03,
        description: 'A Sala dos Espelhos. Cada espelho mostra o pior medo de quem olha. Alguns enlouquecem.',
        reward: '+15 Conhecimento, +10 Moral',
        specialCondition: 'Teste de Estabilidade Mental',
      ),
      TowerFloor(
        number: 4,
        type: FloorType.strategic,
        difficulty: 4.0,
        baseMortalityRate: 0.10,
        description: 'O Labirinto Mecanico. Engrenagens gigantes e armadilhas mortais. Logica e uma necessidade.',
        reward: '+10 Ferro, +10 Conhecimento',
        specialCondition: 'Requer INT > 6 no lider',
      ),
      TowerFloor(
        number: 5,
        type: FloorType.combat,
        difficulty: 5.0,
        baseMortalityRate: 0.12,
        description: 'A Arena Sangrenta. Sem escolha. Lutem ou morram. O chao esta manchado de batalhas anteriores.',
        reward: '+15 Ferro, +20 Fama para sobreviventes',
        specialCondition: 'Sem fuga possivel',
      ),
      TowerFloor(
        number: 6,
        type: FloorType.survival,
        difficulty: 5.5,
        baseMortalityRate: 0.10,
        description: 'O Pantano Toxico. Ar venenoso e agua acida. Cada passo e uma luta contra o ambiente.',
        reward: '+25 Comida (plantas raras), +5 Conhecimento',
        specialCondition: 'Dano continuo - Resistencia testada',
      ),
      TowerFloor(
        number: 7,
        type: FloorType.mystery,
        difficulty: 4.5,
        baseMortalityRate: 0.07,
        description: 'A Biblioteca Proibida. Tomos antigos com conhecimento perigoso. Ler demais pode destruir a mente.',
        reward: '+30 Conhecimento, chance de Talento Oculto',
        specialCondition: 'Risco de perda de sanidade',
      ),
      TowerFloor(
        number: 8,
        type: FloorType.moral,
        difficulty: 6.0,
        baseMortalityRate: 0.05,
        description: 'O Tribunal dos Pecados. A Torre julga seus invasores. Segredos sao revelados, lealdades testadas.',
        reward: '+20 Moral OU -20 Moral (depende da escolha)',
        specialCondition: 'Revela traicoes ocultas',
      ),
      TowerFloor(
        number: 9,
        type: FloorType.strategic,
        difficulty: 7.0,
        baseMortalityRate: 0.15,
        description: 'A Fortaleza das Sombras. Uma estrutura defensiva com inimigos inteligentes. Precisam pensar como generais.',
        reward: '+15 Ferro, +15 Pedra, Blueprint de edificio',
        specialCondition: 'Estrategia > Forca bruta',
      ),
      TowerFloor(
        number: 10,
        type: FloorType.boss,
        difficulty: 10.0,
        baseMortalityRate: 0.20,
        description: 'O GUARDIAO DO PRIMEIRO UMBRAL. Uma entidade massiva que testa o valor da humanidade. Muitos nao voltarao.',
        reward: '+50 todos recursos, Expansao da Cidadela, Revelacao',
        specialCondition: 'BOSS - Requer preparacao maxima',
      ),
    ];
  }
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

// floor_inhabitant.dart
// Sistema de Habitantes — Andares como Zonas Vivas
//
// DESIGN:
//   - FloorInhabitant é serializado dentro de TowerFloor (já tem toJson/fromJson)
//   - Sem dependência de floor_faction.dart ainda — stub FactionStanding incluído
//     para o sistema de facções poder ser plugado sem reescrever este arquivo
//   - GameState NÃO é importado aqui — GameEngine passa o que precisa como parâmetro
//     para evitar dependência circular

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum InhabitantCategory {
  resident,  // mora no andar, efeito passivo automático
  survivor,  // NPC de grupo que falhou — recrutável via Abrigo de Viajantes
  anomaly,   // entidade inexplicável — sempre gera fragmento de lore
}

enum InhabitantDisposition {
  friendly,
  neutral,
  hostile,
  unknown, // usado exclusivamente por anomalias
}

enum EffectType {
  resourceBonus,     // multiplica recursos da re-exploração
  loreFragment,      // gera fragmento de lore (anomalias + residentes)
  floorModifier,     // aplica tag temporária ao andar
  recruitmentReady,  // survivor aguarda recrutamento
  negativeIfHostile, // penaliza re-exploração quando hostil
}

// ---------------------------------------------------------------------------
// InhabitantEffect — efeito passivo aplicado automaticamente
// ---------------------------------------------------------------------------

class InhabitantEffect {
  final EffectType type;
  final double magnitude;    // ex: 1.25 = +25% recurso
  final String loreText;     // texto narrativo exibido ao jogador
  final String? floorModTag; // tag temporária aplicada ao TowerFloor

  const InhabitantEffect({
    required this.type,
    this.magnitude = 1.0,
    this.loreText = '',
    this.floorModTag,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'magnitude': magnitude,
    'loreText': loreText,
    'floorModTag': floorModTag,
  };

  factory InhabitantEffect.fromJson(Map<String, dynamic> json) =>
      InhabitantEffect(
        type: EffectType.values.firstWhere(
          (e) => e.name == (json['type'] as String? ?? 'loreFragment'),
          orElse: () => EffectType.loreFragment,
        ),
        magnitude: (json['magnitude'] as num?)?.toDouble() ?? 1.0,
        loreText: json['loreText'] as String? ?? '',
        floorModTag: json['floorModTag'] as String?,
      );
}

// ---------------------------------------------------------------------------
// SurvivorStats — stats de combate de quem sobreviveu sem auxílio
// ---------------------------------------------------------------------------

class SurvivorStats {
  final double combatPower;
  final double intelligence;
  final double endurance;
  final List<String> traits; // ex: ['battle-hardened', 'traumatized']
  double loyalty;            // inicia baixo, cresce na cidadela

  SurvivorStats({
    required this.combatPower,
    required this.intelligence,
    required this.endurance,
    required this.traits,
    this.loyalty = 15.0,
  });

  Map<String, dynamic> toJson() => {
    'combatPower': combatPower,
    'intelligence': intelligence,
    'endurance': endurance,
    'traits': traits,
    'loyalty': loyalty,
  };

  factory SurvivorStats.fromJson(Map<String, dynamic> json) => SurvivorStats(
    combatPower: (json['combatPower'] as num?)?.toDouble() ?? 10.0,
    intelligence: (json['intelligence'] as num?)?.toDouble() ?? 5.0,
    endurance: (json['endurance'] as num?)?.toDouble() ?? 5.0,
    traits: (json['traits'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    loyalty: (json['loyalty'] as num?)?.toDouble() ?? 15.0,
  );
}

// ---------------------------------------------------------------------------
// FloorInhabitant — modelo central
// ---------------------------------------------------------------------------

class FloorInhabitant {
  final String id;
  final String name;
  final String description;
  final InhabitantCategory category;
  InhabitantDisposition disposition;
  final InhabitantEffect effect;
  final SurvivorStats? survivorStats;

  // Estado de persistência
  bool isRecruited;
  bool hasDeparted;

  // ── Stub de facção (será preenchido quando FloorFaction for implementado) ──
  // Deixado como String? para não criar dependência antes do sistema existir.
  // Quando implementar facções, troque por FloorFaction? factionAffiliation.
  String? factionAffiliation; // ex: 'ironPact', 'silentOrder'

  FloorInhabitant({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.effect,
    this.disposition = InhabitantDisposition.neutral,
    this.survivorStats,
    this.isRecruited = false,
    this.hasDeparted = false,
    this.factionAffiliation,
  });

  bool get isActive => !isRecruited && !hasDeparted;

  bool get isRecruitable =>
      category == InhabitantCategory.survivor &&
      disposition != InhabitantDisposition.hostile &&
      !isRecruited;

  // ── Serialização ──────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'disposition': disposition.name,
    'effect': effect.toJson(),
    'survivorStats': survivorStats?.toJson(),
    'isRecruited': isRecruited,
    'hasDeparted': hasDeparted,
    'factionAffiliation': factionAffiliation,
  };

  factory FloorInhabitant.fromJson(Map<String, dynamic> json) {
    return FloorInhabitant(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Desconhecido',
      description: json['description'] as String? ?? '',
      category: InhabitantCategory.values.firstWhere(
        (e) => e.name == (json['category'] as String? ?? 'resident'),
        orElse: () => InhabitantCategory.resident,
      ),
      disposition: InhabitantDisposition.values.firstWhere(
        (e) => e.name == (json['disposition'] as String? ?? 'neutral'),
        orElse: () => InhabitantDisposition.neutral,
      ),
      effect: json['effect'] != null
          ? InhabitantEffect.fromJson(json['effect'] as Map<String, dynamic>)
          : const InhabitantEffect(type: EffectType.loreFragment),
      survivorStats: json['survivorStats'] != null
          ? SurvivorStats.fromJson(
              json['survivorStats'] as Map<String, dynamic>)
          : null,
      isRecruited: json['isRecruited'] as bool? ?? false,
      hasDeparted: json['hasDeparted'] as bool? ?? false,
      factionAffiliation: json['factionAffiliation'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// InhabitantEncounterResult — resultado para a UI
// ---------------------------------------------------------------------------

class InhabitantEncounterResult {
  final List<String> narrativeLines;
  final double resourceMultiplier;
  final List<String> loreFragments;
  final List<FloorInhabitant> recruitableSurvivors;

  const InhabitantEncounterResult({
    required this.narrativeLines,
    this.resourceMultiplier = 1.0,
    this.loreFragments = const [],
    this.recruitableSurvivors = const [],
  });

  bool get hasContent =>
      narrativeLines.isNotEmpty || loreFragments.isNotEmpty;
}

// ---------------------------------------------------------------------------
// InhabitantProcessor — lógica de processamento (chamado pelo GameEngine)
// ---------------------------------------------------------------------------

class InhabitantProcessor {
  /// Processa habitantes ativos durante re-exploração.
  /// [hasWayfareresRefuge]: GameEngine passa citadel.hasBuilding(wayfareresRefuge)
  static InhabitantEncounterResult process({
    required List<FloorInhabitant> inhabitants,
    required bool hasWayfareresRefuge,
    required int currentDay,
  }) {
    final narratives = <String>[];
    final lore = <String>[];
    final recruitable = <FloorInhabitant>[];
    double resourceMult = 1.0;

    _cycleAnomalies(inhabitants, currentDay);

    for (final inhabitant in inhabitants) {
      if (!inhabitant.isActive) continue;

      switch (inhabitant.category) {
        case InhabitantCategory.resident:
          narratives.add(inhabitant.description);

          if (inhabitant.effect.type == EffectType.resourceBonus &&
              inhabitant.disposition != InhabitantDisposition.hostile) {
            resourceMult *= inhabitant.effect.magnitude;
            if (inhabitant.effect.loreText.isNotEmpty) {
              narratives.add(inhabitant.effect.loreText);
            }
          }

          if (inhabitant.effect.type == EffectType.negativeIfHostile &&
              inhabitant.disposition == InhabitantDisposition.hostile) {
            resourceMult *= 0.5;
            narratives.add(
                '⚠️ ${inhabitant.name} está hostil. A exploração foi dificultada.');
          }

          if (inhabitant.effect.type == EffectType.loreFragment &&
              inhabitant.effect.loreText.isNotEmpty) {
            lore.add(inhabitant.effect.loreText);
          }
          break;

        case InhabitantCategory.survivor:
          narratives.add(inhabitant.description);
          if (inhabitant.effect.loreText.isNotEmpty) {
            lore.add(inhabitant.effect.loreText);
          }

          if (hasWayfareresRefuge && inhabitant.isRecruitable) {
            recruitable.add(inhabitant);
            narratives.add(
                '🏠 ${inhabitant.name} pode ser recrutado no Abrigo de Viajantes.');
          } else if (!hasWayfareresRefuge && inhabitant.isRecruitable) {
            narratives.add(
                '💬 ${inhabitant.name} pergunta se há um lugar seguro na sua cidadela. '
                '(Construa o Abrigo de Viajantes para recrutá-lo)');
          }
          break;

        case InhabitantCategory.anomaly:
          narratives.add(inhabitant.description);
          if (inhabitant.effect.loreText.isNotEmpty) {
            lore.add(inhabitant.effect.loreText);
          }
          // floorModTag é aplicado pelo GameEngine diretamente no TowerFloor
          break;
      }
    }

    return InhabitantEncounterResult(
      narrativeLines: narratives,
      resourceMultiplier: resourceMult,
      loreFragments: lore,
      recruitableSurvivors: recruitable,
    );
  }

  /// Atualiza disposição dos habitantes com base no standing de facção.
  /// [factionStanding]: -100 a +100. Null = sem facção associada ao andar.
  /// Chamado pelo GameEngine quando o standing muda (não só em re-exploração).
  static void updateForFactionStanding({
    required List<FloorInhabitant> inhabitants,
    required double? factionStanding,
  }) {
    final standing = factionStanding ?? 0.0;

    for (final inhabitant in inhabitants) {
      if (!inhabitant.isActive) continue;

      switch (inhabitant.category) {
        case InhabitantCategory.resident:
          if (standing >= 50) {
            inhabitant.disposition = InhabitantDisposition.friendly;
            inhabitant.hasDeparted = false;
          } else if (standing <= -30) {
            inhabitant.hasDeparted = true; // facção os expulsou
          } else {
            inhabitant.disposition = InhabitantDisposition.neutral;
          }
          break;

        case InhabitantCategory.survivor:
          if (standing <= -50) {
            inhabitant.hasDeparted = true; // capturado ou fugiu
          } else if (standing >= 30) {
            inhabitant.disposition = InhabitantDisposition.friendly;
          }
          break;

        case InhabitantCategory.anomaly:
          // Anomalias são imunes a facções
          break;
      }
    }
  }

  /// Ciclo das anomalias: independente de facção, aparecem e somem.
  static void _cycleAnomalies(
      List<FloorInhabitant> inhabitants, int currentDay) {
    for (final inhabitant in inhabitants) {
      if (inhabitant.category != InhabitantCategory.anomaly) continue;
      if (inhabitant.isRecruited) continue;

      final roll = _deterministicRoll(inhabitant.id, currentDay);

      if (inhabitant.hasDeparted && roll < 0.40) {
        inhabitant.hasDeparted = false;
      } else if (!inhabitant.hasDeparted && roll > 0.85) {
        inhabitant.hasDeparted = true;
      }
    }
  }

  /// Roll determinístico: mesma seed no mesmo dia = mesmo resultado.
  static double _deterministicRoll(String id, int day) {
    final hash = id.codeUnits.fold(0, (int a, int b) => a ^ b) + day * 7;
    return (hash.abs() % 100) / 100.0;
  }
}

// ---------------------------------------------------------------------------
// InhabitantFactory — catálogo de habitantes pré-definidos
// ---------------------------------------------------------------------------

class InhabitantFactory {
  // ── Andares 1-10: tutoriais e neutros ─────────────────────────

  static FloorInhabitant blindElder() => FloorInhabitant(
        id: 'resident_blind_elder',
        name: 'Velho de Olhos Brancos',
        description: 'Um velho de olhos brancos sentado na entrada. '
            'Não pede nada. Mas se você deixar comida, ele fala.',
        category: InhabitantCategory.resident,
        effect: const InhabitantEffect(
          type: EffectType.resourceBonus,
          magnitude: 1.25,
          loreText: '"Já vi mil grupos passarem por este andar. Metade nunca desceu."',
        ),
      );

  static FloorInhabitant towerChildren() => FloorInhabitant(
        id: 'resident_tower_children',
        name: 'Crianças da Torre',
        description:
            'Crianças jogam entre as ruínas. Observam em silêncio. '
            'Nenhum adulto está com elas.',
        category: InhabitantCategory.resident,
        effect: const InhabitantEffect(
          type: EffectType.loreFragment,
          loreText:
              'Uma delas aponta para cima. Quando você olha, ela some.',
        ),
      );

  // ── Survivors ─────────────────────────────────────────────────

  static FloorInhabitant dara({int floorNumber = 20}) => FloorInhabitant(
        id: 'survivor_dara_f$floorNumber',
        name: 'Dara',
        description:
            'Dara. De uma expedição que desapareceu há 40 dias. '
            'Está viva. Assustada. Tem marcas de combate recentes.',
        category: InhabitantCategory.survivor,
        disposition: InhabitantDisposition.friendly,
        effect: InhabitantEffect(
          type: EffectType.recruitmentReady,
          loreText:
              '"O Andar ${floorNumber + 1} não é o que parece. Há algo esperando lá."',
        ),
        survivorStats: SurvivorStats(
          combatPower: 7.2,
          intelligence: 5.5,
          endurance: 6.0,
          traits: ['battle-hardened', 'traumatized', 'tower-knowledge'],
          loyalty: 18.0,
        ),
      );

  static FloorInhabitant unknownSoldier({required int floorNumber}) =>
      FloorInhabitant(
        id: 'survivor_soldier_f$floorNumber',
        name: 'Soldado Sem Nome',
        description:
            'Um homem com armadura destruída sentado com as costas contra a parede. '
            'Não diz de onde veio. Apenas observa quem passa.',
        category: InhabitantCategory.survivor,
        disposition: InhabitantDisposition.neutral,
        effect: const InhabitantEffect(
          type: EffectType.recruitmentReady,
          loreText: '"Vocês têm uma cidadela? Pensava que não existia mais nenhuma."',
        ),
        survivorStats: SurvivorStats(
          combatPower: 8.5,
          intelligence: 4.0,
          endurance: 7.0,
          traits: ['battle-hardened', 'silent', 'loyal'],
          loyalty: 12.0,
        ),
      );

  // ── Anomalias ─────────────────────────────────────────────────

  static FloorInhabitant sittingFigure() => FloorInhabitant(
        id: 'anomaly_sitting_figure',
        name: 'Figura Sentada',
        description:
            'Uma figura de costas para a entrada. Imóvel. '
            'Seus exploradores passaram três vezes. '
            'Na quarta visita, havia ido embora. Deixou uma marca.',
        category: InhabitantCategory.anomaly,
        disposition: InhabitantDisposition.unknown,
        effect: const InhabitantEffect(
          type: EffectType.floorModifier,
          loreText:
              'A marca na parede não estava lá antes. Ninguém sabe o que significa.',
          floorModTag: 'anomaly_presence',
        ),
      );

  static FloorInhabitant echoVoice() => FloorInhabitant(
        id: 'anomaly_echo_voice',
        name: 'Voz sem Corpo',
        description:
            'Uma voz repete as últimas palavras ditas por cada explorador. '
            'Não há fonte visível. Não há ameaça. Apenas o eco.',
        category: InhabitantCategory.anomaly,
        disposition: InhabitantDisposition.unknown,
        effect: const InhabitantEffect(
          type: EffectType.loreFragment,
          loreText:
              'A voz repete: "...não voltem para este andar..." '
              '— mas ninguém de seu grupo disse isso.',
        ),
      );

  // ── Geração procedural por tier ──────────────────────────────

  /// Gera um inhabitant apropriado para o andar e tier.
  /// Chamado em TowerFloor.generateInhabitants().
  static FloorInhabitant generateForFloor({
    required int floorNumber,
    required int tier,
    required int seed,
  }) {
    // Seed determinística para consistência entre sessões
    final roll = (seed * 31 + floorNumber * 7) % 100;

    // Distribuição: 50% resident, 30% survivor, 20% anomaly
    if (roll < 50) {
      return _generateResident(floorNumber, tier, seed);
    } else if (roll < 80) {
      return _generateSurvivor(floorNumber, tier, seed);
    } else {
      return _generateAnomaly(floorNumber, seed);
    }
  }

  static FloorInhabitant _generateResident(
      int floor, int tier, int seed) {
    final variants = [
      FloorInhabitant(
        id: 'resident_trader_f$floor',
        name: 'Comerciante Errante',
        description: 'Um mercador que encontrou seu nicho entre os andares. '
            'Não sobe. Não desce. Apenas troca.',
        category: InhabitantCategory.resident,
        effect: InhabitantEffect(
          type: EffectType.resourceBonus,
          magnitude: 1.0 + (tier * 0.1),
          loreText:
              '"Você quer saber o que está no próximo andar? '
              'Custa caro. Mas é informação que salva vidas."',
        ),
      ),
      FloorInhabitant(
        id: 'resident_hermit_f$floor',
        name: 'Eremita da Torre',
        description:
            'Alguém que desistiu de subir mas recusou a descer. '
            'Vive aqui. Não incomoda ninguém.',
        category: InhabitantCategory.resident,
        effect: InhabitantEffect(
          type: EffectType.loreFragment,
          loreText:
              '"Este andar tem memória. Cuidado com o que você faz aqui."',
        ),
      ),
      FloorInhabitant(
        id: 'resident_smith_f$floor',
        name: 'Ferreiro Mudo',
        description:
            'Não fala. Não reage. Mas aceita ferro e devolve algo melhor. '
            'Ninguém sabe como chegou aqui.',
        category: InhabitantCategory.resident,
        effect: InhabitantEffect(
          type: EffectType.resourceBonus,
          magnitude: 1.0 + (tier * 0.15),
        ),
      ),
    ];

    return variants[seed % variants.length];
  }

  static FloorInhabitant _generateSurvivor(
      int floor, int tier, int seed) {
    // Stats escalam com o tier — quem sobreviveu num andar mais alto é mais forte
    final basePower = 5.0 + (tier * 1.5);
    final baseEndurance = 4.0 + (tier * 1.0);

    final names = [
      'Mira',
      'Tarek',
      'Asha',
      'Velon',
      'Cael',
      'Nora',
      'Fen',
      'Lira',
    ];
    final name = names[seed % names.length];

    final traitSets = [
      ['battle-hardened', 'traumatized'],
      ['battle-hardened', 'resourceful'],
      ['traumatized', 'cautious'],
      ['resourceful', 'tower-knowledge'],
    ];

    return FloorInhabitant(
      id: 'survivor_${name.toLowerCase()}_f$floor',
      name: name,
      description:
          '$name sobreviveu no Andar $floor por conta própria. '
          'Os mantimentos acabaram. A esperança, quase.',
      category: InhabitantCategory.survivor,
      disposition: InhabitantDisposition.neutral,
      effect: InhabitantEffect(
        type: EffectType.recruitmentReady,
        loreText:
            '"Se você tem um lugar para eu ir... ainda me lembro de como lutar."',
      ),
      survivorStats: SurvivorStats(
        combatPower: basePower + (seed % 3),
        intelligence: 3.0 + (seed % 4),
        endurance: baseEndurance + (seed % 3),
        traits: traitSets[seed % traitSets.length],
        loyalty: 10.0 + (seed % 10).toDouble(),
      ),
    );
  }

  static FloorInhabitant _generateAnomaly(int floor, int seed) {
    final anomalies = [
      FloorInhabitant(
        id: 'anomaly_mirror_f$floor',
        name: 'Reflexo Sem Origem',
        description:
            'Um reflexo na parede. Mas não há espelho. '
            'Imita os movimentos do último explorador que entrou.',
        category: InhabitantCategory.anomaly,
        disposition: InhabitantDisposition.unknown,
        effect: const InhabitantEffect(
          type: EffectType.loreFragment,
          loreText: 'O reflexo acena. Ninguém acenou primeiro.',
        ),
      ),
      FloorInhabitant(
        id: 'anomaly_counter_f$floor',
        name: 'Contador',
        description:
            'Um número na parede. Muda a cada visita. '
            'Decresce. Ninguém sabe o que acontece quando chegar a zero.',
        category: InhabitantCategory.anomaly,
        disposition: InhabitantDisposition.unknown,
        effect: const InhabitantEffect(
          type: EffectType.floorModifier,
          loreText: 'O número desta vez é menor que da última visita.',
          floorModTag: 'anomaly_countdown',
        ),
      ),
      FloorInhabitant(
        id: 'anomaly_light_f$floor',
        name: 'Luz Sem Fonte',
        description:
            'Uma luz flutua no centro do andar. Não aquece. Não ilumina. '
            'Apenas existe.',
        category: InhabitantCategory.anomaly,
        disposition: InhabitantDisposition.unknown,
        effect: const InhabitantEffect(
          type: EffectType.loreFragment,
          loreText:
              'A luz piscou quando alguém mencionou o andar 100. '
              'Só uma vez. Depois parou.',
        ),
      ),
    ];

    return anomalies[seed % anomalies.length];
  }
}
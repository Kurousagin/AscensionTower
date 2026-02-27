// floor_faction.dart
// Sistema de Facções — Geopolítica Vertical da Torre
//
// DESIGN:
//   - FloorFaction: enum das facções disponíveis
//   - FactionRelation: estado do relacionamento cidadela ↔ facção
//   - FactionConfig: personalidade e lógica de cada facção
//   - FactionProcessor: lógica de interação chamada pelo GameEngine
//   - Serialização: tudo por .name, compatível com saves antigos

// ---------------------------------------------------------------------------
// FloorFaction
// ---------------------------------------------------------------------------

enum FloorFaction {
  none,
  ironPact,      // militarista — respeita força bruta
  silentOrder,   // intelectual — respeita conhecimento e inteligência
  bloodMarket,   // mercantil — respeita recursos e trocas
  voidChildren,  // caótico — imprevisível, regras próprias
  towerServants, // aliados da Torre — perigosos, recompensas únicas
}

extension FloorFactionExt on FloorFaction {
  String get label => const {
    FloorFaction.none: 'Neutro',
    FloorFaction.ironPact: 'Pacto de Ferro',
    FloorFaction.silentOrder: 'Ordem Silenciosa',
    FloorFaction.bloodMarket: 'Mercado de Sangue',
    FloorFaction.voidChildren: 'Filhos do Vazio',
    FloorFaction.towerServants: 'Servos da Torre',
  }[this]!;

  String get shortLabel => const {
    FloorFaction.none: 'Neutro',
    FloorFaction.ironPact: 'Ferro',
    FloorFaction.silentOrder: 'Ordem',
    FloorFaction.bloodMarket: 'Mercado',
    FloorFaction.voidChildren: 'Vazio',
    FloorFaction.towerServants: 'Torre',
  }[this]!;

  String get description => const {
    FloorFaction.none: 'Andar sem controle de facção.',
    FloorFaction.ironPact:
        'Guerreiros que testam força antes de qualquer coisa. '
        'Respeito é ganho com poder de combate.',
    FloorFaction.silentOrder:
        'Estudiosos que rejeitam a brutalidade. '
        'Aqui, inteligência e conhecimento abrem portas.',
    FloorFaction.bloodMarket:
        'Comerciantes que valorizam recursos acima de tudo. '
        'Tudo tem preço. Tudo pode ser negociado.',
    FloorFaction.voidChildren:
        'Entidades do caos. Suas reações são imprevisíveis. '
        'Podem ser aliadas num dia e inimigas no outro.',
    FloorFaction.towerServants:
        'Servem à própria Torre. Não atacam quem a respeita. '
        'Oferecem recompensas únicas — por um preço alto.',
  }[this]!;

  /// Atributo primário que esta facção respeita
  String get primaryAttribute => const {
    FloorFaction.none: '',
    FloorFaction.ironPact: 'combatPower',
    FloorFaction.silentOrder: 'intelligence',
    FloorFaction.bloodMarket: 'resources',
    FloorFaction.voidChildren: 'luck',
    FloorFaction.towerServants: 'fame',
  }[this]!;

  /// Standing inicial ao encontrar essa facção pela primeira vez
  double get initialStanding => const {
    FloorFaction.none: 0.0,
    FloorFaction.ironPact: 0.0,
    FloorFaction.silentOrder: 0.0,
    FloorFaction.bloodMarket: 10.0,  // mercadores preferem parceiros a inimigos
    FloorFaction.voidChildren: -10.0, // caóticos são levemente hostis por padrão
    FloorFaction.towerServants: -20.0, // servos da Torre desconfiam de intrusos
  }[this]!;
}

// ---------------------------------------------------------------------------
// FactionRelation — estado persistente por facção
// ---------------------------------------------------------------------------

class FactionRelation {
  final FloorFaction faction;
  double standing;           // -100 (guerra) a +100 (aliado)
  int totalInteractions;
  bool hasTreaty;
  int lastInteractionDay;
  int incursionsCaused;      // quantas incursões essa facção já fez

  FactionRelation({
    required this.faction,
    double? standing,
    this.totalInteractions = 0,
    this.hasTreaty = false,
    this.lastInteractionDay = 0,
    this.incursionsCaused = 0,
  }) : standing = standing ?? faction.initialStanding;

  // Tier de relacionamento legível
  FactionTier get tier {
    if (standing >= 80) return FactionTier.ally;
    if (standing >= 50) return FactionTier.friendly;
    if (standing >= 10) return FactionTier.neutral;
    if (standing >= -10) return FactionTier.cautious;
    if (standing >= -30) return FactionTier.hostile;
    if (standing >= -60) return FactionTier.atWar;
    return FactionTier.bloodFeud;
  }

  Map<String, dynamic> toJson() => {
    'faction': faction.name,
    'standing': standing,
    'totalInteractions': totalInteractions,
    'hasTreaty': hasTreaty,
    'lastInteractionDay': lastInteractionDay,
    'incursionsCaused': incursionsCaused,
  };

  factory FactionRelation.fromJson(Map<String, dynamic> json) {
    final factionName = json['faction'] as String? ?? 'none';
    final faction = FloorFaction.values.firstWhere(
      (e) => e.name == factionName,
      orElse: () => FloorFaction.none,
    );
    return FactionRelation(
      faction: faction,
      standing: (json['standing'] as num?)?.toDouble() ?? faction.initialStanding,
      totalInteractions: json['totalInteractions'] as int? ?? 0,
      hasTreaty: json['hasTreaty'] as bool? ?? false,
      lastInteractionDay: json['lastInteractionDay'] as int? ?? 0,
      incursionsCaused: json['incursionsCaused'] as int? ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// FactionTier — tier de relacionamento legível para UI
// ---------------------------------------------------------------------------

enum FactionTier {
  ally,
  friendly,
  neutral,
  cautious,
  hostile,
  atWar,
  bloodFeud,
}

extension FactionTierExt on FactionTier {
  String get label => const {
    FactionTier.ally: 'Aliado',
    FactionTier.friendly: 'Amigável',
    FactionTier.neutral: 'Neutro',
    FactionTier.cautious: 'Cauteloso',
    FactionTier.hostile: 'Hostil',
    FactionTier.atWar: 'Em Guerra',
    FactionTier.bloodFeud: 'Vendeta',
  }[this]!;
}

// ---------------------------------------------------------------------------
// FactionInteractionResult — resultado de uma interação para o GameEngine
// ---------------------------------------------------------------------------

class FactionInteractionResult {
  final FloorFaction faction;
  final double standingDelta;      // quanto o standing mudou (+/-)
  final double successChanceMod;   // modificador em attemptFloor
  final double mortalityMod;       // modificador de mortalidade
  final double resourceMod;        // multiplicador de recursos (re-exploração)
  final double foodTribute;        // custo extra de comida (pedágio)
  final List<String> narrativeLines;
  final bool triggeredIncursion;

  const FactionInteractionResult({
    required this.faction,
    this.standingDelta = 0,
    this.successChanceMod = 0,
    this.mortalityMod = 0,
    this.resourceMod = 1.0,
    this.foodTribute = 0,
    this.narrativeLines = const [],
    this.triggeredIncursion = false,
  });
}

// ---------------------------------------------------------------------------
// FactionProcessor — toda a lógica de interação
// ---------------------------------------------------------------------------

class FactionProcessor {
  /// Calcula o resultado de uma tentativa de conquista de andar.
  /// Chamado por GameEngine.attemptFloor() antes de calcular successChance.
  static FactionInteractionResult processFloorAttempt({
    required FloorFaction faction,
    required FactionRelation? relation,
    required double partyPower,
    required double partyIntelligence,
    required double partyResources, // comida disponível no momento
    required double partyFame,
    required double partyLuck,
    required int currentDay,
  }) {
    if (faction == FloorFaction.none) {
      return const FactionInteractionResult(faction: FloorFaction.none);
    }

    final standing = relation?.standing ?? faction.initialStanding;
    final narratives = <String>[];
    double standingDelta = 0;
    double successMod = 0;
    double mortalityMod = 0;
    double foodTribute = 0;

    // ── Efeitos por tier de standing ───────────────────────────────────────
    if (standing >= 80) {
      successMod = 0.20;
      mortalityMod = -0.30;
      narratives.add(
          '🤝 ${faction.label} reconhece seus aliados. Abrem caminho.');
    } else if (standing >= 50) {
      // Amigável: sem penalidade, sem bônus
    } else if (standing >= 10) {
      // Neutro-cauteloso: facção cobra pedágio pequeno
      foodTribute = 5.0;
      narratives.add(
          '💰 ${faction.label} cobra passagem. (−${foodTribute.toStringAsFixed(0)} comida)');
    } else if (standing >= -10) {
      // Cauteloso: sem efeito mecânico, apenas narrativa
      narratives.add('👁 ${faction.label} observa com desconfiança.');
    } else if (standing >= -30) {
      successMod = -0.15;
      narratives.add(
          '⚔️ ${faction.label} dificulta a passagem. (−15% chance de sucesso)');
    } else if (standing >= -60) {
      successMod = -0.20;
      mortalityMod = 0.20;
      narratives.add(
          '🩸 ${faction.label} está HOSTIL. Emboscada possível. (−20% sucesso, +20% mortalidade)');
    } else {
      successMod = -0.30;
      mortalityMod = 0.35;
      narratives.add(
          '💀 VENDETA: ${faction.label} luta para MATAR. (−30% sucesso, +35% mortalidade)');
    }

    // ── Modificadores específicos de facção ────────────────────────────────
    switch (faction) {
      case FloorFaction.ironPact:
        // Respeita força: poder de combate alto ganha standing
        if (partyPower >= 15) {
          standingDelta += 3;
          narratives.add(
              '⚔️ Pacto de Ferro impressionado com seu poder. (+3 standing)');
        } else if (partyPower < 5) {
          standingDelta -= 2;
          narratives.add('⚔️ Pacto de Ferro despreza os fracos. (−2 standing)');
        }
        break;

      case FloorFaction.silentOrder:
        // Respeita inteligência: penaliza força bruta
        if (partyIntelligence >= 8) {
          standingDelta += 3;
          successMod += 0.05;
          narratives.add(
              '📚 Ordem Silenciosa reconhece mentes aguçadas. (+3 standing, +5% sucesso)');
        } else if (partyPower > partyIntelligence * 2) {
          standingDelta -= 3;
          successMod -= 0.10;
          narratives.add(
              '📚 Ordem Silenciosa despreza brutos. (−3 standing, −10% sucesso)');
        }
        break;

      case FloorFaction.bloodMarket:
        // Respeita recursos: pagar voluntariamente aumenta standing
        if (partyResources >= 50) {
          final voluntaryTribute = 8.0;
          foodTribute += voluntaryTribute;
          standingDelta += 5;
          narratives.add(
              '💰 Mercado de Sangue aceita pagamento generoso. (+5 standing)');
        }
        break;

      case FloorFaction.voidChildren:
        // Caótico: standing oscila aleatoriamente ±5 a cada interação
        // (seed determinística baseada no dia para consistência)
        final voidSeed = (currentDay * 31 + 17) % 11 - 5; // -5 a +5
        standingDelta += voidSeed.toDouble();
        if (voidSeed > 0) {
          narratives.add(
              '🌀 Filhos do Vazio estão... curiosos hoje. (+$voidSeed standing)');
        } else if (voidSeed < 0) {
          narratives.add(
              '🌀 Filhos do Vazio estão agitados. ($voidSeed standing)');
        } else {
          narratives.add('🌀 Filhos do Vazio observam em silêncio absoluto.');
        }
        break;

      case FloorFaction.towerServants:
        // Respeita fama: NPCs famosos passam mais fácil
        if (partyFame >= 50) {
          successMod += 0.15;
          standingDelta += 4;
          narratives.add(
              '🏛 Servos da Torre curvam-se diante da fama. (+4 standing, +15% sucesso)');
        } else if (partyFame < 10) {
          successMod -= 0.10;
          narratives.add('🏛 Servos da Torre não reconhecem ninguém do grupo.');
        }
        break;

      case FloorFaction.none:
        break;
    }

    return FactionInteractionResult(
      faction: faction,
      standingDelta: standingDelta,
      successChanceMod: successMod,
      mortalityMod: mortalityMod,
      resourceMod: 1.0,
      foodTribute: foodTribute,
      narrativeLines: narratives,
    );
  }

  /// Calcula resultado de re-exploração em andar com facção.
  /// Chamado por GameEngine.reexploreFloor().
  static FactionInteractionResult processReexploration({
    required FloorFaction faction,
    required FactionRelation? relation,
    required double partyPower,
    required double partyIntelligence,
    required int currentDay,
  }) {
    if (faction == FloorFaction.none) {
      return const FactionInteractionResult(faction: FloorFaction.none);
    }

    final standing = relation?.standing ?? faction.initialStanding;
    final narratives = <String>[];
    double resourceMod = 1.0;
    double standingDelta = 0;

    if (standing >= 80) {
      resourceMod = 1.30;
      standingDelta = 0.5; // crescimento lento de standing via re-exploração
      narratives.add(
          '🤝 ${faction.label} guia seus exploradores. (+30% recursos)');
    } else if (standing >= 50) {
      resourceMod = 1.10;
      narratives.add('🤝 ${faction.label} permite livre acesso. (+10% recursos)');
    } else if (standing <= -30) {
      resourceMod = 0.70;
      standingDelta = -1; // re-explorar território inimigo piora relação
      narratives.add(
          '⚠️ ${faction.label} interfere na coleta. (−30% recursos, −1 standing)');
    } else if (standing <= -60) {
      resourceMod = 0.40;
      standingDelta = -2;
      narratives.add(
          '🩸 ${faction.label} sabota ativamente. (−60% recursos, −2 standing)');
    }

    // Fação bloodMarket tem bônus específico em re-exploração se aliado
    if (faction == FloorFaction.bloodMarket && standing >= 50) {
      resourceMod *= 1.10;
      narratives.add('💰 Rede comercial do Mercado de Sangue amplia coleta.');
    }

    return FactionInteractionResult(
      faction: faction,
      standingDelta: standingDelta,
      resourceMod: resourceMod,
      narrativeLines: narratives,
    );
  }

  /// Verifica se deve gerar incursão à cidadela neste dia.
  static bool shouldIncurse({
    required FactionRelation relation,
    required int currentDay,
    required int incursionCooldownDays,
  }) {
    if (relation.standing > -60) return false;
    if (currentDay % incursionCooldownDays != 0) return false;
    return true;
  }

  /// Distribui facção controladora para um andar dado seu número e tier.
  /// Seed fixa: mesma entrada = mesmo resultado sempre.
  static FloorFaction factionForFloor(int floorNumber, int tierIdx) {
    // Tutorial (1-5) e bosses (múltiplos de 10): sempre neutro
    if (floorNumber <= 5 || floorNumber % 10 == 0) return FloorFaction.none;

    final tierFactions = [
      FloorFaction.ironPact,      // tier 1: andares 1-10
      FloorFaction.silentOrder,   // tier 2: andares 11-20
      FloorFaction.bloodMarket,   // tier 3: andares 21-30
      FloorFaction.ironPact,      // tier 4: andares 31-40 (retorna mais forte)
      FloorFaction.voidChildren,  // tier 5: andares 41-50
      FloorFaction.towerServants, // tier 6+: andares 51+
    ];

    final base = tierFactions[tierIdx.clamp(0, tierFactions.length - 1)];

    final seed = (floorNumber * 17 + tierIdx * 3) % 100;

    // 30% de chance de andar neutro dentro do tier
    if (seed < 30) return FloorFaction.none;

    // 15% de chance de facção diferente (conflito territorial)
    if (seed > 85) {
      // Facção aleatória diferente da base
      final others = FloorFaction.values
          .where((f) => f != FloorFaction.none && f != base)
          .toList();
      return others[seed % others.length];
    }

    return base;
  }
}
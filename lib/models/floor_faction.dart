// floor_faction.dart
// Sistema de Facções — Geopolítica Vertical da Torre
import 'package:flutter/material.dart';
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
  ironPact,
  silentOrder,
  bloodMarket,
  voidChildren,
  towerServants;

  String get key => switch (this) {
    FloorFaction.none => 'none',
    FloorFaction.ironPact => 'ironPact',
    FloorFaction.silentOrder => 'silentOrder',
    FloorFaction.bloodMarket => 'bloodMarket',
    FloorFaction.voidChildren => 'voidChildren',
    FloorFaction.towerServants => 'towerServants',
  };
}

enum DiplomacyOfferType {
  payTribute, // Paga recursos por melhora de standing
  sendGoodwillMission, // Envia grupo forte como demonstração (IronPact)
  donateKnowledge, // Oferece conhecimento acumulado (SilentOrder)
  proposeNonAggression, // Tratado simples; custo fixo de comida
  challengeToTrial, // Enfrenta trial (só TowerServants)
}

class DiplomacyOffer {
  final DiplomacyOfferType type;
  final Map<String, double> resourceCost; // ex: {'food': 30, 'iron': 10}
  final double standingGain;
  final double successChance; // 0.0–1.0
  final String description;

  const DiplomacyOffer({
    required this.type,
    required this.resourceCost,
    required this.standingGain,
    required this.successChance,
    required this.description,
  });
}

extension FloorFactionExt on FloorFaction {
  Color get color => {
    FloorFaction.none: const Color(0xFF666666),
    FloorFaction.ironPact: const Color(0xFFCC4444),
    FloorFaction.silentOrder: const Color(0xFF4488CC),
    FloorFaction.bloodMarket: const Color(0xFFCC8844),
    FloorFaction.voidChildren: const Color(0xFF8844CC),
    FloorFaction.towerServants: const Color(0xFF44CCAA),
  }[this]!;

  IconData get icon => {
    FloorFaction.none: Icons.help_outline,
    FloorFaction.ironPact: Icons.shield,
    FloorFaction.silentOrder: Icons.auto_stories,
    FloorFaction.bloodMarket: Icons.storefront,
    FloorFaction.voidChildren: Icons.blur_on,
    FloorFaction.towerServants: Icons.account_balance,
  }[this]!;

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
    FloorFaction.bloodMarket: 10.0, // mercadores preferem parceiros a inimigos
    FloorFaction.voidChildren:
        -10.0, // caóticos são levemente hostis por padrão
    FloorFaction.towerServants: -20.0, // servos da Torre desconfiam de intrusos
  }[this]!;
}

// ---------------------------------------------------------------------------
// FactionRelation — estado persistente por facção
// ---------------------------------------------------------------------------

class FactionRelation {
  final FloorFaction faction;
  double standing; // -100 (guerra) a +100 (aliado)
  int totalInteractions;
  bool hasTreaty;
  int lastInteractionDay;
  int incursionsCaused; // quantas incursões essa facção já fez
  int lastDiplomacyDay;
  int treatyStartDay;
  Set<String> rewardsGranted;

  FactionRelation({
    required this.faction,
    double? standing,
    this.totalInteractions = 0,
    this.hasTreaty = false,
    this.lastInteractionDay = 0,
    this.incursionsCaused = 0,
    this.treatyStartDay = 0,
    this.lastDiplomacyDay = 0, // ← linha nova
    Set<String>? rewardsGranted,
  }) : standing = standing ?? faction.initialStanding,
       rewardsGranted = rewardsGranted ?? {};

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

  static FactionRelation copyOf(FactionRelation original) {
    return FactionRelation(
      faction: original.faction,
      standing: original.standing,
      totalInteractions: original.totalInteractions,
      hasTreaty: original.hasTreaty,
      lastInteractionDay: original.lastInteractionDay,
      incursionsCaused: original.incursionsCaused,
      treatyStartDay: original.treatyStartDay,
      lastDiplomacyDay: original.lastDiplomacyDay, // ← linha nova
      rewardsGranted: Set.from(original.rewardsGranted),
    );
  }

  Map<String, dynamic> toJson() => {
    'faction': faction.key,
    'standing': standing,
    'totalInteractions': totalInteractions,
    'hasTreaty': hasTreaty,
    'lastInteractionDay': lastInteractionDay,
    'incursionsCaused': incursionsCaused,
    'treatyStartDay': treatyStartDay,
    'lastDiplomacyDay': lastDiplomacyDay, // ← linha nova
    'rewardsGranted': rewardsGranted.toList(),
  };

  factory FactionRelation.fromJson(Map<String, dynamic> json) {
    final factionName = json['faction'] as String? ?? 'none';
    final faction = FloorFaction.values.firstWhere(
      (e) => e.key == factionName,
      orElse: () => FloorFaction.none,
    );
    return FactionRelation(
      faction: faction,
      standing:
          (json['standing'] as num?)?.toDouble() ?? faction.initialStanding,
      totalInteractions: json['totalInteractions'] as int? ?? 0,
      hasTreaty: json['hasTreaty'] as bool? ?? false,
      lastInteractionDay: json['lastInteractionDay'] as int? ?? 0,
      incursionsCaused: json['incursionsCaused'] as int? ?? 0,
      treatyStartDay: json['treatyStartDay'] as int? ?? 0,
      lastDiplomacyDay: json['lastDiplomacyDay'] as int? ?? 0, // ← linha nova
      rewardsGranted: Set<String>.from(
        (json['rewardsGranted'] as List<dynamic>? ?? []),
      ),
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
  Color get color => {
    FactionTier.ally: const Color(0xFF44FF88),
    FactionTier.friendly: const Color(0xFF88FF44),
    FactionTier.neutral: const Color(0xFF888888),
    FactionTier.cautious: const Color(0xFFFFDD44),
    FactionTier.hostile: const Color(0xFFFF8844),
    FactionTier.atWar: const Color(0xFFFF4444),
    FactionTier.bloodFeud: const Color(0xFFCC0000),
  }[this]!;

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
  final double standingDelta; // quanto o standing mudou (+/-)
  final double successChanceMod; // modificador em attemptFloor
  final double mortalityMod; // modificador de mortalidade
  final double resourceMod; // multiplicador de recursos (re-exploração)
  final double foodTribute; // custo extra de comida (pedágio)
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
        '🤝 ${faction.label} reconhece seus aliados. Abrem caminho.',
      );
    } else if (standing >= 50) {
      // Amigável: sem penalidade, sem bônus
    } else if (standing >= 10) {
      // Neutro-cauteloso: facção cobra pedágio pequeno
      foodTribute = 5.0;
      narratives.add(
        '💰 ${faction.label} cobra passagem. (−${foodTribute.toStringAsFixed(0)} comida)',
      );
    } else if (standing >= -10) {
      // Cauteloso: sem efeito mecânico, apenas narrativa
      narratives.add('👁 ${faction.label} observa com desconfiança.');
    } else if (standing >= -30) {
      successMod = -0.15;
      narratives.add(
        '⚔️ ${faction.label} dificulta a passagem. (−15% chance de sucesso)',
      );
    } else if (standing >= -60) {
      successMod = -0.20;
      mortalityMod = 0.20;
      narratives.add(
        '🩸 ${faction.label} está HOSTIL. Emboscada possível. (−20% sucesso, +20% mortalidade)',
      );
    } else {
      successMod = -0.30;
      mortalityMod = 0.35;
      narratives.add(
        '💀 VENDETA: ${faction.label} luta para MATAR. (−30% sucesso, +35% mortalidade)',
      );
    }

    // ── Modificadores específicos de facção ────────────────────────────────
    switch (faction) {
      case FloorFaction.ironPact:
        // Respeita força: poder de combate alto ganha standing
        if (partyPower >= 15) {
          standingDelta += 3;
          narratives.add(
            '⚔️ Pacto de Ferro impressionado com seu poder. (+3 standing)',
          );
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
            '📚 Ordem Silenciosa reconhece mentes aguçadas. (+3 standing, +5% sucesso)',
          );
        } else if (partyPower > partyIntelligence * 2) {
          standingDelta -= 3;
          successMod -= 0.10;
          narratives.add(
            '📚 Ordem Silenciosa despreza brutos. (−3 standing, −10% sucesso)',
          );
        }
        break;

      case FloorFaction.bloodMarket:
        // Respeita recursos: pagar voluntariamente aumenta standing
        if (partyResources >= 50) {
          final voluntaryTribute = 8.0;
          foodTribute += voluntaryTribute;
          standingDelta += 5;
          narratives.add(
            '💰 Mercado de Sangue aceita pagamento generoso. (+5 standing)',
          );
        }
        break;

      case FloorFaction.voidChildren:
        // Caótico: standing oscila aleatoriamente ±5 a cada interação
        // (seed determinística baseada no dia para consistência)
        final voidSeed = (currentDay * 31 + 17) % 11 - 5; // -5 a +5
        standingDelta += voidSeed.toDouble();
        if (voidSeed > 0) {
          narratives.add(
            '🌀 Filhos do Vazio estão... curiosos hoje. (+$voidSeed standing)',
          );
        } else if (voidSeed < 0) {
          narratives.add(
            '🌀 Filhos do Vazio estão agitados. ($voidSeed standing)',
          );
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
            '🏛 Servos da Torre curvam-se diante da fama. (+4 standing, +15% sucesso)',
          );
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
        '🤝 ${faction.label} guia seus exploradores. (+30% recursos)',
      );
    } else if (standing >= 50) {
      resourceMod = 1.10;
      narratives.add(
        '🤝 ${faction.label} permite livre acesso. (+10% recursos)',
      );
    } else if (standing <= -60) {
      // ← mais severo primeiro
      resourceMod = 0.40;
      standingDelta = -2;
      narratives.add(
        '🩸 ${faction.label} sabota ativamente. (−60% recursos, −2 standing)',
      );
    } else if (standing <= -30) {
      resourceMod = 0.70;
      standingDelta = -1;
      narratives.add(
        '⚠️ ${faction.label} interfere na coleta. (−30% recursos, −1 standing)',
      );
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

  static bool shouldIncurse({
    required FactionRelation relation,
    required int currentDay,
    required int incursionCooldownDays,
  }) {
    if (relation.hasTreaty) return false;
    // Incursão ocorre em atWar (< -30) e bloodFeud (< -60)
    if (relation.standing > -30) return false;
    if (currentDay % incursionCooldownDays != 0) return false;
    return true;
  }

  // ---------------------------------------------------------------------------
  // buildDiplomacyOffers — gera ofertas de negociação disponíveis por facção
  // ---------------------------------------------------------------------------

  /// Retorna lista de [DiplomacyOffer] baseada na facção, relação atual e
  /// recursos disponíveis. Ofertas com successChance == 0 (recursos
  /// insuficientes) são filtradas antes de retornar.
  static List<DiplomacyOffer> buildDiplomacyOffers({
    required FloorFaction faction,
    required FactionRelation relation,
    required dynamic currentResources, // Resources model
    required double partyPower,
  }) {
    if (faction == FloorFaction.none) return [];

    final standing = relation.standing;
    final food = (currentResources.food as num).toDouble();
    final ironOre = (currentResources.ironOre as num).toDouble();
    final ironBar = (currentResources.ironBar as num).toDouble();
    final woodLog = (currentResources.woodLog as num).toDouble();
    final knowledge = (currentResources.knowledge as num).toDouble();
    // Para compatibilidade com lógica de ofertas — usa o mais relevante
    final iron = ironBar > 0 ? ironBar : ironOre;
    final wood = woodLog;

    final offers = <DiplomacyOffer>[];

    // ── Oferta universal: Tratado de Não-Agressão ─────────────────────────
    // Disponível acima de -30 de standing
    if (standing >= -30) {
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.proposeNonAggression,
          resourceCost: const {'food': 25},
          standingGain: 12,
          successChance: food >= 25 ? 0.70 : 0.0,
          description:
              'Propõe uma trégua: a cidadela não invadirá os territórios '
              'da facção nos próximos 14 dias.',
        ),
      );
    }

    // ── Pacto de Ferro ────────────────────────────────────────────────────
    if (faction == FloorFaction.ironPact) {
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.payTribute,
          resourceCost: const {'ironBar': 20},
          standingGain: 15,
          successChance: iron >= 20 ? 0.80 : 0.0,
          description:
              'Envia 20 barras de ferro como tributo. '
              'O Pacto de Ferro valora metal acima de palavras.',
        ),
      );
      final missionChance = (partyPower / 20).clamp(0.0, 0.90);
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.sendGoodwillMission,
          resourceCost: const {'food': 15},
          standingGain: 25,
          successChance: food >= 15 ? missionChance : 0.0,
          description:
              'Envia guerreiros para uma prova de força. '
              'Chance depende do poder médio do grupo '
              '(atual: ${partyPower.toStringAsFixed(1)}).',
        ),
      );
    }

    // ── Ordem Silenciosa ──────────────────────────────────────────────────
    if (faction == FloorFaction.silentOrder) {
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.donateKnowledge,
          resourceCost: const {'knowledge': 30},
          standingGain: 20,
          successChance: knowledge >= 30 ? 0.85 : 0.0,
          description:
              'Doa 30 pts de conhecimento aos arquivos da Ordem. '
              'A Ordem reverencia quem busca o saber.',
        ),
      );
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.payTribute,
          resourceCost: const {'woodLong': 15, 'knowledge': 10},
          standingGain: 14,
          successChance: (wood >= 15 && knowledge >= 10) ? 0.75 : 0.0,
          description:
              'Envia materiais para a biblioteca da Ordem. '
              'Papel, madeira e conhecimento — combustível da iluminação.',
        ),
      );
    }

    // ── Mercado de Sangue ─────────────────────────────────────────────────
    if (faction == FloorFaction.bloodMarket) {
      final tributeAmt = standing < 0 ? 40.0 : 20.0;
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.payTribute,
          resourceCost: {'food': tributeAmt},
          standingGain: standing < 0 ? 25 : 15,
          successChance: food >= tributeAmt ? 0.90 : 0.0,
          description:
              'Paga ${tributeAmt.toStringAsFixed(0)} de mantimentos. '
              'Dinheiro fala mais alto que palavras aqui.',
        ),
      );
      if (iron >= 10) {
        offers.add(
          DiplomacyOffer(
            type: DiplomacyOfferType.sendGoodwillMission,
            resourceCost: const {'ironOre': 10, 'food': 10},
            standingGain: 20,
            successChance: (iron >= 10 && food >= 10) ? 0.80 : 0.0,
            description:
                'Propõe parceria comercial: fornece ferro e mantimentos '
                'em troca de acesso preferencial às rotas do Mercado.',
          ),
        );
      }
    }

    // ── Filhos do Vazio ───────────────────────────────────────────────────
    if (faction == FloorFaction.voidChildren) {
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.payTribute, // ← tipo trocado
          resourceCost: const {'food': 5},
          standingGain: 20,
          successChance: food >= 5 ? 0.50 : 0.0,
          description:
              'Envia uma oferta... improvável. Os Filhos do Vazio reagem '
              'de forma imprevisível. Pode dar muito certo. Ou muito errado.',
        ),
      );
    }

    // ── Servos da Torre ───────────────────────────────────────────────────
    if (faction == FloorFaction.towerServants) {
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.challengeToTrial,
          resourceCost: const {'food': 30, 'iron': 15},
          standingGain: 30,
          successChance: (food >= 30 && iron >= 15) ? 0.60 : 0.0,
          description:
              'Submete-se a um julgamento dos Servos. Demonstra submissão '
              'à Torre e dignidade. Fracasso piora a relação.',
        ),
      );
      offers.add(
        DiplomacyOffer(
          type: DiplomacyOfferType.payTribute,
          resourceCost: const {'ironBar': 25, 'knowledge': 20},
          standingGain: 22,
          successChance: (iron >= 25 && knowledge >= 20) ? 0.75 : 0.0,
          description:
              'Oferece artefatos e conhecimento como prova de devoção à Torre. '
              'Os Servos valorizam quem age em nome do poder superior.',
        ),
      );
    }

    // Remove ofertas impossíveis (sem recursos)
    return offers.where((o) => o.successChance > 0).toList();
  }

  /// Distribui facção controladora para um andar dado seu número e tier.
  /// Seed fixa: mesma entrada = mesmo resultado sempre.
  static FloorFaction factionForFloor(int floorNumber, int tierIdx) {
    // Tutorial (1-5) e bosses (múltiplos de 10): sempre neutro
    if (floorNumber <= 5 || floorNumber % 10 == 0) return FloorFaction.none;

    final tierFactions = [
      FloorFaction.ironPact, // tier 1: andares 1-10
      FloorFaction.silentOrder, // tier 2: andares 11-20
      FloorFaction.bloodMarket, // tier 3: andares 21-30
      FloorFaction.ironPact, // tier 4: andares 31-40 (retorna mais forte)
      FloorFaction.voidChildren, // tier 5: andares 41-50
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

// ---------------------------------------------------------------------------
// FactionWar — guerra entre duas facções
// ---------------------------------------------------------------------------

class FactionWar {
  final String id;
  final FloorFaction aggressor;
  final FloorFaction defender;
  final int startDay;
  int duration;
  List<int> contestedFloors;
  double aggressorStrength;
  double defenderStrength;
  FloorFaction? playerSidedWith;
  bool resolved;
  FloorFaction? winner;

  FactionWar({
    required this.id,
    required this.aggressor,
    required this.defender,
    required this.startDay,
    this.duration = 20,
    List<int>? contestedFloors,
    this.aggressorStrength = 50.0,
    this.defenderStrength = 50.0,
    this.playerSidedWith,
    this.resolved = false,
    this.winner,
  }) : contestedFloors = contestedFloors ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'aggressor': aggressor.key,
    'defender': defender.key,
    'startDay': startDay,
    'duration': duration,
    'contestedFloors': contestedFloors,
    'aggressorStrength': aggressorStrength,
    'defenderStrength': defenderStrength,
    'playerSidedWith': playerSidedWith?.key,
    'resolved': resolved,
    'winner': winner?.key,
  };

  factory FactionWar.fromJson(Map<String, dynamic> json) {
    FloorFaction? parseFaction(String? name) {
      if (name == null) return null;
      return FloorFaction.values.firstWhere(
        (e) => e.key == name,
        orElse: () => FloorFaction.none,
      );
    }

    return FactionWar(
      id: json['id'] as String? ?? 'war_unknown',
      aggressor:
          parseFaction(json['aggressor'] as String?) ?? FloorFaction.none,
      defender: parseFaction(json['defender'] as String?) ?? FloorFaction.none,
      startDay: json['startDay'] as int? ?? 0,
      duration: json['duration'] as int? ?? 20,
      contestedFloors: (json['contestedFloors'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      aggressorStrength:
          (json['aggressorStrength'] as num?)?.toDouble() ?? 50.0,
      defenderStrength: (json['defenderStrength'] as num?)?.toDouble() ?? 50.0,
      playerSidedWith: parseFaction(json['playerSidedWith'] as String?),
      resolved: json['resolved'] as bool? ?? false,
      winner: parseFaction(json['winner'] as String?),
    );
  }
}

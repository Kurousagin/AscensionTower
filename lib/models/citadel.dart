// ═══════════════════════════════════════════════════════════════
// SISTEMA DE ARMAZEM
// ═══════════════════════════════════════════════════════════════

enum StorageLevel { none, basic, expanded, grand, spatial }

extension StorageLevelExt on StorageLevel {
  String get label => const {
    StorageLevel.none: 'Sem Armazém',
    StorageLevel.basic: 'Armazém Básico',
    StorageLevel.expanded: 'Armazém Expandido',
    StorageLevel.grand: 'Grande Armazém',
    StorageLevel.spatial: 'Armazém Espacial',
  }[this]!;

  String get shortLabel => const {
    StorageLevel.none: 'Nenhum',
    StorageLevel.basic: 'Básico',
    StorageLevel.expanded: 'Expandido',
    StorageLevel.grand: 'Grande',
    StorageLevel.spatial: 'Espacial',
  }[this]!;

  double get capacity => const {
    StorageLevel.none: 30.0,
    StorageLevel.basic: 60.0,
    StorageLevel.expanded: 120.0,
    StorageLevel.grand: 250.0,
    StorageLevel.spatial: double.infinity,
  }[this]!;

  bool get isInfinite => this == StorageLevel.spatial;

  String get capacityDisplay =>
      isInfinite ? 'INFINITO' : capacity.toStringAsFixed(0);

  int get requiredTier => const {
    StorageLevel.none: 0,
    StorageLevel.basic: 0,
    StorageLevel.expanded: 2,
    StorageLevel.grand: 5,
    StorageLevel.spatial: 9,
  }[this]!;

  Resources get upgradeCost => {
    StorageLevel.none: Resources(wood: 15, stone: 10),
    StorageLevel.basic: Resources(wood: 40, stone: 30, iron: 10),
    StorageLevel.expanded: Resources(
      wood: 80,
      stone: 60,
      iron: 30,
      knowledge: 15,
    ),
    StorageLevel.grand: Resources(
      iron: 80,
      stone: 100,
      knowledge: 60,
      wood: 60,
    ),
    StorageLevel.spatial: Resources(),
  }[this]!;

  StorageLevel? get nextLevel {
    final idx = index + 1;
    if (idx >= StorageLevel.values.length) return null;
    return StorageLevel.values[idx];
  }
}

// ─────────────────────────────────────────────
// RECURSOS
// ─────────────────────────────────────────────

class ResourcesCost {
  final double food, wood, stone, iron, knowledge;
  const ResourcesCost({
    this.food = 0,
    this.wood = 0,
    this.stone = 0,
    this.iron = 0,
    this.knowledge = 0,
  });

  Resources toResources() => Resources(
    food: food,
    wood: wood,
    stone: stone,
    iron: iron,
    knowledge: knowledge,
  );
}

class Resources {
  double food, wood, stone, iron, knowledge, morale;

  Resources({
    this.food = 0,
    this.wood = 0,
    this.stone = 0,
    this.iron = 0,
    this.knowledge = 0,
    this.morale = 0,
  });

  Resources copyWith({
    double? food,
    double? wood,
    double? stone,
    double? iron,
    double? knowledge,
    double? morale,
  }) => Resources(
    food: food ?? this.food,
    wood: wood ?? this.wood,
    stone: stone ?? this.stone,
    iron: iron ?? this.iron,
    knowledge: knowledge ?? this.knowledge,
    morale: morale ?? this.morale,
  );

  Resources clone() => copyWith();

  Map<String, dynamic> toJson() => {
    'food': food,
    'wood': wood,
    'stone': stone,
    'iron': iron,
    'knowledge': knowledge,
    'morale': morale,
  };

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
    food: (json['food'] as num?)?.toDouble() ?? 50,
    wood: (json['wood'] as num?)?.toDouble() ?? 30,
    stone: (json['stone'] as num?)?.toDouble() ?? 10,
    iron: (json['iron'] as num?)?.toDouble() ?? 0,
    knowledge: (json['knowledge'] as num?)?.toDouble() ?? 5,
    morale: (json['morale'] as num?)?.toDouble() ?? 60,
  );

  bool canAfford(Resources cost) =>
      food >= cost.food &&
      wood >= cost.wood &&
      stone >= cost.stone &&
      iron >= cost.iron &&
      knowledge >= cost.knowledge;

  void spend(Resources cost) {
    food -= cost.food;
    wood -= cost.wood;
    stone -= cost.stone;
    iron -= cost.iron;
    knowledge -= cost.knowledge;
    clampNegatives();
  }

  void add(Resources gain) {
    food += gain.food;
    wood += gain.wood;
    stone += gain.stone;
    iron += gain.iron;
    knowledge += gain.knowledge;
    morale += gain.morale;
  }

  Resources addCapped(Resources gain, StorageLevel storage) {
    add(gain);
    return clampToCapacity(storage);
  }

  Resources clampToCapacity(StorageLevel storage) {
    final lost = Resources();
    clampNegatives();
    morale = morale.clamp(0, 100);
    if (!storage.isInfinite) {
      final cap = storage.capacity;
      if (food > cap) {
        lost.food = food - cap;
        food = cap;
      }
      if (wood > cap) {
        lost.wood = wood - cap;
        wood = cap;
      }
      if (stone > cap) {
        lost.stone = stone - cap;
        stone = cap;
      }
      if (iron > cap) {
        lost.iron = iron - cap;
        iron = cap;
      }
      if (knowledge > cap) {
        lost.knowledge = knowledge - cap;
        knowledge = cap;
      }
    }
    return lost;
  }

  void clampNegatives() {
    if (food < 0) food = 0;
    if (wood < 0) wood = 0;
    if (stone < 0) stone = 0;
    if (iron < 0) iron = 0;
    if (knowledge < 0) knowledge = 0;
  }

  bool hasOverflow(StorageLevel storage) {
    if (storage.isInfinite) return false;
    final cap = storage.capacity;
    return food > cap ||
        wood > cap ||
        stone > cap ||
        iron > cap ||
        knowledge > cap;
  }

  bool anyAtCapacity(StorageLevel storage) {
    if (storage.isInfinite) return false;
    final cap = storage.capacity;
    return food >= cap ||
        wood >= cap ||
        stone >= cap ||
        iron >= cap ||
        knowledge >= cap;
  }

  double get totalPhysical => food + wood + stone + iron + knowledge;

  double usageRatio(StorageLevel storage) {
    if (storage.isInfinite) return 0.0;
    final cap = storage.capacity;
    if (cap <= 0) return 0.0;
    return (totalPhysical / (cap * 5)).clamp(0.0, 1.0);
  }
}

// ─────────────────────────────────────────────
// NÍVEL DA CIDADELA
// ─────────────────────────────────────────────

enum CitadelLevel {
  shelter,
  camp,
  village,
  town,
  city,
  fortress,
  citadel,
  kingdom,
  empire,
  ascended,
}

extension CitadelLevelExt on CitadelLevel {
  String get label => const {
    CitadelLevel.shelter: 'Abrigo',
    CitadelLevel.camp: 'Acampamento',
    CitadelLevel.village: 'Vila',
    CitadelLevel.town: 'Povoado',
    CitadelLevel.city: 'Cidade',
    CitadelLevel.fortress: 'Fortaleza',
    CitadelLevel.citadel: 'Cidadela',
    CitadelLevel.kingdom: 'Reino',
    CitadelLevel.empire: 'Império',
    CitadelLevel.ascended: 'Ascendido',
  }[this]!;

  String get ascii => const {
    CitadelLevel.shelter: '[===]',
    CitadelLevel.camp: '[=====]',
    CitadelLevel.village: '[========]',
    CitadelLevel.town: '[==========]',
    CitadelLevel.city: '[=============]',
    CitadelLevel.fortress: '[================]',
    CitadelLevel.citadel: '[===================]',
    CitadelLevel.kingdom: '[======================]',
    CitadelLevel.empire: '[==========================]',
    CitadelLevel.ascended: '[==============================]',
  }[this]!;

  int get maxBuildings => const {
    CitadelLevel.shelter: 3,
    CitadelLevel.camp: 5,
    CitadelLevel.village: 8,
    CitadelLevel.town: 11,
    CitadelLevel.city: 15,
    CitadelLevel.fortress: 19,
    CitadelLevel.citadel: 23,
    CitadelLevel.kingdom: 27,
    CitadelLevel.empire: 32,
    CitadelLevel.ascended: 45,
  }[this]!;

  int get populationRequired => const {
    CitadelLevel.shelter: 0,
    CitadelLevel.camp: 8,
    CitadelLevel.village: 15,
    CitadelLevel.town: 22,
    CitadelLevel.city: 30,
    CitadelLevel.fortress: 40,
    CitadelLevel.citadel: 55,
    CitadelLevel.kingdom: 75,
    CitadelLevel.empire: 100,
    CitadelLevel.ascended: 150,
  }[this]!;

  int get requiredTowerTier => const {
    CitadelLevel.shelter: 0,
    CitadelLevel.camp: 0,
    CitadelLevel.village: 1,
    CitadelLevel.town: 2,
    CitadelLevel.city: 3,
    CitadelLevel.fortress: 4,
    CitadelLevel.citadel: 5,
    CitadelLevel.kingdom: 6,
    CitadelLevel.empire: 8,
    CitadelLevel.ascended: 10,
  }[this]!;

  int get maxBuildingCopies => const {
    CitadelLevel.shelter: 1,
    CitadelLevel.camp: 1,
    CitadelLevel.village: 2,
    CitadelLevel.town: 3,
    CitadelLevel.city: 4,
    CitadelLevel.fortress: 4,
    CitadelLevel.citadel: 5,
    CitadelLevel.kingdom: 5,
    CitadelLevel.empire: 6,
    CitadelLevel.ascended: 6,
  }[this]!;

  int get buildingTier => const {
    CitadelLevel.shelter: 0,
    CitadelLevel.camp: 0,
    CitadelLevel.village: 1,
    CitadelLevel.town: 1,
    CitadelLevel.city: 2,
    CitadelLevel.fortress: 2,
    CitadelLevel.citadel: 3,
    CitadelLevel.kingdom: 3,
    CitadelLevel.empire: 3,
    CitadelLevel.ascended: 3,
  }[this]!;
}

// ─────────────────────────────────────────────
// TIPOS DE EDIFÍCIO
// ─────────────────────────────────────────────

enum BuildingType {
  // Essenciais (Tier 0)
  firepit,
  tent,
  farm,
  // Produção (Tier 1)
  kitchen,
  workshop,
  forge,
  woodworking,
  granary,
  // Conhecimento (Tier 1–2)
  school,
  library,
  infirmary,
  // Militar (Tier 2)
  barracks,
  trainingField,
  wall,
  watchtower,
  // Social/Político (Tier 3)
  tavern,
  market,
  temple,
  prison,
  // ── NOVO: Abrigo de Viajantes (Tier 2) ──────────────────────────────────
  // Permite recrutar survivors encontrados nos andares conquistados.
  // Único (isUnique = true). Não evolui automaticamente (canEvolve = false).
  wayfareresRefuge,
  // Avançados (Tier 4–5)
  arena,
  synthesisLab,
  promotionHall,
  councilHall,
  // Endgame (Tier 6–9)
  alchemyLab,
  warRoom,
  monument,
  nexus,
}

enum BuildingCategory {
  essential,
  production,
  knowledge,
  military,
  social,
  advanced,
  endgame,
}

extension BuildingCategoryExt on BuildingCategory {
  String get label => const {
    BuildingCategory.essential: 'Essencial',
    BuildingCategory.production: 'Produção',
    BuildingCategory.knowledge: 'Conhecimento',
    BuildingCategory.military: 'Militar',
    BuildingCategory.social: 'Social',
    BuildingCategory.advanced: 'Avançado',
    BuildingCategory.endgame: 'Endgame',
  }[this]!;
}

// ─────────────────────────────────────────────
// EDIFÍCIO
// ─────────────────────────────────────────────

class Building {
  final BuildingType type;
  int level;
  int tier;
  int inheritedBonus;

  bool get canUpgrade => level < maxLevel || tier < 3;

  Building({
    required this.type,
    this.level = 1,
    this.tier = 0,
    this.inheritedBonus = 0,
  });

  Building copyWith({int? level, int? tier, int? inheritedBonus}) => Building(
    type: type,
    level: level ?? this.level,
    tier: tier ?? this.tier,
    inheritedBonus: inheritedBonus ?? this.inheritedBonus,
  );

  static const Map<BuildingType, List<double>> levelValues = {
    BuildingType.farm: [2, 4, 6, 8, 10],
    BuildingType.firepit: [1, 3, 4, 5, 6],
    BuildingType.woodworking: [2, 4, 6, 8, 10],
    BuildingType.forge: [2, 5, 8, 12, 16],
    BuildingType.workshop: [1, 2, 4, 6, 8],
    BuildingType.school: [1, 2, 4, 6, 8],
    BuildingType.library: [1, 2, 4, 6, 8],
    BuildingType.kitchen: [1, 2, 4, 6, 8],
    BuildingType.tent: [2, 4, 6, 8, 10],
    BuildingType.infirmary: [0.3, 0.4, 0.5, 0.6],
  };

  double get foodConsumptionReduction {
    if (type != BuildingType.granary) return 0.0;
    const values = [0.015, 0.03, 0.06, 0.10, 0.15];
    final index = (level - 1).clamp(0, values.length - 1);
    return values[index];
  }

  double get valuePerTier {
    final values = levelValues[type];
    if (values == null) return 0.0;
    final t = tier.clamp(0, values.length - 1);
    return values[t];
  }

  double get levelBonus {
    final values = levelValues[type];
    if (values == null) return 0.0;
    final index = (level - 1).clamp(0, values.length - 1);
    return values[index];
  }

  double get bonus => inheritedBonus + levelBonus;

  static const Map<BuildingType, List<String>> _names = {
    BuildingType.firepit: [
      'Fogueira',
      'Marco da Vila',
      'Praça Central',
      'Monumento da Ascensão',
    ],
    BuildingType.tent: ['Tenda', 'Casa', 'Pousada', 'Residência'],
    BuildingType.farm: ['Horta', 'Plantação', 'Fazenda', 'Fazenda Industrial'],
    BuildingType.kitchen: [
      'Cozinha',
      'Refeitório',
      'Salão de Banquetes',
      'Salão de Banquetes',
    ],
    BuildingType.workshop: ['Oficina', 'Manufatura', 'Fábrica', 'Fábrica'],
    BuildingType.forge: ['Forja', 'Fundição', 'Refinaria', 'Refinaria'],
    BuildingType.barracks: [
      'Quartel',
      'Academia Militar',
      'Complexo de Treinamento',
      'Complexo de Treinamento',
    ],
    BuildingType.school: ['Escola', 'Escola', 'Escola', 'Escola'],
    BuildingType.woodworking: [
      'Lenharia',
      'Serraria',
      'Madeireira',
      'Complexo Madeireiro',
    ],
    BuildingType.library: [
      'Biblioteca',
      'Biblioteca',
      'Biblioteca',
      'Biblioteca',
    ],
    BuildingType.infirmary: ['Enfermaria', 'Enfermaria', 'Clinica', 'Hospital'],
    BuildingType.wall: ['Muralha', 'Muralha', 'Muralha', 'Muralha'],
    BuildingType.watchtower: [
      'Torre de Vigia',
      'Torre de Vigia',
      'Torre de Vigia',
      'Torre de Vigia',
    ],
    BuildingType.market: ['Mercado', 'Mercado', 'Mercado', 'Mercado'],
    BuildingType.tavern: ['Taverna', 'Taverna', 'Taverna', 'Taverna'],
    BuildingType.prison: [
      'Cela de Detenção',
      'Prisão',
      'Penitenciária',
      'Presidio',
    ],
    BuildingType.temple: ['Templo', 'Templo', 'Templo', 'Templo'],
    BuildingType.trainingField: [
      'Campo de Treino',
      'Campo de Treino',
      'Campo de Treino',
      'Campo de Treino',
    ],
    BuildingType.arena: ['Arena', 'Arena', 'Arena', 'Arena'],
    BuildingType.synthesisLab: [
      'Câmara de Síntese',
      'Câmara de Síntese',
      'Câmara de Síntese',
      'Câmara de Síntese',
    ],
    BuildingType.promotionHall: [
      'Sala de Promoção',
      'Sala de Promoção',
      'Sala de Promoção',
      'Sala de Promoção',
    ],
    BuildingType.councilHall: [
      'Sala do Conselho',
      'Sala do Conselho',
      'Sala do Conselho',
      'Sala do Conselho',
    ],
    BuildingType.alchemyLab: [
      'Laboratório Alquímico',
      'Laboratório Alquímico',
      'Laboratório Alquímico',
      'Laboratório Alquímico',
    ],
    BuildingType.granary: [
      'Celeiro',
      'Silo',
      'Armazém de Grãos',
      'Estoque Real',
    ],
    BuildingType.warRoom: [
      'Sala de Guerra',
      'Sala de Guerra',
      'Sala de Guerra',
      'Sala de Guerra',
    ],
    BuildingType.monument: ['Monumento', 'Monumento', 'Monumento', 'Monumento'],
    BuildingType.nexus: [
      'Nexus da Torre',
      'Nexus da Torre',
      'Nexus da Torre',
      'Nexus da Torre',
    ],
    // ── NOVO ──────────────────────────────────────────────────────────────────
    BuildingType.wayfareresRefuge: [
      'Abrigo de Viajantes',
      'Hospedaria da Torre',
      'Santuário dos Errantes',
      'Lar dos Sem-Lar',
    ],
  };

  String get name => _names[type]![tier.clamp(0, 3)];

  String get tag => '[${name.substring(0, 3).toUpperCase()}]';

  BuildingCategory get category => const {
    BuildingType.firepit: BuildingCategory.essential,
    BuildingType.tent: BuildingCategory.essential,
    BuildingType.farm: BuildingCategory.essential,
    BuildingType.kitchen: BuildingCategory.production,
    BuildingType.workshop: BuildingCategory.production,
    BuildingType.forge: BuildingCategory.production,
    BuildingType.woodworking: BuildingCategory.production,
    BuildingType.school: BuildingCategory.knowledge,
    BuildingType.library: BuildingCategory.knowledge,
    BuildingType.infirmary: BuildingCategory.knowledge,
    BuildingType.barracks: BuildingCategory.military,
    BuildingType.trainingField: BuildingCategory.military,
    BuildingType.wall: BuildingCategory.military,
    BuildingType.watchtower: BuildingCategory.military,
    BuildingType.tavern: BuildingCategory.social,
    BuildingType.market: BuildingCategory.social,
    BuildingType.temple: BuildingCategory.social,
    BuildingType.prison: BuildingCategory.social,
    BuildingType.arena: BuildingCategory.advanced,
    BuildingType.granary: BuildingCategory.essential,
    BuildingType.synthesisLab: BuildingCategory.advanced,
    BuildingType.promotionHall: BuildingCategory.advanced,
    BuildingType.councilHall: BuildingCategory.advanced,
    BuildingType.alchemyLab: BuildingCategory.endgame,
    BuildingType.warRoom: BuildingCategory.endgame,
    BuildingType.monument: BuildingCategory.endgame,
    BuildingType.nexus: BuildingCategory.endgame,
    // ── NOVO ──────────────────────────────────────────────────────────────────
    BuildingType.wayfareresRefuge: BuildingCategory.social,
  }[type]!;

  int get requiredTier =>
      const {
        BuildingType.firepit: 0, BuildingType.tent: 0, BuildingType.farm: 0,
        BuildingType.kitchen: 1,
        BuildingType.workshop: 1,
        BuildingType.forge: 1,
        BuildingType.school: 1,
        BuildingType.library: 2,
        BuildingType.infirmary: 1,
        BuildingType.woodworking: 2, BuildingType.granary: 2,
        BuildingType.barracks: 2, BuildingType.trainingField: 2,
        BuildingType.wall: 2, BuildingType.watchtower: 2,
        BuildingType.tavern: 3, BuildingType.prison: 3,
        BuildingType.market: 3, BuildingType.temple: 3,
        BuildingType.arena: 4, BuildingType.synthesisLab: 5,
        BuildingType.promotionHall: 5, BuildingType.councilHall: 4,
        BuildingType.alchemyLab: 7, BuildingType.warRoom: 6,
        BuildingType.monument: 8, BuildingType.nexus: 9,
        // ── NOVO: disponível no Tier 2 (mesmo nível que barracks) ────────────────
        BuildingType.wayfareresRefuge: 2,
      }[type] ??
      0;

  bool get isUnique => const {
    BuildingType.library, BuildingType.temple, BuildingType.arena,
    BuildingType.synthesisLab, BuildingType.promotionHall,
    BuildingType.councilHall, BuildingType.alchemyLab,
    BuildingType.warRoom, BuildingType.monument, BuildingType.nexus,
    // ── NOVO: único — não pode ter cópias ────────────────────────────────────
    BuildingType.wayfareresRefuge,
  }.contains(type);

  /// canEvolve: wayfareresRefuge NÃO entra aqui — único e não evolui com citadela
  bool get canEvolve => const {
    BuildingType.firepit,
    BuildingType.tent,
    BuildingType.farm,
    BuildingType.kitchen,
    BuildingType.workshop,
    BuildingType.forge,
    BuildingType.woodworking,
    BuildingType.granary,
    BuildingType.barracks,
    BuildingType.infirmary,
  }.contains(type);

  String get description {
    switch (type) {
      case BuildingType.firepit:
        return '+${bonus.toStringAsFixed(0)} moral/dia, centro social';
      case BuildingType.tent:
        return '+${bonus.toStringAsFixed(0)} capacidade de população';
      case BuildingType.farm:
        return '+${bonus.toStringAsFixed(0)} comida/dia';
      case BuildingType.kitchen:
        return '+${bonus.toStringAsFixed(0)} comida/dia por chef';
      case BuildingType.workshop:
        return '+${bonus.toStringAsFixed(0)} produção avançada/dia';
      case BuildingType.woodworking:
        return '+${bonus.toStringAsFixed(0)} madeira/dia';
      case BuildingType.granary:
        if (tier == 0) return 'Reduz o gasto de comida em 1.5%';
        if (tier == 1) return 'Reduz o gasto de comida em 2.5%';
        return 'Reduz o gasto de comida em 5%';
      case BuildingType.forge:
        return '+${bonus.toStringAsFixed(0)} ferro/dia';
      case BuildingType.school:
        return '+${bonus.toStringAsFixed(0)} conhecimento/dia, treina jovens';
      case BuildingType.library:
        return '+${bonus.toStringAsFixed(0)} conhecimento/dia, revela mecânicas ocultas';
      case BuildingType.infirmary:
        return 'Cura feridos, -30% mortes em expedições';
      case BuildingType.barracks:
        if (tier == 0) return 'Treina guardas, +0.3 FOR soldados/dia';
        if (tier == 1) return 'Treina soldados, +0.5 FOR, +0.3 AGI/dia';
        return 'Treino de elite, +0.8 FOR, +0.5 AGI/dia';
      case BuildingType.trainingField:
        return 'Treino seguro (−95% morte), evolução lenta';
      case BuildingType.wall:
        return '−20% risco de ameaças externas';
      case BuildingType.watchtower:
        return 'Alerta antecipado, detecta traidores +15%';
      case BuildingType.tavern:
        return 'Centro social: +relações, revela fofocas e traidores';
      case BuildingType.prison:
        return 'Permite deter NPCs condenados pelo conselho.';
      case BuildingType.market:
        return 'Troca de recursos, +5% eficiência geral';
      case BuildingType.temple:
        return '+2 moral/dia, +0.5 sanidade/dia para todos';
      case BuildingType.arena:
        return 'Duelos entre NPCs, resolve conflitos, +combate';
      case BuildingType.synthesisLab:
        return 'Combina materiais dos andares em itens raros';
      case BuildingType.promotionHall:
        return 'Promove NPCs: muda rank, desbloqueia habilidades';
      case BuildingType.councilHall:
        return 'Votações políticas, resolve crises democraticamente';
      case BuildingType.alchemyLab:
        return 'Cria poções e itens especiais de recursos raros';
      case BuildingType.warRoom:
        return '+25% chance de sucesso em expedições, estratégia global';
      case BuildingType.monument:
        return '+5 moral/dia, símbolo de poder, +lealdade geral';
      case BuildingType.nexus:
        return 'Conexão com a Torre: −10% dificuldade, +visão dos andares';
      // ── NOVO ───────────────────────────────────────────────────────────────
      case BuildingType.wayfareresRefuge:
        return 'Permite recrutar survivors encontrados nos andares conquistados. '
            'Cada survivor chega com lealdade baixa mas combate elevado.';
    }
  }

  ResourcesCost get cost =>
      const {
        BuildingType.firepit: ResourcesCost(wood: 5),
        BuildingType.tent: ResourcesCost(wood: 10),
        BuildingType.farm: ResourcesCost(wood: 15, stone: 5, food: 3),
        BuildingType.granary: ResourcesCost(wood: 20, stone: 10, food: 5),
        BuildingType.kitchen: ResourcesCost(wood: 10, stone: 5, food: 3),
        BuildingType.workshop: ResourcesCost(
          wood: 20,
          stone: 15,
          iron: 5,
          food: 8,
        ),
        BuildingType.forge: ResourcesCost(
          stone: 25,
          iron: 15,
          knowledge: 5,
          food: 10,
        ),
        BuildingType.woodworking: ResourcesCost(
          wood: 15,
          stone: 10,
          knowledge: 5,
          food: 5,
        ),
        BuildingType.school: ResourcesCost(
          wood: 15,
          stone: 10,
          knowledge: 10,
          food: 5,
        ),
        BuildingType.library: ResourcesCost(
          wood: 20,
          stone: 15,
          knowledge: 15,
          food: 8,
        ),
        BuildingType.infirmary: ResourcesCost(
          wood: 15,
          stone: 10,
          knowledge: 5,
          food: 8,
        ),
        BuildingType.barracks: ResourcesCost(
          wood: 25,
          stone: 20,
          iron: 10,
          food: 12,
        ),
        BuildingType.trainingField: ResourcesCost(
          wood: 25,
          stone: 20,
          iron: 10,
          knowledge: 10,
          food: 12,
        ),
        BuildingType.wall: ResourcesCost(stone: 30, iron: 10, food: 15),
        BuildingType.watchtower: ResourcesCost(
          wood: 15,
          stone: 25,
          iron: 5,
          food: 10,
        ),
        BuildingType.tavern: ResourcesCost(wood: 30, stone: 15, food: 10),
        BuildingType.market: ResourcesCost(wood: 20, stone: 15, food: 8),
        BuildingType.temple: ResourcesCost(
          stone: 30,
          wood: 20,
          knowledge: 20,
          food: 20,
        ),
        BuildingType.prison: ResourcesCost(wood: 30, stone: 40, iron: 20),
        BuildingType.arena: ResourcesCost(
          stone: 40,
          iron: 25,
          wood: 20,
          food: 25,
        ),
        BuildingType.synthesisLab: ResourcesCost(
          iron: 40,
          knowledge: 30,
          stone: 25,
          food: 30,
        ),
        BuildingType.promotionHall: ResourcesCost(
          knowledge: 50,
          iron: 30,
          stone: 30,
          food: 35,
        ),
        BuildingType.councilHall: ResourcesCost(
          wood: 35,
          stone: 30,
          knowledge: 20,
          food: 25,
        ),
        BuildingType.alchemyLab: ResourcesCost(
          knowledge: 80,
          iron: 50,
          stone: 30,
          food: 40,
        ),
        BuildingType.warRoom: ResourcesCost(
          iron: 60,
          stone: 40,
          knowledge: 40,
          food: 35,
        ),
        BuildingType.monument: ResourcesCost(
          stone: 100,
          iron: 50,
          knowledge: 50,
          wood: 50,
          food: 50,
        ),
        BuildingType.nexus: ResourcesCost(
          knowledge: 150,
          iron: 80,
          stone: 80,
          food: 60,
        ),
        // ── NOVO: custo acessível — disponível no Tier 2 ─────────────────────────
        BuildingType.wayfareresRefuge: ResourcesCost(
          wood: 25,
          stone: 15,
          food: 10,
        ),
      }[type] ??
      const ResourcesCost();

  Resources get upgradeCost {
    final base = cost;
    final mult = level * 1.5;
    return Resources(
      food: base.food * mult,
      wood: base.wood * mult,
      stone: base.stone * mult,
      iron: base.iron * mult,
      knowledge: base.knowledge * mult,
    );
  }

  int get maxLevel => 5;
  bool get isMaxLevel => level >= maxLevel;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'level': level,
    'tier': tier,
    'inheritedBonus': inheritedBonus,
  };

  factory Building.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'];
    final type = typeName is int
        ? BuildingType.values[typeName.clamp(0, BuildingType.values.length - 1)]
        : BuildingType.values.firstWhere(
            (e) => e.name == typeName,
            orElse: () => BuildingType.firepit,
          );

    final tier = json['tier'] as int? ?? 0;
    var level = json['level'] as int? ?? 1;
    var inheritedBonus = json['inheritedBonus'] as int? ?? 0;

    if (tier > 0 && inheritedBonus == 0) {
      final values = Building.levelValues[type];
      if (values != null && level > 1) {
        inheritedBonus += values[(level - 1).clamp(0, values.length - 1)]
            .round();
      }
      level = 1;
    }

    return Building(
      type: type,
      level: level,
      tier: tier,
      inheritedBonus: inheritedBonus,
    );
  }
}

// ─────────────────────────────────────────────
// CIDADELA
// ─────────────────────────────────────────────

class Citadel {
  CitadelLevel level;
  List<Building> buildings;
  Resources resources;
  int populationCapacity;
  StorageLevel storageLevel;

  Citadel({
    this.level = CitadelLevel.shelter,
    List<Building>? buildings,
    Resources? resources,
    this.populationCapacity = 15,
    this.storageLevel = StorageLevel.none,
  }) : buildings = buildings ?? [],
       resources = resources ?? Resources();

  double get storageCapacity => storageLevel.capacity;
  bool get hasInfiniteStorage => storageLevel.isInfinite;
  String get storageLabel => storageLevel.label;
  bool get canUpgradeStorage => storageLevel.nextLevel != null;

  bool get canUpgrade => level.index + 1 < CitadelLevel.values.length;

  CitadelLevel? get nextCitadelLevel {
    final idx = level.index + 1;
    if (idx >= CitadelLevel.values.length) return null;
    return CitadelLevel.values[idx];
  }

  ResourcesCost get upgradeCost => const {
    CitadelLevel.shelter: ResourcesCost(wood: 50, stone: 30, food: 30),
    CitadelLevel.camp: ResourcesCost(
      wood: 80,
      stone: 60,
      iron: 10,
      knowledge: 10,
    ),
    CitadelLevel.village: ResourcesCost(
      wood: 120,
      stone: 100,
      iron: 30,
      knowledge: 25,
    ),
    CitadelLevel.town: ResourcesCost(
      wood: 180,
      stone: 150,
      iron: 60,
      knowledge: 50,
    ),
    CitadelLevel.city: ResourcesCost(
      wood: 300,
      stone: 250,
      iron: 100,
      knowledge: 80,
    ),
    CitadelLevel.fortress: ResourcesCost(
      wood: 500,
      stone: 400,
      iron: 200,
      knowledge: 150,
    ),
    CitadelLevel.citadel: ResourcesCost(
      wood: 800,
      stone: 600,
      iron: 350,
      knowledge: 250,
    ),
    CitadelLevel.kingdom: ResourcesCost(
      wood: 1200,
      stone: 1000,
      iron: 600,
      knowledge: 500,
    ),
    CitadelLevel.empire: ResourcesCost(
      wood: 2000,
      stone: 1800,
      iron: 1000,
      knowledge: 800,
    ),
    CitadelLevel.ascended: ResourcesCost(),
  }[level]!;

  double get totalFoodProduction => buildings
      .where((b) => b.type == BuildingType.farm)
      .fold(0.0, (sum, b) => sum + b.bonus);

  double get totalWoodProduction => buildings
      .where((b) => b.type == BuildingType.woodworking)
      .fold(0.0, (sum, b) => sum + b.bonus);

  double get totalIronProduction => buildings
      .where((b) => b.type == BuildingType.forge)
      .fold(0.0, (sum, b) => sum + b.bonus);

  int get totalPopulationCapacity {
    int total = populationCapacity;
    for (final b in buildings) {
      if (b.type == BuildingType.tent) total += b.bonus.round();
    }
    return total;
  }

  bool hasBuilding(BuildingType type) => buildings.any((b) => b.type == type);

  int countBuildings(BuildingType type) =>
      buildings.where((b) => b.type == type).length;

  Building? getBuilding(BuildingType type) {
    for (final b in buildings) {
      if (b.type == type) return b;
    }
    return null;
  }

  bool get hasRoomForBuilding => buildings.length < level.maxBuildings;

  bool canBuild(BuildingType type, int currentTowerTier) {
    if (!hasRoomForBuilding) return false;
    final building = Building(type: type);
    if (currentTowerTier < building.requiredTier) return false;
    if (building.isUnique && hasBuilding(type)) return false;
    if (!building.isUnique && countBuildings(type) >= level.maxBuildingCopies) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'buildings': buildings.map((b) => b.toJson()).toList(),
    'resources': resources.toJson(),
    'populationCapacity': populationCapacity,
    'storageLevel': storageLevel.name,
  };

  factory Citadel.fromJson(Map<String, dynamic> json) {
    T parseEnum<T extends Enum>(List<T> values, Object? raw, T fallback) {
      if (raw is int) return values[raw.clamp(0, values.length - 1)];
      final name = raw as String?;
      if (name == null) return fallback;
      return values.firstWhere((e) => e.name == name, orElse: () => fallback);
    }

    return Citadel(
      level: parseEnum(
        CitadelLevel.values,
        json['level'],
        CitadelLevel.shelter,
      ),
      buildings:
          (json['buildings'] as List<dynamic>?)
              ?.map((b) => Building.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      resources: json['resources'] != null
          ? Resources.fromJson(json['resources'] as Map<String, dynamic>)
          : null,
      populationCapacity: json['populationCapacity'] as int? ?? 15,
      storageLevel: parseEnum(
        StorageLevel.values,
        json['storageLevel'],
        StorageLevel.none,
      ),
    );
  }
}

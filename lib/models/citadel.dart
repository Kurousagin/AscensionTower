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
    StorageLevel.none: Resources(woodLog: 15, stoneRaw: 10),
    StorageLevel.basic: Resources(woodLog: 40, stoneRaw: 30, ironOre: 10),
    StorageLevel.expanded: Resources(
      woodLog: 80,
      stoneRaw: 60,
      ironOre: 30,
      knowledge: 15,
    ),
    StorageLevel.grand: Resources(
      knowledge: 60,
      ironOre: 80,
      stoneRaw: 100,
      woodLog: 60,
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
  final double food,
      woodLog,
      stoneRaw,
      ironOre,
      lumber,
      stoneBrick,
      ironBar,
      knowledge;
  const ResourcesCost({
    this.food = 0,
    this.woodLog = 0,
    this.stoneRaw = 0,
    this.ironOre = 0,
    this.lumber = 0,
    this.stoneBrick = 0,
    this.ironBar = 0,
    this.knowledge = 0,
  });

  Resources toResources() => Resources(
    food: food,
    woodLog: woodLog,
    stoneRaw: stoneRaw,
    ironOre: ironOre,
    lumber: lumber,
    stoneBrick: stoneBrick,
    ironBar: ironBar,
    knowledge: knowledge,
  );
}

class Resources {
  double food, knowledge, morale;
  // Raw — da torre ou coleta
  double woodLog, stoneRaw, ironOre;
  // Processado — manufatura
  double lumber, stoneBrick, ironBar;

  Resources({
    this.food = 0,
    this.knowledge = 0,
    this.morale = 0,
    this.woodLog = 0,
    this.stoneRaw = 0,
    this.ironOre = 0,
    this.lumber = 0,
    this.stoneBrick = 0,
    this.ironBar = 0,
  });

  Resources copyWith({
    double? food,
    double? knowledge,
    double? morale,
    double? woodLog,
    double? stoneRaw,
    double? ironOre,
    double? lumber,
    double? stoneBrick,
    double? ironBar,
  }) => Resources(
    food: food ?? this.food,
    knowledge: knowledge ?? this.knowledge,
    morale: morale ?? this.morale,
    woodLog: woodLog ?? this.woodLog,
    stoneRaw: stoneRaw ?? this.stoneRaw,
    ironOre: ironOre ?? this.ironOre,
    lumber: lumber ?? this.lumber,
    stoneBrick: stoneBrick ?? this.stoneBrick,
    ironBar: ironBar ?? this.ironBar,
  );
  Resources clone() => copyWith();

  Map<String, dynamic> toJson() => {
    'food': food,
    'woodLog': woodLog,
    'stoneRaw': stoneRaw,
    'ironOre': ironOre,
    'lumber': lumber,
    'stoneBrick': stoneBrick,
    'ironBar': ironBar,
    'knowledge': knowledge,
    'morale': morale,
  };

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
    food: (json['food'] as num?)?.toDouble() ?? 0,
    // raw — saves antigos migram wood/stone/iron como ponto de partida
    woodLog:
        (json['woodLog'] as num?)?.toDouble() ??
        (json['wood'] as num?)?.toDouble() ??
        0,
    stoneRaw:
        (json['stoneRaw'] as num?)?.toDouble() ??
        (json['stone'] as num?)?.toDouble() ??
        0,
    ironOre:
        (json['ironOre'] as num?)?.toDouble() ??
        (json['iron'] as num?)?.toDouble() ??
        0,
    lumber: (json['lumber'] as num?)?.toDouble() ?? 0,
    stoneBrick: (json['stoneBrick'] as num?)?.toDouble() ?? 0,
    ironBar: (json['ironBar'] as num?)?.toDouble() ?? 0,
    knowledge: (json['knowledge'] as num?)?.toDouble() ?? 5,
    morale: (json['morale'] as num?)?.toDouble() ?? 60,
  );

  bool canAfford(Resources cost) =>
      food >= cost.food &&
      woodLog >= cost.woodLog &&
      stoneRaw >= cost.stoneRaw &&
      ironOre >= cost.ironOre &&
      lumber >= cost.lumber &&
      stoneBrick >= cost.stoneBrick &&
      ironBar >= cost.ironBar &&
      knowledge >= cost.knowledge;

  void spend(Resources cost) {
    food -= cost.food;
    woodLog -= cost.woodLog;
    stoneRaw -= cost.stoneRaw;
    ironOre -= cost.ironOre;
    lumber -= cost.lumber;
    stoneBrick -= cost.stoneBrick;
    ironBar -= cost.ironBar;
    knowledge -= cost.knowledge;
    clampNegatives();
  }

  void add(Resources gain) {
    food += gain.food;
    woodLog += gain.woodLog;
    stoneRaw += gain.stoneRaw;
    ironOre += gain.ironOre;
    lumber += gain.lumber;
    stoneBrick += gain.stoneBrick;
    ironBar += gain.ironBar;
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
      if (woodLog > cap) {
        lost.woodLog = woodLog - cap;
        woodLog = cap;
      }
      if (stoneRaw > cap) {
        lost.stoneRaw = stoneRaw - cap;
        stoneRaw = cap;
      }
      if (ironOre > cap) {
        lost.ironOre = ironOre - cap;
        ironOre = cap;
      }
      if (lumber > cap) {
        lost.lumber = lumber - cap;
        lumber = cap;
      }
      if (stoneBrick > cap) {
        lost.stoneBrick = stoneBrick - cap;
        stoneBrick = cap;
      }
      if (ironBar > cap) {
        lost.ironBar = ironBar - cap;
        ironBar = cap;
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
    if (woodLog < 0) woodLog = 0;
    if (stoneRaw < 0) stoneRaw = 0;
    if (ironOre < 0) ironOre = 0;
    if (lumber < 0) lumber = 0;
    if (stoneBrick < 0) stoneBrick = 0;
    if (ironBar < 0) ironBar = 0;
    if (knowledge < 0) knowledge = 0;
  }

  bool hasOverflow(StorageLevel storage) {
    if (storage.isInfinite) return false;
    final cap = storage.capacity;
    return food > cap || knowledge > cap;
  }

  bool anyAtCapacity(StorageLevel storage) {
    if (storage.isInfinite) return false;
    final cap = storage.capacity;
    return food >= cap || knowledge >= cap;
  }

  double get totalPhysical =>
      food +
      woodLog +
      stoneRaw +
      ironOre +
      lumber +
      stoneBrick +
      ironBar +
      knowledge;

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
    CitadelLevel.camp: 6,
    CitadelLevel.village: 10,
    CitadelLevel.town: 14,
    CitadelLevel.city: 19,
    CitadelLevel.fortress: 23,
    CitadelLevel.citadel: 25,
    CitadelLevel.kingdom: 30,
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
    CitadelLevel.citadel: 6,
    CitadelLevel.kingdom: 8,
    CitadelLevel.empire: 10,
    CitadelLevel.ascended: 15,
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
  // Coleta de recursos (Tier 1)
  silviculture, // lenhadores → woodLog
  quarry, // pedreiros → stoneRaw
  // Manufatura (Tier 1–2)
  kitchen,
  sawmill, // carpinteiros → woodLog → lumber  (era woodworking)
  masonry, // canteiros → stoneRaw → stoneBrick (era workshop)
  forge, // ferreiros → ironOre → ironBar
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
  simulacrum,
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

  bool get isUpgradeable => !const {
    BuildingType.prison,
    BuildingType.councilHall,
    BuildingType.warRoom,
    BuildingType.promotionHall,
    BuildingType.synthesisLab,
    BuildingType.alchemyLab,
    BuildingType.nexus,
  }.contains(type);

  bool get canUpgrade => isUpgradeable && (level < maxLevel || tier < 3);
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
    BuildingType.silviculture: [3, 5, 8, 12, 16],
    BuildingType.quarry: [2, 4, 7, 10, 14],
    BuildingType.sawmill: [2, 4, 6, 9, 12],
    BuildingType.masonry: [2, 4, 6, 9, 12],
    BuildingType.forge: [2, 5, 8, 12, 16],
    BuildingType.school: [1, 2, 4, 6, 8],
    BuildingType.library: [1, 2, 4, 6, 8],
    BuildingType.kitchen: [1, 2, 4, 6, 8],
    BuildingType.tent: [4, 6, 8, 10, 12],
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
    BuildingType.silviculture: [
      'Clareira',
      'Plantação Florestal',
      'Campo Florestal',
      'Floresta Gerenciada',
    ],
    BuildingType.quarry: [
      'Escavação',
      'Pedreira',
      'Mina Aberta',
      'Mina Profunda',
    ],
    BuildingType.sawmill: [
      'Serraria',
      'Madeireira',
      'Complexo Madeireiro',
      'Complexo Madeireiro',
    ],
    BuildingType.masonry: [
      'Cantaria',
      'Oficina de Pedra',
      'Lapidação',
      'Lapidação',
    ],
    BuildingType.forge: ['Forja', 'Fundição', 'Refinaria', 'Refinaria'],
    BuildingType.barracks: [
      'Quartel',
      'Academia Militar',
      'Complexo de Treinamento',
      'Complexo de Treinamento',
    ],
    BuildingType.school: ['Escola', 'Escola', 'Escola', 'Escola'],
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
    BuildingType.simulacrum: [
      'Simulacro',
      'Simulacro Avançado',
      'Simulacro Arcano',
      'Simulacro Transcendente',
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
    BuildingType.silviculture: BuildingCategory.production,
    BuildingType.quarry: BuildingCategory.production,
    BuildingType.sawmill: BuildingCategory.production,
    BuildingType.masonry: BuildingCategory.production,
    BuildingType.forge: BuildingCategory.production,
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
    BuildingType.alchemyLab: BuildingCategory.advanced,
    BuildingType.simulacrum: BuildingCategory.advanced,
    BuildingType.warRoom: BuildingCategory.advanced,
    BuildingType.monument: BuildingCategory.advanced,
    BuildingType.nexus: BuildingCategory.advanced,
    // ── NOVO ──────────────────────────────────────────────────────────────────
    BuildingType.wayfareresRefuge: BuildingCategory.social,
  }[type]!;

  int get requiredTier =>
      const {
        BuildingType.firepit: 0, BuildingType.tent: 0, BuildingType.farm: 0,
        BuildingType.kitchen: 1,
        BuildingType.silviculture: 1, BuildingType.quarry: 1,
        BuildingType.sawmill: 1, BuildingType.masonry: 2,
        BuildingType.forge: 1,
        BuildingType.school: 1,
        BuildingType.library: 2,
        BuildingType.infirmary: 1,
        BuildingType.granary: 2,
        BuildingType.barracks: 2, BuildingType.trainingField: 2,
        BuildingType.wall: 2, BuildingType.watchtower: 2,
        BuildingType.tavern: 3, BuildingType.prison: 3,
        BuildingType.market: 3, BuildingType.temple: 3,
        BuildingType.arena: 4, BuildingType.synthesisLab: 5,
        BuildingType.promotionHall: 1, BuildingType.councilHall: 4,
        BuildingType.simulacrum: 1,
        BuildingType.alchemyLab: 7,
        BuildingType.warRoom: 6,
        BuildingType.monument: 8,
        BuildingType.nexus: 9,
        // ── NOVO: disponível no Tier 2 (mesmo nível que barracks) ────────────────
        BuildingType.wayfareresRefuge: 2,
      }[type] ??
      0;

  bool get isUnique => const {
    BuildingType.library,
    BuildingType.temple,
    BuildingType.arena,
    BuildingType.synthesisLab,
    BuildingType.simulacrum,
    BuildingType.promotionHall,
    BuildingType.councilHall,
    BuildingType.alchemyLab,
    BuildingType.warRoom,
    BuildingType.monument,
    BuildingType.nexus,
    BuildingType.wayfareresRefuge,
    BuildingType.prison,
    BuildingType.market,
  }.contains(type);

  /// canEvolve: wayfareresRefuge NÃO entra aqui — único e não evolui com citadela
  bool get canEvolve => const {
    BuildingType.firepit,
    BuildingType.tent,
    BuildingType.farm,
    BuildingType.kitchen,
    BuildingType.silviculture,
    BuildingType.simulacrum,
    BuildingType.quarry,
    BuildingType.sawmill,
    BuildingType.masonry,
    BuildingType.forge,
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
      case BuildingType.granary:
        if (tier == 0) return 'Reduz o gasto de comida em 1.5%';
        if (tier == 1) return 'Reduz o gasto de comida em 2.5%';
        return 'Reduz o gasto de comida em 5%';
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
      case BuildingType.simulacrum:
        return 'Batalhas simuladas com o Master. NPCs ganham INT treinando estratégia nos andares conquistados.';
      case BuildingType.warRoom:
        return '+25% chance de sucesso em expedições, estratégia global';
      case BuildingType.monument:
        return '+5 moral/dia, símbolo de poder, +lealdade geral';
      case BuildingType.nexus:
        return 'Conexão com a Torre: −10% dificuldade, +visão dos andares';
      case BuildingType.silviculture:
        return 'Profissão: Lenhador. Gera troncos/dia baseado no nível + lenhadores alocados. '
            'Troncos são matéria-prima — sem Serraria não viram madeira utilizável.';
      case BuildingType.quarry:
        return 'Profissão: Pedreiro. Extrai pedra bruta/dia baseado no nível + pedreiros. '
            'Pedra bruta é matéria-prima — a Cantaria a transforma em tijolos.';
      case BuildingType.sawmill:
        return 'Profissão: Carpinteiro. Converte troncos em madeira serrada (0.7:1). '
            'Madeira serrada é necessária para construções tier 2+.';
      case BuildingType.masonry:
        return 'Profissão: Canteiro. Converte pedra bruta em tijolos (0.6:1). '
            'Tijolos necessários para construções tier 3+ e muralhas.';
      case BuildingType.forge:
        return 'Profissão: Ferreiro. Converte minério em barras de ferro (0.5:1). '
            'Ferro processado essencial para equipamentos e construções avançadas.';
      case BuildingType.kitchen:
        return 'Profissão: Cozinheiro. Multiplica a produção da farm — sem cozinheiros, sem efeito.';
      // ── NOVO ───────────────────────────────────────────────────────────────
      case BuildingType.wayfareresRefuge:
        return 'Permite recrutar survivors encontrados nos andares conquistados. '
            'Cada survivor chega com lealdade baixa mas combate elevado.';
    }
  }

  ResourcesCost get cost =>
      const {
        // ── Tier 0 — só raw ──
        BuildingType.firepit: ResourcesCost(woodLog: 5),
        BuildingType.tent: ResourcesCost(woodLog: 10),
        BuildingType.farm: ResourcesCost(woodLog: 15, stoneRaw: 5, food: 3),
        BuildingType.granary: ResourcesCost(woodLog: 20, stoneRaw: 10, food: 5),
        BuildingType.kitchen: ResourcesCost(woodLog: 10, stoneRaw: 5, food: 3),
        // ── Tier 1 — raw ──
        BuildingType.silviculture: ResourcesCost(woodLog: 10, stoneRaw: 5),
        BuildingType.quarry: ResourcesCost(
          woodLog: 8,
          stoneRaw: 15,
          ironOre: 5,
        ),
        BuildingType.sawmill: ResourcesCost(
          woodLog: 20,
          stoneRaw: 10,
          ironOre: 5,
        ),
        BuildingType.masonry: ResourcesCost(
          woodLog: 15,
          stoneRaw: 20,
          ironOre: 8,
        ),
        BuildingType.school: ResourcesCost(
          woodLog: 15,
          stoneRaw: 10,
          knowledge: 10,
          food: 5,
        ),
        BuildingType.library: ResourcesCost(
          lumber: 20,
          stoneRaw: 15,
          knowledge: 15,
          food: 8,
        ),
        BuildingType.infirmary: ResourcesCost(
          woodLog: 15,
          stoneRaw: 10,
          knowledge: 5,
          food: 8,
        ),
        BuildingType.barracks: ResourcesCost(
          woodLog: 25,
          stoneRaw: 20,
          ironOre: 10,
          food: 10,
        ),
        BuildingType.trainingField: ResourcesCost(
          woodLog: 25,
          stoneRaw: 20,
          ironOre: 10,
          food: 15,
        ),
        BuildingType.wall: ResourcesCost(stoneRaw: 30, ironOre: 10, food: 15),
        BuildingType.watchtower: ResourcesCost(
          woodLog: 15,
          stoneRaw: 25,
          ironOre: 5,
          food: 8,
        ),
        BuildingType.tavern: ResourcesCost(lumber: 30, stoneRaw: 15, food: 10),
        BuildingType.market: ResourcesCost(lumber: 20, stoneBrick: 15, food: 8),
        BuildingType.temple: ResourcesCost(
          stoneBrick: 30,
          lumber: 20,
          food: 15,
        ),
        BuildingType.prison: ResourcesCost(
          lumber: 30,
          stoneBrick: 40,
          ironBar: 20,
        ),
        BuildingType.arena: ResourcesCost(
          stoneBrick: 40,
          ironBar: 25,
          lumber: 20,
          food: 20,
        ),
        BuildingType.synthesisLab: ResourcesCost(
          lumber: 40,
          ironBar: 30,
          knowledge: 30,
          food: 20,
        ),
        BuildingType.promotionHall: ResourcesCost(
          lumber: 40,
          stoneBrick: 35,
          ironBar: 20,
          knowledge: 25,
        ),
        BuildingType.councilHall: ResourcesCost(
          lumber: 35,
          stoneBrick: 30,
          knowledge: 25,
          food: 20,
        ),
        BuildingType.alchemyLab: ResourcesCost(
          ironBar: 50,
          stoneBrick: 30,
          knowledge: 40,
          food: 25,
        ),
        BuildingType.simulacrum: ResourcesCost(
          lumber: 30,
          stoneBrick: 25,
          ironBar: 15,
          knowledge: 40,
        ),
        BuildingType.warRoom: ResourcesCost(
          ironBar: 60,
          stoneBrick: 40,
          knowledge: 30,
          food: 30,
        ),
        BuildingType.monument: ResourcesCost(
          stoneBrick: 100,
          ironBar: 50,
          lumber: 50,
          food: 40,
        ),
        BuildingType.nexus: ResourcesCost(
          ironBar: 80,
          stoneBrick: 80,
          lumber: 60,
          knowledge: 60,
          food: 50,
        ),
        BuildingType.wayfareresRefuge: ResourcesCost(
          woodLog: 25,
          stoneRaw: 15,
          food: 10,
        ),
      }[type] ??
      const ResourcesCost();

  Resources get upgradeCost {
    final base = cost;
    final mult = level * 1.5;
    return Resources(
      food: base.food * mult,
      knowledge: base.knowledge * mult,
      woodLog: base.woodLog * mult,
      stoneRaw: base.stoneRaw * mult,
      ironOre: base.ironOre * mult,
      lumber: base.lumber * mult,
      stoneBrick: base.stoneBrick * mult,
      ironBar: base.ironBar * mult,
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
    CitadelLevel.shelter: ResourcesCost(woodLog: 50, stoneRaw: 30, food: 30),
    CitadelLevel.camp: ResourcesCost(
      woodLog: 80,
      stoneRaw: 60,
      ironOre: 10,
      food: 40,
    ),
    CitadelLevel.village: ResourcesCost(
      woodLog: 120,
      stoneRaw: 100,
      ironOre: 30,
      food: 60,
    ),
    CitadelLevel.town: ResourcesCost(
      lumber: 180,
      stoneBrick: 150,
      ironOre: 60,
      food: 80,
    ),
    CitadelLevel.city: ResourcesCost(
      lumber: 300,
      stoneBrick: 250,
      ironBar: 100,
      food: 120,
    ),
    CitadelLevel.fortress: ResourcesCost(
      lumber: 500,
      stoneBrick: 400,
      ironBar: 200,
      food: 200,
    ),
    // (continuar o padrão para os níveis seguintes com processed crescente)
    CitadelLevel.citadel: ResourcesCost(
      lumber: 800,
      stoneBrick: 600,
      ironBar: 350,
      knowledge: 250,
    ),
    CitadelLevel.kingdom: ResourcesCost(
      lumber: 1200,
      stoneBrick: 1000,
      ironBar: 600,
      knowledge: 500,
    ),
    CitadelLevel.empire: ResourcesCost(
      lumber: 2000,
      stoneBrick: 1800,
      ironBar: 1000,
      knowledge: 800,
    ),
    CitadelLevel.ascended: ResourcesCost(),
  }[level]!;

  double get totalFoodProduction => buildings
      .where((b) => b.type == BuildingType.farm)
      .fold(0.0, (sum, b) => sum + b.bonus);

  double get totalLumberProduction => buildings
      .where((b) => b.type == BuildingType.sawmill)
      .fold(0.0, (sum, b) => sum + b.bonus);

  double get totalIronBarProduction => buildings
      .where((b) => b.type == BuildingType.forge)
      .fold(0.0, (sum, b) => sum + b.bonus);

  double get totalWoodLogProduction => buildings
      .where((b) => b.type == BuildingType.silviculture)
      .fold(0.0, (sum, b) => sum + b.bonus);

  double get totalStoneRawProduction => buildings
      .where((b) => b.type == BuildingType.quarry)
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

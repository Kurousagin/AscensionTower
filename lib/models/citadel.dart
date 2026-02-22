class Resources {
  double food;
  double wood;
  double stone;
  double iron;
  double knowledge;
  double morale;

  Resources({
    this.food = 50,
    this.wood = 30,
    this.stone = 10,
    this.iron = 0,
    this.knowledge = 5,
    this.morale = 60,
  });

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
  }

  void add(Resources gain) {
    food += gain.food;
    wood += gain.wood;
    stone += gain.stone;
    iron += gain.iron;
    knowledge += gain.knowledge;
    morale += gain.morale;
  }

  void clampAll() {
    food = food.clamp(0, 99999);
    wood = wood.clamp(0, 99999);
    stone = stone.clamp(0, 99999);
    iron = iron.clamp(0, 99999);
    knowledge = knowledge.clamp(0, 99999);
    morale = morale.clamp(0, 100);
  }

  Resources clone() => Resources(
        food: food,
        wood: wood,
        stone: stone,
        iron: iron,
        knowledge: knowledge,
        morale: morale,
      );
}

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
  String get label {
    switch (this) {
      case CitadelLevel.shelter: return 'Abrigo';
      case CitadelLevel.camp: return 'Acampamento';
      case CitadelLevel.village: return 'Vila';
      case CitadelLevel.town: return 'Povoado';
      case CitadelLevel.city: return 'Cidade';
      case CitadelLevel.fortress: return 'Fortaleza';
      case CitadelLevel.citadel: return 'Cidadela';
      case CitadelLevel.kingdom: return 'Reino';
      case CitadelLevel.empire: return 'Imperio';
      case CitadelLevel.ascended: return 'Ascendido';
    }
  }

  String get ascii {
    switch (this) {
      case CitadelLevel.shelter: return '[===]';
      case CitadelLevel.camp: return '[=====]';
      case CitadelLevel.village: return '[========]';
      case CitadelLevel.town: return '[==========]';
      case CitadelLevel.city: return '[=============]';
      case CitadelLevel.fortress: return '[================]';
      case CitadelLevel.citadel: return '[===================]';
      case CitadelLevel.kingdom: return '[======================]';
      case CitadelLevel.empire: return '[==========================]';
      case CitadelLevel.ascended: return '[==============================]';
    }
  }

  int get maxBuildings {
    switch (this) {
      case CitadelLevel.shelter: return 3;
      case CitadelLevel.camp: return 5;
      case CitadelLevel.village: return 8;
      case CitadelLevel.town: return 11;
      case CitadelLevel.city: return 15;
      case CitadelLevel.fortress: return 19;
      case CitadelLevel.citadel: return 23;
      case CitadelLevel.kingdom: return 27;
      case CitadelLevel.empire: return 32;
      case CitadelLevel.ascended: return 40;
    }
  }

  int get populationRequired {
    switch (this) {
      case CitadelLevel.shelter: return 0;
      case CitadelLevel.camp: return 8;
      case CitadelLevel.village: return 15;
      case CitadelLevel.town: return 22;
      case CitadelLevel.city: return 30;
      case CitadelLevel.fortress: return 40;
      case CitadelLevel.citadel: return 55;
      case CitadelLevel.kingdom: return 75;
      case CitadelLevel.empire: return 100;
      case CitadelLevel.ascended: return 150;
    }
  }

  /// Tier minimo da Torre necessario para desbloquear este nivel
  int get requiredTowerTier {
    switch (this) {
      case CitadelLevel.shelter: return 0;
      case CitadelLevel.camp: return 0;
      case CitadelLevel.village: return 1;
      case CitadelLevel.town: return 2;
      case CitadelLevel.city: return 3;
      case CitadelLevel.fortress: return 4;
      case CitadelLevel.citadel: return 5;
      case CitadelLevel.kingdom: return 6;
      case CitadelLevel.empire: return 8;
      case CitadelLevel.ascended: return 10;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// EDIFICIOS - Inspirados em Pick Me Up, Infinite Gacha
// O JOGADOR escolhe o que construir (nao e automatico)
// NPCs REAGEM as construcoes (eventos narrativos)
// ═══════════════════════════════════════════════════════════════

enum BuildingType {
  // === Essenciais (Tier 1) ===
  firepit,       // Fogueira - centro social
  tent,          // Tenda - moradia
  farm,          // Fazenda - comida
  storehouse,    // Armazem - capacidade
  // === Producao (Tier 2) ===
  kitchen,       // Cozinha - comida avancada
  workshop,      // Oficina - producao
  forge,         // Forja - armas
  // === Conhecimento (Tier 3) ===
  school,        // Escola - treino jovens
  library,       // Biblioteca - pesquisa
  infirmary,     // Enfermaria - cura
  // === Militar (Tier 3-4) ===
  barracks,      // Quartel - soldados
  trainingField, // Campo de Treino - treino seguro
  wall,          // Muralha - defesa
  watchtower,    // Torre de Vigia - alertas
  // === Social/Politico (Tier 4-5) ===
  tavern,        // Taverna - social, fofocas, detectar traidores
  market,        // Mercado - troca eficiente
  temple,        // Templo - moral e sanidade
  // === Avancados (Tier 5+) - Inspirados em Pick Me Up ===
  arena,         // Arena - duelos, resolver conflitos, treino combate
  synthesisLab,  // Camara de Sintese - combinar materiais raros
  promotionHall, // Sala de Promocao - melhorar rank de NPCs
  councilHall,   // Sala do Conselho - eventos politicos, votacoes
  // === Endgame (Tier 7+) ===
  alchemyLab,    // Laboratorio Alquimico - itens raros
  warRoom,       // Sala de Guerra - estrategia avancada
  monument,      // Monumento - simbolo de poder, moral massiva
  nexus,         // Nexus - conexao com a Torre, bonus globais
}

/// Categoria do edificio para organizacao na UI
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
  String get label {
    switch (this) {
      case BuildingCategory.essential: return 'Essencial';
      case BuildingCategory.production: return 'Producao';
      case BuildingCategory.knowledge: return 'Conhecimento';
      case BuildingCategory.military: return 'Militar';
      case BuildingCategory.social: return 'Social';
      case BuildingCategory.advanced: return 'Avancado';
      case BuildingCategory.endgame: return 'Endgame';
    }
  }
}

class Building {
  final BuildingType type;
  int level;

  Building({required this.type, this.level = 1});

  String get name {
    switch (type) {
      case BuildingType.firepit: return 'Fogueira';
      case BuildingType.tent: return 'Tenda';
      case BuildingType.storehouse: return 'Armazem';
      case BuildingType.kitchen: return 'Cozinha';
      case BuildingType.infirmary: return 'Enfermaria';
      case BuildingType.workshop: return 'Oficina';
      case BuildingType.school: return 'Escola';
      case BuildingType.forge: return 'Forja';
      case BuildingType.market: return 'Mercado';
      case BuildingType.barracks: return 'Quartel';
      case BuildingType.library: return 'Biblioteca';
      case BuildingType.farm: return 'Fazenda';
      case BuildingType.wall: return 'Muralha';
      case BuildingType.watchtower: return 'Torre de Vigia';
      case BuildingType.temple: return 'Templo';
      case BuildingType.trainingField: return 'Campo de Treino';
      case BuildingType.tavern: return 'Taverna';
      case BuildingType.arena: return 'Arena';
      case BuildingType.synthesisLab: return 'Camara de Sintese';
      case BuildingType.promotionHall: return 'Sala de Promocao';
      case BuildingType.councilHall: return 'Sala do Conselho';
      case BuildingType.alchemyLab: return 'Laboratorio Alquimico';
      case BuildingType.warRoom: return 'Sala de Guerra';
      case BuildingType.monument: return 'Monumento';
      case BuildingType.nexus: return 'Nexus da Torre';
    }
  }

  String get description {
    switch (type) {
      case BuildingType.firepit: return '+1 moral/dia, centro social';
      case BuildingType.tent: return '+5 capacidade populacao';
      case BuildingType.storehouse: return '+50% capacidade recursos';
      case BuildingType.kitchen: return '+3 comida/dia por chef';
      case BuildingType.infirmary: return 'Cura feridos, -30% mortes em expedicoes';
      case BuildingType.workshop: return 'Produz equipamentos, +1 iron/dia';
      case BuildingType.school: return '+1 conhecimento/dia, treina jovens';
      case BuildingType.forge: return '+2 ferro/dia, armas melhores (+10% poder combate)';
      case BuildingType.market: return 'Troca de recursos, +5% eficiencia geral';
      case BuildingType.barracks: return 'Treina guardas, +0.3 FOR soldados/dia';
      case BuildingType.library: return '+3 conhecimento/dia, revela mecanicas ocultas';
      case BuildingType.farm: return '+5 comida/dia';
      case BuildingType.wall: return '-20% risco de ameacas externas';
      case BuildingType.watchtower: return 'Alerta antecipado, detecta traidores +15%';
      case BuildingType.temple: return '+2 moral/dia, +0.5 sanidade/dia para todos';
      case BuildingType.trainingField: return 'Treino seguro (-95% morte), evolucao lenta';
      case BuildingType.tavern: return 'Centro social: +relacoes, revela fofocas e traidores';
      case BuildingType.arena: return 'Duelos entre NPCs, resolve conflitos, +combate';
      case BuildingType.synthesisLab: return 'Combina materiais dos andares em itens raros';
      case BuildingType.promotionHall: return 'Promove NPCs: muda rank, desbloqueia habilidades';
      case BuildingType.councilHall: return 'Votacoes politicas, resolve crises democraticamente';
      case BuildingType.alchemyLab: return 'Cria pocoes e itens especiais de recursos raros';
      case BuildingType.warRoom: return '+25% chance sucesso em expedições, estrategia global';
      case BuildingType.monument: return '+5 moral/dia, simbolo de poder, +lealdade geral';
      case BuildingType.nexus: return 'Conexao com a Torre: -10% dificuldade, +visao dos andares';
    }
  }

  BuildingCategory get category {
    switch (type) {
      case BuildingType.firepit:
      case BuildingType.tent:
      case BuildingType.farm:
      case BuildingType.storehouse:
        return BuildingCategory.essential;
      case BuildingType.kitchen:
      case BuildingType.workshop:
      case BuildingType.forge:
        return BuildingCategory.production;
      case BuildingType.school:
      case BuildingType.library:
      case BuildingType.infirmary:
        return BuildingCategory.knowledge;
      case BuildingType.barracks:
      case BuildingType.trainingField:
      case BuildingType.wall:
      case BuildingType.watchtower:
        return BuildingCategory.military;
      case BuildingType.tavern:
      case BuildingType.market:
      case BuildingType.temple:
        return BuildingCategory.social;
      case BuildingType.arena:
      case BuildingType.synthesisLab:
      case BuildingType.promotionHall:
      case BuildingType.councilHall:
        return BuildingCategory.advanced;
      case BuildingType.alchemyLab:
      case BuildingType.warRoom:
      case BuildingType.monument:
      case BuildingType.nexus:
        return BuildingCategory.endgame;
    }
  }

  /// Tier minimo da torre para desbloquear este edificio
  int get requiredTier {
    switch (type) {
      case BuildingType.firepit: return 0;
      case BuildingType.tent: return 0;
      case BuildingType.farm: return 0;
      case BuildingType.storehouse: return 0;
      case BuildingType.kitchen: return 1;
      case BuildingType.workshop: return 1;
      case BuildingType.forge: return 1;
      case BuildingType.school: return 1;
      case BuildingType.library: return 2;
      case BuildingType.infirmary: return 1;
      case BuildingType.barracks: return 2;
      case BuildingType.trainingField: return 2;
      case BuildingType.wall: return 2;
      case BuildingType.watchtower: return 2;
      case BuildingType.tavern: return 3;
      case BuildingType.market: return 3;
      case BuildingType.temple: return 3;
      case BuildingType.arena: return 4;
      case BuildingType.synthesisLab: return 5;
      case BuildingType.promotionHall: return 5;
      case BuildingType.councilHall: return 4;
      case BuildingType.alchemyLab: return 7;
      case BuildingType.warRoom: return 6;
      case BuildingType.monument: return 8;
      case BuildingType.nexus: return 9;
    }
  }

  String get tag => '[${name.substring(0, 3).toUpperCase()}]';

  Resources get cost {
    switch (type) {
      case BuildingType.firepit: return Resources(wood: 5);
      case BuildingType.tent: return Resources(wood: 10);
      case BuildingType.farm: return Resources(wood: 15, stone: 5);
      case BuildingType.storehouse: return Resources(wood: 15, stone: 10);
      case BuildingType.kitchen: return Resources(wood: 10, stone: 5);
      case BuildingType.workshop: return Resources(wood: 20, stone: 15, iron: 5);
      case BuildingType.forge: return Resources(stone: 25, iron: 15, knowledge: 5);
      case BuildingType.school: return Resources(wood: 15, stone: 10, knowledge: 10);
      case BuildingType.library: return Resources(wood: 20, stone: 15, knowledge: 15);
      case BuildingType.infirmary: return Resources(wood: 15, stone: 10, knowledge: 5);
      case BuildingType.barracks: return Resources(wood: 25, stone: 20, iron: 10);
      case BuildingType.trainingField: return Resources(wood: 25, stone: 20, iron: 10, knowledge: 10);
      case BuildingType.wall: return Resources(stone: 30, iron: 10);
      case BuildingType.watchtower: return Resources(wood: 15, stone: 25, iron: 5);
      case BuildingType.tavern: return Resources(wood: 30, stone: 15, food: 10);
      case BuildingType.market: return Resources(wood: 20, stone: 15);
      case BuildingType.temple: return Resources(stone: 30, wood: 20, knowledge: 20);
      case BuildingType.arena: return Resources(stone: 40, iron: 25, wood: 20);
      case BuildingType.synthesisLab: return Resources(iron: 40, knowledge: 30, stone: 25);
      case BuildingType.promotionHall: return Resources(knowledge: 50, iron: 30, stone: 30);
      case BuildingType.councilHall: return Resources(wood: 35, stone: 30, knowledge: 20);
      case BuildingType.alchemyLab: return Resources(knowledge: 80, iron: 50, stone: 30);
      case BuildingType.warRoom: return Resources(iron: 60, stone: 40, knowledge: 40);
      case BuildingType.monument: return Resources(stone: 100, iron: 50, knowledge: 50, wood: 50);
      case BuildingType.nexus: return Resources(knowledge: 150, iron: 80, stone: 80);
    }
  }

  /// Custo para upgrade (multiplica custo base pelo nivel)
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

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'level': level,
      };

  factory Building.fromJson(Map<String, dynamic> json) => Building(
        type: BuildingType.values[(json['type'] as int? ?? 0).clamp(0, BuildingType.values.length - 1)],
        level: json['level'] as int? ?? 1,
      );
}

class Citadel {
  CitadelLevel level;
  List<Building> buildings;
  Resources resources;
  int populationCapacity;

  Citadel({
    this.level = CitadelLevel.shelter,
    List<Building>? buildings,
    Resources? resources,
    this.populationCapacity = 15,
  })  : buildings = buildings ?? [],
        resources = resources ?? Resources();

  bool get canUpgrade {
    final nextIdx = level.index + 1;
    if (nextIdx >= CitadelLevel.values.length) return false;
    return true;
  }

  CitadelLevel? get nextLevel {
    final nextIdx = level.index + 1;
    if (nextIdx >= CitadelLevel.values.length) return null;
    return CitadelLevel.values[nextIdx];
  }

  Resources get upgradeCost {
    switch (level) {
      case CitadelLevel.shelter:
        return Resources(wood: 50, stone: 30, food: 30);
      case CitadelLevel.camp:
        return Resources(wood: 80, stone: 60, iron: 10, knowledge: 10);
      case CitadelLevel.village:
        return Resources(wood: 120, stone: 100, iron: 30, knowledge: 25);
      case CitadelLevel.town:
        return Resources(wood: 180, stone: 150, iron: 60, knowledge: 50);
      case CitadelLevel.city:
        return Resources(wood: 300, stone: 250, iron: 100, knowledge: 80);
      case CitadelLevel.fortress:
        return Resources(wood: 500, stone: 400, iron: 200, knowledge: 150);
      case CitadelLevel.citadel:
        return Resources(wood: 800, stone: 600, iron: 350, knowledge: 250);
      case CitadelLevel.kingdom:
        return Resources(wood: 1200, stone: 1000, iron: 600, knowledge: 500);
      case CitadelLevel.empire:
        return Resources(wood: 2000, stone: 1800, iron: 1000, knowledge: 800);
      case CitadelLevel.ascended:
        return Resources(); // Nivel maximo
    }
  }

  bool hasBuilding(BuildingType type) =>
      buildings.any((b) => b.type == type);

  Building? getBuilding(BuildingType type) {
    try {
      return buildings.firstWhere((b) => b.type == type);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'level': level.index,
        'buildings': buildings.map((b) => b.toJson()).toList(),
        'resources': resources.toJson(),
        'populationCapacity': populationCapacity,
      };

  factory Citadel.fromJson(Map<String, dynamic> json) => Citadel(
        level: CitadelLevel.values[(json['level'] as int? ?? 0).clamp(0, CitadelLevel.values.length - 1)],
        buildings: (json['buildings'] as List<dynamic>?)
                ?.map((b) => Building.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        resources: json['resources'] != null
            ? Resources.fromJson(json['resources'] as Map<String, dynamic>)
            : null,
        populationCapacity: json['populationCapacity'] as int? ?? 15,
      );
}

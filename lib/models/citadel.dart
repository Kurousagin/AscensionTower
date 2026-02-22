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
    food = food.clamp(0, 9999);
    wood = wood.clamp(0, 9999);
    stone = stone.clamp(0, 9999);
    iron = iron.clamp(0, 9999);
    knowledge = knowledge.clamp(0, 9999);
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
  city,
  kingdom,
}

extension CitadelLevelExt on CitadelLevel {
  String get label {
    switch (this) {
      case CitadelLevel.shelter: return 'Abrigo';
      case CitadelLevel.camp: return 'Acampamento';
      case CitadelLevel.village: return 'Vila';
      case CitadelLevel.city: return 'Cidade';
      case CitadelLevel.kingdom: return 'Reino';
    }
  }

  String get ascii {
    switch (this) {
      case CitadelLevel.shelter: return '[===]';
      case CitadelLevel.camp: return '[=====]';
      case CitadelLevel.village: return '[========]';
      case CitadelLevel.city: return '[===========]';
      case CitadelLevel.kingdom: return '[===============]';
    }
  }

  int get maxBuildings {
    switch (this) {
      case CitadelLevel.shelter: return 3;
      case CitadelLevel.camp: return 6;
      case CitadelLevel.village: return 10;
      case CitadelLevel.city: return 16;
      case CitadelLevel.kingdom: return 25;
    }
  }

  int get populationRequired {
    switch (this) {
      case CitadelLevel.shelter: return 0;
      case CitadelLevel.camp: return 8;
      case CitadelLevel.village: return 15;
      case CitadelLevel.city: return 30;
      case CitadelLevel.kingdom: return 60;
    }
  }
}

enum BuildingType {
  firepit,
  tent,
  storehouse,
  kitchen,
  infirmary,
  workshop,
  school,
  forge,
  market,
  barracks,
  library,
  farm,
  wall,
  tower,
  temple,
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
      case BuildingType.tower: return 'Torre de Vigia';
      case BuildingType.temple: return 'Templo';
    }
  }

  String get description {
    switch (type) {
      case BuildingType.firepit: return '+5 moral/dia, centro social';
      case BuildingType.tent: return '+3 capacidade populacao';
      case BuildingType.storehouse: return '+50 capacidade recursos';
      case BuildingType.kitchen: return '+3 comida/dia por chef';
      case BuildingType.infirmary: return 'Cura feridos, reduz mortes';
      case BuildingType.workshop: return 'Produz equipamentos basicos';
      case BuildingType.school: return '+1 conhecimento/dia, treina jovens';
      case BuildingType.forge: return 'Produz armas e armaduras';
      case BuildingType.market: return 'Troca de recursos eficiente';
      case BuildingType.barracks: return 'Treina guardas, +2 FOR soldados';
      case BuildingType.library: return '+3 conhecimento/dia';
      case BuildingType.farm: return '+5 comida/dia';
      case BuildingType.wall: return 'Defesa contra ameacas';
      case BuildingType.tower: return 'Alerta antecipado de perigos';
      case BuildingType.temple: return '+10 moral, +5 estabilidade mental';
    }
  }

  String get tag => '[${name.substring(0, 3).toUpperCase()}]';

  Resources get cost {
    switch (type) {
      case BuildingType.firepit: return Resources(wood: 5);
      case BuildingType.tent: return Resources(wood: 10);
      case BuildingType.storehouse: return Resources(wood: 15, stone: 10);
      case BuildingType.kitchen: return Resources(wood: 10, stone: 5);
      case BuildingType.infirmary: return Resources(wood: 15, stone: 10, knowledge: 5);
      case BuildingType.workshop: return Resources(wood: 20, stone: 15, iron: 5);
      case BuildingType.school: return Resources(wood: 15, stone: 10, knowledge: 10);
      case BuildingType.forge: return Resources(stone: 25, iron: 15, knowledge: 5);
      case BuildingType.market: return Resources(wood: 20, stone: 15);
      case BuildingType.barracks: return Resources(wood: 25, stone: 20, iron: 10);
      case BuildingType.library: return Resources(wood: 20, stone: 15, knowledge: 15);
      case BuildingType.farm: return Resources(wood: 15, stone: 5);
      case BuildingType.wall: return Resources(stone: 30, iron: 10);
      case BuildingType.tower: return Resources(wood: 15, stone: 25, iron: 5);
      case BuildingType.temple: return Resources(stone: 30, wood: 20, knowledge: 20);
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'level': level,
      };

  factory Building.fromJson(Map<String, dynamic> json) => Building(
        type: BuildingType.values[json['type'] as int? ?? 0],
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
        return Resources(wood: 100, stone: 80, iron: 20, knowledge: 15);
      case CitadelLevel.village:
        return Resources(wood: 200, stone: 150, iron: 50, knowledge: 40);
      case CitadelLevel.city:
        return Resources(wood: 400, stone: 300, iron: 100, knowledge: 80);
      case CitadelLevel.kingdom:
        return Resources();
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
        level: CitadelLevel.values[json['level'] as int? ?? 0],
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

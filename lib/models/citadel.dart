// ═══════════════════════════════════════════════════════════════
// SISTEMA DE ARMAZEM — Capacidade limitada, excedente e perdido
// Nivel 1: ~30 | Nivel 2: ~60 | Nivel 3: ~120 | Espacial: infinito
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// REGRAS DE ARMAZEM (SISTEMA HARDCORE)
// ═══════════════════════════════════════════════════════════════
// - Nao e possivel armazenar acima da capacidade maxima
// - Excedente e PERDIDO sem excecao
// - O UNICO meio de expandir e construindo/melhorando o armazem
// - Nivel 0 (Sem Armazem): cap 30
// - Nivel 1 (Basico): cap 60
// - Nivel 2 (Expandido): cap 120
// - Nivel 3 (Grande): cap 250
// - Nivel Final (Espacial): infinito (muito dificil de alcancar)
// ═══════════════════════════════════════════════════════════════

enum StorageLevel {
  none, // Sem armazem: capacidade base 30
  basic, // Armazem Basico: capacidade 60
  expanded, // Armazem Expandido: capacidade 120
  grand, // Grande Armazem: capacidade 250
  spatial, // Armazem Espacial: capacidade infinita (endgame)
}

extension StorageLevelExt on StorageLevel {
  String get label {
    switch (this) {
      case StorageLevel.none:
        return 'Sem Armazem';
      case StorageLevel.basic:
        return 'Armazem Basico';
      case StorageLevel.expanded:
        return 'Armazem Expandido';
      case StorageLevel.grand:
        return 'Grande Armazem';
      case StorageLevel.spatial:
        return 'Armazem Espacial';
    }
  }

  String get shortLabel {
    switch (this) {
      case StorageLevel.none:
        return 'Nenhum';
      case StorageLevel.basic:
        return 'Basico';
      case StorageLevel.expanded:
        return 'Expandido';
      case StorageLevel.grand:
        return 'Grande';
      case StorageLevel.spatial:
        return 'Espacial';
    }
  }

  /// Capacidade maxima por recurso. -1 = infinito
  double get capacity {
    switch (this) {
      case StorageLevel.none:
        return 30;
      case StorageLevel.basic:
        return 60;
      case StorageLevel.expanded:
        return 120;
      case StorageLevel.grand:
        return 250;
      case StorageLevel.spatial:
        return -1; // infinito
    }
  }

  String get capacityDisplay {
    if (this == StorageLevel.spatial) return 'INFINITO';
    return capacity.toStringAsFixed(0);
  }

  bool get isInfinite => this == StorageLevel.spatial;

  /// Custo para upgrade ao proximo nivel
  Resources get upgradeCost {
    switch (this) {
      case StorageLevel.none:
        return Resources(wood: 15, stone: 10);
      case StorageLevel.basic:
        return Resources(wood: 40, stone: 30, iron: 10);
      case StorageLevel.expanded:
        return Resources(wood: 80, stone: 60, iron: 30, knowledge: 15);
      case StorageLevel.grand:
        return Resources(iron: 80, stone: 100, knowledge: 60, wood: 60);
      case StorageLevel.spatial:
        return Resources(); // ja e maximo
    }
  }

  /// Tier minimo da torre para desbloquear este nivel de armazem
  int get requiredTier {
    switch (this) {
      case StorageLevel.none:
        return 0;
      case StorageLevel.basic:
        return 0;
      case StorageLevel.expanded:
        return 2;
      case StorageLevel.grand:
        return 5;
      case StorageLevel.spatial:
        return 9;
    }
  }

  StorageLevel? get nextLevel {
    final idx = index + 1;
    if (idx >= StorageLevel.values.length) return null;
    return StorageLevel.values[idx];
  }
}

class Resources {
  double food;
  double wood;
  double stone;
  double iron;
  double knowledge;
  double morale;

  Resources({
    this.food = 0,
    this.wood = 0,
    this.stone = 0,
    this.iron = 0,
    this.knowledge = 0,
    this.morale = 0,
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

  /// Adiciona recursos e aplica capacidade imediatamente.
  /// Retorna o excedente perdido. Use este metodo para garantir integridade.
  Resources addCapped(Resources gain, StorageLevel storage) {
    add(gain);
    return clampToCapacity(storage);
  }

  /// Clamp com capacidade do armazem. Excedente e PERDIDO.
  /// Retorna quanto foi perdido por overflow.
  Resources clampToCapacity(StorageLevel storage) {
    final cap = storage.capacity;
    final lost = Resources(
      food: 0,
      wood: 0,
      stone: 0,
      iron: 0,
      knowledge: 0,
      morale: 0,
    );

    if (!storage.isInfinite) {
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

    // Garantir minimo 0
    if (food < 0) food = 0;
    if (wood < 0) wood = 0;
    if (stone < 0) stone = 0;
    if (iron < 0) iron = 0;
    if (knowledge < 0) knowledge = 0;
    morale = morale.clamp(0, 100);

    return lost;
  }

  /// Clamp basico de minimos (nunca negativos)
  void clampAll() {
    food = food.clamp(0, 99999);
    wood = wood.clamp(0, 99999);
    stone = stone.clamp(0, 99999);
    iron = iron.clamp(0, 99999);
    knowledge = knowledge.clamp(0, 99999);
    morale = morale.clamp(0, 100);
  }

  /// Verifica e relata qualquer recurso acima da capacidade (debug/validacao)
  bool hasOverflow(StorageLevel storage) {
    if (storage.isInfinite) return false;
    final cap = storage.capacity;
    return food > cap ||
        wood > cap ||
        stone > cap ||
        iron > cap ||
        knowledge > cap;
  }

  /// Retorna string formatada para display do armazem
  String storageDisplay(StorageLevel storage) {
    if (storage.isInfinite) return 'INF';
    return storage.capacity.toStringAsFixed(0);
  }

  /// Total de recursos perdidos (para UI)
  double get totalLost => food + wood + stone + iron + knowledge;

  /// Verifica se algum recurso esta no cap
  bool anyAtCapacity(StorageLevel storage) {
    if (storage.isInfinite) return false;
    final cap = storage.capacity;
    return food >= cap ||
        wood >= cap ||
        stone >= cap ||
        iron >= cap ||
        knowledge >= cap;
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
      case CitadelLevel.shelter:
        return 'Abrigo';
      case CitadelLevel.camp:
        return 'Acampamento';
      case CitadelLevel.village:
        return 'Vila';
      case CitadelLevel.town:
        return 'Povoado';
      case CitadelLevel.city:
        return 'Cidade';
      case CitadelLevel.fortress:
        return 'Fortaleza';
      case CitadelLevel.citadel:
        return 'Cidadela';
      case CitadelLevel.kingdom:
        return 'Reino';
      case CitadelLevel.empire:
        return 'Imperio';
      case CitadelLevel.ascended:
        return 'Ascendido';
    }
  }

  String get ascii {
    switch (this) {
      case CitadelLevel.shelter:
        return '[===]';
      case CitadelLevel.camp:
        return '[=====]';
      case CitadelLevel.village:
        return '[========]';
      case CitadelLevel.town:
        return '[==========]';
      case CitadelLevel.city:
        return '[=============]';
      case CitadelLevel.fortress:
        return '[================]';
      case CitadelLevel.citadel:
        return '[===================]';
      case CitadelLevel.kingdom:
        return '[======================]';
      case CitadelLevel.empire:
        return '[==========================]';
      case CitadelLevel.ascended:
        return '[==============================]';
    }
  }

  int get maxBuildings {
    switch (this) {
      case CitadelLevel.shelter:
        return 3;
      case CitadelLevel.camp:
        return 5;
      case CitadelLevel.village:
        return 8;
      case CitadelLevel.town:
        return 11;
      case CitadelLevel.city:
        return 15;
      case CitadelLevel.fortress:
        return 19;
      case CitadelLevel.citadel:
        return 23;
      case CitadelLevel.kingdom:
        return 27;
      case CitadelLevel.empire:
        return 32;
      case CitadelLevel.ascended:
        return 40;
    }
  }

  int get populationRequired {
    switch (this) {
      case CitadelLevel.shelter:
        return 0;
      case CitadelLevel.camp:
        return 8;
      case CitadelLevel.village:
        return 15;
      case CitadelLevel.town:
        return 22;
      case CitadelLevel.city:
        return 30;
      case CitadelLevel.fortress:
        return 40;
      case CitadelLevel.citadel:
        return 55;
      case CitadelLevel.kingdom:
        return 75;
      case CitadelLevel.empire:
        return 100;
      case CitadelLevel.ascended:
        return 150;
    }
  }

  /// Tier minimo da Torre necessario para desbloquear este nivel
  int get requiredTowerTier {
    switch (this) {
      case CitadelLevel.shelter:
        return 0;
      case CitadelLevel.camp:
        return 0;
      case CitadelLevel.village:
        return 1;
      case CitadelLevel.town:
        return 2;
      case CitadelLevel.city:
        return 3;
      case CitadelLevel.fortress:
        return 4;
      case CitadelLevel.citadel:
        return 5;
      case CitadelLevel.kingdom:
        return 6;
      case CitadelLevel.empire:
        return 8;
      case CitadelLevel.ascended:
        return 10;
    }
  }

  /// Limite maximo de copias da mesma construcao (para construcoes nao-unicas)
  int get maxBuildingCopies {
    switch (this) {
      case CitadelLevel.shelter:
      case CitadelLevel.camp:
        return 1;
      case CitadelLevel.village:
        return 2;
      case CitadelLevel.town:
        return 3;
      case CitadelLevel.city:
      case CitadelLevel.fortress:
        return 4;
      case CitadelLevel.citadel:
      case CitadelLevel.kingdom:
        return 5;
      case CitadelLevel.empire:
      case CitadelLevel.ascended:
        return 6;
    }
  }

  /// Tier de evolucao de edificios baseado no nivel da cidadela
  /// 0: Basico (Shelter, Camp)
  /// 1: Intermediario (Village, Town)
  /// 2: Avancado (City, Fortress)
  /// 3: Elite (Citadel+)
  int get buildingTier {
    switch (this) {
      case CitadelLevel.shelter:
      case CitadelLevel.camp:
        return 0;
      case CitadelLevel.village:
      case CitadelLevel.town:
        return 1;
      case CitadelLevel.city:
      case CitadelLevel.fortress:
        return 2;
      case CitadelLevel.citadel:
      case CitadelLevel.kingdom:
      case CitadelLevel.empire:
      case CitadelLevel.ascended:
        return 3;
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
  firepit, // Fogueira - centro social
  tent, // Tenda - moradia
  farm, // Fazenda - comida
  // === Producao (Tier 2) ===
  kitchen, // Cozinha - comida avancada
  workshop, // Oficina - producao
  forge, // Forja - armas
  // === Conhecimento (Tier 3) ===
  school, // Escola - treino jovens
  library, // Biblioteca - pesquisa
  infirmary, // Enfermaria - cura
  // === Militar (Tier 3-4) ===
  barracks, // Quartel - soldados
  trainingField, // Campo de Treino - treino seguro
  wall, // Muralha - defesa
  watchtower, // Torre de Vigia - alertas
  // === Social/Politico (Tier 4-5) ===
  tavern, // Taverna - social, fofocas, detectar traidores
  market, // Mercado - troca eficiente
  temple, // Templo - moral e sanidade
  // === Avancados (Tier 5+) - Inspirados em Pick Me Up ===
  arena, // Arena - duelos, resolver conflitos, treino combate
  synthesisLab, // Camara de Sintese - combinar materiais raros
  promotionHall, // Sala de Promocao - melhorar rank de NPCs
  councilHall, // Sala do Conselho - eventos politicos, votacoes
  // === Endgame (Tier 7+) ===
  alchemyLab, // Laboratorio Alquimico - itens raros
  warRoom, // Sala de Guerra - estrategia avancada
  monument, // Monumento - simbolo de poder, moral massiva
  nexus, // Nexus - conexao com a Torre, bonus globais
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
      case BuildingCategory.essential:
        return 'Essencial';
      case BuildingCategory.production:
        return 'Producao';
      case BuildingCategory.knowledge:
        return 'Conhecimento';
      case BuildingCategory.military:
        return 'Militar';
      case BuildingCategory.social:
        return 'Social';
      case BuildingCategory.advanced:
        return 'Avancado';
      case BuildingCategory.endgame:
        return 'Endgame';
    }
  }
}

class Building {
  final BuildingType type;
  int level;
  int tier; // 0=basico, 1=intermediario, 2=avancado, 3=elite

  Building({required this.type, this.level = 1, this.tier = 0});

  String get name {
    switch (type) {
      case BuildingType.firepit:
        // Tier 0: Fogueira, 1: Marco da Vila, 2: Praça Central, 3: Monumento da Ascensão
        return ['Fogueira', 'Marco da Vila', 'Praca Central', 'Monumento da Ascensao'][tier.clamp(0, 3)];
      case BuildingType.tent:
        // Tier 0: Tenda, 1: Casa, 2: Pousada, 3: Residencia
        return ['Tenda', 'Casa', 'Pousada', 'Residencia'][tier.clamp(0, 3)];
      case BuildingType.kitchen:
        return ['Cozinha', 'Refeitorio', 'Salao de Banquetes', 'Salao de Banquetes'][tier.clamp(0, 3)];
      case BuildingType.infirmary:
        return 'Enfermaria';
      case BuildingType.workshop:
        return ['Oficina', 'Manufatura', 'Fabrica', 'Fabrica'][tier.clamp(0, 3)];
      case BuildingType.school:
        return 'Escola';
      case BuildingType.forge:
        return ['Forja', 'Fundicao', 'Refinaria', 'Refinaria'][tier.clamp(0, 3)];
      case BuildingType.market:
        return 'Mercado';
      case BuildingType.barracks:
        return ['Quartel', 'Academia Militar', 'Complexo de Treinamento', 'Complexo de Treinamento'][tier.clamp(0, 3)];
      case BuildingType.library:
        return 'Biblioteca';
      case BuildingType.farm:
        return ['Fazenda', 'Plantacao', 'Fazenda Industrial', 'Fazenda Industrial'][tier.clamp(0, 3)];
      case BuildingType.wall:
        return 'Muralha';
      case BuildingType.watchtower:
        return 'Torre de Vigia';
      case BuildingType.temple:
        return 'Templo';
      case BuildingType.trainingField:
        return 'Campo de Treino';
      case BuildingType.tavern:
        return 'Taverna';
      case BuildingType.arena:
        return 'Arena';
      case BuildingType.synthesisLab:
        return 'Camara de Sintese';
      case BuildingType.promotionHall:
        return 'Sala de Promocao';
      case BuildingType.councilHall:
        return 'Sala do Conselho';
      case BuildingType.alchemyLab:
        return 'Laboratorio Alquimico';
      case BuildingType.warRoom:
        return 'Sala de Guerra';
      case BuildingType.monument:
        return 'Monumento';
      case BuildingType.nexus:
        return 'Nexus da Torre';
    }
  }

  String get description {
    switch (type) {
      case BuildingType.firepit:
        // Tier 0: +1, 1: +2, 2: +3, 3: +5
        final moralBonus = [1, 2, 3, 5][tier.clamp(0, 3)];
        return '+$moralBonus moral/dia, centro social';
      case BuildingType.tent:
        // Tier 0: +2, 1: +4, 2: +8, 3: +15
        final popBonus = [2, 4, 8, 15][tier.clamp(0, 3)];
        return '+$popBonus capacidade populacao';
      case BuildingType.kitchen:
        final foodBonus = [3, 8, 15, 15][tier.clamp(0, 3)];
        return '+$foodBonus comida/dia por chef';
      case BuildingType.infirmary:
        return 'Cura feridos, -30% mortes em expedicoes';
      case BuildingType.workshop:
        if (tier == 0) return 'Produz equipamentos, +1 iron/dia';
        if (tier == 1) return 'Produz equipamentos, +3 iron, +2 wood/dia';
        return 'Produz equipamentos, +6 iron, +5 wood/dia';
      case BuildingType.school:
        return '+1 conhecimento/dia, treina jovens';
      case BuildingType.forge:
        if (tier == 0) return '+2 ferro/dia, armas melhores (+10% poder combate)';
        if (tier == 1) return '+5 ferro/dia, armas superiores (+15% poder combate)';
        return '+10 ferro/dia, armas elite (+25% poder combate)';
      case BuildingType.market:
        return 'Troca de recursos, +5% eficiencia geral';
      case BuildingType.barracks:
        if (tier == 0) return 'Treina guardas, +0.3 FOR soldados/dia';
        if (tier == 1) return 'Treina soldados, +0.5 FOR, +0.3 DEX/dia';
        return 'Treino de elite, +0.8 FOR, +0.5 DEX/dia';
      case BuildingType.library:
        return '+3 conhecimento/dia, revela mecanicas ocultas';
      case BuildingType.farm:
        final foodBonus = [5, 12, 25, 25][tier.clamp(0, 3)];
        return '+$foodBonus comida/dia';
      case BuildingType.wall:
        return '-20% risco de ameacas externas';
      case BuildingType.watchtower:
        return 'Alerta antecipado, detecta traidores +15%';
      case BuildingType.temple:
        return '+2 moral/dia, +0.5 sanidade/dia para todos';
      case BuildingType.trainingField:
        return 'Treino seguro (-95% morte), evolucao lenta';
      case BuildingType.tavern:
        return 'Centro social: +relacoes, revela fofocas e traidores';
      case BuildingType.arena:
        return 'Duelos entre NPCs, resolve conflitos, +combate';
      case BuildingType.synthesisLab:
        return 'Combina materiais dos andares em itens raros';
      case BuildingType.promotionHall:
        return 'Promove NPCs: muda rank, desbloqueia habilidades';
      case BuildingType.councilHall:
        return 'Votacoes politicas, resolve crises democraticamente';
      case BuildingType.alchemyLab:
        return 'Cria pocoes e itens especiais de recursos raros';
      case BuildingType.warRoom:
        return '+25% chance sucesso em expedições, estrategia global';
      case BuildingType.monument:
        return '+5 moral/dia, simbolo de poder, +lealdade geral';
      case BuildingType.nexus:
        return 'Conexao com a Torre: -10% dificuldade, +visao dos andares';
    }
  }

  BuildingCategory get category {
    switch (type) {
      case BuildingType.firepit:
      case BuildingType.tent:
      case BuildingType.farm:
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
      case BuildingType.firepit:
        return 0;
      case BuildingType.tent:
        return 0;
      case BuildingType.farm:
        return 0;
      case BuildingType.kitchen:
        return 1;
      case BuildingType.workshop:
        return 1;
      case BuildingType.forge:
        return 1;
      case BuildingType.school:
        return 1;
      case BuildingType.library:
        return 2;
      case BuildingType.infirmary:
        return 1;
      case BuildingType.barracks:
        return 2;
      case BuildingType.trainingField:
        return 2;
      case BuildingType.wall:
        return 2;
      case BuildingType.watchtower:
        return 2;
      case BuildingType.tavern:
        return 3;
      case BuildingType.market:
        return 3;
      case BuildingType.temple:
        return 3;
      case BuildingType.arena:
        return 4;
      case BuildingType.synthesisLab:
        return 5;
      case BuildingType.promotionHall:
        return 5;
      case BuildingType.councilHall:
        return 4;
      case BuildingType.alchemyLab:
        return 7;
      case BuildingType.warRoom:
        return 6;
      case BuildingType.monument:
        return 8;
      case BuildingType.nexus:
        return 9;
    }
  }

  /// Define se a construcao e unica (nao pode ter multiplas copias)
  bool get isUnique {
    switch (type) {
      case BuildingType.library:
      case BuildingType.temple:
      case BuildingType.arena:
      case BuildingType.synthesisLab:
      case BuildingType.promotionHall:
      case BuildingType.councilHall:
      case BuildingType.alchemyLab:
      case BuildingType.warRoom:
      case BuildingType.monument:
      case BuildingType.nexus:
        return true;
      default:
        return false;
    }
  }

  /// Define se o edificio evolui automaticamente com a cidadela
  bool get canEvolve {
    switch (type) {
      case BuildingType.firepit:
      case BuildingType.tent:
      case BuildingType.farm:
      case BuildingType.kitchen:
      case BuildingType.workshop:
      case BuildingType.forge:
      case BuildingType.barracks:
        return true;
      default:
        return false;
    }
  }

  String get tag => '[${name.substring(0, 3).toUpperCase()}]';

  Resources get cost {
    switch (type) {
      // Tier 0-1: Construcoes basicas (0-5 comida)
      case BuildingType.firepit:
        return Resources(wood: 5);
      case BuildingType.tent:
        return Resources(wood: 10);
      case BuildingType.farm:
        return Resources(wood: 15, stone: 5, food: 3);
      case BuildingType.kitchen:
        return Resources(wood: 10, stone: 5, food: 3);

      // Tier 2-3: Construcoes intermediarias (8-15 comida)
      case BuildingType.workshop:
        return Resources(wood: 20, stone: 15, iron: 5, food: 8);
      case BuildingType.forge:
        return Resources(stone: 25, iron: 15, knowledge: 5, food: 10);
      case BuildingType.school:
        return Resources(wood: 15, stone: 10, knowledge: 10, food: 5);
      case BuildingType.library:
        return Resources(wood: 20, stone: 15, knowledge: 15, food: 8);
      case BuildingType.infirmary:
        return Resources(wood: 15, stone: 10, knowledge: 5, food: 8);
      case BuildingType.barracks:
        return Resources(wood: 25, stone: 20, iron: 10, food: 12);
      case BuildingType.trainingField:
        return Resources(
          wood: 25,
          stone: 20,
          iron: 10,
          knowledge: 10,
          food: 12,
        );
      case BuildingType.wall:
        return Resources(stone: 30, iron: 10, food: 15);
      case BuildingType.watchtower:
        return Resources(wood: 15, stone: 25, iron: 5, food: 10);
      case BuildingType.market:
        return Resources(wood: 20, stone: 15, food: 8);

      // Tier 4-5: Construcoes avancadas (20-25 comida)
      case BuildingType.tavern:
        return Resources(wood: 30, stone: 15, food: 10);
      case BuildingType.temple:
        return Resources(stone: 30, wood: 20, knowledge: 20, food: 20);
      case BuildingType.arena:
        return Resources(stone: 40, iron: 25, wood: 20, food: 25);

      // Tier 6+: Megaestruturas (30-60 comida)
      case BuildingType.synthesisLab:
        return Resources(iron: 40, knowledge: 30, stone: 25, food: 30);
      case BuildingType.promotionHall:
        return Resources(knowledge: 50, iron: 30, stone: 30, food: 35);
      case BuildingType.councilHall:
        return Resources(wood: 35, stone: 30, knowledge: 20, food: 25);
      case BuildingType.alchemyLab:
        return Resources(knowledge: 80, iron: 50, stone: 30, food: 40);
      case BuildingType.warRoom:
        return Resources(iron: 60, stone: 40, knowledge: 40, food: 35);
      case BuildingType.monument:
        return Resources(
          stone: 100,
          iron: 50,
          knowledge: 50,
          wood: 50,
          food: 50,
        );
      case BuildingType.nexus:
        return Resources(knowledge: 150, iron: 80, stone: 80, food: 60);
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

  Map<String, dynamic> toJson() => {'type': type.index, 'level': level, 'tier': tier};

  factory Building.fromJson(Map<String, dynamic> json) => Building(
    type:
        BuildingType.values[(json['type'] as int? ?? 0).clamp(
          0,
          BuildingType.values.length - 1,
        )],
    level: json['level'] as int? ?? 1,
    tier: json['tier'] as int? ?? 0,
  );
}

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

  /// Capacidade atual do armazem
  double get storageCapacity => storageLevel.capacity;
  bool get hasInfiniteStorage => storageLevel.isInfinite;
  String get storageLabel => storageLevel.label;

  /// Calcula capacidade populacional total (base + edificios)
  int get totalPopulationCapacity {
    int total = populationCapacity; // Base da cidadela

    // Adiciona bonus de moradias
    for (final building in buildings) {
      if (building.type == BuildingType.tent) {
        // Tier 0: +2, 1: +4, 2: +8, 3: +15
        final popBonus = [2, 4, 8, 15][building.tier.clamp(0, 3)];
        total += popBonus;
      }
    }

    return total;
  }

  /// Pode fazer upgrade no armazem?
  bool get canUpgradeStorage {
    final next = storageLevel.nextLevel;
    if (next == null) return false;
    return true;
  }

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

  bool hasBuilding(BuildingType type) => buildings.any((b) => b.type == type);

  /// Conta quantas construcoes de um tipo especifico existem
  int countBuildings(BuildingType type) =>
      buildings.where((b) => b.type == type).length;

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
    'storageLevel': storageLevel.index,
  };

  factory Citadel.fromJson(Map<String, dynamic> json) => Citadel(
    level:
        CitadelLevel.values[(json['level'] as int? ?? 0).clamp(
          0,
          CitadelLevel.values.length - 1,
        )],
    buildings:
        (json['buildings'] as List<dynamic>?)
            ?.map((b) => Building.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [],
    resources: json['resources'] != null
        ? Resources.fromJson(json['resources'] as Map<String, dynamic>)
        : null,
    populationCapacity: json['populationCapacity'] as int? ?? 15,
    storageLevel:
        StorageLevel.values[(json['storageLevel'] as int? ?? 0).clamp(
          0,
          StorageLevel.values.length - 1,
        )],
  );
}

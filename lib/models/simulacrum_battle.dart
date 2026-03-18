// lib/models/simulacrum_battle.dart
//
// Modelos do Simulacro — minigame de batalha tática simulada.
// O Master (jogador) aloca monstros nas zonas do andar.
// O NPC Comandante aloca tropas e escolhe estratégias.
// A resolução zona a zona gera ganho de INT escalado pela performance.

import 'package:tower_ascension/models/npc_enums.dart';
import 'floor_faction.dart';

// ─────────────────────────────────────────────
// TIPOS DE TROPA DO NPC
// ─────────────────────────────────────────────

enum TroopType {
  warrior,    // FOR — forte no centro e entrada
  archer,     // AGI — forte em flancos
  strategist, // INT — forte em retaguarda, bônus global de +10% para todas tropas
  healer,     // END — suporte, reduz perdas em caso de derrota
  diplomat,   // CAR — confunde posicionamento inimigo, -10% poder monstros na zona
}

extension TroopTypeExt on TroopType {
  String get label => const {
    TroopType.warrior:    'Guerreiro',
    TroopType.archer:     'Arqueiro',
    TroopType.strategist: 'Estrategista',
    TroopType.healer:     'Curandeiro',
    TroopType.diplomat:   'Diplomata',
  }[this]!;

  String get icon => const {
    TroopType.warrior:    '⚔',
    TroopType.archer:     '🏹',
    TroopType.strategist: '🧠',
    TroopType.healer:     '✚',
    TroopType.diplomat:   '🤝',
  }[this]!;

  String get description => const {
    TroopType.warrior:    'Força bruta. Eficaz em zonas abertas e entradas.',
    TroopType.archer:     'Ataques à distância. Eficaz em flancos e torres.',
    TroopType.strategist: 'Coordena o grupo. +10% poder de todas as tropas.',
    TroopType.healer:     'Suporte. Reduz perdas mesmo em zonas perdidas.',
    TroopType.diplomat:   'Confunde os inimigos. -10% poder dos monstros na zona.',
  }[this]!;

  /// Atributo base que define o poder desta tropa
  String get primaryStat => const {
    TroopType.warrior:    'strength',
    TroopType.archer:     'agility',
    TroopType.strategist: 'intelligence',
    TroopType.healer:     'endurance',
    TroopType.diplomat:   'charisma',
  }[this]!;
}

// ─────────────────────────────────────────────
// ESTRATÉGIA DE ATAQUE POR ZONA
// ─────────────────────────────────────────────

enum ZoneStrategy {
  directAssault,  // Assalto Direto — usa FOR, sem bônus especial
  infiltration,   // Infiltração — usa AGI, ignora emboscadas
  tacticalAnalysis, // Análise Tática — usa INT, revela armadilhas antes do confronto
  siege,          // Cerco — bônus se zonas adjacentes também vencidas
  negotiation,    // Negociação — usa CAR, chance de converter monstro menor
}

extension ZoneStrategyExt on ZoneStrategy {
  String get label => const {
    ZoneStrategy.directAssault:    'Assalto Direto',
    ZoneStrategy.infiltration:     'Infiltração',
    ZoneStrategy.tacticalAnalysis: 'Análise Tática',
    ZoneStrategy.siege:            'Cerco',
    ZoneStrategy.negotiation:      'Negociação',
  }[this]!;

  String get icon => const {
    ZoneStrategy.directAssault:    '⚔',
    ZoneStrategy.infiltration:     '👁',
    ZoneStrategy.tacticalAnalysis: '🧠',
    ZoneStrategy.siege:            '🔒',
    ZoneStrategy.negotiation:      '🤝',
  }[this]!;

  String get description => const {
    ZoneStrategy.directAssault:
        'Ataque frontal. Usa força bruta. Eficaz contra Patrulhas.',
    ZoneStrategy.infiltration:
        'Movimento silencioso. Ignora Emboscadores. Requer AGI.',
    ZoneStrategy.tacticalAnalysis:
        'Analisa o terreno. Revela Armadilhas. Requer INT alta.',
    ZoneStrategy.siege:
        'Corta retirada. Bônus +20% se zonas adjacentes controladas.',
    ZoneStrategy.negotiation:
        'Tenta converter monstros menores. Requer CAR. Pode falhar.',
  }[this]!;

  /// INT mínima para esta estratégia ser visível ao NPC
  double get requiredIntelligence => const {
    ZoneStrategy.directAssault:    0.0,
    ZoneStrategy.infiltration:     4.0,
    ZoneStrategy.tacticalAnalysis: 7.0,
    ZoneStrategy.siege:            5.0,
    ZoneStrategy.negotiation:      6.0,
  }[this]!;
}

// ─────────────────────────────────────────────
// TIPOS DE MONSTRO (Master)
// ─────────────────────────────────────────────

enum MonsterType {
  patrol,      // Patrulha — forte em zonas abertas, fraco contra infiltração
  ambusher,    // Emboscador — forte em zonas fechadas, fraco em zonas abertas
  monsterCommander, // Comandante — bônus +15% para todos monstros na mesma zona
  trap,        // Armadilha — invisível até análise tática, +50% poder se não detectada
  brute,       // Bruto — poder puro, sem bônus ou fraquezas especiais
}

extension MonsterTypeExt on MonsterType {
  String get label => const {
    MonsterType.patrol:           'Patrulha',
    MonsterType.ambusher:         'Emboscador',
    MonsterType.monsterCommander: 'Comandante',
    MonsterType.trap:             'Armadilha',
    MonsterType.brute:            'Bruto',
  }[this]!;

  String get icon => const {
    MonsterType.patrol:           '👁',
    MonsterType.ambusher:         '🗡',
    MonsterType.monsterCommander: '💀',
    MonsterType.trap:             '⚡',
    MonsterType.brute:            '👊',
  }[this]!;
}

// ─────────────────────────────────────────────
// TROPA INSTANCIADA (NPC)
// ─────────────────────────────────────────────

class SimulacrumTroop {
  final TroopType type;
  final double power; // calculado do atributo primário do NPC
  String? assignedZoneId;

  SimulacrumTroop({
    required this.type,
    required this.power,
    this.assignedZoneId,
  });
}

// ─────────────────────────────────────────────
// MONSTRO INSTANCIADO (Master)
// ─────────────────────────────────────────────

class SimulacrumMonster {
  final String id;
  final MonsterType type;
  final double power;
  final String name;
  bool revealed; // armadilhas começam não reveladas
  String? assignedZoneId;

  SimulacrumMonster({
    required this.id,
    required this.type,
    required this.power,
    required this.name,
    this.revealed = true,
    this.assignedZoneId,
  });
}

// ─────────────────────────────────────────────
// ZONA DO MAPA
// ─────────────────────────────────────────────

enum ZoneAdvantage {
  open,    // Vantagem do atacante — Patrulhas fortes, Emboscadores fracos
  closed,  // Vantagem do defensor — Emboscadores fortes, Infiltração fraca
  neutral, // Sem vantagem
  elevated, // Torres e alturas — Arqueiros fortes
}

class BattleZone {
  final String id;
  final String name;        // "Portão Norte", "Salão Central", etc.
  final String flavorText;  // Derivado da lore do andar
  final ZoneAdvantage advantage;
  final List<String> adjacentZoneIds; // Para bônus de Cerco
  final double x; // posição no mapa SVG (0.0 a 1.0)
  final double y;

  const BattleZone({
    required this.id,
    required this.name,
    required this.flavorText,
    required this.advantage,
    required this.adjacentZoneIds,
    required this.x,
    required this.y,
  });
}

// ─────────────────────────────────────────────
// LAYOUT DO MAPA (5 layouts pré-definidos)
// ─────────────────────────────────────────────

class SimulacrumMapLayout {
  final String layoutName;
  final List<BattleZone> zones;
  final String backgroundDescription; // para o SVG

  const SimulacrumMapLayout({
    required this.layoutName,
    required this.zones,
    required this.backgroundDescription,
  });

  /// Retorna o layout baseado no nome do andar
  static SimulacrumMapLayout forFloor(String floorName, int floorNumber) {
    final idx = floorNumber % 5;
    switch (idx) {
      case 0:
        return _fortressLayout(floorName);
      case 1:
        return _labyrinthLayout(floorName);
      case 2:
        return _ruinsLayout(floorName);
      case 3:
        return _towerLayout(floorName);
      default:
        return _arenaLayout(floorName);
    }
  }

  // ── Layout: Fortaleza (portões + salão central + torres) ──
  static SimulacrumMapLayout _fortressLayout(String name) {
    return SimulacrumMapLayout(
      layoutName: 'Fortaleza',
      backgroundDescription: 'Muralhas de pedra escura. Três entradas visíveis.',
      zones: [
        const BattleZone(
          id: 'gate_north',
          name: 'Portão Norte',
          flavorText: 'A entrada principal. Guardas sempre patrulham aqui.',
          advantage: ZoneAdvantage.open,
          adjacentZoneIds: ['hall_central', 'tower_west'],
          x: 0.5, y: 0.1,
        ),
        const BattleZone(
          id: 'tower_west',
          name: 'Torre Oeste',
          flavorText: 'Alta e isolada. Quem a controla vê tudo.',
          advantage: ZoneAdvantage.elevated,
          adjacentZoneIds: ['gate_north', 'hall_central'],
          x: 0.1, y: 0.4,
        ),
        const BattleZone(
          id: 'hall_central',
          name: 'Salão Central',
          flavorText: 'O coração da fortaleza. Terreno neutro e disputado.',
          advantage: ZoneAdvantage.neutral,
          adjacentZoneIds: ['gate_north', 'tower_west', 'tower_east', 'keep'],
          x: 0.5, y: 0.45,
        ),
        const BattleZone(
          id: 'tower_east',
          name: 'Torre Leste',
          flavorText: 'Espelha a Torre Oeste. Sombras densas ao entardecer.',
          advantage: ZoneAdvantage.elevated,
          adjacentZoneIds: ['gate_north', 'hall_central'],
          x: 0.9, y: 0.4,
        ),
        const BattleZone(
          id: 'keep',
          name: 'Torre de Comando',
          flavorText: 'O último bastião. Quem cai aqui, perde tudo.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['hall_central'],
          x: 0.5, y: 0.85,
        ),
      ],
    );
  }

  // ── Layout: Labirinto (corredores + câmara central + saídas) ──
  static SimulacrumMapLayout _labyrinthLayout(String name) {
    return SimulacrumMapLayout(
      layoutName: 'Labirinto',
      backgroundDescription: 'Corredores que se bifurcam. Sem saída visível.',
      zones: [
        const BattleZone(
          id: 'entrance',
          name: 'Entrada',
          flavorText: 'O único ponto de entrada conhecido.',
          advantage: ZoneAdvantage.open,
          adjacentZoneIds: ['corridor_left', 'corridor_right'],
          x: 0.5, y: 0.1,
        ),
        const BattleZone(
          id: 'corridor_left',
          name: 'Corredor Esquerdo',
          flavorText: 'Paredes úmidas. Sons distantes de movimento.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['entrance', 'chamber'],
          x: 0.15, y: 0.5,
        ),
        const BattleZone(
          id: 'corridor_right',
          name: 'Corredor Direito',
          flavorText: 'Marcas nas paredes. Alguém passou aqui antes.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['entrance', 'chamber'],
          x: 0.85, y: 0.5,
        ),
        const BattleZone(
          id: 'chamber',
          name: 'Câmara Central',
          flavorText: 'A sala onde todos os caminhos convergem.',
          advantage: ZoneAdvantage.neutral,
          adjacentZoneIds: ['corridor_left', 'corridor_right', 'core'],
          x: 0.5, y: 0.55,
        ),
        const BattleZone(
          id: 'core',
          name: 'Núcleo do Labirinto',
          flavorText: 'O centro. A origem de tudo isso.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['chamber'],
          x: 0.5, y: 0.88,
        ),
      ],
    );
  }

  // ── Layout: Ruínas (3 zonas + acesso central) ──
  static SimulacrumMapLayout _ruinsLayout(String name) {
    return SimulacrumMapLayout(
      layoutName: 'Ruínas',
      backgroundDescription: 'Estruturas colapsadas. Terreno irregular.',
      zones: [
        const BattleZone(
          id: 'outer_ruins',
          name: 'Ruínas Externas',
          flavorText: 'Escombros que antes foram muralhas. Terreno aberto.',
          advantage: ZoneAdvantage.open,
          adjacentZoneIds: ['collapsed_arch', 'sunken_hall'],
          x: 0.5, y: 0.12,
        ),
        const BattleZone(
          id: 'collapsed_arch',
          name: 'Arco Colapsado',
          flavorText: 'Pedras instáveis. Emboscadas são fáceis aqui.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['outer_ruins', 'sunken_hall'],
          x: 0.15, y: 0.5,
        ),
        const BattleZone(
          id: 'sunken_hall',
          name: 'Salão Submerso',
          flavorText: 'Água escura no joelho. Movimentos lentos.',
          advantage: ZoneAdvantage.neutral,
          adjacentZoneIds: ['outer_ruins', 'collapsed_arch', 'inner_sanctum'],
          x: 0.75, y: 0.5,
        ),
        const BattleZone(
          id: 'inner_sanctum',
          name: 'Sanctum Interior',
          flavorText: 'O que resta do coração desta ruína.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['sunken_hall', 'collapsed_arch'],
          x: 0.5, y: 0.85,
        ),
      ],
    );
  }

  // ── Layout: Torre (andares verticais) ──
  static SimulacrumMapLayout _towerLayout(String name) {
    return SimulacrumMapLayout(
      layoutName: 'Torre',
      backgroundDescription: 'Estrutura vertical. Cada andar é uma zona.',
      zones: [
        const BattleZone(
          id: 'base',
          name: 'Base da Torre',
          flavorText: 'O térreo. A única entrada. Sempre guardado.',
          advantage: ZoneAdvantage.open,
          adjacentZoneIds: ['middle_floor'],
          x: 0.5, y: 0.85,
        ),
        const BattleZone(
          id: 'middle_floor',
          name: 'Andar do Meio',
          flavorText: 'Escada estreita. Um de frente ao outro.',
          advantage: ZoneAdvantage.neutral,
          adjacentZoneIds: ['base', 'upper_floor', 'side_passage'],
          x: 0.5, y: 0.55,
        ),
        const BattleZone(
          id: 'side_passage',
          name: 'Passagem Lateral',
          flavorText: 'Uma abertura oculta na parede. Poucos a conhecem.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['middle_floor', 'upper_floor'],
          x: 0.15, y: 0.45,
        ),
        const BattleZone(
          id: 'upper_floor',
          name: 'Andar Superior',
          flavorText: 'Vista privilegiada. Quem chega aqui controla tudo.',
          advantage: ZoneAdvantage.elevated,
          adjacentZoneIds: ['middle_floor', 'side_passage', 'apex'],
          x: 0.5, y: 0.3,
        ),
        const BattleZone(
          id: 'apex',
          name: 'Ápice',
          flavorText: 'O topo. O objetivo final. Não há mais para onde recuar.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['upper_floor'],
          x: 0.5, y: 0.08,
        ),
      ],
    );
  }

  // ── Layout: Arena (campo aberto com posições táticas) ──
  static SimulacrumMapLayout _arenaLayout(String name) {
    return SimulacrumMapLayout(
      layoutName: 'Arena',
      backgroundDescription: 'Campo aberto. Nenhum lugar para se esconder.',
      zones: [
        const BattleZone(
          id: 'north_flank',
          name: 'Flanco Norte',
          flavorText: 'Terreno elevado ao norte. Vantagem para quem chega primeiro.',
          advantage: ZoneAdvantage.open,
          adjacentZoneIds: ['center', 'west_flank'],
          x: 0.5, y: 0.1,
        ),
        const BattleZone(
          id: 'west_flank',
          name: 'Flanco Oeste',
          flavorText: 'Flanqueamento clássico. Risco e recompensa.',
          advantage: ZoneAdvantage.open,
          adjacentZoneIds: ['north_flank', 'center'],
          x: 0.1, y: 0.5,
        ),
        const BattleZone(
          id: 'center',
          name: 'Centro da Arena',
          flavorText: 'Quem controla o centro, controla o combate.',
          advantage: ZoneAdvantage.neutral,
          adjacentZoneIds: ['north_flank', 'west_flank', 'east_flank', 'command'],
          x: 0.5, y: 0.5,
        ),
        const BattleZone(
          id: 'east_flank',
          name: 'Flanco Leste',
          flavorText: 'Espelho do flanco oeste. Simétrico e imprevisível.',
          advantage: ZoneAdvantage.open,
          adjacentZoneIds: ['north_flank', 'center'],
          x: 0.9, y: 0.5,
        ),
        const BattleZone(
          id: 'command',
          name: 'Posto de Comando',
          flavorText: 'A retaguarda inimiga. Destruí-la é vencer.',
          advantage: ZoneAdvantage.closed,
          adjacentZoneIds: ['center'],
          x: 0.5, y: 0.88,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RESULTADO DE ZONA
// ─────────────────────────────────────────────

enum ZoneOutcome { npcWin, masterWin, draw, abandoned }

class ZoneResult {
  final String zoneId;
  final ZoneOutcome outcome;
  final double npcPower;
  final double masterPower;
  final String narrative; // linha narrativa gerada pela resolução
  final bool bonusDecision; // o NPC tomou uma decisão acertada?

  const ZoneResult({
    required this.zoneId,
    required this.outcome,
    required this.npcPower,
    required this.masterPower,
    required this.narrative,
    this.bonusDecision = false,
  });
}

// ─────────────────────────────────────────────
// ESTADO DA BATALHA
// ─────────────────────────────────────────────

enum BattlePhase {
  masterAllocation,  // Master alocando monstros
  npcAllocation,     // NPC escolhendo tropas e estratégias
  resolution,        // Resolução em andamento
  completed,         // Batalha encerrada
}

class SimulacrumBattle {
  final String id;
  final String npcId;
  final int floorNumber;
  final String floorName;
  final SimulacrumMapLayout layout;
  final FloorFaction faction;
  final int tier;

  BattlePhase phase;
  List<SimulacrumMonster> masterMonsters;
  List<SimulacrumTroop> npcTroops;
  Map<String, ZoneStrategy> npcStrategies; // zoneId → strategy
  List<ZoneResult> zoneResults;
  double intGained;
  bool npcVictory;
  int startDay;

  SimulacrumBattle({
    required this.id,
    required this.npcId,
    required this.floorNumber,
    required this.floorName,
    required this.layout,
    required this.faction,
    required this.tier,
    required this.startDay,
    this.phase = BattlePhase.masterAllocation,
    List<SimulacrumMonster>? masterMonsters,
    List<SimulacrumTroop>? npcTroops,
    Map<String, ZoneStrategy>? npcStrategies,
    List<ZoneResult>? zoneResults,
    this.intGained = 0.0,
    this.npcVictory = false,
  })  : masterMonsters = masterMonsters ?? [],
        npcTroops = npcTroops ?? [],
        npcStrategies = npcStrategies ?? {},
        zoneResults = zoneResults ?? [];

  /// Zonas disponíveis neste layout
  List<BattleZone> get zones => layout.zones;

  /// Monstros alocados numa zona específica
  List<SimulacrumMonster> monstersInZone(String zoneId) =>
      masterMonsters.where((m) => m.assignedZoneId == zoneId).toList();

  /// Tropas alocadas numa zona específica
  List<SimulacrumTroop> troopsInZone(String zoneId) =>
      npcTroops.where((t) => t.assignedZoneId == zoneId).toList();

  /// Quantas zonas o NPC venceu
  int get npcZoneWins =>
      zoneResults.where((r) => r.outcome == ZoneOutcome.npcWin).length;

  /// Quantas zonas o Master venceu
  int get masterZoneWins =>
      zoneResults.where((r) => r.outcome == ZoneOutcome.masterWin).length;

  /// Quantas decisões acertadas o NPC tomou
  int get bonusDecisions => zoneResults.where((r) => r.bonusDecision).length;
}

// ─────────────────────────────────────────────
// POOL DE MONSTROS POR FACÇÃO
// ─────────────────────────────────────────────

class MonsterPool {
  /// Retorna o pool de tipos de monstro disponíveis para o Master
  /// baseado na facção controladora do andar.
  static List<_MonsterTemplate> forFaction(FloorFaction faction, int tier) {
    final basePower = 3.0 + tier * 1.5;

    switch (faction) {
      case FloorFaction.ironPact:
        return [
          _MonsterTemplate(MonsterType.brute, 'Guerreiro do Pacto', basePower * 1.2),
          _MonsterTemplate(MonsterType.patrol, 'Sentinela de Ferro', basePower),
          _MonsterTemplate(MonsterType.monsterCommander, 'Comandante do Pacto', basePower * 0.8),
          _MonsterTemplate(MonsterType.brute, 'Cavaleiro Blindado', basePower * 1.4),
        ];
      case FloorFaction.bloodMarket:
        return [
          _MonsterTemplate(MonsterType.ambusher, 'Assassino do Mercado', basePower * 1.1),
          _MonsterTemplate(MonsterType.trap, 'Armadilha Envenenada', basePower * 0.9),
          _MonsterTemplate(MonsterType.patrol, 'Cobrador', basePower * 0.8),
          _MonsterTemplate(MonsterType.ambusher, 'Ladrão de Sombras', basePower * 1.0),
        ];
      case FloorFaction.silentOrder:
        return [
          _MonsterTemplate(MonsterType.monsterCommander, 'Arquivista Corrompido', basePower),
          _MonsterTemplate(MonsterType.trap, 'Runas Proibidas', basePower * 1.2),
          _MonsterTemplate(MonsterType.ambusher, 'Guardião do Conhecimento', basePower * 0.9),
          _MonsterTemplate(MonsterType.patrol, 'Escriba Armado', basePower * 0.7),
        ];
      case FloorFaction.voidChildren:
        return [
          _MonsterTemplate(MonsterType.trap, 'Anomalia do Vazio', basePower * 1.3),
          _MonsterTemplate(MonsterType.ambusher, 'Filho do Caos', basePower * 1.1),
          _MonsterTemplate(MonsterType.brute, 'Entidade Caótica', basePower * 1.5),
          _MonsterTemplate(MonsterType.monsterCommander, 'Pregador do Vazio', basePower * 0.9),
        ];
      case FloorFaction.towerServants:
        return [
          _MonsterTemplate(MonsterType.patrol, 'Servo da Torre', basePower),
          _MonsterTemplate(MonsterType.monsterCommander, 'Guardião Ancestral', basePower * 1.1),
          _MonsterTemplate(MonsterType.brute, 'Construto de Pedra', basePower * 1.3),
          _MonsterTemplate(MonsterType.trap, 'Selo Antigo', basePower * 0.8),
        ];
      case FloorFaction.none:
      default:
        return [
          _MonsterTemplate(MonsterType.patrol, 'Patrulha Errante', basePower),
          _MonsterTemplate(MonsterType.ambusher, 'Emboscador', basePower * 0.9),
          _MonsterTemplate(MonsterType.brute, 'Criatura Selvagem', basePower * 1.1),
          _MonsterTemplate(MonsterType.trap, 'Armadilha Primitiva', basePower * 0.7),
          _MonsterTemplate(MonsterType.monsterCommander, 'Líder da Horda', basePower * 0.8),
        ];
    }
  }

  /// Quantos monstros o Master pode alocar baseado no tier
  static int monsterCount(int tier) => (2 + tier).clamp(2, 6);
}

class _MonsterTemplate {
  final MonsterType type;
  final String name;
  final double power;
  const _MonsterTemplate(this.type, this.name, this.power);
}
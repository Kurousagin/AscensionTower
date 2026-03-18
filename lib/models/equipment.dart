// lib/models/equipment.dart
// ─────────────────────────────────────────────
// Sistema de Equipamentos — Fase 1
// ─────────────────────────────────────────────
// Slots: weapon | armor | accessory (3 por NPC)
// Raridades: common → legendary (5 níveis)
// Origem: drop de andar OU craft na Forja
// ─────────────────────────────────────────────

// ── Slot ───────────────────────────────────────

enum EquipmentSlot { weapon, armor, accessory }

extension EquipmentSlotExt on EquipmentSlot {
  String get label => const {
    EquipmentSlot.weapon: 'Arma',
    EquipmentSlot.armor: 'Armadura',
    EquipmentSlot.accessory: 'Acessório',
  }[this]!;

  String get icon => const {
    EquipmentSlot.weapon: '⚔',
    EquipmentSlot.armor: '🛡',
    EquipmentSlot.accessory: '💍',
  }[this]!;

  /// Atributos primários de cada slot — usados na geração de bônus
  List<String> get primaryStats => const {
    EquipmentSlot.weapon: ['strength', 'agility'],
    EquipmentSlot.armor: ['endurance', 'endurance'], // peso duplo em RES
    EquipmentSlot.accessory: ['intelligence', 'luck'],
  }[this]!;
}

// ── Raridade ───────────────────────────────────

enum EquipmentRarity { common, uncommon, rare, epic, legendary }

extension EquipmentRarityExt on EquipmentRarity {
  String get label => const {
    EquipmentRarity.common: 'Comum',
    EquipmentRarity.uncommon: 'Incomum',
    EquipmentRarity.rare: 'Raro',
    EquipmentRarity.epic: 'Épico',
    EquipmentRarity.legendary: 'Lendário',
  }[this]!;

  String get prefix => const {
    EquipmentRarity.common: '',
    EquipmentRarity.uncommon: '★ ',
    EquipmentRarity.rare: '★★ ',
    EquipmentRarity.epic: '★★★ ',
    EquipmentRarity.legendary: '◆ ',
  }[this]!;

  /// Multiplicador de bônus de atributo base por raridade
  double get statMultiplier => const {
    EquipmentRarity.common: 1.0,
    EquipmentRarity.uncommon: 1.5,
    EquipmentRarity.rare: 2.2,
    EquipmentRarity.epic: 3.2,
    EquipmentRarity.legendary: 5.0,
  }[this]!;

  /// Cor terminal para UI (hex string)
  String get colorHex => const {
    EquipmentRarity.common: '718096', // dim
    EquipmentRarity.uncommon: '48BB78', // green
    EquipmentRarity.rare: '00B4D8', // cyan
    EquipmentRarity.epic: 'B794F4', // purple
    EquipmentRarity.legendary: 'ECC94B', // gold
  }[this]!;

  /// Chance de drop por tier (base + tier scaling)
  /// Retorna a probabilidade DENTRO de um drop já confirmado
  double dropWeight(int tier) => switch (this) {
    EquipmentRarity.common => 0.50 - tier * 0.02, // diminui com tier
    EquipmentRarity.uncommon => 0.25,
    EquipmentRarity.rare => 0.13 + tier * 0.01,
    EquipmentRarity.epic => 0.07 + tier * 0.01,
    EquipmentRarity.legendary => 0.05 + tier * 0.005,
  };
}

// ── Equipment ─────────────────────────────────

class Equipment {
  final String id;
  String name;
  final EquipmentSlot slot;
  final EquipmentRarity rarity;
  final int floorOrigin; // 0 = craftado
  final bool isCrafted;

  /// Bônus de atributos: chaves = nomes dos campos em NpcAttributes
  /// ex: {'strength': 2.5, 'agility': 1.0}
  final Map<String, double> statBonus;

  String description;

  /// ID do NPC que está usando este equipamento (null = no inventário)
  String? equippedByNpcId;

  Equipment({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.floorOrigin,
    required this.statBonus,
    required this.description,
    this.isCrafted = false,
    this.equippedByNpcId,
  });

  bool get isEquipped => equippedByNpcId != null;

  /// String resumida dos bônus para exibição
  String get bonusSummary {
    return statBonus.entries
        .map((e) => '+${e.value.toStringAsFixed(1)} ${_statLabel(e.key)}')
        .join(', ');
  }

  String _statLabel(String key) =>
      const {
        'strength': 'FOR',
        'agility': 'AGI',
        'intelligence': 'INT',
        'endurance': 'RES',
        'charisma': 'CAR',
        'luck': 'SORT',
        'mentalStability': 'SAN',
      }[key] ??
      key;

  // ── Serialização ───────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slot': slot.name,
    'rarity': rarity.name,
    'floorOrigin': floorOrigin,
    'isCrafted': isCrafted,
    'statBonus': statBonus,
    'description': description,
    'equippedByNpcId': equippedByNpcId,
  };

  factory Equipment.fromJson(Map<String, dynamic> json) {
    T parseEnum<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.firstWhere((e) => e.name == name, orElse: () => fallback);

    return Equipment(
      id: json['id'] as String,
      name: json['name'] as String,
      slot: parseEnum(
        EquipmentSlot.values,
        json['slot'] as String?,
        EquipmentSlot.weapon,
      ),
      rarity: parseEnum(
        EquipmentRarity.values,
        json['rarity'] as String?,
        EquipmentRarity.common,
      ),
      floorOrigin: json['floorOrigin'] as int? ?? 0,
      isCrafted: json['isCrafted'] as bool? ?? false,
      statBonus:
          (json['statBonus'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      description: json['description'] as String? ?? '',
      equippedByNpcId: json['equippedByNpcId'] as String?,
    );
  }
}

// ── EquipmentFactory ───────────────────────────
// Geração procedural de itens — nomes, bônus e descrições

class EquipmentFactory {
  static const _weaponNames = {
    EquipmentRarity.common: [
      'Adaga Enferrujada',
      'Lança Simples',
      'Machado Cru',
      'Faca de Osso',
    ],
    EquipmentRarity.uncommon: [
      'Espada Curta',
      'Lança Reforçada',
      'Machado Afiado',
      'Punho de Ferro',
    ],
    EquipmentRarity.rare: [
      'Espada Longa',
      'Alabarda',
      'Machado de Guerra',
      'Garra Dupla',
    ],
    EquipmentRarity.epic: [
      'Lâmina Espectral',
      'Fauces do Abismo',
      'Ceifadora',
      'Punho do Trovão',
    ],
    EquipmentRarity.legendary: [
      'Espada da Torre',
      'Lança do Primordial',
      'Machado do Fim',
      'Garra Dimensional',
    ],
  };

  static const _armorNames = {
    EquipmentRarity.common: [
      'Couro Batido',
      'Vestes Rasgadas',
      'Placa Simples',
      'Malha Tosca',
    ],
    EquipmentRarity.uncommon: [
      'Couro Reforçado',
      'Cota de Malha',
      'Placa de Ferro',
      'Escama de Réptil',
    ],
    EquipmentRarity.rare: [
      'Armadura de Aço',
      'Malha Élfica',
      'Placa Gravada',
      'Escama Antiga',
    ],
    EquipmentRarity.epic: [
      'Armadura Abissal',
      'Cota Espectral',
      'Placa do Guardião',
      'Casca do Leviatã',
    ],
    EquipmentRarity.legendary: [
      'Armadura da Torre',
      'Escudo Primordial',
      'Placa Dimensional',
      'Couraça do Abyss',
    ],
  };

  static const _accessoryNames = {
    EquipmentRarity.common: [
      'Amuleto de Osso',
      'Anel de Cobre',
      'Colar de Pedra',
      'Bracelete Rústico',
    ],
    EquipmentRarity.uncommon: [
      'Amuleto de Prata',
      'Anel Rúnico',
      'Colar de Cristal',
      'Bracelete Entalhado',
    ],
    EquipmentRarity.rare: [
      'Amuleto Arcano',
      'Anel de Poder',
      'Colar da Visão',
      'Bracelete Etéreo',
    ],
    EquipmentRarity.epic: [
      'Amuleto do Vazio',
      'Anel do Destino',
      'Colar do Abyss',
      'Bracelete Espectral',
    ],
    EquipmentRarity.legendary: [
      'Amuleto Primordial',
      'Anel da Torre',
      'Colar Dimensional',
      'Selo do Escolhido',
    ],
  };

  static const _descriptions = {
    EquipmentSlot.weapon:
        'Forjado nas profundezas da Torre. Cada cicatriz conta uma batalha.',
    EquipmentSlot.armor:
        'Proteção extraída dos andares conquistados. Absorve o peso do destino.',
    EquipmentSlot.accessory:
        'Ressonância com a energia da Torre. Amplifica o potencial oculto.',
  };

  /// Gera um equipamento proceduralmente
  static Equipment generate({
    required String id,
    required EquipmentSlot slot,
    required EquipmentRarity rarity,
    required int floorOrigin,
    required int Function(int max) randomInt,
    required double Function() randomDouble,
    bool isCrafted = false,
  }) {
    final nameList = switch (slot) {
      EquipmentSlot.weapon => _weaponNames[rarity]!,
      EquipmentSlot.armor => _armorNames[rarity]!,
      EquipmentSlot.accessory => _accessoryNames[rarity]!,
    };
    final name = '${rarity.prefix}${nameList[randomInt(nameList.length)]}';
    final statBonus = _rollStatBonus(slot, rarity, floorOrigin, randomDouble);
    final description = _descriptions[slot]!;

    return Equipment(
      id: id,
      name: name,
      slot: slot,
      rarity: rarity,
      floorOrigin: floorOrigin,
      statBonus: statBonus,
      description: description,
      isCrafted: isCrafted,
    );
  }

  static Map<String, double> _rollStatBonus(
    EquipmentSlot slot,
    EquipmentRarity rarity,
    int floorOrigin,
    double Function() rand,
  ) {
    final mult = rarity.statMultiplier;
    // Base: floorOrigin/10 garante que itens de tiers maiores sejam melhores
    final tierBonus = (floorOrigin / 10.0).clamp(0.5, 3.0);
    final variance = 0.8 + rand() * 0.4; // 80%–120% do valor base

    final base = mult * tierBonus * variance;

    return switch (slot) {
      EquipmentSlot.weapon => {
        'strength': double.parse((base * 1.2).toStringAsFixed(1)),
        'agility': double.parse((base * 0.8).toStringAsFixed(1)),
      },
      EquipmentSlot.armor => {
        'endurance': double.parse((base * 1.5).toStringAsFixed(1)),
        'mentalStability': double.parse((base * 2.0).toStringAsFixed(1)),
      },
      EquipmentSlot.accessory => {
        'intelligence': double.parse((base * 1.0).toStringAsFixed(1)),
        'luck': double.parse((base * 0.8).toStringAsFixed(1)),
      },
    };
  }

  /// Calcula o custo de craft baseado na raridade
  static ({double ironBar, double knowledge, double stoneBrick}) craftCost(
    EquipmentRarity rarity,
  ) => switch (rarity) {
    EquipmentRarity.common => (ironBar: 5.0, knowledge: 0.0, stoneBrick: 0.0),
    EquipmentRarity.uncommon => (
      ironBar: 12.0,
      knowledge: 5.0,
      stoneBrick: 0.0,
    ),
    EquipmentRarity.rare => (ironBar: 25.0, knowledge: 15.0, stoneBrick: 10.0),
    EquipmentRarity.epic => (ironBar: 50.0, knowledge: 35.0, stoneBrick: 25.0),
    EquipmentRarity.legendary => (
      ironBar: 100.0,
      knowledge: 80.0,
      stoneBrick: 50.0,
    ),
  };
}

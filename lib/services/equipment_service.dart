// lib/services/equipment_service.dart
// ─────────────────────────────────────────────
// Lógica de negócio de equipamentos — separada do game_engine.dart
// para não poluir o arquivo principal.
//
// GameEngine delega para este service via composição:
//   final EquipmentService equipmentService = EquipmentService();
//
// ─────────────────────────────────────────────

import 'dart:math';
import '../models/equipment.dart';
import '../models/citadel.dart';
import '../models/npc.dart';

// ── Resultado de equip/unequip ─────────────────

enum EquipResult {
  success,
  npcNotFound,
  itemNotFound,
  slotMismatch, // item não é do slot correto
  slotOccupied, // slot já tem item; unequip primeiro
  itemAlreadyEquipped, // item já está em outro NPC
}

enum UnequipResult { success, npcNotFound, slotEmpty }

enum CraftResult { success, noForge, insufficientResources }

// ── EquipmentService ───────────────────────────

class EquipmentService {
  final Random _rng;

  EquipmentService({Random? rng}) : _rng = rng ?? Random();

  // ═══════════════════════════════════════════
  // DROP AO CONQUISTAR ANDAR
  // ═══════════════════════════════════════════

  /// Tenta gerar um drop de equipamento ao conquistar/re-explorar um andar.
  /// Retorna null se não dropou nada (a chance é intencional).
  ///
  /// [floorNumber] — número do andar (1–N)
  /// [tier]        — tier do andar (1 = fácil, 10 = endgame)
  Equipment? rollDrop({
    required int floorNumber,
    required int tier,
    required int currentDay,
  }) {
    // Chance base: 10% no tier 1, +5% por tier adicional (cap: 60%)
    final dropChance = (0.10 + (tier - 1) * 0.05).clamp(0.10, 0.60);
    if (_rng.nextDouble() > dropChance) return null;

    final rarity = _rollRarity(tier);
    final slot =
        EquipmentSlot.values[_rng.nextInt(EquipmentSlot.values.length)];
    final id = 'eq_d${currentDay}_f${floorNumber}_${_rng.nextInt(99999)}';

    return EquipmentFactory.generate(
      id: id,
      slot: slot,
      rarity: rarity,
      floorOrigin: floorNumber,
      randomInt: _rng.nextInt,
      randomDouble: _rng.nextDouble,
      isCrafted: false,
    );
  }

  /// Rola raridade baseada no tier do andar.
  /// Tiers maiores aumentam chance de itens raros.
  EquipmentRarity _rollRarity(int tier) {
    // Peso de cada raridade por tier usando dropWeight()
    final rarities = EquipmentRarity.values;
    final weights = rarities.map((r) => r.dropWeight(tier)).toList();
    final total = weights.fold(0.0, (a, b) => a + b);
    double roll = _rng.nextDouble() * total;

    for (int i = 0; i < rarities.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return rarities[i];
    }
    return EquipmentRarity.common;
  }

  // ═══════════════════════════════════════════
  // CRAFT NA FORJA
  // ═══════════════════════════════════════════

  /// Tenta criar um equipamento na Forja.
  /// Consome recursos da cidadela se bem-sucedido.
  ///
  /// Retorna (CraftResult, Equipment?) — Equipment é null em caso de falha.
  (CraftResult, Equipment?) craft({
    required EquipmentSlot slot,
    required EquipmentRarity rarity,
    required Citadel citadel,
    required int currentDay,
  }) {
    // 1. Verificar se Forja existe
    if (!citadel.hasBuilding(BuildingType.forge)) {
      return (CraftResult.noForge, null);
    }

    // 2. Verificar recursos
    final cost = EquipmentFactory.craftCost(rarity);
    final canAfford =
        citadel.resources.ironBar >= cost.ironBar &&
        citadel.resources.knowledge >= cost.knowledge &&
        citadel.resources.stoneBrick >= cost.stoneBrick;

    if (!canAfford) {
      return (CraftResult.insufficientResources, null);
    }

    // 3. Consumir recursos
    citadel.resources.ironBar -= cost.ironBar;
    citadel.resources.knowledge -= cost.knowledge;
    citadel.resources.stoneBrick -= cost.stoneBrick;
    citadel.resources.clampNegatives();

    // 4. Gerar item (tier 1 mínimo para craft, nível da forja escala)
    final forgeLevel = citadel.getBuilding(BuildingType.forge)?.level ?? 1;
    // Forja nível 1 = tier 2, nível 5 = tier 6
    final craftTier = (1 + forgeLevel).clamp(2, 10);
    // Craft usa floorOrigin = 0 para indicar que foi criado, não dropado
    final id = 'eq_c${currentDay}_${slot.name}_${_rng.nextInt(99999)}';

    final equipment = EquipmentFactory.generate(
      id: id,
      slot: slot,
      rarity: rarity,
      floorOrigin: craftTier * 10, // pseudo-floor para calcular bônus
      randomInt: _rng.nextInt,
      randomDouble: _rng.nextDouble,
      isCrafted: true,
    );
    // Marca como craftado explicitamente no nome
    equipment.name = '⚒ ${equipment.name}';

    return (CraftResult.success, equipment);
  }

  // ═══════════════════════════════════════════
  // EQUIPAR / DESEQUIPAR
  // ═══════════════════════════════════════════

  /// Equipa um item em um NPC.
  /// - Valida que o item existe no inventário e não está equipado
  /// - Valida que o slot está vazio (não faz troca automática)
  /// - Atualiza tanto o NPC quanto o Equipment
  EquipResult equip({
    required String npcId,
    required String equipmentId,
    required List<Npc> npcs,
    required List<Equipment> inventory,
  }) {
    final npc = npcs.firstWhereOrNull((n) => n.id == npcId);
    if (npc == null) return EquipResult.npcNotFound;

    final eq = inventory.firstWhereOrNull((e) => e.id == equipmentId);
    if (eq == null) return EquipResult.itemNotFound;

    // Verificar se já está equipado por alguém
    if (eq.isEquipped) return EquipResult.itemAlreadyEquipped;

    // Verificar se slot está livre
    if (npc.hasEquipment(eq.slot)) return EquipResult.slotOccupied;

    // Equipar
    _setSlot(npc, eq.slot, equipmentId);
    eq.equippedByNpcId = npcId;

    return EquipResult.success;
  }

  /// Remove o equipamento de um slot de um NPC e o devolve ao inventário.
  UnequipResult unequip({
    required String npcId,
    required EquipmentSlot slot,
    required List<Npc> npcs,
    required List<Equipment> inventory,
  }) {
    final npc = npcs.firstWhereOrNull((n) => n.id == npcId);
    if (npc == null) return UnequipResult.npcNotFound;

    final slotId = npc.equippedIdForSlot(slot);
    if (slotId == null) return UnequipResult.slotEmpty;

    // Limpar no equipment
    final eq = inventory.firstWhereOrNull((e) => e.id == slotId);
    eq?.equippedByNpcId = null;

    // Limpar no NPC
    _setSlot(npc, slot, null);

    return UnequipResult.success;
  }

  /// Desequipa todos os itens de um NPC (usado na morte do NPC)
  void unequipAll({
    required String npcId,
    required List<Npc> npcs,
    required List<Equipment> inventory,
  }) {
    for (final slot in EquipmentSlot.values) {
      unequip(npcId: npcId, slot: slot, npcs: npcs, inventory: inventory);
    }
  }

  // ── helpers internos ──────────────────────

  void _setSlot(Npc npc, EquipmentSlot slot, String? id) {
    switch (slot) {
      case EquipmentSlot.weapon:
        npc.equippedWeaponId = id;
      case EquipmentSlot.armor:
        npc.equippedArmorId = id;
      case EquipmentSlot.accessory:
        npc.equippedAccessoryId = id;
    }
  }

  // ═══════════════════════════════════════════
  // QUERIES DE CONVENIÊNCIA
  // ═══════════════════════════════════════════

  /// Itens disponíveis para um slot específico (não equipados)
  List<Equipment> availableForSlot(
    EquipmentSlot slot,
    List<Equipment> inventory,
  ) =>
      inventory.where((e) => e.slot == slot && !e.isEquipped).toList()
        ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));

  /// Todos os itens equipados em um NPC
  List<Equipment> equippedOn(String npcId, List<Equipment> inventory) =>
      inventory.where((e) => e.equippedByNpcId == npcId).toList();

  /// Custo de craft para exibir na UI (sem instanciar item)
  ({double ironBar, double knowledge, double stoneBrick}) craftCostFor(
    EquipmentRarity rarity,
  ) => EquipmentFactory.craftCost(rarity);

  /// Verifica se a cidadela tem recursos suficientes para craftar
  bool canCraft(EquipmentRarity rarity, Resources resources) {
    final cost = EquipmentFactory.craftCost(rarity);
    return resources.ironBar >= cost.ironBar &&
        resources.knowledge >= cost.knowledge &&
        resources.stoneBrick >= cost.stoneBrick;
  }
}

// ── Extensão local para firstWhereOrNull ──────
// (mesma usada no game_provider — se você já usa o pacote collection, remova)
extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

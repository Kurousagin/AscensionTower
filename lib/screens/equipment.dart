// lib/screens/equipment_screen.dart
// ─────────────────────────────────────────────
// Tela de Gerenciamento de Equipamentos
// ─────────────────────────────────────────────
// 3 abas:
//   [INVENTÁRIO]  — todos os itens, filtro por slot/raridade
//   [NPCs]        — cada NPC com seus 3 slots equipados
//   [CRAFT]       — criar itens na Forja (requer BuildingType.forge)
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/citadel.dart';
import '../models/equipment.dart';
import '../models/npc.dart';
import '../providers/game_provider.dart';

// ── Paleta terminal ───────────────────────────
// Cores consistentes com o resto do jogo

class _C {
  static const bg = Color(0xFF1A202C);
  static const surface = Color(0xFF2D3748);
  static const border = Color(0xFF4A5568);
  static const cyan = Color(0xFF00B4D8);
  static const orange = Color(0xFFF4A261);
  static const green = Color(0xFF48BB78);
  static const red = Color(0xFFFC8181);
  static const yellow = Color(0xFFECC94B);
  static const purple = Color(0xFFB794F4);
  static const dim = Color(0xFF718096);
  static const light = Color(0xFFE2E8F0);
  static const dark = Color(0xFF1A202C);

  static Color forRarity(EquipmentRarity r) => switch (r) {
    EquipmentRarity.common => dim,
    EquipmentRarity.uncommon => green,
    EquipmentRarity.rare => cyan,
    EquipmentRarity.epic => purple,
    EquipmentRarity.legendary => yellow,
  };
}

// ─────────────────────────────────────────────
// SCREEN PRINCIPAL
// ─────────────────────────────────────────────

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        title: const Text(
          '⚔ EQUIPAMENTOS',
          style: TextStyle(
            fontFamily: 'Consolas',
            color: _C.cyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _C.cyan,
          labelColor: _C.cyan,
          unselectedLabelColor: _C.dim,
          labelStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
          tabs: const [
            Tab(text: 'INVENTÁRIO'),
            Tab(text: 'NPCs'),
            Tab(text: 'CRAFT'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_InventoryTab(), _NpcsTab(), _CraftTab()],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ABA 1: INVENTÁRIO
// ─────────────────────────────────────────────

class _InventoryTab extends StatefulWidget {
  const _InventoryTab();

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  EquipmentSlot? _filterSlot;
  EquipmentRarity? _filterRarity;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final inventory = provider.inventory;

    final filtered =
        inventory.where((e) {
          if (_filterSlot != null && e.slot != _filterSlot) return false;
          if (_filterRarity != null && e.rarity != _filterRarity) return false;
          return true;
        }).toList()..sort((a, b) {
          // Disponíveis primeiro; depois por raridade decrescente
          final aEquipped = a.isEquipped ? 1 : 0;
          final bEquipped = b.isEquipped ? 1 : 0;
          if (aEquipped != bEquipped) return aEquipped - bEquipped;
          return b.rarity.index.compareTo(a.rarity.index);
        });

    return Column(
      children: [
        // ── Filtros ──
        _FilterRow(
          selectedSlot: _filterSlot,
          selectedRarity: _filterRarity,
          onSlotChanged: (s) => setState(() => _filterSlot = s),
          onRarityChanged: (r) => setState(() => _filterRarity = r),
        ),

        // ── Contagem ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} itens',
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  color: _C.dim,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${inventory.where((e) => !e.isEquipped).length} disponíveis',
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  color: _C.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // ── Lista ──
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  icon: '📦',
                  message:
                      'Nenhum item encontrado.\nConquiste andares ou craft na Forja.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _InventoryItemCard(
                    equipment: filtered[i],
                    allNpcs: provider.aliveNpcs,
                    onEquip: (npcId) {
                      final ok = provider.equipItem(npcId, filtered[i].id);
                      if (!ok && mounted) {
                        _showSnack(
                          context,
                          'Slot já ocupado! Desequipe primeiro.',
                        );
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// ABA 2: NPCs
// ─────────────────────────────────────────────

class _NpcsTab extends StatelessWidget {
  const _NpcsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final npcs = provider.aliveNpcs
      ..sort(
        (a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower),
      );

    if (npcs.isEmpty) {
      return const _EmptyState(icon: '👤', message: 'Nenhum NPC vivo.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: npcs.length,
      itemBuilder: (ctx, i) => _NpcEquipmentCard(
        npc: npcs[i],
        inventory: provider.inventory,
        availableForSlot: provider.availableForSlot,
        onEquip: provider.equipItem,
        onUnequip: provider.unequipItem,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ABA 3: CRAFT
// ─────────────────────────────────────────────

class _CraftTab extends StatefulWidget {
  const _CraftTab();

  @override
  State<_CraftTab> createState() => _CraftTabState();
}

class _CraftTabState extends State<_CraftTab> {
  EquipmentSlot _selectedSlot = EquipmentSlot.weapon;
  EquipmentRarity _selectedRarity = EquipmentRarity.common;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (!provider.hasForge) {
      return _EmptyState(
        icon: '🔥',
        message:
            'Forja não construída.\nConstrua a Forja para craftar equipamentos.',
        actionLabel: 'Ir para Cidadela',
        onAction: () => Navigator.pop(context),
      );
    }

    final cost = provider.craftCostFor(_selectedRarity);
    final canAfford = provider.canCraft(_selectedRarity);
    final resources = provider.citadel.resources;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Título ──
          const _SectionTitle('SELECIONAR TIPO'),
          const SizedBox(height: 8),

          // ── Slot ──
          const Text(
            'SLOT:',
            style: TextStyle(
              fontFamily: 'Consolas',
              color: _C.dim,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: EquipmentSlot.values.map((slot) {
              final selected = _selectedSlot == slot;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _SelectButton(
                    label: '${slot.icon} ${slot.label}',
                    selected: selected,
                    onTap: () => setState(() => _selectedSlot = slot),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ── Raridade ──
          const Text(
            'RARIDADE:',
            style: TextStyle(
              fontFamily: 'Consolas',
              color: _C.dim,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: EquipmentRarity.values.map((r) {
              return _SelectButton(
                label:
                    '${r.prefix.trim().isEmpty ? "" : "${r.prefix.trim()} "}${r.label}',
                selected: _selectedRarity == r,
                color: _C.forRarity(r),
                onTap: () => setState(() => _selectedRarity = r),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const _SectionTitle('CUSTO'),
          const SizedBox(height: 8),

          // ── Custo detalhado ──
          _CostRow(
            resources: resources,
            ironBar: cost.ironBar,
            knowledge: cost.knowledge,
            stoneBrick: cost.stoneBrick,
          ),

          const SizedBox(height: 20),

          // ── Preview do item esperado ──
          const _SectionTitle('BÔNUS ESPERADO'),
          const SizedBox(height: 8),
          _BonusPreview(slot: _selectedSlot, rarity: _selectedRarity),

          const SizedBox(height: 24),

          // ── Botão de craft ──
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: canAfford
                  ? () {
                      final eq = provider.craftEquipment(
                        _selectedSlot,
                        _selectedRarity,
                      );
                      if (eq != null && mounted) {
                        _showCraftSuccess(context, eq);
                      } else if (mounted) {
                        _showSnack(context, 'Recursos insuficientes!');
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? _C.orange : _C.border,
                foregroundColor: _C.dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                canAfford ? '⚒ CRAFTAR' : '⚒ RECURSOS INSUFICIENTES',
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS REUTILIZÁVEIS
// ─────────────────────────────────────────────

// ── Filtro de inventário ──────────────────────

class _FilterRow extends StatelessWidget {
  final EquipmentSlot? selectedSlot;
  final EquipmentRarity? selectedRarity;
  final ValueChanged<EquipmentSlot?> onSlotChanged;
  final ValueChanged<EquipmentRarity?> onRarityChanged;

  const _FilterRow({
    required this.selectedSlot,
    required this.selectedRarity,
    required this.onSlotChanged,
    required this.onRarityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slots
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: selectedSlot == null,
                  onTap: () => onSlotChanged(null),
                ),
                ...EquipmentSlot.values.map(
                  (s) => _FilterChip(
                    label: '${s.icon} ${s.label}',
                    selected: selectedSlot == s,
                    onTap: () => onSlotChanged(selectedSlot == s ? null : s),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Raridades
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: selectedRarity == null,
                  onTap: () => onRarityChanged(null),
                ),
                ...EquipmentRarity.values.map(
                  (r) => _FilterChip(
                    label: r.label,
                    selected: selectedRarity == r,
                    color: _C.forRarity(r),
                    onTap: () =>
                        onRarityChanged(selectedRarity == r ? null : r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = _C.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: selected ? color : _C.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Consolas',
            color: selected ? color : _C.dim,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ── Card de item no inventário ────────────────

class _InventoryItemCard extends StatelessWidget {
  final Equipment equipment;
  final List<Npc> allNpcs;
  final ValueChanged<String> onEquip;

  const _InventoryItemCard({
    required this.equipment,
    required this.allNpcs,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = _C.forRarity(equipment.rarity);
    final isEquipped = equipment.isEquipped;

    // NPC que está usando (se equipado)
    final owner = isEquipped
        ? allNpcs.firstWhere(
            (n) => n.id == equipment.equippedByNpcId,
            orElse: () => allNpcs.first,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(left: BorderSide(color: rarityColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome + slot + raridade
          Row(
            children: [
              Text(equipment.slot.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  equipment.name,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    color: rarityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (equipment.floorOrigin > 0)
                Text(
                  'Andar ${equipment.floorOrigin}',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    color: _C.dim,
                    fontSize: 10,
                  ),
                ),
              if (equipment.isCrafted)
                const Text(
                  '⚒ Craftado',
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    color: _C.orange,
                    fontSize: 10,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Bônus
          Text(
            equipment.bonusSummary,
            style: const TextStyle(
              fontFamily: 'Consolas',
              color: _C.green,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 6),

          // Status: equipado ou botão de equipar
          if (isEquipped)
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: _C.dim),
                const SizedBox(width: 4),
                Text(
                  'Equipado por ${owner?.name ?? "?"}',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    color: _C.dim,
                    fontSize: 11,
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: () => _showEquipDialog(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
              ),
              child: const Text(
                '[ EQUIPAR EM NPC → ]',
                style: TextStyle(
                  fontFamily: 'Consolas',
                  color: _C.cyan,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEquipDialog(BuildContext context) {
    // Filtrar NPCs que podem receber este slot
    final eligible =
        allNpcs.where((n) => !n.hasEquipment(equipment.slot)).toList()..sort(
          (a, b) =>
              b.attributes.combatPower.compareTo(a.attributes.combatPower),
        );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        title: Text(
          'Equipar ${equipment.name}',
          style: const TextStyle(
            fontFamily: 'Consolas',
            color: _C.cyan,
            fontSize: 14,
          ),
        ),
        content: SizedBox(
          width: 300,
          child: eligible.isEmpty
              ? const Text(
                  'Nenhum NPC com slot livre.',
                  style: TextStyle(fontFamily: 'Consolas', color: _C.dim),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: eligible.length,
                  itemBuilder: (_, i) {
                    final npc = eligible[i];
                    final powerGain = equipment.statBonus.entries.fold(
                      0.0,
                      (acc, e) => acc + e.value * 0.25,
                    );
                    return ListTile(
                      dense: true,
                      title: Text(
                        npc.name,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          color: _C.light,
                          fontSize: 12,
                        ),
                      ),
                      subtitle: Text(
                        '⚔ ${npc.attributes.combatPower.toStringAsFixed(1)} → +${powerGain.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          color: _C.green,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        onEquip(npc.id);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Consolas', color: _C.dim),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de NPC com slots ─────────────────────

class _NpcEquipmentCard extends StatelessWidget {
  final Npc npc;
  final List<Equipment> inventory;
  final List<Equipment> Function(EquipmentSlot) availableForSlot;
  final bool Function(String, String) onEquip;
  final bool Function(String, EquipmentSlot) onUnequip;

  const _NpcEquipmentCard({
    required this.npc,
    required this.inventory,
    required this.availableForSlot,
    required this.onEquip,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    final equippedItems = inventory
        .where((e) => e.equippedByNpcId == npc.id)
        .toList();
    final gearPowerBonus = equippedItems.fold(
      0.0,
      (acc, eq) =>
          acc +
          (eq.statBonus['strength'] ?? 0) * 0.30 +
          (eq.statBonus['agility'] ?? 0) * 0.25 +
          (eq.statBonus['endurance'] ?? 0) * 0.25 +
          (eq.statBonus['intelligence'] ?? 0) * 0.20,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header do NPC ──
          Row(
            children: [
              Text(
                npc.name,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  color: _C.light,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '⚔ ${npc.attributes.combatPower.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      color: _C.orange,
                      fontSize: 12,
                    ),
                  ),
                  if (gearPowerBonus > 0)
                    Text(
                      '+ ${gearPowerBonus.toStringAsFixed(1)} gear',
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        color: _C.green,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── 3 slots ──
          Row(
            children: EquipmentSlot.values.map((slot) {
              final equipped = inventory.firstWhere(
                (e) => e.equippedByNpcId == npc.id && e.slot == slot,
                orElse: () => Equipment(
                  id: '__empty__',
                  name: '',
                  slot: slot,
                  rarity: EquipmentRarity.common,
                  floorOrigin: 0,
                  statBonus: {},
                  description: '',
                ),
              );
              final hasItem = equipped.id != '__empty__';
              final available = availableForSlot(slot);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _SlotButton(
                    slot: slot,
                    equipped: hasItem ? equipped : null,
                    availableCount: available.length,
                    onTap: () {
                      if (hasItem) {
                        // Desequipar
                        onUnequip(npc.id, slot);
                      } else {
                        // Equipar — mostrar seletor
                        _showSlotSelector(context, slot, available);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showSlotSelector(
    BuildContext context,
    EquipmentSlot slot,
    List<Equipment> available,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        title: Text(
          '${slot.icon} ${slot.label} — ${npc.name}',
          style: const TextStyle(
            fontFamily: 'Consolas',
            color: _C.cyan,
            fontSize: 13,
          ),
        ),
        content: SizedBox(
          width: 300,
          child: available.isEmpty
              ? const Text(
                  'Nenhum item disponível neste slot.',
                  style: TextStyle(fontFamily: 'Consolas', color: _C.dim),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final eq = available[i];
                    final rarityColor = _C.forRarity(eq.rarity);
                    return ListTile(
                      dense: true,
                      title: Text(
                        eq.name,
                        style: TextStyle(
                          fontFamily: 'Consolas',
                          color: rarityColor,
                          fontSize: 12,
                        ),
                      ),
                      subtitle: Text(
                        eq.bonusSummary,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          color: _C.green,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        onEquip(npc.id, eq.id);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Consolas', color: _C.dim),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slot button ───────────────────────────────

class _SlotButton extends StatelessWidget {
  final EquipmentSlot slot;
  final Equipment? equipped;
  final int availableCount;
  final VoidCallback onTap;

  const _SlotButton({
    required this.slot,
    required this.equipped,
    required this.availableCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasItem = equipped != null;
    final rarityColor = hasItem ? _C.forRarity(equipped!.rarity) : _C.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: hasItem ? rarityColor.withOpacity(0.1) : _C.bg,
          border: Border.all(
            color: hasItem ? rarityColor : _C.border,
            width: hasItem ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              slot.icon,
              style: TextStyle(
                fontSize: 18,
                color: hasItem ? rarityColor : _C.border,
              ),
            ),
            const SizedBox(height: 4),
            if (hasItem) ...[
              Text(
                equipped!.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Consolas',
                  color: rarityColor,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '[ REMOVER ]',
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  color: _C.red,
                  fontSize: 8,
                ),
              ),
            ] else ...[
              Text(
                slot.label,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  color: _C.dim,
                  fontSize: 9,
                ),
              ),
              if (availableCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '$availableCount disponível${availableCount > 1 ? "is" : ""}',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    color: _C.cyan,
                    fontSize: 8,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Preview de bônus no craft ─────────────────

class _BonusPreview extends StatelessWidget {
  final EquipmentSlot slot;
  final EquipmentRarity rarity;

  const _BonusPreview({required this.slot, required this.rarity});

  @override
  Widget build(BuildContext context) {
    // Preview estimado (sem RNG — mostra faixas)
    final mult = rarity.statMultiplier;
    final stats = slot.primaryStats;
    final color = _C.forRarity(rarity);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.08),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.icon} ${slot.label} — ${rarity.label}',
            style: TextStyle(
              fontFamily: 'Consolas',
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          ...stats.toSet().map((stat) {
            final baseMin = (mult * 0.5 * 0.8).toStringAsFixed(1);
            final baseMax = (mult * 0.5 * 1.2 * 1.5).toStringAsFixed(1);
            return Text(
              '+$baseMin~$baseMax ${_statLabel(stat)}',
              style: const TextStyle(
                fontFamily: 'Consolas',
                color: _C.green,
                fontSize: 12,
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Bônus final varia conforme Forja e andar.',
            style: const TextStyle(
              fontFamily: 'Consolas',
              color: _C.dim,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _statLabel(String key) =>
      const {
        'strength': 'FOR',
        'agility': 'AGI',
        'intelligence': 'INT',
        'endurance': 'RES',
        'luck': 'SORT',
      }[key] ??
      key;
}

// ── Linha de custo ────────────────────────────

class _CostRow extends StatelessWidget {
  final Resources resources;
  final double ironBar, knowledge, stoneBrick;

  const _CostRow({
    required this.resources,
    required this.ironBar,
    required this.knowledge,
    required this.stoneBrick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.bg,
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (ironBar > 0) _CostItem('⛏ Ferro', ironBar, resources.ironBar),
          if (knowledge > 0)
            _CostItem('📚 Conhec.', knowledge, resources.knowledge),
          if (stoneBrick > 0) _CostItem('🧱 Tijolos', stoneBrick, resources.stoneBrick),
        ],
      ),
    );
  }
}

class _CostItem extends StatelessWidget {
  final String label;
  final double cost;
  final double have;

  const _CostItem(this.label, this.cost, this.have);

  @override
  Widget build(BuildContext context) {
    final canAfford = have >= cost;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Consolas',
            color: _C.dim,
            fontSize: 10,
          ),
        ),
        Text(
          cost.toStringAsFixed(0),
          style: TextStyle(
            fontFamily: 'Consolas',
            color: canAfford ? _C.green : _C.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          '/ ${have.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'Consolas',
            color: canAfford ? _C.dim : _C.red,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Helpers visuais ───────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Consolas',
        color: _C.cyan,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SelectButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = _C.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: selected ? color.withOpacity(0.2) : _C.surface,
          border: Border.all(
            color: selected ? color : _C.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Consolas',
            color: selected ? color : _C.dim,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Consolas',
              color: _C.dim,
              fontSize: 12,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontFamily: 'Consolas', color: _C.cyan),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Snackbar helper ───────────────────────────

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: _C.surface,
      content: Text(
        msg,
        style: const TextStyle(fontFamily: 'Consolas', color: _C.red),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

void _showCraftSuccess(BuildContext context, Equipment eq) {
  final color = _C.forRarity(eq.rarity);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: _C.surface,
      content: Row(
        children: [
          Text(eq.slot.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eq.name,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  eq.bonusSummary,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    color: _C.green,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

// ── Import que falta no arquivo (Resources está em citadel.dart) ──
// Adicione no topo de equipment_screen.dart:
// import '../models/citadel.dart';   // para Resources

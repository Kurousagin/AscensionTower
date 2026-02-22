import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class NpcListScreen extends StatefulWidget {
  const NpcListScreen({super.key});

  @override
  State<NpcListScreen> createState() => _NpcListScreenState();
}

class _NpcListScreenState extends State<NpcListScreen> {
  String _filter = 'all';
  String _sort = 'name';

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        List<Npc> npcs;
        switch (_filter) {
          case 'alive': npcs = gp.aliveNpcs; break;
          case 'dead': npcs = gp.deadNpcs; break;
          default: npcs = gp.allNpcs;
        }

        switch (_sort) {
          case 'power': npcs.sort((a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower)); break;
          case 'mental': npcs.sort((a, b) => a.attributes.mentalStability.compareTo(b.attributes.mentalStability)); break;
          case 'fame': npcs.sort((a, b) => b.fame.compareTo(a.fame)); break;
          default: npcs.sort((a, b) => a.name.compareTo(b.name));
        }

        return ScanlineOverlay(
          child: Column(
            children: [
              _buildFilters(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: npcs.length,
                  itemBuilder: (context, i) => _buildNpcTile(context, npcs[i], gp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          _filterChip('TODOS', 'all'),
          _filterChip('VIVOS', 'alive'),
          _filterChip('MORTOS', 'dead'),
          const Spacer(),
          const TerminalText('Ord:', fontSize: 9, color: AppTheme.textDim),
          const SizedBox(width: 4),
          _sortChip('NOM', 'name'),
          _sortChip('POW', 'power'),
          _sortChip('MEN', 'mental'),
          _sortChip('FAM', 'fame'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: active ? AppTheme.cyan : AppTheme.border),
            borderRadius: BorderRadius.circular(2),
            color: active ? AppTheme.cyan.withValues(alpha: 0.1) : null,
          ),
          child: TerminalText(label, fontSize: 8, color: active ? AppTheme.cyan : AppTheme.textDim),
        ),
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final active = _sort == value;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: () => setState(() => _sort = value),
        child: TerminalText(label, fontSize: 8, color: active ? AppTheme.cyan : AppTheme.textDim, fontWeight: active ? FontWeight.bold : null),
      ),
    );
  }

  Widget _buildNpcTile(BuildContext context, Npc npc, GameProvider gp) {
    final mentalColor = npc.attributes.mentalStability > 60
        ? AppTheme.green
        : npc.attributes.mentalStability > 30 ? AppTheme.yellow : AppTheme.red;

    return GestureDetector(
      onTap: () => _showNpcDetail(context, npc, gp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: npc.alive ? AppTheme.bgCard : AppTheme.bgCard.withValues(alpha: 0.5),
          border: Border.all(
            color: npc.alive
                ? (npc.attributes.mentalStability < 20 ? AppTheme.red.withValues(alpha: 0.5) : AppTheme.border)
                : AppTheme.red.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TerminalText(npc.origin.icon, fontSize: 9, color: npc.alive ? AppTheme.cyan : AppTheme.red),
                const SizedBox(width: 6),
                Expanded(
                  child: TerminalText(npc.name, fontSize: 11,
                      color: npc.alive ? AppTheme.textPrimary : AppTheme.red.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold),
                ),
                TerminalText(npc.alive ? 'G${npc.generation}' : 'MORTO',
                    fontSize: 9, color: npc.alive ? AppTheme.textDim : AppTheme.red),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TerminalText('${npc.profession.tag}', fontSize: 9, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                TerminalText('${npc.age}a', fontSize: 9, color: AppTheme.textDim),
                const SizedBox(width: 8),
                TerminalText('PWR:${npc.attributes.combatPower.toStringAsFixed(1)}', fontSize: 9, color: AppTheme.orange),
                const SizedBox(width: 8),
                TerminalText('MS:${npc.attributes.mentalStability.toStringAsFixed(0)}', fontSize: 9, color: mentalColor),
                if (npc.fame > 0) ...[
                  const SizedBox(width: 8),
                  TerminalText('F:${npc.fame.toStringAsFixed(0)}', fontSize: 9, color: AppTheme.yellow),
                ],
              ],
            ),
            if (npc.talentDiscovered && npc.hiddenTalent != HiddenTalent.none)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: TerminalText('* ${npc.hiddenTalent.label}', fontSize: 9, color: AppTheme.purple),
              ),
          ],
        ),
      ),
    );
  }

  void _showNpcDetail(BuildContext context, Npc npc, GameProvider gp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 3, color: AppTheme.border, margin: const EdgeInsets.only(bottom: 12))),
              Row(children: [
                TerminalText(npc.origin.icon, fontSize: 14, color: AppTheme.cyan),
                const SizedBox(width: 8),
                Expanded(child: TerminalText(npc.name, fontSize: 14, color: AppTheme.cyan, fontWeight: FontWeight.bold)),
                TerminalText(npc.statusTag, fontSize: 10, color: npc.alive ? AppTheme.green : AppTheme.red),
              ]),
              const SizedBox(height: 4),
              TerminalText('${npc.origin.label} | Geracao ${npc.generation} | ${npc.age} anos | ${npc.daysSurvived} dias',
                  fontSize: 9, color: AppTheme.textSecondary),
              const CyanDivider(label: 'ATRIBUTOS'),
              StatBar(label: 'FOR', value: npc.attributes.strength, maxValue: 15),
              StatBar(label: 'AGI', value: npc.attributes.agility, maxValue: 15),
              StatBar(label: 'INT', value: npc.attributes.intelligence, maxValue: 15),
              StatBar(label: 'RES', value: npc.attributes.endurance, maxValue: 15),
              StatBar(label: 'CAR', value: npc.attributes.charisma, maxValue: 15),
              StatBar(label: 'MEN', value: npc.attributes.mentalStability, maxValue: 100,
                  color: npc.attributes.mentalStability > 60 ? AppTheme.green :
                  npc.attributes.mentalStability > 30 ? AppTheme.yellow : AppTheme.red),
              const SizedBox(height: 4),
              TerminalText('Poder Combate: ${npc.attributes.combatPower.toStringAsFixed(1)} | Media: ${npc.attributes.average.toStringAsFixed(1)}',
                  fontSize: 9, color: AppTheme.orange),
              const CyanDivider(label: 'PERSONALIDADE'),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: npc.traits.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.purple.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(2)),
                  child: TerminalText(t.label, fontSize: 9, color: AppTheme.purple),
                )).toList(),
              ),
              if (npc.hiddenTalent != HiddenTalent.none) ...[
                const CyanDivider(label: 'TALENTO OCULTO'),
                TerminalText(
                  npc.talentDiscovered ? '${npc.hiddenTalent.label}: ${npc.hiddenTalent.description}' : '??? Nao descoberto',
                  fontSize: 10, color: npc.talentDiscovered ? AppTheme.purple : AppTheme.textDim,
                ),
              ],
              const CyanDivider(label: 'PROFISSAO'),
              Row(children: [
                TerminalText('Atual: ${npc.profession.label}', fontSize: 10, color: AppTheme.textPrimary),
                const Spacer(),
                if (npc.alive)
                  TerminalButton(
                    label: 'MUDAR',
                    color: AppTheme.blue,
                    onPressed: () => _showProfessionPicker(context, npc, gp),
                  ),
              ]),
              const CyanDivider(label: 'ESTATISTICAS'),
              TerminalText('Andares limpos: ${npc.floorsCleared}', fontSize: 9, color: AppTheme.textSecondary),
              TerminalText('Fama: ${npc.fame.toStringAsFixed(0)}', fontSize: 9, color: AppTheme.yellow),
              TerminalText('Condicao: ${npc.calculatedMentalCondition.label}', fontSize: 9, color: AppTheme.textSecondary),
              if (npc.partnerId != null)
                Builder(builder: (_) {
                  final partner = gp.allNpcs.where((n) => n.id == npc.partnerId).firstOrNull;
                  return TerminalText('Parceiro: ${partner?.name ?? "Desconhecido"}', fontSize: 9, color: AppTheme.pink);
                }),
              if (npc.childrenIds.isNotEmpty)
                TerminalText('Filhos: ${npc.childrenIds.length}', fontSize: 9, color: AppTheme.green),
              if (npc.traumas.isNotEmpty) ...[
                const CyanDivider(label: 'TRAUMAS'),
                ...npc.traumas.map((t) => TerminalText('- $t', fontSize: 9, color: AppTheme.red)),
              ],
              if (npc.history.isNotEmpty) ...[
                const CyanDivider(label: 'HISTORICO'),
                ...npc.history.reversed.take(10).map((h) => TerminalText('> $h', fontSize: 9, color: AppTheme.textDim)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProfessionPicker(BuildContext context, Npc npc, GameProvider gp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ATRIBUIR PROFISSAO'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Profession.values.map((p) => ListTile(
              dense: true,
              title: TerminalText('${p.tag} - ${p.label}', fontSize: 10,
                  color: npc.profession == p ? AppTheme.cyan : AppTheme.textSecondary),
              onTap: () {
                gp.assignProfession(npc.id, p);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/equipment.dart';
import 'package:tower_ascension/screens/equipment.dart';
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
          case 'alive':
            npcs = gp.aliveNpcs;
            break;
          case 'dead':
            npcs = gp.deadNpcs;
            break;
          case 'exhausted':
            npcs = gp.aliveNpcs.where((n) => n.fatigue >= 50).toList();
            break;
          default:
            npcs = gp.allNpcs;
        }

        switch (_sort) {
          case 'power':
            npcs.sort(
              (a, b) =>
                  b.attributes.combatPower.compareTo(a.attributes.combatPower),
            );
            break;
          case 'mental':
            npcs.sort(
              (a, b) => a.attributes.mentalStability.compareTo(
                b.attributes.mentalStability,
              ),
            );
            break;
          case 'fame':
            npcs.sort((a, b) => b.fame.compareTo(a.fame));
            break;
          case 'loyalty':
            npcs.sort((a, b) => b.loyalty.compareTo(a.loyalty));
            break;
          case 'betrayal':
            npcs.sort((a, b) => b.betrayalRisk.compareTo(a.betrayalRisk));
            break;
          case 'fatigue':
            npcs.sort((a, b) => b.fatigue.compareTo(a.fatigue));
            break;
          default:
            npcs.sort((a, b) => a.name.compareTo(b.name));
        }

        return ScanlineOverlay(
          child: Column(
            children: [
              _buildFilters(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.shield,
                      size: 18,
                      color: AppTheme.cyan,
                    ),
                    label: const Text(
                      'Equipamentos',
                      style: TextStyle(
                        color: AppTheme.cyan,
                        fontFamily: 'Consolas',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bgCard,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: AppTheme.cyan),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EquipmentScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: npcs.length,
                  itemBuilder: (context, i) =>
                      _buildNpcTile(context, npcs[i], gp),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _filterChip('TODOS', 'all'),
          _filterChip('VIVOS', 'alive'),
          _filterChip('MORTOS', 'dead'),
          _filterChip('EXAUSTOS', 'exhausted'),
          const Spacer(),
          const TerminalText('Ordenar:', fontSize: 9, color: AppTheme.textDim),
          const SizedBox(width: 4),
          _sortChip('Nome', 'name'),
          _sortChip('Poder', 'power'),
          _sortChip('Mental', 'mental'),
          _sortChip('Fama', 'fame'),
          _sortChip('Leal.', 'loyalty'),
          _sortChip('Risco', 'betrayal'),
          _sortChip('Fadiga', 'fatigue'),
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
          child: TerminalText(
            label,
            fontSize: 8,
            color: active ? AppTheme.cyan : AppTheme.textDim,
          ),
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
        child: TerminalText(
          label,
          fontSize: 8,
          color: active ? AppTheme.cyan : AppTheme.textDim,
          fontWeight: active ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _buildNpcTile(BuildContext context, Npc npc, GameProvider gp) {
    final mentalColor = npc.attributes.mentalStability > 60
        ? AppTheme.green
        : npc.attributes.mentalStability > 30
        ? AppTheme.yellow
        : AppTheme.red;

    return GestureDetector(
      onTap: () => _showNpcDetail(context, npc, gp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: npc.alive
              ? AppTheme.bgCard
              : AppTheme.bgCard.withValues(alpha: 0.5),
          border: Border.all(
            color: npc.alive
                ? (npc.attributes.mentalStability < 20
                      ? AppTheme.red.withValues(alpha: 0.5)
                      : AppTheme.border)
                : AppTheme.red.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TerminalText(
                    npc.name,
                    fontSize: 11,
                    color: npc.alive
                        ? AppTheme.textPrimary
                        : AppTheme.red.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TerminalText(
                  npc.alive ? 'Geracao ${npc.generation}' : 'MORTO',
                  fontSize: 9,
                  color: npc.alive ? AppTheme.textDim : AppTheme.red,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                TerminalText(
                  'Origem: ${npc.origin.label}',
                  fontSize: 9,
                  color: AppTheme.cyan,
                ),
                TerminalText(
                  'Funcao: ${npc.profession.label}',
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
                TerminalText(
                  '${npc.age} anos',
                  fontSize: 9,
                  color: AppTheme.textDim,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                TerminalText(
                  'Poder: ${npc.effectiveCombatPowerWithGear(gp.equippedOn(npc.id)).toStringAsFixed(1)}',
                  fontSize: 9,
                  color: AppTheme.orange,
                ),
                TerminalText(
                  'Sanidade: ${npc.attributes.mentalStability.toStringAsFixed(0)}%',
                  fontSize: 9,
                  color: mentalColor,
                ),
                _fatigueTag(npc),
                if (npc.fame > 0)
                  TerminalText(
                    'Fama: ${npc.fame.toStringAsFixed(0)}',
                    fontSize: 9,
                    color: AppTheme.yellow,
                  ),
                if (npc.fame < 0)
                  TerminalText(
                    'Infame: ${npc.fame.toStringAsFixed(0)}',
                    fontSize: 9,
                    color: AppTheme.red,
                  ),
                TerminalText(
                  'Leal: ${npc.loyalty.toStringAsFixed(0)}%',
                  fontSize: 9,
                  color: npc.loyalty > 60
                      ? AppTheme.green
                      : npc.loyalty > 30
                      ? AppTheme.yellow
                      : AppTheme.red,
                ),
              ],
            ),
            if (npc.talentDiscovered && npc.hiddenTalent != HiddenTalent.none)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: TerminalText(
                  'Talento: ${npc.hiddenTalent.label}',
                  fontSize: 9,
                  color: AppTheme.purple,
                ),
              ),
            if (npc.isSuspicious || npc.betrayalRisk > 30)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    TerminalText(
                      'ALERTA: Risco de traicao ${npc.betrayalRisk.toStringAsFixed(0)}%',
                      fontSize: 9,
                      color: AppTheme.red,
                    ),
                    if (npc.origin.isDarkOrigin)
                      TerminalText(
                        ' [${npc.origin.label}]',
                        fontSize: 9,
                        color: AppTheme.red,
                      ),
                  ],
                ),
              ),
            if (npc.groupId != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Builder(
                  builder: (_) {
                    final group = gp.groups
                        .where((g) => g.id == npc.groupId)
                        .firstOrNull;
                    return TerminalText(
                      'Grupo: ${group?.name ?? "Desconhecido"}',
                      fontSize: 9,
                      color: AppTheme.blue,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fatigueTag(Npc npc) {
    Color color;
    if (npc.fatigue >= 90) {
      color = const Color(0xFFFF0044);
    } else if (npc.fatigue >= 70) {
      color = AppTheme.red;
    } else if (npc.fatigue >= 50) {
      color = AppTheme.orange;
    } else if (npc.fatigue >= 30) {
      color = AppTheme.yellow;
    } else {
      color = AppTheme.green;
    }
    return TerminalText(
      'Fadiga: ${npc.fatigue.toStringAsFixed(0)}%',
      fontSize: 9,
      color: color,
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
              Center(
                child: Container(
                  width: 40,
                  height: 3,
                  color: AppTheme.border,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TerminalText(
                      npc.name,
                      fontSize: 14,
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TerminalText(
                    npc.alive ? 'VIVO' : 'MORTO',
                    fontSize: 10,
                    color: npc.alive ? AppTheme.green : AppTheme.red,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TerminalText(
                'Origem: ${npc.origin.label} | Geracao ${npc.generation} | ${npc.age} anos | ${npc.daysSurvived} dias na Torre',
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
              const CyanDivider(label: 'ATRIBUTOS'),
              StatBar(
                label: 'Forca',
                value: npc.totalStrength(gp.equippedOn(npc.id)),
                maxValue: 20,
              ),
              StatBar(
                label: 'Agil.',
                value: npc.totalAgility(gp.equippedOn(npc.id)),
                maxValue: 20,
              ),
              StatBar(
                label: 'Intel.',
                value: npc.totalIntelligence(gp.equippedOn(npc.id)),
                maxValue: 20,
              ),
              StatBar(
                label: 'Resist.',
                value: npc.totalEndurance(gp.equippedOn(npc.id)),
                maxValue: 20,
              ),
              StatBar(
                label: 'Caris.',
                value: npc.totalCharisma(gp.equippedOn(npc.id)),
                maxValue: 20,
              ),
              StatBar(
                label: 'Sanid.',
                value: npc.attributes.mentalStability,
                maxValue: 100,
                color: npc.attributes.mentalStability > 60
                    ? AppTheme.green
                    : npc.attributes.mentalStability > 30
                    ? AppTheme.yellow
                    : AppTheme.red,
              ),
              StatBar(
                label: 'Fadiga',
                value: npc.fatigue,
                maxValue: 100,
                color: npc.fatigue < 30
                    ? AppTheme.green
                    : npc.fatigue < 50
                    ? AppTheme.yellow
                    : npc.fatigue < 70
                    ? AppTheme.orange
                    : AppTheme.red,
              ),
              const SizedBox(height: 2),
              TerminalText(
                'Estado fisico: ${npc.fatigueLabel}${npc.isIncapacitated
                    ? " [INCAPACITADO]"
                    : npc.isExhausted
                    ? " [EXAUSTO]"
                    : ""}',
                fontSize: 9,
                color: npc.fatigue >= 70
                    ? AppTheme.red
                    : npc.fatigue >= 50
                    ? AppTheme.orange
                    : AppTheme.green,
              ),
              const SizedBox(height: 4),
              TerminalText(
                'Poder de combate: ${npc.effectiveCombatPowerWithGear(gp.equippedOn(npc.id)).toStringAsFixed(1)} | Media geral: ${npc.attributes.average.toStringAsFixed(1)}',
                fontSize: 9,
                color: AppTheme.orange,
              ),
              const CyanDivider(label: 'PERSONALIDADE'),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: npc.traits
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.purple.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TerminalText(
                          t.label,
                          fontSize: 9,
                          color: AppTheme.purple,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (npc.hiddenTalent != HiddenTalent.none) ...[
                const CyanDivider(label: 'TALENTO OCULTO'),
                TerminalText(
                  npc.talentDiscovered
                      ? '${npc.hiddenTalent.label}: ${npc.hiddenTalent.description}'
                      : '??? Talento ainda nao revelado',
                  fontSize: 10,
                  color: npc.talentDiscovered
                      ? AppTheme.purple
                      : AppTheme.textDim,
                ),
              ],
              const CyanDivider(label: 'FUNCAO NA CIDADELA'),
              TerminalText(
                'Funcao atual: ${npc.profession.label}',
                fontSize: 10,
                color: AppTheme.textPrimary,
              ),
              const CyanDivider(label: 'ESTATISTICAS'),
              TerminalText(
                'Andares superados: ${npc.floorsCleared}',
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
              TerminalText(
                'Fama acumulada: ${npc.fame.toStringAsFixed(0)}',
                fontSize: 9,
                color: AppTheme.yellow,
              ),
              TerminalText(
                'Estado mental: ${npc.mentalCondition.label}',
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
              const CyanDivider(label: 'SOCIAL'),
              StatBar(
                label: 'Leal.',
                value: npc.loyalty,
                maxValue: 100,
                color: npc.loyalty > 60
                    ? AppTheme.green
                    : npc.loyalty > 30
                    ? AppTheme.yellow
                    : AppTheme.red,
              ),
              TerminalText(
                'Reputacao: ${npc.fameLabel} (${npc.fame.toStringAsFixed(0)})',
                fontSize: 9,
                color: npc.fame >= 0 ? AppTheme.yellow : AppTheme.red,
              ),
              if (npc.betrayalRisk > 10)
                TerminalText(
                  'Risco de traicao: ${npc.betrayalRisk.toStringAsFixed(0)}%',
                  fontSize: 9,
                  color: npc.betrayalRisk > 50 ? AppTheme.red : AppTheme.orange,
                ),
              if (npc.groupId != null)
                Builder(
                  builder: (_) {
                    final group = gp.groups
                        .where((g) => g.id == npc.groupId)
                        .firstOrNull;
                    return TerminalText(
                      'Grupo: ${group?.name ?? "Sem grupo"}',
                      fontSize: 9,
                      color: AppTheme.blue,
                    );
                  },
                ),
              if (npc.trainingSuggestionsReceived > 0)
                TerminalText(
                  'Sugestoes: ${npc.trainingSuggestionsAccepted}/${npc.trainingSuggestionsReceived} aceitas',
                  fontSize: 9,
                  color: AppTheme.textDim,
                ),
              if (npc.origin.isDarkOrigin)
                TerminalText(
                  'ORIGEM OBSCURA: ${npc.origin.label}',
                  fontSize: 9,
                  color: AppTheme.red,
                ),
              if (npc.partnerId != null)
                Builder(
                  builder: (_) {
                    final partner = gp.allNpcs
                        .where((n) => n.id == npc.partnerId)
                        .firstOrNull;
                    return TerminalText(
                      'Parceiro(a): ${partner?.name ?? "Desconhecido"}',
                      fontSize: 9,
                      color: AppTheme.pink,
                    );
                  },
                ),
              if (npc.childrenIds.isNotEmpty)
                TerminalText(
                  'Filhos: ${npc.childrenIds.length}',
                  fontSize: 9,
                  color: AppTheme.green,
                ),
              if (npc.traumas.isNotEmpty) ...[
                const CyanDivider(label: 'TRAUMAS'),
                ...npc.traumas.map(
                  (t) => TerminalText('- $t', fontSize: 9, color: AppTheme.red),
                ),
              ],
              if (npc.traumas.isNotEmpty) ...[
                const CyanDivider(label: 'TRAUMAS'),
                ...npc.traumas.map(
                  (t) => TerminalText('- $t', fontSize: 9, color: AppTheme.red),
                ),
              ],
              // Exibe equipamentos equipados
              if (gp.equippedOn(npc.id).isNotEmpty) ...[
                const CyanDivider(label: 'EQUIPAMENTOS'),
                ...gp
                    .equippedOn(npc.id)
                    .map(
                      (eq) => TerminalText(
                        '${eq.slot.label}: ${eq.name} (${eq.rarity.label})',
                        fontSize: 9,
                        color: AppTheme.cyan,
                      ),
                    ),
              ],
              if (npc.history.isNotEmpty) ...[
                const CyanDivider(label: 'HISTORICO'),
                ...npc.history.reversed
                    .take(10)
                    .map(
                      (h) => TerminalText(
                        '> $h',
                        fontSize: 9,
                        color: AppTheme.textDim,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

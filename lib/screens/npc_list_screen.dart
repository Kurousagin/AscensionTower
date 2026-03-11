import 'package:collection/collection.dart';
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
    final (statusIcon, statusColor) = _npcStatusIcon(npc);
    final sanidadeColor = npc.attributes.mentalStability > 60
        ? AppTheme.green
        : npc.attributes.mentalStability > 30
        ? AppTheme.yellow
        : AppTheme.red;
    final fadigaColor = npc.fatigue < 30
        ? AppTheme.textSecondary
        : npc.fatigue < 50
        ? AppTheme.yellow
        : npc.fatigue < 70
        ? AppTheme.orange
        : AppTheme.red;

    // Determine border color
    final borderColor = !npc.alive
        ? AppTheme.red
        : npc.betrayalRisk > 60
        ? AppTheme.orange
        : AppTheme.border;

    return GestureDetector(
      onTap: () => _showNpcDetail(context, npc, gp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROW 1 — header with icon, name, and badge
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Expanded(
                  child: TerminalText(
                    npc.name,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: npc.alive
                        ? AppTheme.textPrimary
                        : AppTheme.red.withValues(alpha: 0.6),
                  ),
                ),
                // Badge widget
                if (!npc.alive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.red.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.red),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const TerminalText(
                      'MORTO',
                      fontSize: 8,
                      color: AppTheme.red,
                    ),
                  )
                else if (npc.betrayalRisk > 60)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.orange),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const TerminalText(
                      '⚠ RISCO',
                      fontSize: 8,
                      color: AppTheme.orange,
                    ),
                  )
                else if (npc.groupId != null)
                  Builder(
                    builder: (_) {
                      final group = gp.groups
                          .where((g) => g.id == npc.groupId)
                          .firstOrNull;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cyan.withValues(alpha: 0.1),
                          border: Border.all(color: AppTheme.cyan),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TerminalText(
                          group?.name ?? 'Grupo',
                          fontSize: 8,
                          color: AppTheme.cyan,
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 5),

            // ROW 2 — quote
            TerminalText(_npcQuote(npc), fontSize: 9, color: AppTheme.textDim),
            const SizedBox(height: 6),

            // ROW 3 — bars (sanidade and fadiga)
            _buildBar(
              'Sanidade',
              npc.attributes.mentalStability / 100,
              sanidadeColor,
            ),
            const SizedBox(height: 4),
            _buildBar('Fadiga', npc.fatigue / 100, fadigaColor),
            const SizedBox(height: 6),

            // ROW 4 — traits + loyalty/risk
            Row(
              children: [
                ...npc.traits.take(2).map((trait) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.purple.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: TerminalText(
                      trait.label,
                      fontSize: 8,
                      color: AppTheme.purple,
                    ),
                  );
                }),
                const Spacer(),
                if (npc.loyalty > 60)
                  const TerminalText(
                    'Lealdade ▲',
                    fontSize: 8,
                    color: AppTheme.green,
                  ),
                if (npc.betrayalRisk > 30) ...[
                  if (npc.loyalty > 60) const SizedBox(width: 4),
                  TerminalText(
                    'Risco ⚠',
                    fontSize: 8,
                    color: npc.betrayalRisk > 60
                        ? AppTheme.red
                        : AppTheme.orange,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double fraction, Color color) {
    return Row(
      children: [
        TerminalText(label, fontSize: 8, color: AppTheme.textDim),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 4,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  String _npcQuote(Npc npc) {
    if (npc.attributes.mentalStability < 20 && npc.traumas.isNotEmpty) {
      return '"Não consigo mais."';
    }
    if (npc.attributes.mentalStability < 20) {
      return '"Algo está errado comigo."';
    }
    if (npc.betrayalRisk > 60) {
      return '"Ninguém aqui merece minha lealdade."';
    }
    if (npc.betrayalRisk > 30 && npc.loyalty < 30) {
      return '"Estou observando. Esperando."';
    }
    if (npc.fatigue > 80) {
      return '"Preciso descansar. Não aguento mais subir."';
    }
    if (npc.fatigue > 50 && npc.floorsCleared > 10) {
      return '"Cada andar pesa mais que o anterior."';
    }
    if (npc.partnerId != null && npc.loyalty > 70) {
      return '"Faço isso por quem eu amo."';
    }
    if (npc.traumas.isNotEmpty && npc.floorsCleared > 5) {
      return '"Carrego o que vi lá em cima."';
    }
    if (npc.floorsCleared > 20) {
      return '"Já vi coisas que você não quer saber."';
    }
    if (npc.floorsCleared > 5) {
      return '"A torre muda quem sobe."';
    }
    return '"Estou pronto. Para o que vier."';
  }

  (IconData, Color) _npcStatusIcon(Npc npc) {
    if (!npc.alive) {
      return (Icons.close, AppTheme.red);
    }
    if (npc.attributes.mentalStability < 20) {
      return (Icons.warning_amber, AppTheme.red);
    }
    if (npc.betrayalRisk > 60) {
      return (Icons.remove_red_eye, AppTheme.orange);
    }
    if (npc.fatigue > 80) {
      return (Icons.battery_1_bar, AppTheme.yellow);
    }
    if (npc.groupId != null) {
      return (Icons.groups, AppTheme.cyan);
    }
    return (Icons.person_outline, AppTheme.textSecondary);
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
              if (npc.talentDiscovered && _hasSpecialCapabilities(npc)) ...[
  const CyanDivider(label: 'CAPACIDADES'),
  ..._buildCapabilities(npc),
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
              // ── Parceiro (detalhado no modal) ──
              if (npc.partnerId != null)
                Builder(
                  builder: (_) {
                    final partner = gp.allNpcs
                        .where((n) => n.id == npc.partnerId)
                        .firstOrNull;
                    if (partner == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              partner.alive
                                  ? Icons.favorite
                                  : Icons.heart_broken,
                              size: 11,
                              color: partner.alive
                                  ? AppTheme.pink
                                  : AppTheme.textDim,
                            ),
                            const SizedBox(width: 4),
                            TerminalText(
                              'Parceiro(a): ${partner.name}',
                              fontSize: 9,
                              color: partner.alive
                                  ? AppTheme.pink
                                  : AppTheme.textDim,
                            ),
                            if (!partner.alive)
                              TerminalText(
                                ' [falecido(a)]',
                                fontSize: 9,
                                color: AppTheme.red,
                              ),
                          ],
                        ),
                        if (npc.childrenIds.isNotEmpty)
                          TerminalText(
                            '${npc.childrenIds.length} filho(s) juntos',
                            fontSize: 9,
                            color: AppTheme.green,
                          ),
                      ],
                    );
                  },
                ),
              // Mostra filhos se não tem parceiro mas tem filhos
              if (npc.partnerId == null && npc.childrenIds.isNotEmpty)
                TerminalText(
                  '${npc.childrenIds.length} filho(s)',
                  fontSize: 9,
                  color: AppTheme.green,
                ),
              // ── Relacionamentos ──
              if (npc.relationships.isNotEmpty) ...[
                const CyanDivider(label: 'VINCULOS'),
                ...npc.relationships
                    .where((r) => r.affinity.abs() > 0.2)
                    .take(6)
                    .map((r) {
                      final target = gp.allNpcs.firstWhereOrNull(
                        (n) => n.id == r.targetId,
                      );
                      if (target == null) return const SizedBox.shrink();
                      final color = r.affinity > 0.6
                          ? AppTheme.green
                          : r.affinity > 0.2
                          ? AppTheme.yellow
                          : AppTheme.red;
                      final icon = r.type == 'parceiro'
                          ? '♥'
                          : r.type == 'familiar'
                          ? '⌂'
                          : r.affinity > 0.3
                          ? '+'
                          : '−';
                      final label = r.affinity > 0.6
                          ? 'proximo'
                          : r.affinity > 0.2
                          ? 'amigavel'
                          : 'hostil';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            TerminalText('$icon ', fontSize: 9, color: color),
                            TerminalText(
                              target.name,
                              fontSize: 9,
                              color: target.alive
                                  ? AppTheme.textPrimary
                                  : AppTheme.textDim,
                            ),
                            if (!target.alive)
                              TerminalText(
                                ' ✝',
                                fontSize: 9,
                                color: AppTheme.red,
                              ),
                            const Spacer(),
                            TerminalText(label, fontSize: 8, color: color),
                            TerminalText(
                              '  ${(r.affinity * 100).toStringAsFixed(0)}%',
                              fontSize: 8,
                              color: AppTheme.textDim,
                            ),
                          ],
                        ),
                      );
                    }),
              ],
              if (npc.traumas.isNotEmpty) ...[
                const CyanDivider(label: 'TRAUMAS'),
                ...npc.traumas.map(
                  (t) => TerminalText('- $t', fontSize: 9, color: AppTheme.red),
                ),
              ],
              const CyanDivider(label: 'EQUIPAMENTOS'),
              Row(
                children: [
                  _EquipSlot(
                    label: 'ARMA',
                    icon: '⚔',
                    equipment: gp
                        .equippedOn(npc.id)
                        .firstWhereOrNull(
                          (e) => e.slot == EquipmentSlot.weapon,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _EquipSlot(
                    label: 'ARMOR',
                    icon: '🛡',
                    equipment: gp
                        .equippedOn(npc.id)
                        .firstWhereOrNull((e) => e.slot == EquipmentSlot.armor),
                  ),
                  const SizedBox(width: 8),
                  _EquipSlot(
                    label: 'ACESS.',
                    icon: '💍',
                    equipment: gp
                        .equippedOn(npc.id)
                        .firstWhereOrNull(
                          (e) => e.slot == EquipmentSlot.accessory,
                        ),
                  ),
                ],
              ),
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

class _EquipSlot extends StatelessWidget {
  final String label;
  final String icon;
  final Equipment? equipment;
  const _EquipSlot({
    required this.label,
    required this.icon,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    final eq = equipment;
    final rarityColor = eq == null
        ? AppTheme.border
        : switch (eq.rarity) {
            EquipmentRarity.common => AppTheme.textDim,
            EquipmentRarity.uncommon => AppTheme.green,
            EquipmentRarity.rare => AppTheme.blue,
            EquipmentRarity.epic => AppTheme.purple,
            EquipmentRarity.legendary => AppTheme.yellow,
            _ => AppTheme.textDim,
          };

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(3),
          color: rarityColor.withValues(alpha: 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                TerminalText(label, fontSize: 7, color: AppTheme.textDim),
              ],
            ),
            const SizedBox(height: 4),
            if (eq == null)
              TerminalText('—', fontSize: 8, color: AppTheme.textDim)
            else ...[
              TerminalText(
                eq.name,
                fontSize: 8,
                color: rarityColor,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 2),
              TerminalText(
                eq.bonusSummary,
                fontSize: 7,
                color: AppTheme.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
bool _hasSpecialCapabilities(Npc npc) {
  final a = npc.attributes;
  return a.canHealAfterBattle ||
      a.canEvadeCombat ||
      a.canCraftMedicine ||
      a.canTameCreatures ||
      a.canRevealSecrets ||
      a.immuneToSanityLoss ||
      a.equipmentBonusMultiplier > 1.0 ||
      a.combatPowerMultiplier > 1.0 ||
      a.groupMortalityReduction > 0 ||
      a.groupMoraleBonus > 0 ||
      a.groupSynergyBonus > 0;
}

List<Widget> _buildCapabilities(Npc npc) {
  final a = npc.attributes;
  final caps = <(String, String, Color)>[];

  if (a.canHealAfterBattle) {
    caps.add(('✚', 'Cura aliados após batalha', AppTheme.green));
  }
  if (a.canEvadeCombat) {
    caps.add(('◈', 'Pode evadir combate', AppTheme.blue));
  }
  if (a.canCraftMedicine) {
    caps.add(('⚗', 'Cria medicamentos', AppTheme.green));
  }
  if (a.canTameCreatures) {
    caps.add(('⬡', 'Domina criaturas', AppTheme.yellow));
  }
  if (a.canRevealSecrets) {
    caps.add(('◉', 'Revela segredos da Torre', AppTheme.purple));
  }
  if (a.immuneToSanityLoss) {
    caps.add(('◇', 'Imune à perda de sanidade', AppTheme.cyan));
  }
  if (a.equipmentBonusMultiplier > 1.0) {
    caps.add(('⚒', 'Equipamentos ${a.equipmentBonusMultiplier.toStringAsFixed(1)}x eficientes', AppTheme.orange));
  }
  if (a.combatPowerMultiplier > 1.0) {
    caps.add(('⚡', 'Poder de combate ${a.combatPowerMultiplier.toStringAsFixed(1)}x', AppTheme.red));
  }
  if (a.groupMortalityReduction > 0) {
    caps.add(('☯', '−${(a.groupMortalityReduction * 100).toStringAsFixed(0)}% mortalidade do grupo', AppTheme.green));
  }
  if (a.groupMoraleBonus > 0) {
    caps.add(('♦', '+${(a.groupMoraleBonus * 100).toStringAsFixed(0)}% moral do grupo', AppTheme.yellow));
  }
  if (a.groupSynergyBonus > 0) {
    caps.add(('∞', '+${(a.groupSynergyBonus * 100).toStringAsFixed(0)}% sinergia', AppTheme.cyan));
  }

  return caps.map((c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      TerminalText('${c.$1} ', fontSize: 10, color: c.$3),
      Expanded(
        child: TerminalText(c.$2, fontSize: 9, color: AppTheme.textSecondary),
      ),
    ]),
  )).toList();
}
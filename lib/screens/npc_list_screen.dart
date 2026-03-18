import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/npc_enums.dart';
//import 'package:tower_ascension/models/equipment.dart';
import 'package:tower_ascension/screens/equipment.dart';
import 'package:tower_ascension/screens/npc_detail_screen.dart';
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
          case 'deserting':
            npcs = gp.aliveNpcs.where((n) => n.wantsToLeave).toList();
            break;
          case 'favorites':
            npcs = gp.aliveNpcs.where((n) => n.isFavorite).toList();
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
              (a, b) => b.attributes.mentalStability.compareTo(
                a.attributes.mentalStability,
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
          case 'profession':
            npcs.sort(
              (a, b) => a.profession.label.compareTo(b.profession.label),
            );
            break;
          default:
            npcs.sort((a, b) => a.name.compareTo(b.name));
        }

        return ScanlineOverlay(
          child: Column(
            children: [
              _buildFilters(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    // Botão Designar profissões em massa
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.work_outline,
                        size: 16,
                        color: AppTheme.yellow,
                      ),
                      label: const Text(
                        'Designar',
                        style: TextStyle(
                          color: AppTheme.yellow,
                          fontFamily: 'Consolas',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.bgCard,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: AppTheme.yellow),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _showBulkProfessionSheet(context, gp),
                    ),
                    const Spacer(),
                    // Botão Equipamentos
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.shield,
                        size: 16,
                        color: AppTheme.cyan,
                      ),
                      label: const Text(
                        'Equipamentos',
                        style: TextStyle(
                          color: AppTheme.cyan,
                          fontFamily: 'Consolas',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.bgCard,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: AppTheme.cyan),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EquipmentScreen(),
                        ),
                      ),
                    ),
                  ],
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1 — filtros de status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                _filterChip('TODOS', 'all'),
                _filterChip('VIVOS', 'alive'),
                _filterChip('MORTOS', 'dead'),
                _filterChip('EXAUSTOS', 'exhausted'),
                _filterChip('QUERENDO IR', 'deserting'),
                _filterChip('⭐ FAVORITOS', 'favorites'),
              ],
            ),
          ),
          // Linha 2 — ordenação
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                const TerminalText(
                  'Ordenar:',
                  fontSize: 9,
                  color: AppTheme.textDim,
                ),
                const SizedBox(width: 6),
                _sortChip('Nome', 'name'),
                _sortChip('Poder', 'power'),
                _sortChip('Mental', 'mental'),
                _sortChip('Fama', 'fame'),
                _sortChip('Leal.', 'loyalty'),
                _sortChip('Risco', 'betrayal'),
                _sortChip('Fadiga', 'fatigue'),
                _sortChip('Prof.', 'profession'),
              ],
            ),
          ),
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

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(2),
      ),
      child: TerminalText(
        label,
        fontSize: 8,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _rankColor(NpcRank rank) {
    switch (rank) {
      case NpcRank.ssr:
        return const Color(0xFFECC94B);
      case NpcRank.sr:
        return const Color(0xFF00B4D8);
      case NpcRank.r:
        return const Color(0xFF48BB78);
      case NpcRank.n:
        return const Color(0xFF718096);
    }
  }

  Widget _rankBadge(NpcRank rank, int stars, bool isPromoted) {
    final color = _rankColor(rank);
    final starsStr = stars > 0 ? '★' * stars : '';
    final promotedMark = isPromoted ? '*' : '';
    final label = '${rank.label}$promotedMark$starsStr';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(
          color: color.withValues(alpha: isPromoted ? 1.0 : 0.6),
          width: isPromoted ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: TerminalText(
        label,
        fontSize: 8,
        color: color,
        fontWeight: FontWeight.bold,
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
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => NpcDetailScreen(npcId: npc.id))),
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
            // ROW 1 — header with icon, name, badges
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
                // Badges agrupados num Row com mainAxisSize.min
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!npc.alive)
                      _badge('MORTO', AppTheme.red)
                    else if (npc.betrayalRisk > 60)
                      _badge('⚠ RISCO', AppTheme.orange)
                    else if (npc.groupId != null)
                      Builder(
                        builder: (_) {
                          final group = gp.groups
                              .where((g) => g.id == npc.groupId)
                              .firstOrNull;
                          return _badge(group?.name ?? 'Grupo', AppTheme.cyan);
                        },
                      ),
                    if (npc.alive) ...[
                      const SizedBox(width: 4),
                      _rankBadge(npc.rank, npc.stars, npc.isPromoted),
                    ],
                    if (npc.alive && npc.isFavorite) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 11,
                        color: Color(0xFFECC94B),
                      ),
                    ],
                    if (npc.alive && npc.wantsToLeave) ...[
                      const SizedBox(width: 4),
                      _badge('QUER PARTIR', AppTheme.orange),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            // ROW 2 — quote
            // Profissão atual
            if (npc.alive)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      size: 10,
                      color: AppTheme.textDim,
                    ),
                    const SizedBox(width: 4),
                    TerminalText(
                      npc.profession.label,
                      fontSize: 8,
                      color: npc.profession == Profession.idle
                          ? AppTheme.textDim
                          : AppTheme.blue,
                    ),
                  ],
                ),
              ),
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
            if (npc.partnerId != null)
              Builder(
                builder: (_) {
                  final partner = gp.allNpcs
                      .where((n) => n.id == npc.partnerId)
                      .firstOrNull;
                  if (partner == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          partner.alive ? Icons.favorite : Icons.heart_broken,
                          size: 10,
                          color: partner.alive
                              ? AppTheme.pink
                              : AppTheme.textDim,
                        ),
                        const SizedBox(width: 4),
                        TerminalText(
                          partner.alive
                              ? '♥ ${partner.name}'
                              : '✝ ${partner.name} [falecido(a)]',
                          fontSize: 8,
                          color: partner.alive
                              ? AppTheme.pink
                              : AppTheme.textDim,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet de designação em massa ─────────────────────────

  void _showBulkProfessionSheet(BuildContext context, GameProvider gp) {
    // Mapa mutavel: npcId -> profissão selecionada (parte do estado do pendênte)
    final pending = <String, Profession>{
      for (final npc in gp.aliveNpcs) npc.id: npc.profession,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final npcs = gp.aliveNpcs;
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) => Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const TerminalText(
                        'DESIGNAR PROFISSÕES',
                        fontSize: 13,
                        color: AppTheme.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                      const Spacer(),
                      TerminalText(
                        '\${npcs.length} habitantes',
                        fontSize: 9,
                        color: AppTheme.textDim,
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: AppTheme.border),
                // Lista
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: npcs.length,
                    itemBuilder: (ctx, i) {
                      final npc = npcs[i];
                      final selected = pending[npc.id] ?? npc.profession;
                      final changed = selected != npc.profession;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.border),
                          ),
                          color: changed
                              ? AppTheme.yellow.withValues(alpha: 0.04)
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Info do NPC
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      TerminalText(
                                        npc.name,
                                        fontSize: 11,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      const SizedBox(width: 6),
                                      _rankBadge(
                                        npc.rank,
                                        npc.stars,
                                        npc.isPromoted,
                                      ),
                                    ],
                                  ),
                                  TerminalText(
                                    'G\${npc.generation} · \${npc.origin.label}',
                                    fontSize: 8,
                                    color: AppTheme.textDim,
                                  ),
                                ],
                              ),
                            ),
                            // Dropdown de profissão
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: changed
                                      ? AppTheme.yellow
                                      : AppTheme.border,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color: AppTheme.bg,
                              ),
                              child: DropdownButton<Profession>(
                                value: selected,
                                isDense: true,
                                underline: const SizedBox.shrink(),
                                dropdownColor: AppTheme.bgCard,
                                style: const TextStyle(
                                  fontFamily: 'FiraCode',
                                  fontSize: 11,
                                  color: AppTheme.textPrimary,
                                ),
                                items: Profession.values.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p.label),
                                  );
                                }).toList(),
                                onChanged: (p) {
                                  if (p != null) {
                                    setSheetState(() => pending[npc.id] = p);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Rodapé com contagem de mudanças e botão confirmar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.border)),
                    color: AppTheme.bgCard,
                  ),
                  child: Builder(
                    builder: (ctx) {
                      final changes = pending.entries.where((e) {
                        final npc = gp.allNpcs.firstWhereOrNull(
                          (n) => n.id == e.key,
                        );
                        return npc != null && e.value != npc.profession;
                      }).length;
                      return Row(
                        children: [
                          TerminalText(
                            changes > 0
                                ? '\$changes alteração(ões) pendente(s)'
                                : 'Sem alterações',
                            fontSize: 9,
                            color: changes > 0
                                ? AppTheme.yellow
                                : AppTheme.textDim,
                          ),
                          const Spacer(),
                          if (changes > 0)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.yellow,
                                foregroundColor: AppTheme.bg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () {
                                for (final entry in pending.entries) {
                                  final npc = gp.allNpcs.firstWhereOrNull(
                                    (n) => n.id == entry.key,
                                  );
                                  if (npc != null &&
                                      entry.value != npc.profession) {
                                    gp.assignProfession(entry.key, entry.value);
                                  }
                                }
                                Navigator.pop(ctx);
                              },
                              child: const Text(
                                'CONFIRMAR',
                                style: TextStyle(
                                  fontFamily: 'FiraCode',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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

  // void _showNpcDetail(BuildContext context, Npc npc, GameProvider gp) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: AppTheme.bgCard,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
  //       side: BorderSide(color: AppTheme.border),
  //     ),
  //     builder: (context) => DraggableScrollableSheet(
  //       initialChildSize: 0.85,
  //       minChildSize: 0.5,
  //       maxChildSize: 0.95,
  //       expand: false,
  //       builder: (context, scrollController) => SingleChildScrollView(
  //         controller: scrollController,
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Center(
  //               child: Container(
  //                 width: 40,
  //                 height: 3,
  //                 color: AppTheme.border,
  //                 margin: const EdgeInsets.only(bottom: 12),
  //               ),
  //             ),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: TerminalText(
  //                     npc.name,
  //                     fontSize: 14,
  //                     color: AppTheme.cyan,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 TerminalText(
  //                   npc.alive ? 'VIVO' : 'MORTO',
  //                   fontSize: 10,
  //                   color: npc.alive ? AppTheme.green : AppTheme.red,
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 4),
  //             TerminalText(
  //               'Origem: ${npc.origin.label} | Geracao ${npc.generation} | ${npc.age} anos | ${npc.daysSurvived} dias na Torre',
  //               fontSize: 9,
  //               color: AppTheme.textSecondary,
  //             ),
  //             const CyanDivider(label: 'ATRIBUTOS'),
  //             StatBar(
  //               label: 'Forca',
  //               value: npc.totalStrength(gp.equippedOn(npc.id)),
  //               maxValue: 20,
  //             ),
  //             StatBar(
  //               label: 'Agil.',
  //               value: npc.totalAgility(gp.equippedOn(npc.id)),
  //               maxValue: 20,
  //             ),
  //             StatBar(
  //               label: 'Intel.',
  //               value: npc.totalIntelligence(gp.equippedOn(npc.id)),
  //               maxValue: 20,
  //             ),
  //             StatBar(
  //               label: 'Resist.',
  //               value: npc.totalEndurance(gp.equippedOn(npc.id)),
  //               maxValue: 20,
  //             ),
  //             StatBar(
  //               label: 'Caris.',
  //               value: npc.totalCharisma(gp.equippedOn(npc.id)),
  //               maxValue: 20,
  //             ),
  //             StatBar(
  //               label: 'Sanid.',
  //               value: npc.attributes.mentalStability,
  //               maxValue: 100,
  //               color: npc.attributes.mentalStability > 60
  //                   ? AppTheme.green
  //                   : npc.attributes.mentalStability > 30
  //                   ? AppTheme.yellow
  //                   : AppTheme.red,
  //             ),
  //             StatBar(
  //               label: 'Fadiga',
  //               value: npc.fatigue,
  //               maxValue: 100,
  //               color: npc.fatigue < 30
  //                   ? AppTheme.green
  //                   : npc.fatigue < 50
  //                   ? AppTheme.yellow
  //                   : npc.fatigue < 70
  //                   ? AppTheme.orange
  //                   : AppTheme.red,
  //             ),
  //             const SizedBox(height: 2),
  //             TerminalText(
  //               'Estado fisico: ${npc.fatigueLabel}${npc.isIncapacitated
  //                   ? " [INCAPACITADO]"
  //                   : npc.isExhausted
  //                   ? " [EXAUSTO]"
  //                   : ""}',
  //               fontSize: 9,
  //               color: npc.fatigue >= 70
  //                   ? AppTheme.red
  //                   : npc.fatigue >= 50
  //                   ? AppTheme.orange
  //                   : AppTheme.green,
  //             ),
  //             const SizedBox(height: 4),
  //             TerminalText(
  //               'Poder de combate: ${npc.effectiveCombatPowerWithGear(gp.equippedOn(npc.id)).toStringAsFixed(1)} | Media geral: ${npc.attributes.average.toStringAsFixed(1)}',
  //               fontSize: 9,
  //               color: AppTheme.orange,
  //             ),
  //             const CyanDivider(label: 'PERSONALIDADE'),
  //             Wrap(
  //               spacing: 6,
  //               runSpacing: 4,
  //               children: npc.traits
  //                   .map(
  //                     (t) => Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 6,
  //                         vertical: 2,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         border: Border.all(
  //                           color: AppTheme.purple.withValues(alpha: 0.5),
  //                         ),
  //                         borderRadius: BorderRadius.circular(2),
  //                       ),
  //                       child: TerminalText(
  //                         t.label,
  //                         fontSize: 9,
  //                         color: AppTheme.purple,
  //                       ),
  //                     ),
  //                   )
  //                   .toList(),
  //             ),
  //             if (npc.hiddenTalent != HiddenTalent.none) ...[
  //               const CyanDivider(label: 'TALENTO OCULTO'),
  //               TerminalText(
  //                 npc.talentDiscovered
  //                     ? '${npc.hiddenTalent.label}: ${npc.hiddenTalent.description}'
  //                     : '??? Talento ainda nao revelado',
  //                 fontSize: 10,
  //                 color: npc.talentDiscovered
  //                     ? AppTheme.purple
  //                     : AppTheme.textDim,
  //               ),
  //             ],
  //             if (npc.talentDiscovered && _hasSpecialCapabilities(npc)) ...[
  //               const CyanDivider(label: 'CAPACIDADES'),
  //               ..._buildCapabilities(npc),
  //             ],
  //             const CyanDivider(label: 'FUNCAO NA CIDADELA'),
  //             TerminalText(
  //               'Funcao atual: ${npc.profession.label}',
  //               fontSize: 10,
  //               color: AppTheme.textPrimary,
  //             ),
  //             const CyanDivider(label: 'ESTATISTICAS'),
  //             TerminalText(
  //               'Andares superados: ${npc.floorsCleared}',
  //               fontSize: 9,
  //               color: AppTheme.textSecondary,
  //             ),
  //             TerminalText(
  //               'Fama acumulada: ${npc.fame.toStringAsFixed(0)}',
  //               fontSize: 9,
  //               color: AppTheme.yellow,
  //             ),
  //             TerminalText(
  //               'Estado mental: ${npc.mentalCondition.label}',
  //               fontSize: 9,
  //               color: AppTheme.textSecondary,
  //             ),
  //             const CyanDivider(label: 'SOCIAL'),
  //             StatBar(
  //               label: 'Leal.',
  //               value: npc.loyalty,
  //               maxValue: 100,
  //               color: npc.loyalty > 60
  //                   ? AppTheme.green
  //                   : npc.loyalty > 30
  //                   ? AppTheme.yellow
  //                   : AppTheme.red,
  //             ),
  //             TerminalText(
  //               'Reputacao: ${npc.fameLabel} (${npc.fame.toStringAsFixed(0)})',
  //               fontSize: 9,
  //               color: npc.fame >= 0 ? AppTheme.yellow : AppTheme.red,
  //             ),
  //             if (npc.betrayalRisk > 10)
  //               TerminalText(
  //                 'Risco de traicao: ${npc.betrayalRisk.toStringAsFixed(0)}%',
  //                 fontSize: 9,
  //                 color: npc.betrayalRisk > 50 ? AppTheme.red : AppTheme.orange,
  //               ),
  //             if (npc.groupId != null)
  //               Builder(
  //                 builder: (_) {
  //                   final group = gp.groups
  //                       .where((g) => g.id == npc.groupId)
  //                       .firstOrNull;
  //                   return TerminalText(
  //                     'Grupo: ${group?.name ?? "Sem grupo"}',
  //                     fontSize: 9,
  //                     color: AppTheme.blue,
  //                   );
  //                 },
  //               ),
  //             if (npc.trainingSuggestionsReceived > 0)
  //               TerminalText(
  //                 'Sugestoes: ${npc.trainingSuggestionsAccepted}/${npc.trainingSuggestionsReceived} aceitas',
  //                 fontSize: 9,
  //                 color: AppTheme.textDim,
  //               ),
  //             if (npc.origin.isDarkOrigin)
  //               TerminalText(
  //                 'ORIGEM OBSCURA: ${npc.origin.label}',
  //                 fontSize: 9,
  //                 color: AppTheme.red,
  //               ),
  //             // ── Parceiro (detalhado no modal) ──
  //             if (npc.partnerId != null)
  //               Builder(
  //                 builder: (_) {
  //                   final partner = gp.allNpcs
  //                       .where((n) => n.id == npc.partnerId)
  //                       .firstOrNull;
  //                   if (partner == null) return const SizedBox.shrink();
  //                   return Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: [
  //                           Icon(
  //                             partner.alive
  //                                 ? Icons.favorite
  //                                 : Icons.heart_broken,
  //                             size: 11,
  //                             color: partner.alive
  //                                 ? AppTheme.pink
  //                                 : AppTheme.textDim,
  //                           ),
  //                           const SizedBox(width: 4),
  //                           TerminalText(
  //                             'Parceiro(a): ${partner.name}',
  //                             fontSize: 9,
  //                             color: partner.alive
  //                                 ? AppTheme.pink
  //                                 : AppTheme.textDim,
  //                           ),
  //                           if (!partner.alive)
  //                             TerminalText(
  //                               ' [falecido(a)]',
  //                               fontSize: 9,
  //                               color: AppTheme.red,
  //                             ),
  //                         ],
  //                       ),
  //                       if (npc.childrenIds.isNotEmpty)
  //                         TerminalText(
  //                           '${npc.childrenIds.length} filho(s) juntos',
  //                           fontSize: 9,
  //                           color: AppTheme.green,
  //                         ),
  //                     ],
  //                   );
  //                 },
  //               ),
  //             // Mostra filhos se não tem parceiro mas tem filhos
  //             if (npc.partnerId == null && npc.childrenIds.isNotEmpty)
  //               TerminalText(
  //                 '${npc.childrenIds.length} filho(s)',
  //                 fontSize: 9,
  //                 color: AppTheme.green,
  //               ),
  //             // ── Relacionamentos ──
  //             if (npc.relationships.isNotEmpty) ...[
  //               const CyanDivider(label: 'VINCULOS'),
  //               ...npc.relationships
  //                   .where((r) => r.affinity.abs() > 0.2)
  //                   .take(6)
  //                   .map((r) {
  //                     final target = gp.allNpcs.firstWhereOrNull(
  //                       (n) => n.id == r.targetId,
  //                     );
  //                     if (target == null) return const SizedBox.shrink();
  //                     final color = r.affinity > 0.6
  //                         ? AppTheme.green
  //                         : r.affinity > 0.2
  //                         ? AppTheme.yellow
  //                         : AppTheme.red;
  //                     final icon = r.type == 'parceiro'
  //                         ? '♥'
  //                         : r.type == 'familiar'
  //                         ? '⌂'
  //                         : r.affinity > 0.3
  //                         ? '+'
  //                         : '−';
  //                     final label = r.affinity > 0.6
  //                         ? 'proximo'
  //                         : r.affinity > 0.2
  //                         ? 'amigavel'
  //                         : 'hostil';
  //                     return Padding(
  //                       padding: const EdgeInsets.symmetric(vertical: 2),
  //                       child: Row(
  //                         children: [
  //                           TerminalText('$icon ', fontSize: 9, color: color),
  //                           TerminalText(
  //                             target.name,
  //                             fontSize: 9,
  //                             color: target.alive
  //                                 ? AppTheme.textPrimary
  //                                 : AppTheme.textDim,
  //                           ),
  //                           if (!target.alive)
  //                             TerminalText(
  //                               ' ✝',
  //                               fontSize: 9,
  //                               color: AppTheme.red,
  //                             ),
  //                           const Spacer(),
  //                           TerminalText(label, fontSize: 8, color: color),
  //                           TerminalText(
  //                             '  ${(r.affinity * 100).toStringAsFixed(0)}%',
  //                             fontSize: 8,
  //                             color: AppTheme.textDim,
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //             ],
  //             if (npc.traumas.isNotEmpty) ...[
  //               const CyanDivider(label: 'TRAUMAS'),
  //               ...npc.traumas.map(
  //                 (t) => TerminalText('- $t', fontSize: 9, color: AppTheme.red),
  //               ),
  //             ],
  //             const CyanDivider(label: 'EQUIPAMENTOS'),
  //             Row(
  //               children: [
  //                 _EquipSlot(
  //                   label: 'ARMA',
  //                   icon: '⚔',
  //                   equipment: gp
  //                       .equippedOn(npc.id)
  //                       .firstWhereOrNull(
  //                         (e) => e.slot == EquipmentSlot.weapon,
  //                       ),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 _EquipSlot(
  //                   label: 'ARMOR',
  //                   icon: '🛡',
  //                   equipment: gp
  //                       .equippedOn(npc.id)
  //                       .firstWhereOrNull((e) => e.slot == EquipmentSlot.armor),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 _EquipSlot(
  //                   label: 'ACESS.',
  //                   icon: '💍',
  //                   equipment: gp
  //                       .equippedOn(npc.id)
  //                       .firstWhereOrNull(
  //                         (e) => e.slot == EquipmentSlot.accessory,
  //                       ),
  //                 ),
  //               ],
  //             ),
  //             if (npc.history.isNotEmpty) ...[
  //               const CyanDivider(label: 'HISTORICO'),
  //               ...npc.history.reversed
  //                   .take(10)
  //                   .map(
  //                     (h) => TerminalText(
  //                       '> $h',
  //                       fontSize: 9,
  //                       color: AppTheme.textDim,
  //                     ),
  //                   ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

// class _EquipSlot extends StatelessWidget {
//   final String label;
//   final String icon;
//   final Equipment? equipment;
//   const _EquipSlot({
//     required this.label,
//     required this.icon,
//     required this.equipment,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final eq = equipment;
//     final rarityColor = eq == null
//         ? AppTheme.border
//         : switch (eq.rarity) {
//             EquipmentRarity.common => AppTheme.textDim,
//             EquipmentRarity.uncommon => AppTheme.green,
//             EquipmentRarity.rare => AppTheme.blue,
//             EquipmentRarity.epic => AppTheme.purple,
//             EquipmentRarity.legendary => AppTheme.yellow,
//             _ => AppTheme.textDim,
//           };

//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
//           borderRadius: BorderRadius.circular(3),
//           color: rarityColor.withValues(alpha: 0.04),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text(icon, style: const TextStyle(fontSize: 10)),
//                 const SizedBox(width: 4),
//                 TerminalText(label, fontSize: 7, color: AppTheme.textDim),
//               ],
//             ),
//             const SizedBox(height: 4),
//             if (eq == null)
//               TerminalText('—', fontSize: 8, color: AppTheme.textDim)
//             else ...[
//               TerminalText(
//                 eq.name,
//                 fontSize: 8,
//                 color: rarityColor,
//                 fontWeight: FontWeight.bold,
//               ),
//               const SizedBox(height: 2),
//               TerminalText(
//                 eq.bonusSummary,
//                 fontSize: 7,
//                 color: AppTheme.textSecondary,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// bool _hasSpecialCapabilities(Npc npc) {
//   final a = npc.attributes;
//   return a.canHealAfterBattle ||
//       a.canEvadeCombat ||
//       a.canCraftMedicine ||
//       a.canTameCreatures ||
//       a.canRevealSecrets ||
//       a.immuneToSanityLoss ||
//       a.equipmentBonusMultiplier > 1.0 ||
//       a.combatPowerMultiplier > 1.0 ||
//       a.groupMortalityReduction > 0 ||
//       a.groupMoraleBonus > 0 ||
//       a.groupSynergyBonus > 0;
// }

// List<Widget> _buildCapabilities(Npc npc) {
//   final a = npc.attributes;
//   final caps = <(String, String, Color)>[];

//   if (a.canHealAfterBattle) {
//     caps.add(('✚', 'Cura aliados após batalha', AppTheme.green));
//   }
//   if (a.canEvadeCombat) {
//     caps.add(('◈', 'Pode evadir combate', AppTheme.blue));
//   }
//   if (a.canCraftMedicine) {
//     caps.add(('⚗', 'Cria medicamentos', AppTheme.green));
//   }
//   if (a.canTameCreatures) {
//     caps.add(('⬡', 'Domina criaturas', AppTheme.yellow));
//   }
//   if (a.canRevealSecrets) {
//     caps.add(('◉', 'Revela segredos da Torre', AppTheme.purple));
//   }
//   if (a.immuneToSanityLoss) {
//     caps.add(('◇', 'Imune à perda de sanidade', AppTheme.cyan));
//   }
//   if (a.equipmentBonusMultiplier > 1.0) {
//     caps.add((
//       '⚒',
//       'Equipamentos ${a.equipmentBonusMultiplier.toStringAsFixed(1)}x eficientes',
//       AppTheme.orange,
//     ));
//   }
//   if (a.combatPowerMultiplier > 1.0) {
//     caps.add((
//       '⚡',
//       'Poder de combate ${a.combatPowerMultiplier.toStringAsFixed(1)}x',
//       AppTheme.red,
//     ));
//   }
//   if (a.groupMortalityReduction > 0) {
//     caps.add((
//       '☯',
//       '−${(a.groupMortalityReduction * 100).toStringAsFixed(0)}% mortalidade do grupo',
//       AppTheme.green,
//     ));
//   }
//   if (a.groupMoraleBonus > 0) {
//     caps.add((
//       '♦',
//       '+${(a.groupMoraleBonus * 100).toStringAsFixed(0)}% moral do grupo',
//       AppTheme.yellow,
//     ));
//   }
//   if (a.groupSynergyBonus > 0) {
//     caps.add((
//       '∞',
//       '+${(a.groupSynergyBonus * 100).toStringAsFixed(0)}% sinergia',
//       AppTheme.cyan,
//     ));
//   }

//   return caps
//       .map(
//         (c) => Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2),
//           child: Row(
//             children: [
//               TerminalText('${c.$1} ', fontSize: 10, color: c.$3),
//               Expanded(
//                 child: TerminalText(
//                   c.$2,
//                   fontSize: 9,
//                   color: AppTheme.textSecondary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       )
//       .toList();
// }

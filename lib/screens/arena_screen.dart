import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import '../models/npc.dart';
import '../models/game_event.dart';
import '../models/citadel.dart';
import '../models/citadel_record.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  int _tab = 0; // 0: Ranking, 1: Histórico, 2: Registros

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final hasArena = gp.citadel.hasBuilding(BuildingType.arena);

        if (!hasArena) {
          return ScanlineOverlay(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_mma_outlined,
                      color: AppTheme.textDim,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const TerminalText(
                      'ARENA NÃO CONSTRUÍDA',
                      fontSize: 14,
                      color: AppTheme.textDim,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    const TerminalText(
                      'Construa a Arena na Cidadela para ativar duelos,\napostas e o ranking de gladiadores.',
                      fontSize: 11,
                      color: AppTheme.textDim,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final arenaLevel =
            gp.citadel.getBuilding(BuildingType.arena)?.level ?? 1;
        final gladiators = _getGladiators(gp);
        final champion = gladiators.isNotEmpty ? gladiators.first : null;
        final arenaEvents = _getArenaEvents(gp);
        final honorRecords = _getHonorRecords(gp);

        return ScanlineOverlay(
          child: Column(
            children: [
              // ── Campeão ──────────────────────────────────
              _buildChampionCard(champion, arenaLevel),

              // ── Tabs ─────────────────────────────────────
              _buildTabBar(),

              // ── Conteúdo da tab ───────────────────────────
              Expanded(
                child: _tab == 0
                    ? _buildRanking(gladiators, gp)
                    : _tab == 1
                    ? _buildHistory(arenaEvents)
                    : _buildRecords(honorRecords),
              ),

              // ── Ações do jogador ──────────────────────────
              _buildActionsBar(context, gp, arenaLevel),
            ],
          ),
        );
      },
    );
  }

  // ── Dados ──────────────────────────────────────────────────

  List<Npc> _getGladiators(GameProvider gp) {
    return gp.aliveNpcs
        .where((n) => n.arenaWins > 0 || n.arenaLosses > 0)
        .toList()
      ..sort((a, b) => b.arenaWins.compareTo(a.arenaWins));
  }

  List<GameEvent> _getArenaEvents(GameProvider gp) {
    return gp.events
        .where(
          (e) =>
              e.type == GameEventType.combat &&
              (e.title.contains('Arena') || e.title.contains('Desafio')),
        )
        .toList()
        .reversed
        .take(30)
        .toList();
  }

  List<CitadelRecord> _getHonorRecords(GameProvider gp) {
    return gp.citadelRecords
        .where((r) => r.category == RecordCategory.honor)
        .toList()
        .reversed
        .toList();
  }

  // ── Campeão ────────────────────────────────────────────────

  Widget _buildChampionCard(Npc? champion, int arenaLevel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(
          color:
              champion != null ? AppTheme.yellow : AppTheme.border,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: champion != null ? AppTheme.yellow : AppTheme.textDim,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: champion == null
                ? const TerminalText(
                    'Nenhum campeão coroado ainda.',
                    fontSize: 12,
                    color: AppTheme.textDim,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TerminalText(
                        _arenaTitle(champion.arenaWins).toUpperCase(),
                        fontSize: 9,
                        color: AppTheme.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                      TerminalText(
                        champion.name,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      TerminalText(
                        '${champion.arenaWins}V · ${champion.arenaLosses}D · ${champion.fame.toStringAsFixed(0)} fama',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TerminalText(
                'ARENA Nv.$arenaLevel',
                fontSize: 9,
                color: AppTheme.cyan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────

  Widget _buildTabBar() {
    const labels = ['RANKING', 'HISTÓRICO', 'REGISTROS'];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = _tab == i;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppTheme.cyan : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: TerminalText(
                labels[i],
                fontSize: 11,
                color: active ? AppTheme.cyan : AppTheme.textDim,
                fontWeight: active ? FontWeight.bold : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Ranking ────────────────────────────────────────────────

  Widget _buildRanking(List<Npc> gladiators, GameProvider gp) {
    if (gladiators.isEmpty) {
      return const Center(
        child: TerminalText(
          'Nenhum gladiador registrado ainda.\nOs duelos acontecem automaticamente a cada 7 dias.',
          fontSize: 11,
          color: AppTheme.textDim,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: gladiators.length,
      itemBuilder: (context, i) => _buildGladiatorCard(gladiators[i], i + 1),
    );
  }

  Widget _buildGladiatorCard(Npc npc, int rank) {
    final title = _arenaTitle(npc.arenaWins);
    final isLegendary = npc.arenaWins >= 20;
    final rankColor = rank == 1
        ? AppTheme.yellow
        : rank == 2
        ? AppTheme.textSecondary
        : rank == 3
        ? AppTheme.orange
        : AppTheme.textDim;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(
          color: isLegendary
              ? AppTheme.yellow.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // rank
          SizedBox(
            width: 28,
            child: TerminalText(
              '#$rank',
              fontSize: 13,
              color: rankColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TerminalText(
                      npc.name,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    if (isLegendary) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: AppTheme.yellow,
                      ),
                    ],
                  ],
                ),
                TerminalText(
                  title,
                  fontSize: 10,
                  color: isLegendary ? AppTheme.yellow : AppTheme.textDim,
                ),
              ],
            ),
          ),
          // stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  TerminalText(
                    '${npc.arenaWins}V',
                    fontSize: 12,
                    color: AppTheme.green,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(width: 6),
                  TerminalText(
                    '${npc.arenaLosses}D',
                    fontSize: 12,
                    color: AppTheme.red,
                  ),
                ],
              ),
              TerminalText(
                '${npc.fame.toStringAsFixed(0)} fama',
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              TerminalText(
                'CP ${npc.attributes.combatPower.toStringAsFixed(1)}',
                fontSize: 9,
                color: AppTheme.textDim,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Histórico ──────────────────────────────────────────────

  Widget _buildHistory(List<GameEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: TerminalText(
          'Nenhum duelo registrado ainda.',
          fontSize: 11,
          color: AppTheme.textDim,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, i) => _buildEventRow(events[i]),
    );
  }

  Widget _buildEventRow(GameEvent e) {
    final isChallenge = e.title.contains('Desafio');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: isChallenge
                    ? AppTheme.orange.withValues(alpha: 0.5)
                    : AppTheme.red.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: TerminalText(
              isChallenge ? 'DESAFIO' : 'DUELO',
              fontSize: 8,
              color: isChallenge ? AppTheme.orange : AppTheme.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(
                  e.description,
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(height: 2),
                TerminalText(
                  'Dia ${e.day}',
                  fontSize: 9,
                  color: AppTheme.textDim,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Registros ──────────────────────────────────────────────

  Widget _buildRecords(List<CitadelRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: TerminalText(
          'Nenhum registro de honra ainda.\nAtinja 5, 10, 20 ou 30 vitórias na arena.',
          fontSize: 11,
          color: AppTheme.textDim,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      itemBuilder: (context, i) => _buildRecordCard(records[i]),
    );
  }

  Widget _buildRecordCard(CitadelRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(
          color: AppTheme.yellow.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            r.title.toUpperCase(),
            fontSize: 12,
            color: AppTheme.yellow,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          TerminalText(r.body, fontSize: 11, color: AppTheme.textSecondary),
          const SizedBox(height: 4),
          TerminalText('Dia ${r.day}', fontSize: 9, color: AppTheme.textDim),
        ],
      ),
    );
  }

  // ── Barra de ações ─────────────────────────────────────────

  Widget _buildActionsBar(
    BuildContext context,
    GameProvider gp,
    int arenaLevel,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
        color: AppTheme.bgCard,
      ),
      child: Row(
        children: [
          Expanded(
            child: TerminalButton(
              label: 'DESAFIO MANUAL',
              icon: Icons.sports_mma,
              color: AppTheme.orange,
              expanded: true,
              onPressed: () => _showChallengeDialog(context, gp, arenaLevel),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialog de desafio manual ───────────────────────────────

  void _showChallengeDialog(
    BuildContext context,
    GameProvider gp,
    int arenaLevel,
  ) {
    final foodCost = 5 + (arenaLevel * 5);
    final eligible = gp.aliveNpcs
        .where(
          (n) =>
              n.attributes.combatPower > 3.0 &&
              (gp.state.currentDay - n.lastArenaChallengeDay) >= 3,
        )
        .toList()
      ..sort((a, b) => b.attributes.combatPower.compareTo(a.attributes.combatPower));

    String? selectedA;
    String? selectedB;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.orange),
          ),
          title: const TerminalText(
            'DESAFIO MANUAL',
            fontSize: 14,
            color: AppTheme.orange,
            fontWeight: FontWeight.bold,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(
                  'Custo: $foodCost comida · Cooldown: 3 dias por lutador',
                  fontSize: 10,
                  color: AppTheme.textDim,
                ),
                const SizedBox(height: 12),
                if (eligible.length < 2)
                  const TerminalText(
                    'Lutadores insuficientes disponíveis.\n(mín. combatePower > 3 e cooldown zerado)',
                    fontSize: 11,
                    color: AppTheme.red,
                  )
                else ...[
                  const TerminalText(
                    'Lutador A:',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _npcDropdown(
                    eligible,
                    selectedA,
                    exclude: selectedB,
                    onChanged: (v) => setS(() => selectedA = v),
                  ),
                  const SizedBox(height: 10),
                  const TerminalText(
                    'Lutador B:',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _npcDropdown(
                    eligible,
                    selectedB,
                    exclude: selectedA,
                    onChanged: (v) => setS(() => selectedB = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TerminalButton(
              label: 'CANCELAR',
              color: AppTheme.textDim,
              onPressed: () => Navigator.pop(ctx),
            ),
            if (eligible.length >= 2)
              TerminalButton(
                label: 'LUTAR',
                icon: Icons.sports_mma,
                color: AppTheme.orange,
                onPressed: selectedA != null && selectedB != null
                    ? () {
                        Navigator.pop(ctx);
                        final result =
                            gp.runArenaChallenge(selectedA!, selectedB!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.bgCard,
                            content: TerminalText(
                              result,
                              fontSize: 12,
                              color: AppTheme.orange,
                            ),
                          ),
                        );
                        setState(() {});
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _npcDropdown(
    List<Npc> options,
    String? value, {
    String? exclude,
    required void Function(String?) onChanged,
  }) {
    final filtered = options.where((n) => n.id != exclude).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.bgElevated,
      ),
      child: DropdownButton<String>(
        value: filtered.any((n) => n.id == value) ? value : null,
        isExpanded: true,
        dropdownColor: AppTheme.bgCard,
        underline: const SizedBox(),
        hint: const TerminalText(
          'Selecionar...',
          fontSize: 11,
          color: AppTheme.textDim,
        ),
        items: filtered
            .map(
              (n) => DropdownMenuItem(
                value: n.id,
                child: TerminalText(
                  '${n.name}  CP ${n.attributes.combatPower.toStringAsFixed(1)}  ${n.arenaWins}V/${n.arenaLosses}D',
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  String _arenaTitle(int wins) {
    if (wins >= 30) return 'Imortal da Arena';
    if (wins >= 20) return 'Campeão Lendário';
    if (wins >= 10) return 'Campeão da Arena';
    if (wins >= 5) return 'Lutador Destaque';
    return 'Gladiador';
  }
}
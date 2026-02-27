// lib/screens/prison_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/citadel.dart';
import '../providers/game_provider.dart';
import '../models/prison.dart';
import '../models/npc.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class PrisonScreen extends StatefulWidget {
  const PrisonScreen({super.key});

  @override
  State<PrisonScreen> createState() => _PrisonScreenState();
}

class _PrisonScreenState extends State<PrisonScreen>
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
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final hasPrison = gp.engine.citadel.hasBuilding(BuildingType.prison);
        final hasCouncil =
            gp.engine.citadel.hasBuilding(BuildingType.councilHall);

        return ScanlineOverlay(
          child: Column(
            children: [
              _buildHeader(gp, hasPrison, hasCouncil),
              if (!hasPrison || !hasCouncil)
                _buildRequirementsWarning(hasPrison, hasCouncil)
              else ...[
                _buildTabBar(gp),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildTrialsTab(gp),
                      _buildCellsTab(gp),
                      _buildCrimesTab(gp),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────

  Widget _buildHeader(GameProvider gp, bool hasPrison, bool hasCouncil) {
    final pendingCount = gp.prison.pendingTrials.length;
    final cellCount = gp.prison.cells.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Container(width: 3, height: 20, color: AppTheme.red),
          const SizedBox(width: 8),
          TerminalText('JUSTIÇA DA CIDADELA',
              fontSize: 11, color: AppTheme.red, fontWeight: FontWeight.bold),
          const Spacer(),
          if (pendingCount > 0) ...[
            _badge('$pendingCount JULGAMENTO(S)', AppTheme.orange),
            const SizedBox(width: 6),
          ],
          if (cellCount > 0)
            _badge('$cellCount PRESO(S)', AppTheme.red),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: TerminalText(label,
            fontSize: 7, color: color, fontWeight: FontWeight.bold),
      );

  // ─────────────────────────────────────────────────────────
  // REQUISITOS
  // ─────────────────────────────────────────────────────────

  Widget _buildRequirementsWarning(bool hasPrison, bool hasCouncil) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TerminalText('[ SISTEMA INATIVO ]',
                  fontSize: 11,
                  color: AppTheme.textDim,
                  fontWeight: FontWeight.bold),
              const SizedBox(height: 16),
              if (!hasCouncil)
                _requirementRow('Sala do Conselho', false,
                    'Necessaria para realizar julgamentos'),
              if (!hasPrison)
                _requirementRow(
                    'Prisao', false, 'Necessaria para deter criminosos'),
              const SizedBox(height: 16),
              TerminalText(
                'Construa os edificios necessarios\npara ativar o sistema de justica.',
                fontSize: 9,
                color: AppTheme.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requirementRow(String name, bool met, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            TerminalText(met ? '✓' : '✗', fontSize: 10,
                color: met ? AppTheme.green : AppTheme.red),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TerminalText(name,
                  fontSize: 9,
                  color: met ? AppTheme.green : AppTheme.textPrimary),
              TerminalText(desc, fontSize: 7, color: AppTheme.textDim),
            ]),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────

  Widget _buildTabBar(GameProvider gp) {
    final pending = gp.prison.pendingTrials.length;
    return Container(
      color: AppTheme.bgCard,
      child: TabBar(
        controller: _tabs,
        indicatorColor: AppTheme.red,
        indicatorWeight: 1.5,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: [
          _tabItem('JULGAMENTOS', pending > 0 ? '$pending' : null),
          _tabItem('CELAS', null),
          _tabItem('CRIMES', null),
        ],
      ),
    );
  }

  Widget _tabItem(String label, String? badge) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TerminalText(label, fontSize: 9, color: AppTheme.textSecondary),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TerminalText(badge,
                    fontSize: 7, color: AppTheme.orange),
              ),
            ],
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────
  // TAB: JULGAMENTOS
  // ─────────────────────────────────────────────────────────

  Widget _buildTrialsTab(GameProvider gp) {
    final trials = gp.prison.allTrials.reversed.toList();
    if (trials.isEmpty) {
      return _emptyState('Nenhum julgamento registrado.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: trials.length,
      itemBuilder: (_, i) => _buildTrialCard(trials[i], gp),
    );
  }

  Widget _buildTrialCard(Trial trial, GameProvider gp) {
    final accused =
        gp.engine.npcs.firstWhereOrNull((n) => n.id == trial.accusedId);
    final isPending = !trial.isComplete;
    final color = isPending
        ? AppTheme.orange
        : trial.verdict == TrialVerdict.guilty
            ? AppTheme.red
            : trial.verdict == TrialVerdict.exile
                ? AppTheme.purple
                : AppTheme.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              border:
                  Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(children: [
              _badge(trial.primaryCrime.label, color),
              const SizedBox(width: 8),
              TerminalText(
                accused != null ? accused.name : '???',
                fontSize: 10,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              _badge(trial.verdict.label, color),
            ]),
          ),

          // Evidências
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(children: [
              TerminalText('EVIDENCIAS: ',
                  fontSize: 8,
                  color: AppTheme.textDim,
                  fontWeight: FontWeight.bold),
              TerminalText('${trial.evidence.length} registro(s)',
                  fontSize: 8, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              TerminalText('DIA: ', fontSize: 8, color: AppTheme.textDim),
              TerminalText('${trial.dayStarted}',
                  fontSize: 8, color: AppTheme.textSecondary),
            ]),
          ),

          // Votos
          if (trial.votes.isNotEmpty)
            _buildVoteBar(trial, gp),

          // Jurados e seus votos
          if (trial.votes.isNotEmpty)
            _buildJurorVotes(trial, gp),

          // Sentença final
          if (trial.isComplete && trial.sentenceDays > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.red.withValues(alpha: 0.08),
                  border: Border.all(
                      color: AppTheme.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TerminalText(
                  'SENTENCA: ${trial.sentenceDays} dias de prisao',
                  fontSize: 8,
                  color: AppTheme.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Botão de voto do jogador
          if (isPending && !trial.playerHasVoted)
            _buildPlayerVoteButtons(trial, gp),
        ],
      ),
    );
  }

  Widget _buildVoteBar(Trial trial, GameProvider gp) {
    final total = trial.jurorIds.length + 1; // +1 = jogador
    final guiltyPct =
        total > 0 ? (trial.guiltyVotes / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TerminalText('CULPADO ${trial.guiltyVotes}',
                fontSize: 7,
                color: AppTheme.red,
                fontWeight: FontWeight.bold),
            const Spacer(),
            TerminalText('${trial.notGuiltyVotes} INOCENTE',
                fontSize: 7,
                color: AppTheme.green,
                fontWeight: FontWeight.bold),
          ]),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Row(children: [
                Flexible(
                  flex: (guiltyPct * 100).round(),
                  child: Container(color: AppTheme.red),
                ),
                Flexible(
                  flex: ((1 - guiltyPct) * 100).round(),
                  child: Container(color: AppTheme.green),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurorVotes(Trial trial, GameProvider gp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText('VOTOS DO CONSELHO:',
              fontSize: 7,
              color: AppTheme.textDim,
              fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          ...trial.votes
              .where((v) => v.npcId != 'player_weight')
              .map((vote) {
            final isPlayer = vote.npcId == 'player';
            final juror = isPlayer
                ? null
                : gp.engine.npcs
                    .firstWhereOrNull((n) => n.id == vote.npcId);
            final name = isPlayer
                ? '[ VOCE ]'
                : juror?.name ?? '???';
            final voteColor =
                vote.guiltyVote ? AppTheme.red : AppTheme.green;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText(
                    vote.guiltyVote ? '▲' : '▽',
                    fontSize: 8,
                    color: voteColor,
                  ),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 80,
                    child: TerminalText(name,
                        fontSize: 8,
                        color: isPlayer
                            ? AppTheme.cyan
                            : AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TerminalText(
                      '"${vote.reason}"',
                      fontSize: 7,
                      color: AppTheme.textDim,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Jurados que ainda não votaram
          ...trial.jurorIds
              .where((id) => !trial.votes.any((v) => v.npcId == id))
              .map((id) {
            final juror =
                gp.engine.npcs.firstWhereOrNull((n) => n.id == id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                TerminalText('?', fontSize: 8, color: AppTheme.textDim),
                const SizedBox(width: 5),
                TerminalText(juror?.name ?? '???',
                    fontSize: 8, color: AppTheme.textDim),
                const SizedBox(width: 6),
                TerminalText('aguardando...',
                    fontSize: 7, color: AppTheme.textDim),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlayerVoteButtons(Trial trial, GameProvider gp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.05),
        border:
            Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            'Seu voto como lider vale 2x. Deseja votar?',
            fontSize: 8,
            color: AppTheme.cyan,
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  gp.prison.playerVote(
                      trialId: trial.id, guiltyVote: true);
                  gp.refresh();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withValues(alpha: 0.15),
                    border: Border.all(
                        color: AppTheme.red.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: TerminalText('CULPADO',
                        fontSize: 9,
                        color: AppTheme.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  gp.prison.playerVote(
                      trialId: trial.id, guiltyVote: false);
                  gp.refresh();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.15),
                    border: Border.all(
                        color: AppTheme.green.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: TerminalText('INOCENTE',
                        fontSize: 9,
                        color: AppTheme.green,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB: CELAS
  // ─────────────────────────────────────────────────────────

  Widget _buildCellsTab(GameProvider gp) {
    final cells = gp.prison.cells;
    if (cells.isEmpty) {
      return _emptyState('Nenhum NPC detido no momento.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: cells.length,
      itemBuilder: (_, i) => _buildCellCard(cells[i], gp),
    );
  }

  Widget _buildCellCard(PrisonCell cell, GameProvider gp) {
    final npc =
        gp.engine.npcs.firstWhereOrNull((n) => n.id == cell.npcId);
    final remaining =
        cell.remainingDays(gp.engine.state.currentDay);
    final pct = cell.sentenceDays > 0
        ? 1.0 - (remaining / cell.sentenceDays).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TerminalText(
              npc?.name ?? '???',
              fontSize: 10,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(width: 8),
            _badge(cell.primaryCrime.label, AppTheme.red),
            const Spacer(),
            TerminalText(
              '$remaining dias restantes',
              fontSize: 8,
              color: remaining <= 2 ? AppTheme.green : AppTheme.orange,
            ),
          ]),
          const SizedBox(height: 6),
          // Barra de progresso da sentença
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Row(children: [
                Flexible(
                  flex: (pct * 100).round().clamp(0, 100),
                  child: Container(
                      color: AppTheme.red.withValues(alpha: 0.6)),
                ),
                Flexible(
                  flex: ((1 - pct) * 100).round().clamp(0, 100),
                  child: Container(color: AppTheme.border),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          TerminalText(
            cell.verdict,
            fontSize: 7,
            color: AppTheme.textDim,
          ),
          if (npc != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              TerminalText('Lealdade: ',
                  fontSize: 7, color: AppTheme.textDim),
              TerminalText(
                  npc.loyalty.toStringAsFixed(0),
                  fontSize: 7,
                  color: npc.loyalty < 30
                      ? AppTheme.red
                      : AppTheme.textSecondary),
              const SizedBox(width: 12),
              TerminalText('Sanidade: ',
                  fontSize: 7, color: AppTheme.textDim),
              TerminalText(
                  npc.attributes.mentalStability.toStringAsFixed(0),
                  fontSize: 7,
                  color: npc.attributes.mentalStability < 30
                      ? AppTheme.red
                      : AppTheme.textSecondary),
            ]),
          ],
          // Botão de soltura antecipada
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _confirmRelease(context, cell, gp);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.yellow.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: TerminalText(
                'SOLTAR ANTECIPADAMENTE',
                fontSize: 7,
                color: AppTheme.yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRelease(
      BuildContext context, PrisonCell cell, GameProvider gp) {
    final npc =
        gp.engine.npcs.firstWhereOrNull((n) => n.id == cell.npcId);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: TerminalText(
          'Soltar ${npc?.name ?? "???"}?',
          fontSize: 11,
          color: AppTheme.yellow,
          fontWeight: FontWeight.bold,
        ),
        content: TerminalText(
          'Soltar antes do fim da sentenca pode '
          'reduzir a confiança do povo na justiça. '
          'Restam ${cell.remainingDays(gp.engine.state.currentDay)} dias.',
          fontSize: 9,
          color: AppTheme.textSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TerminalText('CANCELAR',
                fontSize: 9, color: AppTheme.textDim),
          ),
          TextButton(
            onPressed: () {
              gp.prison.releaseEarly(cell.npcId);
              // Penalidade de moral por clemência controversa
              gp.engine.citadel.resources.morale -= 5;
              gp.refresh();
              Navigator.pop(context);
              setState(() {});
            },
            child: TerminalText('SOLTAR',
                fontSize: 9, color: AppTheme.yellow),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB: CRIMES
  // ─────────────────────────────────────────────────────────

  Widget _buildCrimesTab(GameProvider gp) {
    // Agrupa crimes por NPC
    final allCrimes = gp.prison.allCrimes;
    if (allCrimes.isEmpty) {
      return _emptyState('Nenhum crime registrado.');
    }

    final byNpc = <String, List<CrimeRecord>>{};
    for (final c in allCrimes) {
      byNpc.putIfAbsent(c.npcId, () => []).add(c);
    }

    // Ordena por número de crimes
    final sorted = byNpc.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final entry = sorted[i];
        final npc =
            gp.engine.npcs.firstWhereOrNull((n) => n.id == entry.key);
        return _buildCriminalCard(npc, entry.value, gp);
      },
    );
  }

  Widget _buildCriminalCard(
      Npc? npc, List<CrimeRecord> crimes, GameProvider gp) {
    final witnessed = crimes.where((c) => c.witnessed).length;
    final hasTrial = npc != null && gp.prison.isOnTrial(npc.id);
    final isPrisoned = npc != null && gp.prison.isImprisoned(npc.id);

    // Cor por gravidade
    final maxSeverity = crimes.isEmpty
        ? 0
        : crimes
            .map((c) => c.type.severity)
            .reduce((a, b) => a > b ? a : b);
    final color = maxSeverity >= 4
        ? AppTheme.red
        : maxSeverity >= 3
            ? AppTheme.orange
            : AppTheme.yellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              border: Border(
                  bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(children: [
              TerminalText(
                npc?.name ?? '??? (removido)',
                fontSize: 10,
                color: (npc?.alive ?? false)
                    ? AppTheme.textPrimary
                    : AppTheme.textDim,
                fontWeight: FontWeight.bold,
              ),
              if (!(npc?.alive ?? true))
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: TerminalText('✝',
                      fontSize: 8, color: AppTheme.textDim),
                ),
              const Spacer(),
              if (isPrisoned) _badge('PRESO', AppTheme.red),
              if (hasTrial) _badge('EM JULGAMENTO', AppTheme.orange),
              if (!isPrisoned && !hasTrial && npc?.alive == true)
                _badge('SOLTO', AppTheme.textDim),
            ]),
          ),

          // Lista de crimes
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  TerminalText(
                    '${crimes.length} crime(s) — $witnessed evidencia(s)',
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                  ),
                ]),
                const SizedBox(height: 6),
                ...crimes.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6, top: 1),
                          decoration: BoxDecoration(
                            color: c.witnessed
                                ? color
                                : AppTheme.textDim,
                            shape: BoxShape.circle,
                          ),
                        ),
                        TerminalText(
                          c.type.label,
                          fontSize: 8,
                          color: c.witnessed
                              ? AppTheme.textPrimary
                              : AppTheme.textDim,
                        ),
                        const SizedBox(width: 8),
                        TerminalText(
                          'Dia ${c.day}',
                          fontSize: 7,
                          color: AppTheme.textDim,
                        ),
                        const SizedBox(width: 8),
                        if (c.witnessed)
                          TerminalText('✓ EVIDENCIA',
                              fontSize: 7, color: color)
                        else if (c.rumorSpread)
                          TerminalText('~ rumor',
                              fontSize: 7,
                              color: AppTheme.textDim),
                      ]),
                    )),

                // Botão de prender (se há evidências, não está preso, não em julgamento)
                if (witnessed >= 1 &&
                    npc != null &&
                    npc.alive &&
                    !isPrisoned &&
                    !hasTrial) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _tryArrest(context, npc, gp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.12),
                        border: Border.all(
                            color:
                                AppTheme.red.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TerminalText(
                        'ABRIR JULGAMENTO',
                        fontSize: 8,
                        color: AppTheme.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _tryArrest(BuildContext context, Npc npc, GameProvider gp) {
    final result = gp.engine.arrestNpc(npc.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgElevated,
        content: TerminalText(
          result.message,
          fontSize: 9,
          color: result == ArrestResult.trialOpened
              ? AppTheme.green
              : AppTheme.red,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() {});
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  Widget _emptyState(String msg) => Center(
        child: TerminalText(msg, fontSize: 9, color: AppTheme.textDim),
      );
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
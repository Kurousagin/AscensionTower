import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/npc_enums.dart';
import 'package:tower_ascension/widgets/market_sheet.dart';
import '../providers/game_provider.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import '../models/game_event.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/floor_faction.dart';
import '../widgets/pending_recruits_badge.dart';
import '../services/quest_service.dart' show QuestService;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final state = gp.state;
        final res = gp.citadel.resources;
        final events = gp.lastWeekEvents;

        return ScanlineOverlay(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabeçalho principal ──────────────────────────
                _buildHeader(state, gp),
                const SizedBox(height: 8),

                // ── Controle de tempo ────────────────────────────
                _buildSimControl(gp),
                const SizedBox(height: 8),

                // ── Banners de ação (recrutas / mercado) ─────────
                if (gp.pendingRecruits.isNotEmpty)
                  Builder(
                    builder: (ctx) => PendingRecruitsBanner(
                      recruits: gp.pendingRecruits,
                      hasRefuge: gp.citadel.hasBuilding(
                        BuildingType.wayfareresRefuge,
                      ),
                      onTap: () => showModalBottomSheet(
                        context: ctx,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => RecruitListSheet(engine: gp.engine),
                      ),
                    ),
                  ),
                if (gp.pendingRecruits.isNotEmpty) const SizedBox(height: 8),
                if (gp.citadel.hasBuilding(BuildingType.market) &&
                    gp.allTradeOffers.isNotEmpty)
                  Builder(
                    builder: (ctx) => MarketBanner(
                      offerCount: gp.allTradeOffers.length,
                      onTap: () => showModalBottomSheet(
                        context: ctx,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const MarketSheet(),
                      ),
                    ),
                  ),
                if (gp.citadel.hasBuilding(BuildingType.market) &&
                    gp.allTradeOffers.isNotEmpty)
                  const SizedBox(height: 8),

                // ── Alertas críticos ─────────────────────────────
                _buildAlerts(gp),

                // ── Linha dupla: Recursos + NPC destaque ─────────
                if (gp.aliveNpcs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildMidRow(gp, res),
                ] else ...[
                  const SizedBox(height: 8),
                  _buildResourcePanel(res, gp),
                ],

                // ── Estado da sociedade ──────────────────────────
                const SizedBox(height: 8),
                _buildQuickStats(gp),

                // ── Missões ativas ───────────────────────────────
                if (gp.activeQuests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildActiveQuestsWidget(gp),
                ],

                // ── Última expedição ─────────────────────────────
                if (gp.lastChallenge != null) ...[
                  const SizedBox(height: 8),
                  _buildLastExpedition(gp),
                ],

                // ── Log de eventos ───────────────────────────────
                const SizedBox(height: 8),
                _buildEventLog(events),

                // ── Game Over ────────────────────────────────────
                if (state.gameOver) ...[
                  const SizedBox(height: 16),
                  _buildGameOver(state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER — identidade + stats vitais numa linha
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeader(state, GameProvider gp) {
    final floor = state.highestFloorCleared;
    final floorPct = (floor / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyan.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + tempo
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TerminalText(
                      'TORRE DA SEGUNDA HUMANIDADE',
                      fontSize: 11,
                      color: AppTheme.textDim,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 2),
                    TerminalText(
                      gp.timeDisplay,
                      fontSize: 18,
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TerminalText(
                    'DIA ${state.currentDay}',
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  TerminalText(
                    gp.dayPeriod,
                    fontSize: 9,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progresso da torre
          Row(
            children: [
              const TerminalText(
                'ANDAR ',
                fontSize: 8,
                color: AppTheme.textDim,
              ),
              TerminalText(
                '$floor',
                fontSize: 11,
                color: AppTheme.orange,
                fontWeight: FontWeight.bold,
              ),
              const TerminalText(
                ' / 100',
                fontSize: 8,
                color: AppTheme.textDim,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(color: AppTheme.border),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: floorPct,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.orange.withValues(alpha: 0.6),
                              AppTheme.orange,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Stats vitais em linha
          Row(
            children: [
              _statChip(
                '${gp.population}',
                'VIVOS',
                gp.population <= 5 ? AppTheme.red : AppTheme.green,
              ),
              const SizedBox(width: 6),
              _statChip('${state.totalDeaths}', 'MORTOS', AppTheme.red),
              const SizedBox(width: 6),
              _statChip('${state.totalBirths}', 'NASC.', AppTheme.cyan),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.purple.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: AppTheme.purple.withValues(alpha: 0.06),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TerminalText(
                        gp.citadel.level.label.toUpperCase(),
                        fontSize: 9,
                        color: AppTheme.purple,
                        fontWeight: FontWeight.bold,
                      ),
                      const TerminalText(
                        'CIDADELA',
                        fontSize: 7,
                        color: AppTheme.textDim,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(3),
        color: color.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TerminalText(
            value,
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(label, fontSize: 7, color: AppTheme.textDim),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTROLE DE TEMPO — compacto e funcional
  // ═══════════════════════════════════════════════════════════

  Widget _buildSimControl(GameProvider gp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Status
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gp.paused ? AppTheme.orange : AppTheme.green,
                    boxShadow: [
                      BoxShadow(
                        color: (gp.paused ? AppTheme.orange : AppTheme.green)
                            .withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalText(
                      gp.paused
                          ? 'PAUSADO'
                          : '${gp.simSpeed}x — ${gp.speedDescription}',
                      fontSize: 10,
                      color: gp.paused ? AppTheme.orange : AppTheme.green,
                      fontWeight: FontWeight.bold,
                    ),
                    TerminalText(
                      gp.paused ? 'A Torre aguarda.' : gp.realTimePerDay,
                      fontSize: 8,
                      color: AppTheme.textDim,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Velocidades
          Row(
            children: [
              ...GameProvider.availableSpeeds.map(
                (speed) => _speedButton(gp, speed),
              ),
              const SizedBox(width: 8),
              _pauseButton(gp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _speedButton(GameProvider gp, int speed) {
    final active = gp.simSpeed == speed && !gp.paused;
    return GestureDetector(
      onTap: () => gp.setSpeed(speed),
      child: Container(
        margin: const EdgeInsets.only(right: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: active ? AppTheme.cyan : AppTheme.border),
          borderRadius: BorderRadius.circular(2),
          color: active ? AppTheme.cyan.withValues(alpha: 0.12) : null,
        ),
        child: TerminalText(
          '${speed}x',
          fontSize: 9,
          color: active ? AppTheme.cyan : AppTheme.textDim,
          fontWeight: active ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _pauseButton(GameProvider gp) {
    return GestureDetector(
      onTap: gp.state.gameOver ? null : () => gp.togglePause(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: gp.paused ? AppTheme.green : AppTheme.orange,
          ),
          borderRadius: BorderRadius.circular(2),
          color: (gp.paused ? AppTheme.green : AppTheme.orange).withValues(
            alpha: 0.1,
          ),
        ),
        child: Icon(
          gp.paused ? Icons.play_arrow : Icons.pause,
          size: 14,
          color: gp.paused ? AppTheme.green : AppTheme.orange,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LINHA DO MEIO — recursos + NPC destaque lado a lado
  // ═══════════════════════════════════════════════════════════

  Widget _buildMidRow(GameProvider gp, Resources res) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recursos — 45% da largura
          Expanded(flex: 45, child: _buildResourcePanel(res, gp)),
          const SizedBox(width: 8),
          // NPC destaque — 55%
          Expanded(flex: 55, child: _buildNpcDestaque(gp)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RECURSOS — painel denso com barras
  // ═══════════════════════════════════════════════════════════

  Widget _buildResourcePanel(Resources res, GameProvider gp) {
    final cap = gp.citadel.storageCapacity;
    final isInfinite = gp.citadel.hasInfiniteStorage;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TerminalText(
                'RECURSOS',
                fontSize: 11,
                color: AppTheme.textDim,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              TerminalText(
                isInfinite ? 'INF' : gp.citadel.storageLabel,
                fontSize: 7,
                color: AppTheme.textDim,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _resRow('🌾', res.food, cap, isInfinite, AppTheme.green),
          _resRow('📚', res.knowledge, cap, isInfinite, AppTheme.purple),
          // Raw
          _resRow('🪵', res.woodLog, cap, isInfinite, AppTheme.orange),
          _resRow('🪨', res.stoneRaw, cap, isInfinite, AppTheme.textSecondary),
          _resRow('⛏', res.ironOre, cap, isInfinite, AppTheme.blue),
          // Processado
          _resRow('🪚', res.lumber, cap, isInfinite, AppTheme.orange),
          _resRow(
            '🧱',
            res.stoneBrick,
            cap,
            isInfinite,
            AppTheme.textSecondary,
          ),
          _resRow('⚙️', res.ironBar, cap, isInfinite, AppTheme.blue),
          const SizedBox(height: 6),
          // Moral com barra larga
          Row(
            children: [
              const TerminalText('♥ ', fontSize: 9, color: AppTheme.textDim),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (res.morale / 100).clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: AppTheme.bgElevated,
                    valueColor: AlwaysStoppedAnimation(
                      res.morale > 70
                          ? AppTheme.green
                          : res.morale > 40
                          ? AppTheme.yellow
                          : AppTheme.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TerminalText(
                res.morale.toStringAsFixed(0),
                fontSize: 8,
                color: AppTheme.textDim,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resRow(
    String icon,
    double value,
    double cap,
    bool isInfinite,
    Color color,
  ) {
    final atCap = !isInfinite && value >= cap;
    final pct = isInfinite ? 0.8 : (value / cap).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(icon, style: const TextStyle(fontSize: 9)),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 34,
            child: TerminalText(
              value.toStringAsFixed(0),
              fontSize: 9,
              color: atCap ? AppTheme.red : color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 3,
                backgroundColor: AppTheme.bgElevated,
                valueColor: AlwaysStoppedAnimation(
                  atCap ? AppTheme.red : color.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NPC DESTAQUE — protagonista com peso visual
  // ═══════════════════════════════════════════════════════════

  Color _rankColor(NpcRank rank) {
    switch (rank) {
      case NpcRank.ssr: return const Color(0xFFECC94B);
      case NpcRank.sr:  return const Color(0xFF00B4D8);
      case NpcRank.r:   return const Color(0xFF48BB78);
      case NpcRank.n:   return const Color(0xFF718096);
    }
  }

  Widget _buildNpcDestaque(GameProvider gp) {
    if (gp.aliveNpcs.isEmpty) return const SizedBox.shrink();

    final npc = gp.aliveNpcs.firstWhere(
      (n) => n.betrayalRisk > 60,
      orElse: () => gp.aliveNpcs.firstWhere(
        (n) => n.attributes.mentalStability < 20,
        orElse: () => gp.aliveNpcs.firstWhere(
          (n) => n.fatigue > 80,
          orElse: () => gp.aliveNpcs.firstWhere(
            (n) => n.floorsCleared > 15,
            orElse: () =>
                gp.aliveNpcs[gp.state.currentDay * 31 % gp.aliveNpcs.length],
          ),
        ),
      ),
    );

    final (badgeLabel, badgeColor) = npc.betrayalRisk > 60
        ? ('RISCO', AppTheme.orange)
        : npc.attributes.mentalStability < 30
        ? ('INSTÁVEL', AppTheme.red)
        : npc.fatigue > 80
        ? ('EXAUSTO', AppTheme.yellow)
        : npc.floorsCleared > 15
        ? ('VETERANO', AppTheme.cyan)
        : (null, AppTheme.border);

    final accentColor =
        npc.attributes.mentalStability < 20 || npc.betrayalRisk > 60
        ? AppTheme.red
        : npc.fatigue > 70
        ? AppTheme.orange
        : npc.loyalty > 70
        ? AppTheme.green
        : AppTheme.cyan;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + badge
          Row(
            children: [
              const TerminalText(
                'HABITANTE EM DESTAQUE',
                fontSize: 11,
                color: AppTheme.textDim,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              if (badgeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: badgeColor),
                    borderRadius: BorderRadius.circular(2),
                    color: badgeColor.withValues(alpha: 0.1),
                  ),
                  child: TerminalText(
                    badgeLabel,
                    fontSize: 7,
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Nome + rank
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TerminalText(
                  npc.name,
                  fontSize: 13,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _rankColor(npc.rank).withValues(alpha: 0.7),
                  ),
                  borderRadius: BorderRadius.circular(2),
                  color: _rankColor(npc.rank).withValues(alpha: 0.1),
                ),
                child: TerminalText(
                  npc.rank.label,
                  fontSize: 8,
                  color: _rankColor(npc.rank),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TerminalText(
            '\${npc.profession.label} · G\${npc.generation} · \${npc.age}a',
            fontSize: 8,
            color: AppTheme.textDim,
          ),

          const SizedBox(height: 8),

          // Quote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            child: TerminalText(
              _npcQuote(npc),
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          // Barras compactas
          _npcBar(
            'Sanidade',
            npc.attributes.mentalStability / 100,
            npc.attributes.mentalStability > 60
                ? AppTheme.green
                : npc.attributes.mentalStability > 30
                ? AppTheme.yellow
                : AppTheme.red,
          ),
          const SizedBox(height: 3),
          _npcBar(
            'Fadiga',
            npc.fatigue / 100,
            npc.fatigue < 30
                ? AppTheme.textSecondary
                : npc.fatigue < 60
                ? AppTheme.yellow
                : AppTheme.red,
          ),
          const SizedBox(height: 3),
          _npcBar(
            'Lealdade',
            npc.loyalty / 100,
            npc.loyalty > 60
                ? AppTheme.green
                : npc.loyalty > 30
                ? AppTheme.yellow
                : AppTheme.red,
          ),

          const SizedBox(height: 8),

          // Traços
          if (npc.traits.isNotEmpty)
            Wrap(
              spacing: 4,
              children: npc.traits
                  .take(3)
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.purple.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TerminalText(
                        t.label,
                        fontSize: 7,
                        color: AppTheme.purple,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _npcBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: TerminalText(label, fontSize: 7, color: AppTheme.textDim),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 4,
              backgroundColor: AppTheme.bgElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  String _npcQuote(Npc npc) {
    if (npc.attributes.mentalStability < 20 && npc.traumas.isNotEmpty)
      return '"Não consigo mais."';
    if (npc.attributes.mentalStability < 20)
      return '"Algo está errado comigo."';
    if (npc.betrayalRisk > 60) return '"Ninguém aqui merece minha lealdade."';
    if (npc.betrayalRisk > 30 && npc.loyalty < 30)
      return '"Estou observando. Esperando."';
    if (npc.fatigue > 80) return '"Preciso descansar."';
    if (npc.fatigue > 50 && npc.floorsCleared > 10)
      return '"Cada andar pesa mais."';
    if (npc.partnerId != null && npc.loyalty > 70)
      return '"Faço isso por quem eu amo."';
    if (npc.traumas.isNotEmpty) return '"Carrego o que vi lá em cima."';
    if (npc.floorsCleared > 20)
      return '"Já vi coisas que você não quer saber."';
    return '"Estou pronto. Para o que vier."';
  }

  // ═══════════════════════════════════════════════════════════
  // ALERTAS — urgência visual real
  // ═══════════════════════════════════════════════════════════

  Widget _buildAlerts(GameProvider gp) {
    final alerts = <_AlertItem>[];

    // Alerta de deserção de SR/SSR — prioridade máxima
    final deserting = gp.aliveNpcs
        .where((n) => n.wantsToLeave)
        .toList();
    final highRankDeserting = deserting
        .where((n) => n.rank == NpcRank.sr || n.rank == NpcRank.ssr)
        .toList();
    if (highRankDeserting.isNotEmpty) {
      final names = highRankDeserting
          .map((n) => '\${n.name} [\${n.rank.label}]')
          .join(', ');
      alerts.add(
        _AlertItem(
          'DESERÇÃO IMINENTE: $names quer partir!',
          AppTheme.orange,
          Icons.exit_to_app,
          priority: 3,
        ),
      );
    } else if (deserting.isNotEmpty) {
      alerts.add(
        _AlertItem(
          '\${deserting.length} habitante(s) querendo abandonar a cidadela',
          AppTheme.yellow,
          Icons.exit_to_app,
          priority: 2,
        ),
      );
    }

    final suspicious = gp.suspiciousNpcs;
    if (suspicious.isNotEmpty) {
      alerts.add(
        _AlertItem(
          '${suspicious.length} habitante(s) com alto risco de traição',
          AppTheme.red,
          Icons.person_off,
          priority: 3,
        ),
      );
    }

    final hostileFactions = gp.state.factionRelations.values
        .where(
          (r) => r.tier == FactionTier.atWar || r.tier == FactionTier.bloodFeud,
        )
        .toList();
    for (final rel in hostileFactions) {
      alerts.add(
        _AlertItem(
          'GUERRA: ${rel.faction.label} — Incursões a cada 14 dias',
          AppTheme.red,
          Icons.local_fire_department,
          priority: 3,
        ),
      );
    }

    if (gp.population <= 5) {
      alerts.add(
        _AlertItem(
          'CRÍTICO: População muito baixa (${gp.population})',
          AppTheme.orange,
          Icons.error_outline,
          priority: 2,
        ),
      );
    }

    if (!gp.citadel.hasInfiniteStorage &&
        gp.citadel.resources.anyAtCapacity(gp.citadel.storageLevel)) {
      alerts.add(
        _AlertItem(
          'Armazém no limite — recursos serão perdidos',
          AppTheme.orange,
          Icons.warehouse,
          priority: 2,
        ),
      );
    }

    final stressed = gp.aliveNpcs
        .where((n) => n.attributes.mentalStability < 40)
        .length;
    if (stressed > 0) {
      alerts.add(
        _AlertItem(
          '$stressed habitante(s) com sanidade crítica',
          AppTheme.orange,
          Icons.psychology,
          priority: 2,
        ),
      );
    }

    if (gp.citadel.resources.food < gp.population * 3) {
      alerts.add(
        _AlertItem(
          'Estoques de comida perigosamente baixos',
          AppTheme.orange,
          Icons.no_food,
          priority: 2,
        ),
      );
    }

    final hostileOnly = gp.state.factionRelations.values
        .where((r) => r.tier == FactionTier.hostile)
        .toList();
    if (hostileOnly.isNotEmpty) {
      alerts.add(
        _AlertItem(
          '${hostileOnly.length} facção(ões) hostil(is): ${hostileOnly.map((r) => r.faction.label).join(', ')}',
          AppTheme.yellow,
          Icons.warning_amber,
          priority: 1,
        ),
      );
    }

    if (gp.clearedFloors.isNotEmpty) {
      alerts.add(
        _AlertItem(
          '${gp.clearedFloors.length} andar(es) disponível(is) para re-exploração',
          AppTheme.cyan,
          Icons.explore,
          priority: 0,
        ),
      );
    }

    if (gp.groups.isNotEmpty) {
      alerts.add(
        _AlertItem(
          '${gp.groups.length} esquadrão(ões) ativo(s)',
          AppTheme.blue,
          Icons.groups,
          priority: 0,
        ),
      );
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    alerts.sort((a, b) => b.priority.compareTo(a.priority));
    final topColor = alerts.first.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: topColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: topColor.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: alerts.asMap().entries.map((entry) {
          final i = entry.key;
          final alert = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: i < alerts.length - 1
                  ? Border(bottom: BorderSide(color: AppTheme.border))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: alert.color,
                    boxShadow: [
                      BoxShadow(
                        color: alert.color.withValues(alpha: 0.8),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Icon(alert.icon, size: 11, color: alert.color),
                const SizedBox(width: 6),
                Expanded(
                  child: TerminalText(
                    alert.message,
                    fontSize: 9,
                    color: alert.priority >= 2
                        ? alert.color
                        : AppTheme.textSecondary,
                    fontWeight: alert.priority >= 3 ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SOCIEDADE — profissões + saúde coletiva
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuickStats(GameProvider gp) {
    final alive = gp.aliveNpcs;
    final couples = alive.where((n) => n.partnerId != null).length ~/ 2;

    final profCounts = <Profession, int>{};
    for (final npc in alive) {
      profCounts[npc.profession] = (profCounts[npc.profession] ?? 0) + 1;
    }
    final occupied = profCounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'SOCIEDADE',
            fontSize: 8,
            color: AppTheme.textDim,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...occupied.map((e) {
                final color = e.key == Profession.idle
                    ? AppTheme.textDim
                    : e.key == Profession.guard
                    ? AppTheme.red
                    : e.key == Profession.farmer
                    ? AppTheme.green
                    : e.key == Profession.explorer || e.key == Profession.scout
                    ? AppTheme.cyan
                    : AppTheme.textSecondary;
                return _profBadge(e.key.label, e.value, color);
              }),
              if (couples > 0) _profBadge('Casais', couples, AppTheme.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(3),
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TerminalText(
            '$count',
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(width: 4),
          TerminalText(label, fontSize: 8, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MISSÕES ATIVAS
  // ═══════════════════════════════════════════════════════════

  Widget _buildActiveQuestsWidget(GameProvider gp) {
    final quests = gp.activeQuests;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.blue.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TerminalText(
                'MISSÕES',
                fontSize: 11,
                color: AppTheme.textDim,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(width: 6),
              TerminalText(
                '${quests.length}/${QuestService.maxActiveQuests}',
                fontSize: 8,
                color: AppTheme.blue,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...quests.map((q) {
            final daysLeft = q.dayLimit - gp.state.currentDay;
            final urgent = daysLeft <= 5;
            final color = urgent ? AppTheme.orange : AppTheme.blue;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 4, right: 7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TerminalText(
                          q.title,
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                        TerminalText(
                          '${q.type.name.toUpperCase()} · ${daysLeft > 0 ? "$daysLeft dias" : "EXPIRA HOJE"}',
                          fontSize: 7,
                          color: AppTheme.textDim,
                        ),
                        if (q.assignedGroupId != null)
                          TerminalText(
                            'Grupo: ${gp.groups.firstWhereOrNull((g) => g.id == q.assignedGroupId)?.name ?? "?"}'
                            ' · Falha: ${(q.failureChance * 100).toStringAsFixed(0)}%',
                            fontSize: 7,
                            color: q.failureChance > 0.4
                                ? AppTheme.orange
                                : AppTheme.textDim,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ÚLTIMA EXPEDIÇÃO
  // ═══════════════════════════════════════════════════════════

  Widget _buildLastExpedition(GameProvider gp) {
    final ch = gp.lastChallenge!;
    final color = ch.victory ? AppTheme.green : AppTheme.red;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(
                  'EXPEDIÇÃO — ANDAR ${ch.floor.number}',
                  fontSize: 8,
                  color: AppTheme.textDim,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 3),
                TerminalText(
                  ch.victory ? '⚔ VITÓRIA' : '✗ DERROTA',
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                TerminalText(
                  ch.casualties.isNotEmpty
                      ? '${ch.casualties.length} baixa(s) · ${ch.victory ? "Andar conquistado." : "Forçados a recuar."}'
                      : ch.victory
                      ? 'Sem baixas · Andar conquistado.'
                      : 'Forçados a recuar.',
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LOG DE EVENTOS — feed vivo com identidade
  // ═══════════════════════════════════════════════════════════

  Widget _buildEventLog(List<GameEvent> events) {
    final display = events.reversed.take(20).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                const TerminalText(
                  'EVENTOS RECENTES',
                  fontSize: 8,
                  color: AppTheme.textDim,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.green,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.border),
          display.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: TerminalText(
                    'Aguardando o primeiro ciclo...',
                    fontSize: 10,
                    color: AppTheme.textDim,
                  ),
                )
              : Column(
                  children: display.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final color = _eventColor(e.type);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: e.isMajor ? color.withValues(alpha: 0.04) : null,
                        border: i < display.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: AppTheme.border.withValues(alpha: 0.5),
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag colorida
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            margin: const EdgeInsets.only(right: 7, top: 1),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: TerminalText(
                              e.type.tag,
                              fontSize: 7,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Conteúdo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TerminalText(
                                  e.title,
                                  fontSize: 9,
                                  color: e.isMajor
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontWeight: e.isMajor
                                      ? FontWeight.bold
                                      : null,
                                ),
                                if (e.isMajor && e.description.isNotEmpty)
                                  TerminalText(
                                    e.description,
                                    fontSize: 8,
                                    color: AppTheme.textDim,
                                  ),
                              ],
                            ),
                          ),
                          // Dia
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: TerminalText(
                              'D${e.day}',
                              fontSize: 7,
                              color: AppTheme.textDim,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Color _eventColor(GameEventType type) {
    switch (type) {
      case GameEventType.death:
      case GameEventType.combat:
      case GameEventType.betrayalAttempt:
        return AppTheme.red;
      case GameEventType.birth:
      case GameEventType.towerCleared:
      case GameEventType.upgrade:
      case GameEventType.resourceGain:
        return AppTheme.green;
      case GameEventType.crisis:
      case GameEventType.emergencySummon:
      case GameEventType.resourceLoss:
        return AppTheme.orange;
      case GameEventType.discovery:
      case GameEventType.floorReexplore:
        return AppTheme.cyan;
      case GameEventType.romance:
      case GameEventType.betrayal:
        return AppTheme.pink;
      case GameEventType.mentalBreak:
        return AppTheme.purple;
      case GameEventType.construction:
      case GameEventType.training:
        return AppTheme.blue;
      case GameEventType.celebration:
        return AppTheme.yellow;
      case GameEventType.politicalEvent:
        return AppTheme.orange;
      default:
        return AppTheme.textDim;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // GAME OVER
  // ═══════════════════════════════════════════════════════════

  Widget _buildGameOver(state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.red, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.red.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          const TerminalText(
            '▓▓▓ EXTINÇÃO ▓▓▓',
            fontSize: 16,
            color: AppTheme.red,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppTheme.red.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          TerminalText(
            state.gameOverReason,
            color: AppTheme.textPrimary,
            fontSize: 11,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TerminalText(
            'A humanidade resistiu por ${state.currentDay} dias.',
            fontSize: 10,
            color: AppTheme.textSecondary,
            textAlign: TextAlign.center,
          ),
          TerminalText(
            'Andar mais alto: ${state.highestFloorCleared}',
            fontSize: 10,
            color: AppTheme.textSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Classe auxiliar para alertas ordenados
class _AlertItem {
  final String message;
  final Color color;
  final IconData icon;
  final int priority;
  const _AlertItem(
    this.message,
    this.color,
    this.icon, {
    required this.priority,
  });
}
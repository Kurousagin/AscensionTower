import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(state, gp),
                const SizedBox(height: 12),
                _buildSimControl(gp),
                const SizedBox(height: 12),
                if (gp.aliveNpcs.isNotEmpty) ...[
                  _buildNpcDestaque(gp),
                  const SizedBox(height: 12),
                ],
                // ── Survivors aguardando recrutamento ──
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
                if (gp.pendingRecruits.isNotEmpty) const SizedBox(height: 12),
                _buildResourcePanel(res),
                const SizedBox(height: 12),
                if (gp.activeQuests.isNotEmpty) ...[
                  _buildActiveQuestsWidget(gp),
                  const SizedBox(height: 12),
                ],
                _buildAlerts(gp),
                const SizedBox(height: 12),
                _buildQuickStats(gp),
                const SizedBox(height: 12),
                _buildEventLog(events),
                if (gp.lastChallenge != null) ...[
                  const SizedBox(height: 12),
                  _buildLastExpedition(gp),
                ],
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

  Widget _buildHeader(state, GameProvider gp) {
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            'THE TOWER OF THE',
            fontSize: 9,
            color: AppTheme.textDim,
          ),
          const TerminalText(
            'SECOND HUMANITY',
            fontSize: 16,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          TerminalText(
            '${gp.timeDisplay}  |  ${gp.dayPeriod}  (Dia ${state.currentDay})',
            fontSize: 10,
            color: AppTheme.cyan,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _tag('Andar ${state.highestFloorCleared}', AppTheme.green),
              _tag('Populacao: ${gp.population}', AppTheme.yellow),
              _tag('Mortes: ${state.totalDeaths}', AppTheme.red),
              _tag('Nascimentos: ${state.totalBirths}', AppTheme.green),
              _tag('Cidadela: ${gp.citadel.level.label}', AppTheme.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimControl(GameProvider gp) {
    return TerminalCard(
      title: 'FLUXO DO TEMPO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalText(
                      gp.paused
                          ? 'TEMPO CONGELADO'
                          : '${gp.dayPeriod} (${gp.simSpeed}x)',
                      fontSize: 10,
                      color: gp.paused ? AppTheme.orange : AppTheme.green,
                    ),
                    const SizedBox(height: 2),
                    TerminalText(
                      gp.paused
                          ? 'A Torre aguarda em silencio.'
                          : '${gp.speedDescription} | ${gp.realTimePerDay}',
                      fontSize: 9,
                      color: AppTheme.textDim,
                    ),
                  ],
                ),
              ),
              TerminalButton(
                label: gp.paused ? 'RETOMAR' : 'PAUSAR',
                icon: gp.paused ? Icons.play_arrow : Icons.pause,
                color: gp.paused ? AppTheme.green : AppTheme.orange,
                onPressed: gp.state.gameOver ? null : () => gp.togglePause(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: GameProvider.availableSpeeds.map((speed) {
              return _speedButton(gp, speed);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _speedButton(GameProvider gp, int speed) {
    final active = gp.simSpeed == speed;
    return GestureDetector(
      onTap: () => gp.setSpeed(speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: active ? AppTheme.cyan : AppTheme.border),
          borderRadius: BorderRadius.circular(2),
          color: active ? AppTheme.cyan.withValues(alpha: 0.1) : null,
        ),
        child: TerminalText(
          '${speed}x',
          fontSize: 9,
          color: active ? AppTheme.cyan : AppTheme.textDim,
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: TerminalText(
        text,
        fontSize: 9,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNpcDestaque(GameProvider gp) {
    if (gp.aliveNpcs.isEmpty) {
      return SizedBox.shrink();
    }

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

    final borderColor =
        npc.attributes.mentalStability < 20 || npc.betrayalRisk > 60
        ? AppTheme.red
        : npc.fatigue > 70
        ? AppTheme.orange
        : npc.loyalty > 70
        ? AppTheme.green
        : AppTheme.cyan;

    final statusBadge = npc.betrayalRisk > 60
        ? ('⚠ RISCO', AppTheme.orange)
        : npc.attributes.mentalStability < 30
        ? ('⚡ INSTÁVEL', AppTheme.red)
        : npc.fatigue > 80
        ? ('😴 EXAUSTO', AppTheme.yellow)
        : npc.floorsCleared > 15
        ? ('⚔ VETERANO', AppTheme.cyan)
        : (null, null);

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
    final loyaltyColor = npc.loyalty > 60
        ? AppTheme.green
        : npc.loyalty > 30
        ? AppTheme.yellow
        : AppTheme.red;

    return TerminalCard(
      title: 'HABITANTE EM DESTAQUE — Dia ${gp.state.currentDay}',
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TerminalText(
                  'HABITANTE EM DESTAQUE — Dia ${gp.state.currentDay}',
                  fontSize: 9,
                  color: AppTheme.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppTheme.cyan),
              const SizedBox(width: 6),
              Expanded(
                child: TerminalText(
                  npc.name,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (statusBadge.$1 != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusBadge.$2!.withValues(alpha: 0.1),
                    border: Border.all(color: statusBadge.$2!),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TerminalText(
                    statusBadge.$1!,
                    fontSize: 8,
                    color: statusBadge.$2!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TerminalText(
            _npcQuoteDestaque(npc),
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBarCompact(
                      'Sanidade',
                      npc.attributes.mentalStability / 100,
                      sanidadeColor,
                    ),
                    const SizedBox(height: 4),
                    _buildBarCompact('Fadiga', npc.fatigue / 100, fadigaColor),
                    const SizedBox(height: 4),
                    _buildBarCompact(
                      'Lealdade',
                      npc.loyalty / 100,
                      loyaltyColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bgCard,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: const TerminalText(
                  'Ver Habitante',
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _npcQuoteDestaque(Npc npc) {
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
      return '"Preciso descansar."';
    }
    if (npc.fatigue > 50 && npc.floorsCleared > 10) {
      return '"Cada andar pesa mais."';
    }
    if (npc.partnerId != null && npc.loyalty > 70) {
      return '"Faço isso por quem eu amo."';
    }
    if (npc.traumas.isNotEmpty) {
      return '"Carrego o que vi lá em cima."';
    }
    if (npc.floorsCleared > 20) {
      return '"Já vi coisas que você não quer saber."';
    }
    return '"Estou pronto. Para o que vier."';
  }

  Widget _buildBarCompact(String label, double fraction, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: TerminalText(label, fontSize: 8, color: AppTheme.textDim),
        ),
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

  Widget _buildResourcePanel(Resources res) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final cap = gp.citadel.storageCapacity;
        final isInfinite = gp.citadel.hasInfiniteStorage;
        final capStr = isInfinite ? 'INF' : cap.toStringAsFixed(0);
        return TerminalCard(
          title:
              'RECURSOS (Armazem: ${gp.citadel.storageLabel} | Cap: $capStr)',
          child: Column(
            children: [
              _resRowWithCap(
                'Comida',
                res.food,
                cap,
                isInfinite,
                AppTheme.green,
              ),
              _resRowWithCap(
                'Madeira',
                res.wood,
                cap,
                isInfinite,
                AppTheme.orange,
              ),
              _resRowWithCap(
                'Pedra',
                res.stone,
                cap,
                isInfinite,
                AppTheme.textSecondary,
              ),
              _resRowWithCap('Ferro', res.iron, cap, isInfinite, AppTheme.blue),
              _resRowWithCap(
                'Conhecimento',
                res.knowledge,
                cap,
                isInfinite,
                AppTheme.purple,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: TerminalText(
                      'Moral',
                      fontSize: 10,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: StatBar(
                      label: '',
                      value: res.morale,
                      maxValue: 100,
                      color: res.morale > 70
                          ? AppTheme.green
                          : res.morale > 40
                          ? AppTheme.yellow
                          : AppTheme.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resRowWithCap(
    String label,
    double value,
    double cap,
    bool isInfinite,
    Color color,
  ) {
    final atCap = !isInfinite && value >= cap;
    final pct = isInfinite ? 0.0 : (value / cap).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: TerminalText(
              label,
              fontSize: 10,
              color: AppTheme.textPrimary,
            ),
          ),
          TerminalText(
            value.toStringAsFixed(0),
            fontSize: 11,
            color: atCap ? AppTheme.red : color,
            fontWeight: FontWeight.bold,
          ),
          if (!isInfinite) ...[
            TerminalText(
              '/${cap.toStringAsFixed(0)}',
              fontSize: 8,
              color: AppTheme.textDim,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(1),
                  border: Border.all(color: AppTheme.border),
                ),
                child: FractionallySizedBox(
                  widthFactor: pct,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: atCap ? AppTheme.red : color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 6),
            const Expanded(
              child: TerminalText('INF', fontSize: 8, color: AppTheme.textDim),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(GameProvider gp) {
    final alive = gp.aliveNpcs;
    final stressed = alive
        .where((n) => n.attributes.mentalStability < 40)
        .length;
    final couples = alive.where((n) => n.partnerId != null).length ~/ 2;

    // Conta NPCs por profissão
    final professionCounts = <Profession, int>{};
    for (final npc in alive) {
      professionCounts[npc.profession] =
          (professionCounts[npc.profession] ?? 0) + 1;
    }

    // Filtra apenas profissões ocupadas e ordena
    final occupiedProfessions =
        professionCounts.entries.where((e) => e.value > 0).toList()..sort(
          (a, b) => b.value.compareTo(a.value),
        ); // Ordena por quantidade (maior primeiro)

    return TerminalCard(
      title: 'ESTADO DA SOCIEDADE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              // Profissões ocupadas
              ...occupiedProfessions.map(
                (entry) => TerminalText(
                  '${entry.key.label}: ${entry.value}',
                  fontSize: 9,
                  color: entry.key == Profession.idle
                      ? AppTheme.textDim
                      : entry.key == Profession.guard
                      ? AppTheme.red
                      : entry.key == Profession.farmer
                      ? AppTheme.green
                      : entry.key == Profession.explorer ||
                            entry.key == Profession.scout
                      ? AppTheme.cyan
                      : AppTheme.textSecondary,
                ),
              ),
              // Casais (separado pois não é profissão)
              if (couples > 0)
                TerminalText(
                  'Casais: $couples',
                  fontSize: 9,
                  color: AppTheme.pink,
                ),
            ],
          ),
          if (stressed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TerminalText(
                'ALERTA: $stressed habitante(s) com sanidade critica',
                fontSize: 9,
                color: AppTheme.red,
              ),
            ),
          if (gp.citadel.resources.food < gp.population * 3)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: TerminalText(
                'ALERTA: Estoques de comida perigosamente baixos',
                fontSize: 9,
                color: AppTheme.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastExpedition(GameProvider gp) {
    final ch = gp.lastChallenge!;
    return TerminalCard(
      title: 'ULTIMA EXPEDIÇÃO - Andar ${ch.floor.number}',
      borderColor: ch.victory ? AppTheme.green : AppTheme.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            ch.victory ? 'RESULTADO: VITORIA' : 'RESULTADO: DERROTA',
            fontSize: 11,
            color: ch.victory ? AppTheme.green : AppTheme.red,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          if (ch.casualties.isNotEmpty)
            TerminalText(
              'Baixas: ${ch.casualties.length} mortos',
              fontSize: 9,
              color: AppTheme.red,
            ),
          TerminalText(
            ch.victory
                ? 'O grupo superou o desafio do andar ${ch.floor.number}.'
                : 'O grupo foi forcado a recuar do andar ${ch.floor.number}.',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog(List<GameEvent> events) {
    final displayEvents = events.reversed.take(20).toList();
    return TerminalCard(
      title: 'EVENTOS RECENTES',
      child: displayEvents.isEmpty
          ? const TerminalText(
              'Aguardando o primeiro ciclo...',
              color: AppTheme.textDim,
              fontSize: 10,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayEvents
                  .map(
                    (e) => TerminalEventTile(
                      tag: e.type.tag,
                      title: e.title,
                      description: e.isMajor ? e.description : null,
                      tagColor: _eventColor(e.type),
                      isMajor: e.isMajor,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Color _eventColor(GameEventType type) {
    switch (type) {
      case GameEventType.death:
        return AppTheme.red;
      case GameEventType.birth:
        return AppTheme.green;
      case GameEventType.combat:
        return AppTheme.red;
      case GameEventType.discovery:
        return AppTheme.cyan;
      case GameEventType.crisis:
        return AppTheme.orange;
      case GameEventType.celebration:
        return AppTheme.yellow;
      case GameEventType.betrayal:
        return AppTheme.pink;
      case GameEventType.romance:
        return AppTheme.pink;
      case GameEventType.construction:
        return AppTheme.blue;
      case GameEventType.towerCleared:
        return AppTheme.green;
      case GameEventType.mentalBreak:
        return AppTheme.purple;
      case GameEventType.upgrade:
        return AppTheme.green;
      case GameEventType.resourceGain:
        return AppTheme.green;
      case GameEventType.resourceLoss:
        return AppTheme.orange;
      case GameEventType.training:
        return AppTheme.blue;
      default:
        return AppTheme.textDim;
    }
  }

  Widget _buildGameOver(state) {
    return TerminalCard(
      borderColor: AppTheme.red,
      child: Column(
        children: [
          const TerminalText(
            '=== EXTINCAO ===',
            fontSize: 16,
            color: AppTheme.red,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          TerminalText(
            state.gameOverReason,
            color: AppTheme.textPrimary,
            fontSize: 11,
          ),
          const SizedBox(height: 4),
          TerminalText(
            'A humanidade resistiu por ${state.currentDay} dias na Torre.',
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
          TerminalText(
            'Andar mais alto alcancado: ${state.highestFloorCleared}',
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuestsWidget(GameProvider gp) {
    final quests = gp.activeQuests;
    return TerminalCard(
      title:
          'MISSOES ATIVAS (${quests.length}/${QuestService.maxActiveQuests})',
      borderColor: AppTheme.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: quests.map((q) {
          final daysLeft = q.dayLimit - gp.state.currentDay;
          final urgentColor = daysLeft <= 5 ? AppTheme.orange : AppTheme.blue;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 3, right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: urgentColor,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TerminalText(
                        q.title,
                        fontSize: 9,
                        color: urgentColor,
                        fontWeight: FontWeight.bold,
                      ),
                      TerminalText(
                        '${q.type.name.toUpperCase()} — ${daysLeft > 0 ? "$daysLeft dias restantes" : "EXPIRA HOJE"}',
                        fontSize: 7,
                        color: AppTheme.textDim,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlerts(GameProvider gp) {
    final alerts = <Widget>[];
    final suspicious = gp.suspiciousNpcs;
    if (suspicious.isNotEmpty) {
      alerts.add(
        Row(
          children: [
            const Icon(Icons.warning_amber, size: 12, color: AppTheme.red),
            const SizedBox(width: 4),
            Expanded(
              child: TerminalText(
                '${suspicious.length} habitante(s) com alto risco de traicao!',
                fontSize: 9,
                color: AppTheme.red,
              ),
            ),
          ],
        ),
      );
    }
    if (gp.population <= 5) {
      alerts.add(
        Row(
          children: [
            const Icon(Icons.error_outline, size: 12, color: AppTheme.orange),
            const SizedBox(width: 4),
            Expanded(
              child: TerminalText(
                'CRITICO: Populacao muito baixa (${gp.population})! Invocacao emergencial possivel.',
                fontSize: 9,
                color: AppTheme.orange,
              ),
            ),
          ],
        ),
      );
    }
    final cleared = gp.clearedFloors;
    if (cleared.isNotEmpty) {
      alerts.add(
        Row(
          children: [
            const Icon(Icons.explore, size: 12, color: AppTheme.cyan),
            const SizedBox(width: 4),
            Expanded(
              child: TerminalText(
                '${cleared.length} andar(es) disponivel(is) para re-exploracao.',
                fontSize: 9,
                color: AppTheme.cyan,
              ),
            ),
          ],
        ),
      );
    }
    if (gp.groups.isNotEmpty) {
      alerts.add(
        Row(
          children: [
            const Icon(Icons.groups, size: 12, color: AppTheme.blue),
            const SizedBox(width: 4),
            Expanded(
              child: TerminalText(
                '${gp.groups.length} esquadrao(es) ativo(s).',
                fontSize: 9,
                color: AppTheme.blue,
              ),
            ),
          ],
        ),
      );
    }
    // ── Alerta de armazem cheio ──
    if (!gp.citadel.hasInfiniteStorage &&
        gp.citadel.resources.anyAtCapacity(gp.citadel.storageLevel)) {
      alerts.add(
        Row(
          children: [
            const Icon(Icons.warehouse, size: 12, color: AppTheme.orange),
            const SizedBox(width: 4),
            Expanded(
              child: TerminalText(
                'Armazem no limite! Recursos coletados hoje excedem a capacidade e estragarao ao virar o dia. Amplie o Armazem.',
                fontSize: 9,
                color: AppTheme.orange,
              ),
            ),
          ],
        ),
      );
    }
    // ── Alertas de facções hostis / em guerra ──
    final hostileFactions = gp.state.factionRelations.values
        .where(
          (r) => r.tier == FactionTier.atWar || r.tier == FactionTier.bloodFeud,
        )
        .toList();
    for (final rel in hostileFactions) {
      alerts.add(
        Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 12,
              color: AppTheme.red,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TerminalText(
                'GUERRA: ${rel.faction.label} esta em conflito ativo! Incursoes a cada 14 dias.',
                fontSize: 9,
                color: AppTheme.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    final hostileOnly = gp.state.factionRelations.values
        .where((r) => r.tier == FactionTier.hostile)
        .toList();
    if (hostileOnly.isNotEmpty) {
      alerts.add(
        Row(
          children: [
            const Icon(Icons.warning_amber, size: 12, color: AppTheme.orange),
            const SizedBox(width: 4),
            Expanded(
              child: TerminalText(
                '${hostileOnly.length} faccao(oes) hostil(is): ${hostileOnly.map((r) => r.faction.label).join(', ')}. Melhore as relacoes.',
                fontSize: 9,
                color: AppTheme.orange,
              ),
            ),
          ],
        ),
      );
    }
    if (alerts.isEmpty) return const SizedBox.shrink();
    return TerminalCard(
      title: 'ALERTAS & STATUS',
      borderColor: suspicious.isNotEmpty ? AppTheme.red : AppTheme.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerts
            .map(
              (a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: a,
              ),
            )
            .toList(),
      ),
    );
  }
}

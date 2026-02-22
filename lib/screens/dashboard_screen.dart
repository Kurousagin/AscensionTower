import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import '../models/game_event.dart';
import '../models/npc.dart';
import '../models/citadel.dart';

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
                _buildResourcePanel(res),
                const SizedBox(height: 12),
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
          const TerminalText('THE TOWER OF THE', fontSize: 9, color: AppTheme.textDim),
          const TerminalText('SECOND HUMANITY', fontSize: 16, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          TerminalText(
            '${gp.timeDisplay}  |  ${gp.dayPeriod}  (Dia ${state.currentDay})',
            fontSize: 10, color: AppTheme.cyan,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _tag('Andar ${state.highestFloorCleared}/10', AppTheme.green),
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
                      gp.paused ? 'TEMPO CONGELADO' : '${gp.dayPeriod} (${gp.simSpeed}x)',
                      fontSize: 10,
                      color: gp.paused ? AppTheme.orange : AppTheme.green,
                    ),
                    const SizedBox(height: 2),
                    TerminalText(
                      gp.paused
                          ? 'A Torre aguarda em silencio.'
                          : '${gp.speedDescription} | ${gp.realTimePerDay}',
                      fontSize: 9, color: AppTheme.textDim,
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
        child: TerminalText('${speed}x', fontSize: 9, color: active ? AppTheme.cyan : AppTheme.textDim),
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
      child: TerminalText(text, fontSize: 9, color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildResourcePanel(Resources res) {
    return TerminalCard(
      title: 'RECURSOS DA CIDADELA',
      child: Column(
        children: [
          _resRow('Comida', res.food, AppTheme.green),
          _resRow('Madeira', res.wood, AppTheme.orange),
          _resRow('Pedra', res.stone, AppTheme.textSecondary),
          _resRow('Ferro', res.iron, AppTheme.blue),
          _resRow('Conhecimento', res.knowledge, AppTheme.purple),
          const SizedBox(height: 4),
          Row(children: [
            const SizedBox(width: 100, child: TerminalText('Moral', fontSize: 10, color: AppTheme.textPrimary)),
            Expanded(
              child: StatBar(label: '', value: res.morale, maxValue: 100,
                  color: res.morale > 70 ? AppTheme.green : res.morale > 40 ? AppTheme.yellow : AppTheme.red),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _resRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        SizedBox(width: 100, child: TerminalText(label, fontSize: 10, color: AppTheme.textPrimary)),
        TerminalText(value.toStringAsFixed(0), fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ]),
    );
  }

  Widget _buildQuickStats(GameProvider gp) {
    final alive = gp.aliveNpcs;
    final guards = alive.where((n) => n.profession == Profession.guard).length;
    final farmers = alive.where((n) => n.profession == Profession.farmer).length;
    final explorers = alive.where((n) => n.profession == Profession.explorer || n.profession == Profession.scout).length;
    final idle = alive.where((n) => n.profession == Profession.idle).length;
    final stressed = alive.where((n) => n.attributes.mentalStability < 40).length;
    final couples = alive.where((n) => n.partnerId != null).length ~/ 2;

    return TerminalCard(
      title: 'ESTADO DA SOCIEDADE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              TerminalText('Guardas: $guards', fontSize: 9, color: AppTheme.red),
              TerminalText('Fazendeiros: $farmers', fontSize: 9, color: AppTheme.green),
              TerminalText('Exploradores: $explorers', fontSize: 9, color: AppTheme.cyan),
              TerminalText('Ociosos: $idle', fontSize: 9, color: AppTheme.textDim),
              TerminalText('Casais: $couples', fontSize: 9, color: AppTheme.pink),
            ],
          ),
          if (stressed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TerminalText('ALERTA: $stressed habitante(s) com sanidade critica', fontSize: 9, color: AppTheme.red),
            ),
          if (gp.citadel.resources.food < gp.population * 3)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: TerminalText('ALERTA: Estoques de comida perigosamente baixos', fontSize: 9, color: AppTheme.orange),
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
            fontSize: 11, color: ch.victory ? AppTheme.green : AppTheme.red, fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          if (ch.casualties.isNotEmpty)
            TerminalText('Baixas: ${ch.casualties.length} mortos', fontSize: 9, color: AppTheme.red),
          TerminalText(
            ch.victory
                ? 'O grupo superou o desafio do andar ${ch.floor.number}.'
                : 'O grupo foi forcado a recuar do andar ${ch.floor.number}.',
            fontSize: 9, color: AppTheme.textSecondary,
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
          ? const TerminalText('Aguardando o primeiro ciclo...', color: AppTheme.textDim, fontSize: 10)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayEvents
                  .map((e) => TerminalEventTile(
                        tag: e.type.tag,
                        title: e.title,
                        description: e.isMajor ? e.description : null,
                        tagColor: _eventColor(e.type),
                        isMajor: e.isMajor,
                      ))
                  .toList(),
            ),
    );
  }

  Color _eventColor(GameEventType type) {
    switch (type) {
      case GameEventType.death: return AppTheme.red;
      case GameEventType.birth: return AppTheme.green;
      case GameEventType.combat: return AppTheme.red;
      case GameEventType.discovery: return AppTheme.cyan;
      case GameEventType.crisis: return AppTheme.orange;
      case GameEventType.celebration: return AppTheme.yellow;
      case GameEventType.betrayal: return AppTheme.pink;
      case GameEventType.romance: return AppTheme.pink;
      case GameEventType.construction: return AppTheme.blue;
      case GameEventType.towerCleared: return AppTheme.green;
      case GameEventType.mentalBreak: return AppTheme.purple;
      case GameEventType.upgrade: return AppTheme.green;
      case GameEventType.resourceGain: return AppTheme.green;
      case GameEventType.resourceLoss: return AppTheme.orange;
      case GameEventType.training: return AppTheme.blue;
      default: return AppTheme.textDim;
    }
  }

  Widget _buildGameOver(state) {
    return TerminalCard(
      borderColor: AppTheme.red,
      child: Column(
        children: [
          const TerminalText('=== EXTINCAO ===', fontSize: 16, color: AppTheme.red, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          TerminalText(state.gameOverReason, color: AppTheme.textPrimary, fontSize: 11),
          const SizedBox(height: 4),
          TerminalText('A humanidade resistiu por ${state.currentDay} dias na Torre.', fontSize: 10, color: AppTheme.textSecondary),
          TerminalText('Andar mais alto alcancado: ${state.highestFloorCleared}', fontSize: 10, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildAlerts(GameProvider gp) {
    final alerts = <Widget>[];
    final suspicious = gp.suspiciousNpcs;
    if (suspicious.isNotEmpty) {
      alerts.add(Row(
        children: [
          const Icon(Icons.warning_amber, size: 12, color: AppTheme.red),
          const SizedBox(width: 4),
          Expanded(child: TerminalText(
            '${suspicious.length} habitante(s) com alto risco de traicao!',
            fontSize: 9, color: AppTheme.red,
          )),
        ],
      ));
    }
    if (gp.population <= 5) {
      alerts.add(Row(
        children: [
          const Icon(Icons.error_outline, size: 12, color: AppTheme.orange),
          const SizedBox(width: 4),
          Expanded(child: TerminalText(
            'CRITICO: Populacao muito baixa (${gp.population})! Invocacao emergencial possivel.',
            fontSize: 9, color: AppTheme.orange,
          )),
        ],
      ));
    }
    final cleared = gp.clearedFloors;
    if (cleared.isNotEmpty) {
      alerts.add(Row(
        children: [
          const Icon(Icons.explore, size: 12, color: AppTheme.cyan),
          const SizedBox(width: 4),
          Expanded(child: TerminalText(
            '${cleared.length} andar(es) disponivel(is) para re-exploracao.',
            fontSize: 9, color: AppTheme.cyan,
          )),
        ],
      ));
    }
    if (gp.groups.isNotEmpty) {
      alerts.add(Row(
        children: [
          const Icon(Icons.groups, size: 12, color: AppTheme.blue),
          const SizedBox(width: 4),
          Expanded(child: TerminalText(
            '${gp.groups.length} esquadrao(es) ativo(s).',
            fontSize: 9, color: AppTheme.blue,
          )),
        ],
      ));
    }
    if (alerts.isEmpty) return const SizedBox.shrink();
    return TerminalCard(
      title: 'ALERTAS & STATUS',
      borderColor: suspicious.isNotEmpty ? AppTheme.red : AppTheme.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerts.map((a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: a,
        )).toList(),
      ),
    );
  }
}

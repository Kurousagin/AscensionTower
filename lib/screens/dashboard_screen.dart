import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import '../models/game_event.dart';
import '../models/npc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final state = gp.state;
        final res = gp.citadel.resources;
        final events = gp.lastDayEvents;

        return ScanlineOverlay(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(state, gp),
                const SizedBox(height: 12),
                _buildResourcePanel(res),
                const SizedBox(height: 12),
                _buildQuickStats(gp),
                const SizedBox(height: 12),
                _buildDayControls(context, gp),
                const SizedBox(height: 12),
                _buildEventLog(events),
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
          Row(
            children: [
              _tag('DIA ${state.currentDay}', AppTheme.cyan),
              const SizedBox(width: 8),
              _tag('ANDAR ${state.highestFloorCleared}/10', AppTheme.green),
              const SizedBox(width: 8),
              _tag('POP ${gp.population}', AppTheme.yellow),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _tag('MORTES ${state.totalDeaths}', AppTheme.red),
              const SizedBox(width: 8),
              _tag('NASC ${state.totalBirths}', AppTheme.green),
              const SizedBox(width: 8),
              _tag(gp.citadel.level.name.toUpperCase(), AppTheme.purple),
            ],
          ),
        ],
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

  Widget _buildResourcePanel(res) {
    return TerminalCard(
      title: 'RECURSOS',
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          ResourceBar(label: 'COM', value: res.food, color: AppTheme.green),
          ResourceBar(label: 'MAD', value: res.wood, color: AppTheme.orange),
          ResourceBar(label: 'PED', value: res.stone, color: AppTheme.textSecondary),
          ResourceBar(label: 'FER', value: res.iron, color: AppTheme.blue),
          ResourceBar(label: 'CON', value: res.knowledge, color: AppTheme.purple),
          ResourceBar(label: 'MOR', value: res.morale, color: _moraleColor(res.morale)),
        ],
      ),
    );
  }

  Color _moraleColor(double morale) {
    if (morale > 70) return AppTheme.green;
    if (morale > 40) return AppTheme.yellow;
    return AppTheme.red;
  }

  Widget _buildQuickStats(GameProvider gp) {
    final alive = gp.aliveNpcs;
    final guards = alive.where((n) => n.profession == Profession.guard).length;
    final farmers = alive.where((n) => n.profession == Profession.farmer).length;
    final explorers = alive.where((n) => n.profession == Profession.explorer || n.profession == Profession.scout).length;
    final idle = alive.where((n) => n.profession == Profession.idle).length;
    final stressed = alive.where((n) => n.attributes.mentalStability < 40).length;

    return TerminalCard(
      title: 'STATUS RAPIDO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              TerminalText('Guardas:$guards', fontSize: 9, color: AppTheme.red),
              TerminalText('Fazend:$farmers', fontSize: 9, color: AppTheme.green),
              TerminalText('Explor:$explorers', fontSize: 9, color: AppTheme.cyan),
              TerminalText('Ociosos:$idle', fontSize: 9, color: AppTheme.textDim),
            ],
          ),
          if (stressed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TerminalText('! $stressed NPC(s) com sanidade critica', fontSize: 9, color: AppTheme.red),
            ),
          if (gp.citadel.resources.food < gp.population * 3)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: TerminalText('! Comida baixa - risco de fome', fontSize: 9, color: AppTheme.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildDayControls(BuildContext context, GameProvider gp) {
    return TerminalCard(
      title: 'SIMULACAO',
      child: Row(
        children: [
          Expanded(
            child: TerminalButton(
              label: 'AVANCAR 1 DIA',
              icon: Icons.skip_next,
              expanded: true,
              onPressed: gp.state.gameOver ? null : () => gp.advanceDay(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TerminalButton(
              label: '+7 DIAS',
              icon: Icons.fast_forward,
              expanded: true,
              onPressed: gp.state.gameOver || gp.autoSimulating
                  ? null
                  : () => gp.advanceMultipleDays(7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TerminalButton(
              label: '+30 DIAS',
              icon: Icons.speed,
              color: AppTheme.orange,
              expanded: true,
              onPressed: gp.state.gameOver || gp.autoSimulating
                  ? null
                  : () => gp.advanceMultipleDays(30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog(List<GameEvent> events) {
    final displayEvents = events.reversed.take(15).toList();
    return TerminalCard(
      title: 'LOG DE EVENTOS',
      child: displayEvents.isEmpty
          ? const TerminalText('Nenhum evento recente.', color: AppTheme.textDim, fontSize: 10)
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
          const TerminalText('=== GAME OVER ===', fontSize: 16, color: AppTheme.red, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          TerminalText(state.gameOverReason, color: AppTheme.textPrimary, fontSize: 11),
          const SizedBox(height: 4),
          TerminalText('Dias sobrevividos: ${state.currentDay}', fontSize: 10, color: AppTheme.textSecondary),
          TerminalText('Andar mais alto: ${state.highestFloorCleared}', fontSize: 10, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_event.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({super.key});

  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  GameEventType? _typeFilter;
  bool _majorOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        var events = gp.events.reversed.toList();
        if (_typeFilter != null) {
          events = events.where((e) => e.type == _typeFilter).toList();
        }
        if (_majorOnly) {
          events = events.where((e) => e.isMajor).toList();
        }

        return ScanlineOverlay(
          child: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: events.isEmpty
                    ? const Center(child: TerminalText('Nenhum evento registrado.', color: AppTheme.textDim))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: events.length,
                        itemBuilder: (context, i) => _buildEventCard(events[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('Todos', null),
            _chip('Morte', GameEventType.death),
            _chip('Nascimento', GameEventType.birth),
            _chip('Torre', GameEventType.towerCleared),
            _chip('Crise', GameEventType.crisis),
            _chip('Colapso', GameEventType.mentalBreak),
            _chip('Romance', GameEventType.romance),
            _chip('Combate', GameEventType.combat),
            _chip('Construcao', GameEventType.construction),
            _chip('Traicao', GameEventType.betrayalAttempt),
            _chip('Grupos', GameEventType.groupFormed),
            _chip('Sugestao', GameEventType.trainingSuggestion),
            _chip('Invocacao', GameEventType.emergencySummon),
            _chip('Re-Explor.', GameEventType.floorReexplore),
            _chip('Politica', GameEventType.politicalEvent),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _majorOnly = !_majorOnly),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: _majorOnly ? AppTheme.yellow : AppTheme.border),
                  borderRadius: BorderRadius.circular(2),
                  color: _majorOnly ? AppTheme.yellow.withValues(alpha: 0.1) : null,
                ),
                child: TerminalText('Importantes', fontSize: 8, color: _majorOnly ? AppTheme.yellow : AppTheme.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, GameEventType? value) {
    final active = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = value),
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

  Widget _buildEventCard(GameEvent event) {
    final weekNum = (event.day / 7).ceil();
    String timeLabel;
    if (weekNum < 4) {
      timeLabel = 'Semana $weekNum';
    } else {
      final months = weekNum ~/ 4;
      final rw = weekNum % 4;
      if (months < 12) {
        timeLabel = rw > 0 ? 'Mes $months, Sem $rw' : 'Mes $months';
      } else {
        final years = months ~/ 12;
        final rm = months % 12;
        timeLabel = 'Ano $years, Mes $rm';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: event.isMajor ? AppTheme.bgElevated : AppTheme.bgCard,
        border: Border.all(color: event.isMajor ? _getEventColor(event.type).withValues(alpha: 0.3) : AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: _getEventColor(event.type).withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: TerminalText(event.type.tag, fontSize: 8, color: _getEventColor(event.type), fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            TerminalText(timeLabel, fontSize: 8, color: AppTheme.textDim),
            const SizedBox(width: 4),
            TerminalText('(Dia ${event.day})', fontSize: 7, color: AppTheme.textDim),
            if (event.isMajor) ...[
              const SizedBox(width: 6),
              TerminalText('*', fontSize: 10, color: AppTheme.yellow, fontWeight: FontWeight.bold),
            ],
          ]),
          const SizedBox(height: 4),
          TerminalText(event.title, fontSize: 10, color: AppTheme.textPrimary, fontWeight: event.isMajor ? FontWeight.bold : null),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            TerminalText(event.description, fontSize: 9, color: AppTheme.textSecondary),
          ],
        ],
      ),
    );
  }

  Color _getEventColor(GameEventType type) {
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
      case GameEventType.groupFormed: return AppTheme.blue;
      case GameEventType.trainingSuggestion: return AppTheme.green;
      case GameEventType.betrayalAttempt: return AppTheme.red;
      case GameEventType.emergencySummon: return AppTheme.orange;
      case GameEventType.floorReexplore: return AppTheme.cyan;
      case GameEventType.loyaltyChange: return AppTheme.yellow;
      case GameEventType.politicalEvent: return AppTheme.orange;
      default: return AppTheme.textDim;
    }
  }
}

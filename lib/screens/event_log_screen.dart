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
  String _typeFilter = 'all';
  bool _majorOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        var events = gp.events.reversed.toList();
        if (_typeFilter != 'all') {
          final filterType = GameEventType.values.firstWhere(
            (t) => t.tag == _typeFilter,
            orElse: () => GameEventType.system,
          );
          events = events.where((e) => e.type == filterType).toList();
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
            _chip('TODOS', 'all'),
            _chip('[MORTE]', '[MORTE]'),
            _chip('[NASC]', '[NASC]'),
            _chip('[TORRE]', '[TORRE]'),
            _chip('[CRISE]', '[CRISE]'),
            _chip('[MENTAL]', '[MENTAL]'),
            _chip('[AMOR]', '[AMOR]'),
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
                child: TerminalText('MAJOR', fontSize: 8, color: _majorOnly ? AppTheme.yellow : AppTheme.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
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
            TerminalText('DIA ${event.day}', fontSize: 8, color: AppTheme.textDim),
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
      default: return AppTheme.textDim;
    }
  }
}

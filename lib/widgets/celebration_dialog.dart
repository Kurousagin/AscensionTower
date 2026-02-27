import 'package:flutter/material.dart';
import 'package:tower_ascension/models/game_event.dart';
import 'theme.dart';
import 'terminal_widgets.dart';

class CelebrationDialog extends StatefulWidget {
  final GameEvent event;

  const CelebrationDialog({super.key, required this.event});

  static void show(BuildContext context, GameEvent event) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => CelebrationDialog(event: event),
    );
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForEvent(widget.event);
    final accentColor = _colorForEvent(widget.event);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone pulsando
              ScaleTransition(
                scale: _pulse,
                child: Text(icon, style: const TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 12),
              // Título
              TerminalText(
                widget.event.title.toUpperCase(),
                fontSize: 16,
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              // Linha decorativa
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accentColor,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Descrição
              TerminalText(
                widget.event.description,
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              // Dia do evento
              const SizedBox(height: 8),
              TerminalText(
                'Dia ${widget.event.day}',
                fontSize: 8,
                color: AppTheme.textDim,
              ),
              const SizedBox(height: 16),
              TerminalButton(
                label: 'FESTEJAR!',
                icon: Icons.celebration,
                color: accentColor,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _iconForEvent(GameEvent event) {
    if (event.title.contains('Nasceu') || event.title.contains('Membro')) {
      return '👶';
    }
    if (event.title.contains('Monumento')) return '🏛️';
    if (event.title.contains('Andar') || event.title.contains('BOSS')) {
      return '⚔️';
    }
    if (event.title.contains('Fe') || event.title.contains('Templo')) {
      return '⛪';
    }
    if (event.title.contains('Cidadela') || event.title.contains('Evoluiu')) {
      return '🏰';
    }
    if (event.title.contains('Talento')) return '✨';
    return '🎉';
  }

  Color _colorForEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.towerCleared:
        return AppTheme.orange;
      case GameEventType.birth:
        return AppTheme.cyan;
      case GameEventType.upgrade:
        return AppTheme.purple;
      case GameEventType.celebration:
        return AppTheme.yellow;
      default:
        return AppTheme.green;
    }
  }
}
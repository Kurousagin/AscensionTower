import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/game_event.dart';
import 'package:tower_ascension/providers/game_provider.dart';
import 'theme.dart';
import 'terminal_widgets.dart';

class CrisisDialog extends StatefulWidget {
  final GameEvent event;
  const CrisisDialog({super.key, required this.event});

  static Future<void> show(BuildContext context, GameEvent event) {
   return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticInOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => CrisisDialog(event: event),
    );
  }

  @override
  State<CrisisDialog> createState() => _CrisisDialogState();
}

class _CrisisDialogState extends State<CrisisDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 600,
      ), // pulso mais rápido e urgente
    )..repeat(reverse: true);

    _pulse = Tween(begin: 0.92, end: 1.08).animate(
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
    final accentColor = const Color(0xFFFF4444); // vermelho forte

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accentColor,
              width: 3,
            ), // borda mais grossa
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.5),
                blurRadius: 32,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone pulsando forte
              ScaleTransition(
                scale: _pulse,
                child: Text(icon, style: const TextStyle(fontSize: 52)),
              ),
              const SizedBox(height: 12),

              // Título com "ALERTA"
              TerminalText(
                'ALERTA: ${widget.event.title.toUpperCase()}',
                fontSize: 18,
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 8),

              // Linha decorativa
              Container(
                height: 2,
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

              const SizedBox(height: 8),
              TerminalText(
                'Dia ${widget.event.day}',
                fontSize: 8,
                color: AppTheme.textDim,
              ),

              const SizedBox(height: 16),

              TerminalButton(
                label: 'ENTENDIDO!',
                icon: Icons.warning_rounded,
                color: accentColor,
                expanded: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  // Retoma a simulação automaticamente se foi pausada por crise
                  final gp = Provider.of<GameProvider>(context, listen: false);
                  gp.resumeIfCrisisPaused();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _iconForEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.crisis:
        return '🚨';
      case GameEventType.emergencySummon:
        return '🆘';
      default:
        return '⚠️';
    }
  }
}

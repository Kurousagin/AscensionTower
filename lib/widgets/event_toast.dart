// lib/widgets/event_toast.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/providers/game_provider.dart';
import 'package:tower_ascension/widgets/celebration_dialog.dart';
import 'package:tower_ascension/widgets/crisis_dialog.dart';
import 'package:tower_ascension/widgets/terminal_widgets.dart';
import 'package:tower_ascension/widgets/theme.dart';
import '../models/game_event.dart';

/// Tipos de evento que devem aparecer como toast (não no log principal)
const Set<GameEventType> kToastOnlyEvents = {
  GameEventType.training,
  GameEventType.resourceGain,
  GameEventType.resourceLoss,
  GameEventType.trainingSuggestion,
  GameEventType.loyaltyChange,
  GameEventType.system,
  GameEventType.discovery,
  GameEventType.recruitment,
  GameEventType.questEvent,
  GameEventType.tradeEvent,
  GameEventType.groupFormed,
  GameEventType.groupDissolved,
  GameEventType.combat,
  GameEventType.exploration,
};

const Set<GameEventType> kCelebrationDialogTypes = {
  GameEventType.celebration,
  GameEventType.towerCleared,
  GameEventType.birth,
  GameEventType.upgrade,
};

const Set<GameEventType> kCrisisDialogTypes = {
  GameEventType.crisis,
  GameEventType.emergencySummon,
  GameEventType.mentalBreak,
  GameEventType.warEvent,
};

bool isCelebrationEvent(GameEvent e) =>
    e.isMajor && kCelebrationDialogTypes.contains(e.type);

bool isCrisisEvent(GameEvent e) =>
    e.isMajor && kCrisisDialogTypes.contains(e.type);

const Set<GameEventType> kLoreDialogTypes = {GameEventType.discovery};

bool isLoreEvent(GameEvent e) => e.isMajor && kLoreDialogTypes.contains(e.type);

bool isToastEvent(GameEvent e) =>
    !e.isMajor && kToastOnlyEvents.contains(e.type);

/// Eventos que NUNCA devem ser exibidos
const Set<GameEventType> kSilentEvents = {};

// ─────────────────────────────────────────────────────────────
// CONTROLLER GLOBAL
// ─────────────────────────────────────────────────────────────
class ToastController extends ChangeNotifier {
  static final ToastController _instance = ToastController._();
  factory ToastController() => _instance;
  ToastController._();

  // ── Filas ───────────────────────────────────────────────────
  final List<ToastEntry> _queue = [];
  ToastEntry? _current;
  Timer? _timer;

  final List<GameEvent> _celebrationQueue = [];
  final List<GameEvent> _crisisQueue = [];
  final List<GameEvent> _loreQueue = [];

  List<GameEvent> get pendingCelebrations =>
      List.unmodifiable(_celebrationQueue);
  List<GameEvent> get pendingCrises => List.unmodifiable(_crisisQueue);
  List<GameEvent> get pendingLore => List.unmodifiable(_loreQueue);

  void consumeCelebration() {
    if (_celebrationQueue.isNotEmpty) _celebrationQueue.removeAt(0);
  }

  void consumeCrisis() {
    if (_crisisQueue.isNotEmpty) _crisisQueue.removeAt(0);
  }

  void consumeLore() {
    if (_loreQueue.isNotEmpty) _loreQueue.removeAt(0);
  }

  // ── Show single ─────────────────────────────────────────────
  void show(GameEvent event) {
    if (isLoreEvent(event)) {
      _loreQueue.add(event);
      notifyListeners();
      return;
    }
    if (isCelebrationEvent(event)) {
      _celebrationQueue.add(event);
      notifyListeners();
      return;
    }
    if (isCrisisEvent(event)) {
      _crisisQueue.add(event);
      notifyListeners();
      return;
    }
    if (!isToastEvent(event)) return;

    _queue.add(ToastEntry(event));
    if (_current == null) _next();
  }

  // ── Show batch ──────────────────────────────────────────────
  static const int _maxQueueSize = 4;

  void showBatch(List<GameEvent> events) {
    // Se a fila já tem muita coisa acumulada, descarta toasts antigos não-críticos
    if (_queue.length > _maxQueueSize) {
      _queue.clear();
    }

    for (final e in events) {
      if (isLoreEvent(e)) {
        _loreQueue.add(e);
      } else if (isCelebrationEvent(e)) {
        _celebrationQueue.add(e);
      } else if (isCrisisEvent(e)) {
        _crisisQueue.add(e);
      }
    }

    final toasts = events
        .where(
          (e) =>
              isToastEvent(e) &&
              !isLoreEvent(e) &&
              !isCelebrationEvent(e) &&
              !isCrisisEvent(e),
        )
        .toList();

    if (toasts.isEmpty &&
        (_loreQueue.isNotEmpty ||
            _celebrationQueue.isNotEmpty ||
            _crisisQueue.isNotEmpty)) {
      notifyListeners();
      return;
    }
    if (toasts.isEmpty) return;

    // Fila cheia: descarta toasts triviais, mantém só isMajor
    if (_queue.length >= _maxQueueSize) {
      final major = toasts.where((e) => e.isMajor).toList();
      if (major.isEmpty) return;
      _queue.add(ToastEntry.batch(major));
      if (_current == null) _next();
      return;
    }

    if (toasts.length > 3) {
      _queue.add(ToastEntry.batch(toasts));
    } else {
      for (final e in toasts) {
        _queue.add(ToastEntry(e));
      }
    }
    if (_current == null) _next();
  }

  void _next() {
    _timer?.cancel();
    if (_queue.isEmpty) {
      _current = null;
      notifyListeners();
      return;
    }
    _current = _queue.removeAt(0);
    notifyListeners();
    _timer = Timer(
      Duration(milliseconds: _current!.isBatch ? 3500 : 2200),
      _next,
    );
  }

  ToastEntry? get current => _current;
}

class ToastEntry {
  final GameEvent? event;
  final List<GameEvent>? batch;
  bool get isBatch => batch != null;

  ToastEntry(GameEvent e) : event = e, batch = null;
  ToastEntry.batch(List<GameEvent> events) : batch = events, event = null;
}

// ─────────────────────────────────────────────────────────────
// WIDGET OVERLAY (o resto permanece igual)
// ─────────────────────────────────────────────────────────────
class EventToastOverlay extends StatefulWidget {
  final Widget child;
  const EventToastOverlay({super.key, required this.child});

  @override
  State<EventToastOverlay> createState() => _EventToastOverlayState();
}

class _EventToastOverlayState extends State<EventToastOverlay>
    with SingleTickerProviderStateMixin {
  final _ctrl = ToastController();
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);

    _ctrl.addListener(_onToastChange);
  }

  bool _crisisDialogOpen = false;

  void _onToastChange() {
    // PRIORIDADE MÁXIMA: Crise
    if (_ctrl.pendingCrises.isNotEmpty && mounted && !_crisisDialogOpen) {
      final event = _ctrl.pendingCrises.first;
      _ctrl.consumeCrisis();

      final gp = Provider.of<GameProvider>(context, listen: false);
      gp.pauseForCrisis();

      _crisisDialogOpen = true; // ← guard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          CrisisDialog.show(context, event).then((_) {
            _crisisDialogOpen = false;
            _onToastChange();
          });
        }
      });
      return;
    }
    // Depois lore
    if (_ctrl.pendingLore.isNotEmpty && mounted) {
      final event = _ctrl.pendingLore.first;
      _ctrl.consumeLore();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLoreDialog(context, event);
      });
    }
    // Depois celebrações normais
    if (_ctrl.pendingCelebrations.isNotEmpty && mounted) {
      final event = _ctrl.pendingCelebrations.first;
      _ctrl.consumeCelebration();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) CelebrationDialog.show(context, event);
      });
    }

    if (_ctrl.current != null) {
      _anim.forward(from: 0);
    } else {
      _anim.reverse();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onToastChange);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_ctrl.current != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: _buildToast(_ctrl.current!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToast(ToastEntry entry) {
    if (entry.isBatch) {
      return _BatchToast(events: entry.batch!);
    }
    return _SingleToast(event: entry.event!);
  }

  void _showLoreDialog(BuildContext context, GameEvent event) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F14),
            border: Border.all(color: const Color(0xFF44DDFF), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_stories,
                    size: 14,
                    color: Color(0xFF44DDFF),
                  ),
                  const SizedBox(width: 8),
                  TerminalText(
                    'FRAGMENTO DE LORE',
                    fontSize: 10,
                    color: const Color(0xFF44DDFF),
                    fontWeight: FontWeight.bold,
                  ),
                  const Spacer(),
                  TerminalText(
                    'DIA ${event.day}',
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: const Color(0xFF44DDFF).withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              TerminalText(
                event.title,
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              TerminalText(
                event.description,
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF44DDFF).withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const TerminalText(
                      'REGISTRAR',
                      fontSize: 9,
                      color: Color(0xFF44DDFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single Event Toast ─────────────────────────────────────────

class _SingleToast extends StatelessWidget {
  final GameEvent event;
  const _SingleToast({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(event.type);
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                border: Border(
                  top: BorderSide(color: color.withValues(alpha: 0.3)),
                  bottom: BorderSide(color: color.withValues(alpha: 0.3)),
                  right: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: TerminalText(
                      event.type.tag,
                      fontSize: 7,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TerminalText(
                      event.title,
                      fontSize: 9,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TerminalText(
                    'D${event.day}',
                    fontSize: 7,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Batch Toast ────────────────────────────────────────────────

class _BatchToast extends StatelessWidget {
  final List<GameEvent> events;
  const _BatchToast({required this.events});

  @override
  Widget build(BuildContext context) {
    final typeGroups = <GameEventType, int>{};
    for (final e in events) {
      typeGroups[e.type] = (typeGroups[e.type] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          TerminalText(
            '${events.length} EVENTOS',
            fontSize: 8,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: typeGroups.entries.map((e) {
                final color = _colorFor(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TerminalText(
                    '${e.key.tag} x${e.value}',
                    fontSize: 7,
                    color: color,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorFor(GameEventType type) {
  switch (type) {
    case GameEventType.death:
    case GameEventType.combat:
    case GameEventType.betrayalAttempt:
      return const Color(0xFFFF4444);
    case GameEventType.birth:
    case GameEventType.towerCleared:
    case GameEventType.upgrade:
    case GameEventType.trainingSuggestion:
    case GameEventType.resourceGain:
      return const Color(0xFF44FF88);
    case GameEventType.crisis:
    case GameEventType.emergencySummon:
    case GameEventType.resourceLoss:
      return const Color(0xFFFF8800);
    case GameEventType.discovery:
    case GameEventType.floorReexplore:
      return const Color(0xFF44DDFF);
    case GameEventType.romance:
    case GameEventType.betrayal:
      return const Color(0xFFFF88AA);
    case GameEventType.mentalBreak:
      return const Color(0xFFAA44FF);
    case GameEventType.construction:
    case GameEventType.training:
      return const Color(0xFF88AAFF);
    case GameEventType.celebration:
      return const Color(0xFFFFDD44);
    case GameEventType.recruitment:
      return const Color.fromARGB(255, 251, 255, 0);
    case GameEventType.warEvent:
      return const Color(0xFFFF2200);
    case GameEventType.politicalEvent:
      return const Color(0xFFDDAA66);
    case GameEventType.questEvent:
      return const Color(0xFF44AAFF);
    case GameEventType.tradeEvent:
      return const Color(0xFFFFAA44);
    default:
      return const Color(0xFF888888);
  }
}

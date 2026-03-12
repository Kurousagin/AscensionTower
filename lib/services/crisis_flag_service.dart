// lib/services/crisis_flag_service.dart
//
// Bridge entre GameEngine e o sistema de notificações.
// Usa SharedPreferences para persistir crises pendentes — acessível
// tanto pelo app quanto pelo isolate do WorkManager.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_event.dart';

class CrisisFlagService {
  CrisisFlagService._();
  static final CrisisFlagService instance = CrisisFlagService._();

  // ── Chaves ──────────────────────────────────────────────────
  static const _kPending = 'notif_crisis_pending';
  static const _kTitle = 'notif_crisis_title';
  static const _kBody = 'notif_crisis_body';
  static const _kType = 'notif_crisis_type';
  static const _kDay = 'notif_crisis_day';
  static const _kNotified = 'notif_crisis_notified';

  // ── Escrita (chamada pelo GameEngine) ────────────────────────

  /// Persiste uma crise para que o WorkManager possa notificar o usuário
  /// enquanto o app estiver fechado.
  Future<void> writePending(GameEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPending, true);
    await prefs.setString(_kTitle, event.title);
    await prefs.setString(_kBody, event.description);
    await prefs.setString(_kType, _typeKey(event.type));
    await prefs.setInt(_kDay, event.day);
    await prefs.setBool(_kNotified, false);
  }

  // ── Leitura (chamada ao abrir o app) ────────────────────────

  /// Retorna os dados da crise pendente e limpa todos os flags.
  /// Retorna null se não houver crise pendente.
  Future<_PendingCrisis?> consumePending() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_kPending) ?? false;
    if (!pending) return null;

    final crisis = _PendingCrisis(
      title: prefs.getString(_kTitle) ?? '',
      body: prefs.getString(_kBody) ?? '',
      type: prefs.getString(_kType) ?? 'crisis',
      day: prefs.getInt(_kDay) ?? 0,
    );

    // Limpa tudo após consumir
    await prefs.remove(_kPending);
    await prefs.remove(_kTitle);
    await prefs.remove(_kBody);
    await prefs.remove(_kType);
    await prefs.remove(_kDay);
    await prefs.remove(_kNotified);

    return crisis;
  }

  // ── Getters para o Worker (isolate) ────────────────────────

  /// Verifica se há uma crise pendente sem consumi-la.
  Future<bool> get hasPending async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPending) ?? false;
  }

  /// Verifica se o WorkManager já disparou a notificação desta crise.
  Future<bool> get wasNotified async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotified) ?? false;
  }

  /// Marca a crise como já notificada (evita duplicatas).
  Future<void> markNotified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotified, true);
  }

  /// Lê título e corpo sem consumir (para uso no worker).
  Future<Map<String, String>?> readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_kPending) ?? false;
    if (!pending) return null;
    return {
      'title': prefs.getString(_kTitle) ?? '',
      'body': prefs.getString(_kBody) ?? '',
      'type': prefs.getString(_kType) ?? 'crisis',
    };
  }

  // ── Helpers ─────────────────────────────────────────────────

  String _typeKey(GameEventType type) {
    switch (type) {
      case GameEventType.warEvent:
        return 'war';
      case GameEventType.mentalBreak:
        return 'mentalBreak';
      case GameEventType.emergencySummon:
        return 'emergencySummon';
      default:
        return 'crisis';
    }
  }
}

/// Dados da crise persistida, usados para recriar o diálogo in-app.
class _PendingCrisis {
  final String title;
  final String body;
  final String type;
  final int day;

  const _PendingCrisis({
    required this.title,
    required this.body,
    required this.type,
    required this.day,
  });

  @override
  String toString() => '_PendingCrisis(day: $day, type: $type, title: $title)';
}

// Exporta _PendingCrisis para uso no game_provider
typedef PendingCrisis = _PendingCrisis;

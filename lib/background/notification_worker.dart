// lib/background/notification_worker.dart
//
// Callback top-level registrado no WorkManager.
// DEVE ser função top-level (fora de qualquer classe) — restrição do WorkManager Flutter.
// Roda em isolate separado: NÃO tem acesso ao GameProvider nem ao Hive.
// Usa apenas SharedPreferences e flutter_local_notifications.

import 'dart:ui' show Color;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Ponto de entrada do WorkManager — registrado em main().
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName != 'crisis_check_task') return Future.value(true);

      final prefs = await SharedPreferences.getInstance();

      final pending  = prefs.getBool('notif_crisis_pending')  ?? false;
      final notified = prefs.getBool('notif_crisis_notified') ?? false;

      // Só dispara se houver crise pendente e ainda não notificada
      if (!pending || notified) return Future.value(true);

      final title = prefs.getString('notif_crisis_title') ?? 'Crise na Torre!';
      final body  = prefs.getString('notif_crisis_body')  ?? 'Ação necessária.';
      final type  = prefs.getString('notif_crisis_type')  ?? 'crisis';

      await _fireNotification(title, body, type);

      // Marca como notificado para não disparar duas vezes
      await prefs.setBool('notif_crisis_notified', true);

      return Future.value(true);
    } catch (e) {
      // Nunca deixa o worker falhar silenciosamente
      return Future.value(false);
    }
  });
}

// ── Helpers internos (não usam classes do app) ───────────────────────────────

Future<void> _fireNotification(
  String title,
  String body,
  String type,
) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings =
      AndroidInitializationSettings('@drawable/ic_notification');
  await plugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  final channelId   = _channelId(type);
  final channelName = _channelName(type);
  final notifId     = _notifId(type);
  final icon        = _icon(type);
  final color       = _color(type);

  final androidDetails = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: 'Alerta de crise — Tower Ascension',
    importance: type == 'war' ? Importance.max : Importance.high,
    priority: Priority.high,
    ticker: 'Torre em alerta',
    styleInformation: BigTextStyleInformation(body),
    color: color,
    icon: '@drawable/ic_notification',
    autoCancel: true,
  );

  await plugin.show(
    notifId,
    '[$icon TOWER ASCENSION] $title',
    body,
    NotificationDetails(android: androidDetails),
  );
}

String _channelId(String type) {
  switch (type) {
    case 'war':            return 'tower_war';
    case 'emergencySummon':
    case 'mentalBreak':    return 'tower_emergency';
    default:               return 'tower_crisis';
  }
}

String _channelName(String type) {
  switch (type) {
    case 'war':            return '⚔ Guerra';
    case 'emergencySummon':
    case 'mentalBreak':    return '🆘 Emergência';
    default:               return '🚨 Crise';
  }
}

int _notifId(String type) {
  switch (type) {
    case 'war':            return 1001;
    case 'emergencySummon': return 1002;
    case 'mentalBreak':    return 1003;
    default:               return 1000;
  }
}

String _icon(String type) {
  switch (type) {
    case 'war':            return '⚔';
    case 'emergencySummon': return '🆘';
    case 'mentalBreak':    return '⚠';
    default:               return '🚨';
  }
}

Color _color(String type) {
  switch (type) {
    case 'war':            return const Color(0xFFFF2200);
    case 'emergencySummon':
    case 'mentalBreak':    return const Color(0xFFAA44FF);
    default:               return const Color(0xFFFF8800);
  }
}
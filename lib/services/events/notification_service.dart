// lib/services/notification_service.dart
//
// Encapsula flutter_local_notifications.
// Cria os canais Android e dispara notificações de crise.

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── IDs dos canais ──────────────────────────────────────────
  static const String _chWar = 'tower_war';
  static const String _chCrisis = 'tower_crisis';
  static const String _chEmergency = 'tower_emergency';

  // ── Inicialização ───────────────────────────────────────────

  /// Deve ser chamado em main(), após WidgetsFlutterBinding.ensureInitialized().
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(defaultActionName: 'Abrir');

    const settings = InitializationSettings(
      android: android,
      iOS: iOS,
      linux: linux,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels(); // ← chamar após initialize
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _chWar,
        '⚔ Guerra',
        description: 'Notificações de eventos de guerra na Torre',
        importance: Importance.max,
        ledColor: Color(0xFFFF2200),
        enableVibration: true,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _chCrisis,
        '🚨 Crise',
        description: 'Notificações de crises internas na Torre',
        importance: Importance.high,
        ledColor: Color(0xFFFF8800),
        enableVibration: true,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _chEmergency,
        '🆘 Emergência',
        description: 'Notificações de emergências e colapsos mentais',
        importance: Importance.high,
        ledColor: Color(0xFFAA44FF),
        enableVibration: true,
        playSound: true,
      ),
    );
  }

  // ── Disparo ─────────────────────────────────────────────────

  /// Dispara uma notificação imediata de crise.
  /// [type] pode ser: "war" | "crisis" | "mentalBreak" | "emergencySummon"
  Future<void> showCrisis(String title, String body, String type) async {
    final channelId = _channelForType(type);
    final notifId = _idForType(type);
    final icon = _iconForType(type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelNameForType(type),
      channelDescription: 'Alerta de crise — Tower Ascension',
      importance: type == 'war' ? Importance.max : Importance.high,
      priority: Priority.high,
      ticker: 'Torre em alerta',
      styleInformation: BigTextStyleInformation(body),
      color: _colorForType(type),
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      subText: icon,
      ongoing: false,
      autoCancel: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      notifId,
      '[$icon TOWER ASCENSION] $title',
      body,
      details,
    );
  }

  // ── Cancelamento ────────────────────────────────────────────

  /// Cancela todas as notificações pendentes (chamado ao abrir o app).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Callback de toque ────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    // O app já abre normalmente pelo sistema.
    // O GameProvider consome a crise pendente no init().
    // Nenhuma ação adicional necessária aqui.
  }

  // ── Helpers ─────────────────────────────────────────────────

  String _channelForType(String type) {
    switch (type) {
      case 'war':
        return _chWar;
      case 'emergencySummon':
      case 'mentalBreak':
        return _chEmergency;
      default:
        return _chCrisis;
    }
  }

  String _channelNameForType(String type) {
    switch (type) {
      case 'war':
        return '⚔ Guerra';
      case 'emergencySummon':
      case 'mentalBreak':
        return '🆘 Emergência';
      default:
        return '🚨 Crise';
    }
  }

  int _idForType(String type) {
    switch (type) {
      case 'war':
        return 1001;
      case 'emergencySummon':
        return 1002;
      case 'mentalBreak':
        return 1003;
      default:
        return 1000;
    }
  }

  String _iconForType(String type) {
    switch (type) {
      case 'war':
        return '⚔';
      case 'emergencySummon':
        return '🆘';
      case 'mentalBreak':
        return '⚠';
      default:
        return '🚨';
    }
  }

  /// Cor de destaque da LED e da notificação.
  /// Usa int puro (flutter_local_notifications não importa dart:ui aqui).
  Color _colorForType(String type) {
    switch (type) {
      case 'war':
        return const Color(0xFFFF2200);
      case 'emergencySummon':
      case 'mentalBreak':
        return const Color(0xFFAA44FF);
      default:
        return const Color(0xFFFF8800);
    }
  }
}

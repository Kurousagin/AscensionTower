// lib/models/ambient_state.dart
//
// AmbientState — determina o estado visual do jogo baseado
// em condições do GameProvider (guerra, moral, fome, estação).

import 'package:flutter/material.dart';
import '../providers/game_provider.dart';
import 'game_event.dart';

enum AmbientState {
  normal,
  winter,
  autumn,
  famine,
  bloodCrisis,
  war,
}

extension AmbientStateExt on AmbientState {
  /// Cor de destaque do tema neste estado
  Color get accentColor {
    switch (this) {
      case AmbientState.war:
        return const Color(0xFFCC2200);
      case AmbientState.bloodCrisis:
        return const Color(0xFF990033);
      case AmbientState.famine:
        return const Color(0xFFAA6600);
      case AmbientState.winter:
        return const Color(0xFF5599CC);
      case AmbientState.autumn:
        return const Color(0xFFCC7733);
      case AmbientState.normal:
        return const Color(0xFF00E5CC);
    }
  }

  /// Cor de fundo levemente tingida
  Color get bgTint {
    switch (this) {
      case AmbientState.war:
        return const Color(0xFF1A0A08);
      case AmbientState.bloodCrisis:
        return const Color(0xFF140008);
      case AmbientState.famine:
        return const Color(0xFF140E04);
      case AmbientState.winter:
        return const Color(0xFF080E14);
      case AmbientState.autumn:
        return const Color(0xFF120A04);
      case AmbientState.normal:
        return const Color(0xFF0A0E14);
    }
  }

  /// Cor das partículas
  Color get particleColor {
    switch (this) {
      case AmbientState.war:
        return const Color(0xFF888888); // cinza fumaça
      case AmbientState.bloodCrisis:
        return const Color(0xFFCC0033); // vermelho sangue
      case AmbientState.famine:
        return const Color(0xFF886633); // poeira/areia
      case AmbientState.winter:
        return const Color(0xFFCCEEFF); // branco neve
      case AmbientState.autumn:
        return const Color(0xFFCC8844); // folhas laranja
      case AmbientState.normal:
        return Colors.transparent;
    }
  }

  /// Intensidade das partículas (0.0 a 1.0)
  double get particleOpacity {
    switch (this) {
      case AmbientState.war:        return 0.35;
      case AmbientState.bloodCrisis: return 0.45;
      case AmbientState.famine:     return 0.30;
      case AmbientState.winter:     return 0.50;
      case AmbientState.autumn:     return 0.40;
      case AmbientState.normal:     return 0.0;
    }
  }

  /// Quantidade de partículas
  int get particleCount {
    switch (this) {
      case AmbientState.war:        return 35;
      case AmbientState.bloodCrisis: return 25;
      case AmbientState.famine:     return 20;
      case AmbientState.winter:     return 50;
      case AmbientState.autumn:     return 18;
      case AmbientState.normal:     return 0;
    }
  }

  /// Velocidade de queda das partículas
  double get particleSpeed {
    switch (this) {
      case AmbientState.war:        return 1.2; // fumaça lenta
      case AmbientState.bloodCrisis: return 0.8; // gotas pesadas lentas
      case AmbientState.famine:     return 1.5; // poeira errante
      case AmbientState.winter:     return 1.0; // neve suave
      case AmbientState.autumn:     return 0.9; // folhas flutuando
      case AmbientState.normal:     return 0.0;
    }
  }

  bool get hasParticles => this != AmbientState.normal;

  String get label {
    switch (this) {
      case AmbientState.war:        return 'GUERRA';
      case AmbientState.bloodCrisis: return 'CRISE';
      case AmbientState.famine:     return 'FOME';
      case AmbientState.winter:     return 'INVERNO';
      case AmbientState.autumn:     return 'OUTONO';
      case AmbientState.normal:     return '';
    }
  }
}

/// Determina o AmbientState atual baseado no GameProvider.
/// Prioridade: war > bloodCrisis > famine > estação > normal
AmbientState resolveAmbientState(GameProvider gp) {
  // 1. Guerra ativa
  if (gp.activeWars.isNotEmpty) return AmbientState.war;

  final morale = gp.citadel.resources.morale;
  final food = gp.citadel.resources.food;
  final day = gp.state.currentDay;

  // 2. Crise de sangue: moral < 20 OU mortes em massa recentes
  final recentDeaths = gp.lastWeekEvents
      .where((e) => e.type == GameEventType.death)
      .length;
  if (morale < 20 || recentDeaths >= 3) return AmbientState.bloodCrisis;

  // 3. Fome crítica
  if (food < 10) return AmbientState.famine;

  // 4. Estações (ciclo de 90 dias)
  final season = day % 90;
  if (season >= 60) return AmbientState.winter;
  if (season >= 45) return AmbientState.autumn;

  return AmbientState.normal;
}
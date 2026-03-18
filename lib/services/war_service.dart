// lib/services/war_service.dart
//
// WarService — gerencia guerras entre facções na torre.
// Guerras impactam andares contestados (recursos e mortalidade) e
// podem ser influenciadas pelo jogador escolhendo um lado.

import 'dart:math';
import '../models/floor_faction.dart';
import '../models/tower.dart';
import '../models/game_event.dart' hide ServiceEvent;
import '../services/faction_service.dart';
import 'package:collection/collection.dart';

// ServiceEvent is defined in game_event.dart

class WarService {
  final Random _rng;
  final List<FactionWar> _activeWars = [];
  final List<FactionWar> _warHistory = [];
  int _warIdCounter = 0;

  WarService(this._rng);

  // ── Accessors ─────────────────────────────────────────────────────────────

  List<FactionWar> get activeWars => List.unmodifiable(_activeWars);
  List<FactionWar> get warHistory => List.unmodifiable(_warHistory);

  bool isFloorContested(int floorNumber) {
    return _activeWars.any((w) => w.contestedFloors.contains(floorNumber));
  }

  /// Retorna o multiplicador de perturbação para recursos de uma facção em guerra.
  /// Andares contestados: -40% recursos. Andares não contestados da facção: -20%.
  double warDisruptionForFaction(FloorFaction faction) {
    final isAtWar = _activeWars.any(
      (w) => w.aggressor == faction || w.defender == faction,
    );
    return isAtWar ? 0.80 : 1.0;
  }

  double contestedFloorResourceMod(int floorNumber) {
    return isFloorContested(floorNumber) ? 0.60 : 1.0;
  }

  double contestedFloorMortalityMod(int floorNumber) {
    return isFloorContested(floorNumber) ? 0.30 : 0.0;
  }

  // ── Processar guerras diariamente ─────────────────────────────────────────

  List<ServiceEvent> processWars({
    required int currentDay,
    required List<TowerFloor> floors,
    required Map<String, FactionRelation> factionRelations,
  }) {
    final events = <ServiceEvent>[];

    // 1. Tentar iniciar nova guerra (~a cada 30 dias)
    if (currentDay % 30 == 0 && _rng.nextDouble() < 0.4) {
      final warEvents = _tryStartWar(currentDay, floors, factionRelations);
      events.addAll(warEvents);
    }

    // 2. Processar guerras ativas
    final toResolve = <FactionWar>[];
    for (final war in _activeWars) {
      final daysElapsed = currentDay - war.startDay;

      // Batalha diária: força oscila
      final aggressorGain = _rng.nextDouble() * 10 - 3;
      final defenderGain = _rng.nextDouble() * 10 - 3;
      war.aggressorStrength = (war.aggressorStrength + aggressorGain).clamp(
        0,
        100,
      );
      war.defenderStrength = (war.defenderStrength + defenderGain).clamp(
        0,
        100,
      );

      // Bônus se o jogador escolheu um lado
      if (war.playerSidedWith == war.aggressor) {
        war.aggressorStrength = (war.aggressorStrength + 5).clamp(0, 100);
      } else if (war.playerSidedWith == war.defender) {
        war.defenderStrength = (war.defenderStrength + 5).clamp(0, 100);
      }

      // Guerra termina quando duração é atingida ou uma facção tem força 0
      if (daysElapsed >= war.duration ||
          war.aggressorStrength <= 0 ||
          war.defenderStrength <= 0) {
        toResolve.add(war);
      }
    }

    for (final war in toResolve) {
      final resolved = _resolveWar(war, floors, factionRelations, currentDay);
      events.addAll(resolved);
    }

    return events;
  }

  List<ServiceEvent> _tryStartWar(
    int currentDay,
    List<TowerFloor> floors,
    Map<String, FactionRelation> factionRelations,
  ) {
    // Precisa de pelo menos 2 facções com andares na torre
    final factionsWithTerritories = FloorFaction.values
        .where(
          (f) =>
              f != FloorFaction.none &&
              floors.any((fl) => fl.cleared && fl.controllingFaction == f),
        )
        .toList();

    if (factionsWithTerritories.length < 2) return [];

    // Verifica se já há guerra entre essas facções
    final eligible = factionsWithTerritories
        .where(
          (f) => !_activeWars.any((w) => w.aggressor == f || w.defender == f),
        )
        .toList();

    if (eligible.length < 2) return [];

    eligible.shuffle(_rng);
    final aggressor = eligible[0];
    final defender = eligible[1];

    // Duração aleatória: 10-30 dias
    final duration = 10 + _rng.nextInt(21);

    // Andares contestados: andares da facção defensora que estão conquistados
    final contested = floors
        .where((f) => f.cleared && (f.controllingFaction == defender))
        .map((f) => f.number)
        .take(3) // no máximo 3 andares contestados
        .toList();

    _warIdCounter++;
    final war = FactionWar(
      id: 'war_$_warIdCounter',
      aggressor: aggressor,
      defender: defender,
      startDay: currentDay,
      duration: duration,
      contestedFloors: contested,
      aggressorStrength: 40.0 + _rng.nextDouble() * 20,
      defenderStrength: 40.0 + _rng.nextDouble() * 20,
    );
    _activeWars.add(war);

    return [
      ServiceEvent(
        type: GameEventType.warEvent,
        title: 'GUERRA: ${aggressor.label} x ${defender.label}',
        description:
            '${aggressor.label} declarou guerra ao ${defender.label}! '
            'Duração estimada: $duration dias. '
            '${contested.isEmpty ? 'Nenhum andar contestado ainda.' : 'Andares contestados: ${contested.join(", ")}.'}',
        isMajor: true,
      ),
    ];
  }

  List<ServiceEvent> _resolveWar(
    FactionWar war,
    List<TowerFloor> floors,
    Map<String, FactionRelation> factionRelations,
    int currentDay,
  ) {
    war.resolved = true;
    _activeWars.remove(war);
    _warHistory.add(war);

    final events = <ServiceEvent>[];

    // Determina vencedor
    if (war.aggressorStrength <= 0) {
      war.winner = war.defender;
    } else if (war.defenderStrength <= 0) {
      war.winner = war.aggressor;
    } else {
      // Vencedor por força ao final da duração
      war.winner = war.aggressorStrength >= war.defenderStrength
          ? war.aggressor
          : war.defender;
    }

    final winner = war.winner!;
    final loser = winner == war.aggressor ? war.defender : war.aggressor;

    // Vencedor assume andares contestados
    for (final floorNum in war.contestedFloors) {
      final floor = floors.firstWhereOrNull((f) => f.number == floorNum);
      if (floor != null && floor.cleared) {
        floor.controllingFaction = winner;
      }
    }

    // Forçar saída do estado de guerra — tier volta a hostile no mínimo
    // (standing -29 = teto de hostile, abaixo de atWar que começa em -30)
    final winnerRel = factionRelations[winner.name];
    if (winnerRel != null) {
      // Garantir que sai de atWar/bloodFeud
      if (winnerRel.standing < -29) winnerRel.standing = -29;
      if (war.playerSidedWith == winner) {
        winnerRel.standing = (winnerRel.standing + 15).clamp(-29, 100);
      }
    }
    final loserRel = factionRelations[loser.name];
    if (loserRel != null) {
      // Perdedor também sai de guerra mas fica hostil
      if (loserRel.standing < -29) loserRel.standing = -29;
      if (war.playerSidedWith == loser) {
        loserRel.standing = (loserRel.standing + 5).clamp(-29, 100);
      } else if (war.playerSidedWith == winner) {
        loserRel.standing = (loserRel.standing - 5).clamp(-29, 100);
      }
    }

    events.add(
      ServiceEvent(
        type: GameEventType.warEvent,
        title: 'FIM DE GUERRA: ${winner.label} venceu!',
        description:
            '${winner.label} derrotou ${loser.label} após ${currentDay - war.startDay} dias. '
            '${war.contestedFloors.isNotEmpty ? "Andares ${war.contestedFloors.join(", ")} agora pertencem a ${winner.label}." : ""}',
        isMajor: true,
      ),
    );

    return events;
  }

  // ── Intervir em guerra ────────────────────────────────────────────────────

  /// Jogador escolhe um lado na guerra. Retorna mensagem de resultado.
  String sideWithFaction({
    required String warId,
    required FloorFaction faction,
    required Map<String, FactionRelation> factionRelations,
  }) {
    final war = _activeWars.firstWhereOrNull((w) => w.id == warId);
    if (war == null) return 'Guerra não encontrada.';
    if (war.playerSidedWith != null) {
      return 'Você já escolheu um lado nesta guerra.';
    }
    if (faction != war.aggressor && faction != war.defender) {
      return '${faction.label} não está nesta guerra.';
    }
    war.playerSidedWith = faction;

    // Corta tratado com a facção rival
    final rival = faction == war.aggressor ? war.defender : war.aggressor;
    final rivalRel = factionRelations[rival.key];
    if (rivalRel != null) {
      rivalRel.hasTreaty = false;
      rivalRel.standing = (rivalRel.standing - 20).clamp(-100.0, 100.0);
    }

    return 'Você se aliou a ${faction.label} nesta guerra! Tratado com ${rival.label} cancelado.';
  }

  // ── Serialização ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'activeWars': _activeWars.map((w) => w.toJson()).toList(),
    'warHistory': _warHistory.map((w) => w.toJson()).toList(),
    'warIdCounter': _warIdCounter,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _activeWars
      ..clear()
      ..addAll(
        (json['activeWars'] as List<dynamic>? ?? []).map(
          (e) => FactionWar.fromJson(e as Map<String, dynamic>),
        ),
      );
    _warHistory
      ..clear()
      ..addAll(
        (json['warHistory'] as List<dynamic>? ?? []).map(
          (e) => FactionWar.fromJson(e as Map<String, dynamic>),
        ),
      );
    _warIdCounter = json['warIdCounter'] as int? ?? 0;
  }

  void clear() {
    _activeWars.clear();
    _warHistory.clear();
    _warIdCounter = 0;
  }
}

// ── Iterable extension ────────────────────────────────────────────────────────

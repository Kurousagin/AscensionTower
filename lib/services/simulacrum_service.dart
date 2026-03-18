// lib/services/simulacrum_service.dart
//
// SimulacrumService — lógica de resolução das batalhas simuladas.
// Extraído do GameEngine para manter responsabilidade única.

import 'dart:math';
import 'package:collection/collection.dart';
import '../models/simulacrum_battle.dart';
import '../models/npc.dart';
import '../models/tower.dart';

class SimulacrumService {
  final Random _rng;
  SimulacrumService(this._rng);

  // ─────────────────────────────────────────────
  // CRIAR BATALHA
  // ─────────────────────────────────────────────

  SimulacrumBattle createBattle({
    required String battleId,
    required Npc npc,
    required TowerFloor floor,
    required int currentDay,
  }) {
    final layout = SimulacrumMapLayout.forFloor(
      floor.description,
      floor.number,
    );
    return SimulacrumBattle(
      id: battleId,
      npcId: npc.id,
      floorNumber: floor.number,
      floorName: floor.description,
      layout: layout,
      faction: floor.controllingFaction,
      tier: floor.tier,
      startDay: currentDay,
    );
  }

  // ─────────────────────────────────────────────
  // GERAR POOL DE MONSTROS DISPONÍVEIS PARA O MASTER
  // ─────────────────────────────────────────────

  List<SimulacrumMonster> generateMonsterPool(SimulacrumBattle battle) {
    final templates = MonsterPool.forFaction(battle.faction, battle.tier);
    final count = MonsterPool.monsterCount(battle.tier);
    final monsters = <SimulacrumMonster>[];

    for (int i = 0; i < count; i++) {
      final template = templates[i % templates.length];
      final isHidden = template.type == MonsterType.trap;
      monsters.add(
        SimulacrumMonster(
          id: 'monster_${battle.id}_$i',
          type: template.type,
          power: template.power * (0.70 + _rng.nextDouble() * 0.60),
          name: template.name,
          revealed: !isHidden,
        ),
      );
    }

    return monsters;
  }

  // ─────────────────────────────────────────────
  // GERAR TROPAS DO NPC (baseadas nos atributos)
  // ─────────────────────────────────────────────

  List<SimulacrumTroop> generateNpcTroops(Npc npc) {
    final troops = <SimulacrumTroop>[];
    final attrs = npc.attributes;

    // Variação de ±15% no poder de cada tropa para quebrar simetria entre simulações
    double vary(double base) => base * (0.85 + _rng.nextDouble() * 0.30);

    if (attrs.strength >= 3) {
      troops.add(
        SimulacrumTroop(type: TroopType.warrior, power: vary(attrs.strength)),
      );
    }
    if (attrs.agility >= 3) {
      troops.add(
        SimulacrumTroop(type: TroopType.archer, power: vary(attrs.agility)),
      );
    }
    if (attrs.intelligence >= 3) {
      troops.add(
        SimulacrumTroop(
          type: TroopType.strategist,
          power: vary(attrs.intelligence),
        ),
      );
    }
    if (attrs.endurance >= 3) {
      troops.add(
        SimulacrumTroop(type: TroopType.healer, power: vary(attrs.endurance)),
      );
    }
    if (attrs.charisma >= 3) {
      troops.add(
        SimulacrumTroop(type: TroopType.diplomat, power: vary(attrs.charisma)),
      );
    }

    // Garante pelo menos 2 tropas mesmo com atributos baixos
    while (troops.length < 2) {
      troops.add(SimulacrumTroop(type: TroopType.warrior, power: 3.0));
    }

    // Máximo 5 tropas
    return troops.take(5).toList();
  }

  // ─────────────────────────────────────────────
  // ESTRATÉGIAS VISÍVEIS PARA O NPC
  // ─────────────────────────────────────────────

  /// Retorna quais estratégias o NPC pode ver baseado na sua INT
  List<ZoneStrategy> availableStrategies(Npc npc) {
    final intel = npc.attributes.intelligence;
    return ZoneStrategy.values
        .where((s) => intel >= s.requiredIntelligence)
        .toList();
  }

  // ─────────────────────────────────────────────
  // RESOLUÇÃO DA BATALHA
  // ─────────────────────────────────────────────

  SimulacrumBattle resolve(SimulacrumBattle battle, Npc npc) {
    final results = <ZoneResult>[];

    // Verifica se há Estrategista — bônus global +10%
    final hasStrategist = battle.npcTroops.any(
      (t) => t.type == TroopType.strategist && t.assignedZoneId != null,
    );
    final strategistBonus = hasStrategist ? 1.1 : 1.0;

    for (final zone in battle.zones) {
      final troops = battle.troopsInZone(zone.id);
      final monsters = battle.monstersInZone(zone.id);
      final strategy = battle.npcStrategies[zone.id];

      // Zonas sem alocação de nenhum lado — abandoned
      if (troops.isEmpty && monsters.isEmpty) {
        results.add(
          ZoneResult(
            zoneId: zone.id,
            outcome: ZoneOutcome.abandoned,
            npcPower: 0,
            masterPower: 0,
            narrative: '${zone.name} ficou sem disputa.',
          ),
        );
        continue;
      }

      // Calcula poder do NPC nesta zona
      double npcPower =
          troops.fold(0.0, (s, t) => s + t.power) * strategistBonus;
      bool bonusDecision = false;

      // Aplica modificadores de estratégia
      if (strategy != null) {
        npcPower = _applyStrategyModifier(
          npcPower: npcPower,
          strategy: strategy,
          monsters: monsters,
          zone: zone,
          npc: npc,
          bonusDecisionCallback: () => bonusDecision = true,
        );
      }

      // Aplica vantagem de terreno para o NPC
      npcPower *= _zoneAttackerMultiplier(zone.advantage);

      // Calcula poder do Master nesta zona
      double masterPower = 0.0;
      for (final monster in monsters) {
        var mp = monster.power;

        // Comandante dá bônus para os outros na mesma zona
        if (monster.type == MonsterType.monsterCommander) {
          masterPower += mp * 0.5; // o próprio vale menos
          masterPower +=
              (monsters.length - 1) * mp * 0.15; // bônus para os outros
          continue;
        }

        // Armadilha não detectada
        if (monster.type == MonsterType.trap && !monster.revealed) {
          mp *= 1.5;
        }

        // Emboscador em zona fechada
        if (monster.type == MonsterType.ambusher &&
            zone.advantage == ZoneAdvantage.closed) {
          mp *= 1.3;
        }

        // Patrulha em zona aberta
        if (monster.type == MonsterType.patrol &&
            zone.advantage == ZoneAdvantage.open) {
          mp *= 1.2;
        }

        // Diplomata reduz poder dos monstros
        if (troops.any((t) => t.type == TroopType.diplomat)) {
          mp *= 0.9;
          bonusDecision = true;
        }

        masterPower += mp;
      }

      // Variação aleatória maior (±25%) para quebrar simetria
      npcPower *= 0.75 + _rng.nextDouble() * 0.50;
      masterPower *= 0.75 + _rng.nextDouble() * 0.50;

      // Fator surpresa adicional — evento inesperado (10% de chance)
      if (_rng.nextDouble() < 0.10) {
        final surprise = _rng.nextBool();
        if (surprise) {
          npcPower *= 1.3;
        } else {
          masterPower *= 1.3;
        }
      }

      // Determina resultado — threshold menor para reduzir empates
      final ZoneOutcome outcome;
      final String narrative;

      if (npcPower > masterPower * 1.05) {
        outcome = ZoneOutcome.npcWin;
        narrative = _npcWinNarrative(zone, strategy, troops);
      } else if (masterPower > npcPower * 1.05) {
        outcome = ZoneOutcome.masterWin;
        narrative = _masterWinNarrative(zone, monsters);
      } else {
        outcome = ZoneOutcome.draw;
        narrative = '${zone.name}: confronto inconclusivo. Ambos recuam.';
      }
      results.add(
        ZoneResult(
          zoneId: zone.id,
          outcome: outcome,
          npcPower: npcPower,
          masterPower: masterPower,
          narrative: narrative,
          bonusDecision: bonusDecision,
        ),
      );
    }

    // Aplica bônus de Cerco
    final resultsWithSiege = _applySiegeBonus(results, battle);

    // Calcula ganho de INT
    final intGained = _calculateIntGain(resultsWithSiege, npc);

    battle
      ..zoneResults = resultsWithSiege
      ..npcVictory = _determineVictory(resultsWithSiege)
      ..intGained = intGained
      ..phase = BattlePhase.completed;

    return battle;
  }

  // ─────────────────────────────────────────────
  // HELPERS DE RESOLUÇÃO
  // ─────────────────────────────────────────────

  double _applyStrategyModifier({
    required double npcPower,
    required ZoneStrategy strategy,
    required List<SimulacrumMonster> monsters,
    required BattleZone zone,
    required Npc npc,
    required void Function() bonusDecisionCallback,
  }) {
    switch (strategy) {
      case ZoneStrategy.directAssault:
        // Sem modificador, mas +10% se zona aberta
        if (zone.advantage == ZoneAdvantage.open) {
          bonusDecisionCallback();
          return npcPower * 1.1;
        }
        return npcPower;

      case ZoneStrategy.infiltration:
        // Ignora emboscadores — decisão acertada se há emboscadores
        final hasAmbusher = monsters.any((m) => m.type == MonsterType.ambusher);
        if (hasAmbusher) {
          bonusDecisionCallback();
          return npcPower * 1.2;
        }
        // Penalidade em zonas abertas
        if (zone.advantage == ZoneAdvantage.open) return npcPower * 0.85;
        return npcPower;

      case ZoneStrategy.tacticalAnalysis:
        // Revela armadilhas — decisão acertada se há armadilhas
        final hasTrap = monsters.any((m) => m.type == MonsterType.trap);
        if (hasTrap) {
          // Revela todas as armadilhas na zona
          for (final m in monsters.where((m) => m.type == MonsterType.trap)) {
            m.revealed = true;
          }
          bonusDecisionCallback();
          return npcPower * 1.15;
        }
        // Bônus pequeno de INT mesmo sem armadilhas
        return npcPower * (1.0 + npc.attributes.intelligence * 0.01);

      case ZoneStrategy.siege:
        // Bônus aplicado depois em _applySiegeBonus
        return npcPower;

      case ZoneStrategy.negotiation:
        // Chance de converter monstro menor baseada em CAR
        final minorMonster = monsters.firstWhereOrNull(
          (m) =>
              m.type != MonsterType.brute &&
              m.type != MonsterType.monsterCommander,
        );
        if (minorMonster != null) {
          final successChance = (npc.attributes.charisma / 15.0).clamp(
            0.1,
            0.7,
          );
          if (_rng.nextDouble() < successChance) {
            bonusDecisionCallback();
            // Remove o monstro convertido do confronto
            minorMonster.assignedZoneId = null;
            return npcPower * 1.1;
          }
        }
        return npcPower;
    }
  }

  double _zoneAttackerMultiplier(ZoneAdvantage advantage) {
    switch (advantage) {
      case ZoneAdvantage.open:
        return 1.1; // atacante tem vantagem
      case ZoneAdvantage.closed:
        return 0.9; // defensor tem vantagem
      case ZoneAdvantage.elevated:
        return 1.0; // neutro para todos
      case ZoneAdvantage.neutral:
        return 1.0;
    }
  }

  List<ZoneResult> _applySiegeBonus(
    List<ZoneResult> results,
    SimulacrumBattle battle,
  ) {
    final updated = [...results];

    for (int i = 0; i < updated.length; i++) {
      final result = updated[i];
      final strategy = battle.npcStrategies[result.zoneId];
      if (strategy != ZoneStrategy.siege) continue;

      final zone = battle.zones.firstWhereOrNull((z) => z.id == result.zoneId);
      if (zone == null) continue;

      // Conta zonas adjacentes vencidas pelo NPC
      final adjacentWins = zone.adjacentZoneIds.where((adjId) {
        return results.any(
          (r) => r.zoneId == adjId && r.outcome == ZoneOutcome.npcWin,
        );
      }).length;

      if (adjacentWins >= 1 && result.outcome != ZoneOutcome.abandoned) {
        // Aplica bônus de cerco — converte empate em vitória ou melhora vitória
        if (result.outcome == ZoneOutcome.draw) {
          updated[i] = ZoneResult(
            zoneId: result.zoneId,
            outcome: ZoneOutcome.npcWin,
            npcPower: result.npcPower * (1.0 + adjacentWins * 0.2),
            masterPower: result.masterPower,
            narrative: '${zone.name}: o cerco forçou a rendição inimiga.',
            bonusDecision: true,
          );
        }
      }
    }

    return updated;
  }

  bool _determineVictory(List<ZoneResult> results) {
    final npcWins = results
        .where((r) => r.outcome == ZoneOutcome.npcWin)
        .length;
    final masterWins = results
        .where((r) => r.outcome == ZoneOutcome.masterWin)
        .length;
    return npcWins > masterWins;
  }

  double _calculateIntGain(List<ZoneResult> results, Npc npc) {
    final npcWins = results
        .where((r) => r.outcome == ZoneOutcome.npcWin)
        .length;
    final masterWins = results
        .where((r) => r.outcome == ZoneOutcome.masterWin)
        .length;
    final bonusDecisions = results.where((r) => r.bonusDecision).length;
    final total = results
        .where((r) => r.outcome != ZoneOutcome.abandoned)
        .length;

    if (total == 0) return 0.1;

    double base;
    if (npcWins == 0) {
      base = 0.1; // derrota total
    } else if (npcWins < masterWins) {
      base = 0.3; // derrota parcial
    } else if (npcWins == masterWins) {
      base = 0.5; // empate
    } else if (npcWins == total) {
      base = 1.2; // vitória total
    } else {
      base = 0.8; // vitória parcial
    }

    // Bônus por decisões acertadas
    final decisionBonus = bonusDecisions * 0.1;

    // Bônus por estrelas do NPC
    final starBonus = npc.stars * 0.05;

    // Diminishing returns — INT alta ganha menos
    final intPenalty = (npc.attributes.intelligence / 20.0) * 0.3;

    return ((base + decisionBonus + starBonus) * (1.0 - intPenalty)).clamp(
      0.05,
      2.0,
    );
  }

  // ─────────────────────────────────────────────
  // NARRATIVAS
  // ─────────────────────────────────────────────

  String _npcWinNarrative(
    BattleZone zone,
    ZoneStrategy? strategy,
    List<SimulacrumTroop> troops,
  ) {
    final troopNames = troops.map((t) => t.type.label).join(', ');
    switch (strategy) {
      case ZoneStrategy.infiltration:
        return '${zone.name}: infiltração bem-sucedida. Os inimigos não souberam o que os acertou.';
      case ZoneStrategy.tacticalAnalysis:
        return '${zone.name}: análise revelou as armadilhas. Avanço calculado e preciso.';
      case ZoneStrategy.siege:
        return '${zone.name}: o cerco funcionou. Sem saída, os defensores cederam.';
      case ZoneStrategy.negotiation:
        return '${zone.name}: palavras onde armas falhariam. Um inimigo virou aliado.';
      case ZoneStrategy.directAssault:
        return '${zone.name}: assalto direto. $troopNames forçaram a passagem.';
      default:
        return '${zone.name}: zona conquistada. $troopNames avançaram sem resistência.';
    }
  }

  String _masterWinNarrative(
    BattleZone zone,
    List<SimulacrumMonster> monsters,
  ) {
    final monsterNames = monsters.map((m) => m.name).join(', ');
    return '${zone.name}: $monsterNames resistiram. As tropas recuaram com perdas.';
  }

  /// Gera sumário narrativo completo da batalha
  String generateBattleSummary(SimulacrumBattle battle, Npc npc) {
    final wins = battle.npcZoneWins;
    final losses = battle.masterZoneWins;
    final intGain = battle.intGained.toStringAsFixed(2);

    final outcome = battle.npcVictory
        ? 'VITÓRIA DO COMANDANTE'
        : wins == losses
        ? 'EMPATE TÁTICO'
        : 'DERROTA DO COMANDANTE';

    final lines = [
      '=== $outcome ===',
      '${npc.name} — ${battle.floorName}',
      '',
      ...battle.zoneResults.map((r) => r.narrative),
      '',
      'Zonas: $wins vitórias / $losses derrotas',
      'Decisões acertadas: ${battle.bonusDecisions}',
      '+$intGain INT para ${npc.name}',
    ];

    return lines.join('\n');
  }
}

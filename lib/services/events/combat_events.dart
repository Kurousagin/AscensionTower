// import '../../models/citadel.dart';
// import '../../models/npc.dart';
// import '../../models/game_event.dart';
// import 'event_processor.dart';

// /// Processa eventos de combate: duelos na arena, conflitos
// class CombatEvents extends EventProcessor {
//   CombatEvents({
//     required super.rng,
//     required super.citadel,
//     required super.npcs,
//     required super.state,
//     required super.addEvent,
//   });

//   /// Processa eventos da arena (duelos entre NPCs)
//   void processArenaEvents() {
//     if (!citadel.hasBuilding(BuildingType.arena)) return;
//     if (state.currentDay % 7 != 0 || aliveNpcs.length < 2) return;
//     if (rng.nextDouble() >= 0.3) return;

//     final fighters = aliveNpcs
//         .where(
//           (n) =>
//               n.attributes.mentalStability > 30 &&
//               n.attributes.combatPower > 3.0,
//         )
//         .toList();
//     if (fighters.length < 2) return;

//     fighters.shuffle(rng);
//     final a = fighters[0], b = fighters[1];
//     final aWins =
//         a.attributes.combatPower + rng.nextDouble() * 3 >
//         b.attributes.combatPower + rng.nextDouble() * 3;

//     final winner = aWins ? a : b;
//     final loser = aWins ? b : a;
//     winner.fame += 2;
//     winner.attributes.strength += 0.2;
//     loser.attributes.endurance += 0.1;

//     addEvent(
//       GameEventType.combat,
//       'Duelo na Arena',
//       '${winner.name} venceu ${loser.name}! +Fama, +Stats.',
//       involvedIds: [a.id, b.id],
//     );
//   }

//   /// Processa conflitos espontâneos entre NPCs com baixa afinidade
//   void processConflicts() {
//     if (rng.nextDouble() >= 0.05) return; // 5% de chance por dia
//     if (aliveNpcs.length < 2) return;

//     // Busca NPCs com relacionamento muito ruim
//     for (final npc in aliveNpcs) {
//       final enemies = npc.relationships
//           .where((r) => r.affinity < -0.3)
//           .toList();

//       if (enemies.isEmpty) continue;

//       final enemyRel = enemies[rng.nextInt(enemies.length)];
//       final enemy = aliveNpcs.firstWhere(
//         (n) => n.id == enemyRel.targetId,
//         orElse: () => npc,
//       );

//       if (enemy.id == npc.id) continue;

//       // Conflito verbal ou físico
//       if (rng.nextDouble() < 0.3) {
//         // Conflito físico (raro)
//         _processPhysicalConflict(npc, enemy);
//       } else {
//         // Conflito verbal
//         _processVerbalConflict(npc, enemy);
//       }

//       break; // Apenas um conflito por dia
//     }
//   }

//   void _processPhysicalConflict(Npc a, Npc b) {
//     final aWins = a.attributes.combatPower > b.attributes.combatPower;
//     final winner = aWins ? a : b;
//     final loser = aWins ? b : a;

//     // Perdedor toma dano
//     loser.attributes.endurance -= 0.5;
//     loser.attributes.mentalStability -= 5;
//     loser.loyalty -= 2;

//     // Vencedor ganha reputação, mas perde moral geral
//     winner.fame += 1;
//     citadel.resources.morale -= 3;

//     addEvent(
//       GameEventType.combat,
//       'Briga na Cidadela!',
//       '${a.name} e ${b.name} entraram em conflito físico! '
//           '${winner.name} levou vantagem. Moral geral cai.',
//       involvedIds: [a.id, b.id],
//     );
//   }

//   void _processVerbalConflict(Npc a, Npc b) {
//     a.loyalty -= 1;
//     b.loyalty -= 1;

//     addEvent(
//       GameEventType.politicalEvent,
//       'Discussão Acalorada',
//       '${a.name} e ${b.name} discutiram publicamente. A tensão aumenta.',
//       involvedIds: [a.id, b.id],
//     );
//   }
// }

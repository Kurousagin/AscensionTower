// import '../../models/citadel.dart';
// import '../../models/npc.dart';
// import '../../models/game_event.dart';
// import 'event_processor.dart';

// /// Processa eventos relacionados a relacionamentos entre NPCs
// class RelationshipEvents extends EventProcessor {
//   RelationshipEvents({
//     required super.rng,
//     required super.citadel,
//     required super.npcs,
//     required super.state,
//     required super.addEvent,
//   });

//   /// Eventos da taverna (ocorrem a cada 5 dias)
//   void processTavernEvents() {
//     if (!citadel.hasBuilding(BuildingType.tavern) || state.currentDay % 5 != 0) {
//       return;
//     }

//     // Revelar traidor via boato (10%)
//     if (rng.nextDouble() < 0.1) {
//       final hidden = aliveNpcs
//           .where((n) => n.origin.isDarkOrigin && !n.isSuspicious)
//           .toList();
//       if (hidden.isNotEmpty) {
//         final npc = hidden[rng.nextInt(hidden.length)];
//         // Atualizar na lista npcs
//         final npcIndex = npcs.indexWhere((n) => n.id == npc.id);
//         if (npcIndex != -1) {
//           npcs[npcIndex] = npcs[npcIndex].copyWith(isSuspicious: true);
//         }
//         addEvent(
//           GameEventType.system,
//           'Boato na Taverna',
//           '${npc.name} tem passado questionavel...',
//           involvedIds: [npc.id],
//         );
//       }
//     }

//     // Fortalecer relação (20%)
//     if (rng.nextDouble() < 0.2 && aliveNpcs.length >= 2) {
//       final a = aliveNpcs[rng.nextInt(aliveNpcs.length)];
//       final b = pickOther(aliveNpcs, a);

//       final relIndex = a.relationships.indexWhere((r) => r.targetId == b.id);
//       if (relIndex != -1) {
//         a.relationships[relIndex] = a.relationships[relIndex].copyWith(
//           affinity: a.relationships[relIndex].affinity + 0.1,
//         );
//       }
//     }
//   }

//   /// Processa formação de novas relações entre NPCs
//   void processRelationshipFormation() {
//     if (aliveNpcs.length < 2 || rng.nextDouble() < 0.7) return;

//     final a = aliveNpcs[rng.nextInt(aliveNpcs.length)];
//     final b = pickOther(aliveNpcs, a);

//     // Verifica se já existe relacionamento
//     final hasRelationship = a.relationships.any((r) => r.targetId == b.id);
//     if (hasRelationship) return;

//     // Cria novo relacionamento
//     final baseAffinity = 0.5 + (rng.nextDouble() * 0.3 - 0.15);
//     a.relationships.add(
//       Relationship(
//         targetId: b.id,
//         type: 'acquaintance',
//         affinity: baseAffinity,
//       ),
//     );

//     b.relationships.add(
//       Relationship(
//         targetId: a.id,
//         type: 'acquaintance',
//         affinity: baseAffinity,
//       ),
//     );
//   }

//   /// Processa deterioração de relacionamentos ruins
//   void processRelationshipDecay() {
//     for (final npc in aliveNpcs) {
//       for (int i = 0; i < npc.relationships.length; i++) {
//         final rel = npc.relationships[i];

//         // Relacionamentos negativos podem piorar
//         if (rel.affinity < 0.3 && rng.nextDouble() < 0.1) {
//           npc.relationships[i] = rel.copyWith(
//             affinity: (rel.affinity - 0.05).clamp(-1.0, 1.0),
//           );

//           // Conflito pode ocorrer
//           if (rel.affinity < 0.1 && rng.nextDouble() < 0.05) {
//             final target = aliveNpcs.firstWhere(
//               (n) => n.id == rel.targetId,
//               orElse: () => npc,
//             );

//             if (target.id != npc.id) {
//               addEvent(
//                 GameEventType.politicalEvent,
//                 'Tensão entre NPCs',
//                 '${npc.name} e ${target.name} tiveram um desentendimento.',
//                 involvedIds: [npc.id, target.id],
//               );
//             }
//           }
//         }
//       }
//     }
//   }
// }

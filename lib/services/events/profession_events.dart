// import '../../models/citadel.dart';
// import '../../models/npc.dart';
// import '../../models/game_event.dart';
// import 'event_processor.dart';

// /// Processa eventos relacionados a profissões e treinamento
// class ProfessionEvents extends EventProcessor {
//   ProfessionEvents({
//     required super.rng,
//     required super.citadel,
//     required super.npcs,
//     required super.state,
//     required super.addEvent,
//   });

//   /// Processa treino diário de NPCs baseado em suas profissões
//   void processTraining() {
//     final trainedToday = <String, List<String>>{};

//     for (final npc in aliveNpcs) {
//       final gains = _applyProfessionTraining(npc);
//       if (gains.isNotEmpty) {
//         npc.history.add(
//           'Treinou como ${npc.profession.label}: ${gains.join(", ")}',
//         );
//         trainedToday
//             .putIfAbsent(npc.profession.label, () => [])
//             .add('${npc.name} (${gains.join(", ")})');
//       }
//     }

//     if (trainedToday.isNotEmpty) {
//       final details = trainedToday.entries
//           .map((e) => '${e.key}: ${e.value.join(", ")}')
//           .join('\n');
//       addEvent(GameEventType.training, 'Treino Diario', details);
//     }
//   }

//   List<String> _applyProfessionTraining(Npc npc) {
//     if (rng.nextDouble() >= 0.1) return [];
//     final gains = <String>[];

//     switch (npc.profession) {
//       case Profession.guard:
//       case Profession.explorer:
//         npc.attributes.strength += 0.1;
//         npc.attributes.endurance += 0.1;
//         gains.addAll(['FOR+0.1', 'RES+0.1']);

//         // Bônus do Barracks baseado no tier
//         final barracks = citadel.getBuilding(BuildingType.barracks);
//         if (barracks != null) {
//           final t = barracks.getBonusTier();
//           final strBonus = [0.3, 0.5, 0.8, 0.8][t];
//           final agiBonus = [0.0, 0.3, 0.5, 0.5][t];

//           npc.attributes.strength += strBonus;
//           gains.add('FOR+$strBonus (Barracks)');

//           if (agiBonus > 0) {
//             npc.attributes.agility += agiBonus;
//             gains.add('AGI+$agiBonus (Barracks)');
//           }
//         }
//         break;

//       case Profession.scribe:
//       case Profession.teacher:
//         npc.attributes.intelligence += 0.1;
//         gains.add('INT+0.1');
//         break;

//       case Profession.scout:
//         npc.attributes.agility += 0.1;
//         gains.add('AGI+0.1');
//         break;

//       case Profession.trainer:
//         npc.attributes.strength += 0.05;
//         npc.attributes.endurance += 0.05;
//         npc.attributes.intelligence += 0.05;
//         gains.addAll(['FOR+0.05', 'RES+0.05', 'INT+0.05']);
//         break;

//       default:
//         break;
//     }
//     return gains;
//   }

//   /// Processa escolha automática de profissão para NPCs sem profissão
//   void processAutoProfessionAssignment() {
//     final unemployed = aliveNpcs
//         .where((n) => n.profession == Profession.idle && n.age >= 16)
//         .toList();

//     if (unemployed.isEmpty) return;

//     for (final npc in unemployed) {
//       final profession = _chooseBestProfession(npc);
//       npc.profession = profession;

//       addEvent(
//         GameEventType.system,
//         'Nova Profissão',
//         '${npc.name} se tornou ${profession.label}.',
//         involvedIds: [npc.id],
//       );
//     }
//   }

//   Profession _chooseBestProfession(Npc npc) {
//     // Lógica baseada em atributos e traits
//     if (npc.attributes.combatPower > 5) {
//       return rng.nextBool() ? Profession.guard : Profession.explorer;
//     }

//     if (npc.attributes.intelligence > 7) {
//       return rng.nextBool() ? Profession.scribe : Profession.teacher;
//     }

//     if (npc.attributes.agility > 6) {
//       return Profession.scout;
//     }

//     if (npc.traits.contains(PersonalityTrait.compassionate)) {
//       return Profession.doctor;
//     }

//     if (npc.traits.contains(PersonalityTrait.creative)) {
//       return Profession.builder;
//     }

//     // Padrão: profissões básicas
//     final basic = [Profession.farmer, Profession.builder, Profession.chef];
//     return basic[rng.nextInt(basic.length)];
//   }
// }

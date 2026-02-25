// import '../../models/citadel.dart';
// import '../../models/npc.dart';
// import 'event_processor.dart';

// /// Processa reações dos NPCs a construções e upgrades de prduções
// class ProductionEvents extends EventProcessor {
//   ProductionEvents({
//     required super.rng,
//     required super.citadel,
//     required super.npcs,
//     required super.state,
//     required super.addEvent,
//   });

//   // ─────────────────────────────────────────────
//   // PRODUCAO & CONSUMO
//   // ─────────────────────────────────────────────

//   void processResourceProduction() {
//     final res = citadel.resources;
//     final farmers = countProfession(Profession.farmer);
//     final builders = countProfession(Profession.builder);
//     final scribes = countProfession(Profession.scribe);

//     // Produção base por profissão
//     res.food += 2.0 + farmers * 3.0;
//     res.wood += 1.0 + builders * 2.0;
//     res.stone += 0.5 + builders * 1.0;
//     res.knowledge += 0.2 + scribes * 1.5;

//     // Produção de edifícios
//     for (final building in citadel.buildings) {
//       _applyBuildingProduction(building, res);
//     }
//   }

//   void _applyBuildingProduction(Building building, Resources res) {
//     final t = building.getBonusTier();
//     switch (building.type) {
//       case BuildingType.farm:
//         res.food += [5.0, 12.0, 25.0, 25.0][t];
//         break;
//       case BuildingType.kitchen:
//         final chefs = countProfession(Profession.chef);
//         res.food += chefs * [3.0, 8.0, 15.0, 15.0][t];
//         break;
//       case BuildingType.workshop:
//         if (t == 0) {
//           res.iron += 1.0;
//         } else if (t == 1) {
//           res.iron += 3.0;
//           res.wood += 2.0;
//         } else {
//           res.iron += 6.0;
//           res.wood += 5.0;
//         }
//         break;
//       case BuildingType.woodworking:
//         if (t == 0) {
//           res.wood += 2.0;
//         } else if (t == 1) {
//           res.wood += 5.0;
//           res.morale += 1.0;
//         } else {
//           res.wood += 10.0;
//           res.morale += 3.0;
//         }
//         break;
//       case BuildingType.forge:
//         res.iron += [2.0, 5.0, 10.0, 10.0][t];
//         break;
//       case BuildingType.library:
//         res.knowledge += 3.0;
//         break;
//       case BuildingType.temple:
//         res.morale += 2.0;
//         for (final npc in aliveNpcs) {
//           npc.attributes.mentalStability =
//               (npc.attributes.mentalStability + 0.5).clamp(0, 100);
//         }
//         break;
//       case BuildingType.firepit:
//         res.morale += [1.0, 2.0, 3.0, 5.0][t];
//         break;
//       default:
//         break;
//     }
//   }
// }

// import '../../models/citadel.dart';
// import '../../models/npc.dart';
// import '../../models/game_event.dart';
// import 'event_processor.dart';

// /// Processa reações dos NPCs a construções e upgrades de edifícios
// class ConstructionEvents extends EventProcessor {
//   ConstructionEvents({
//     required super.rng,
//     required super.citadel,
//     required super.npcs,
//     required super.state,
//     required super.addEvent,
//   });

//   /// Processa reações dos NPCs quando um edifício é construído ou melhorado
//   void processNpcBuildReaction(BuildingType type, {bool isUpgrade = false}) {
//     final action = isUpgrade ? 'melhoria' : 'construcao';

//     switch (type) {
//       case BuildingType.barracks:
//         _processBarracksReaction(isUpgrade);
//         break;

//       case BuildingType.trainingField:
//         _processTrainingFieldReaction(action);
//         break;

//       case BuildingType.temple:
//         _processTempleReaction(action);
//         break;

//       case BuildingType.tavern:
//         _processTavernReaction();
//         break;

//       case BuildingType.arena:
//         _processArenaReaction();
//         break;

//       case BuildingType.councilHall:
//         _processCouncilHallReaction();
//         break;

//       case BuildingType.promotionHall:
//         _processPromotionHallReaction();
//         break;

//       default:
//         break;
//     }
//   }

//   void _processBarracksReaction(bool isUpgrade) {
//     final militants = aliveNpcs.where(
//       (n) =>
//           n.profession == Profession.guard ||
//           n.profession == Profession.explorer ||
//           n.profession == Profession.trainer,
//     ).toList();

//     final lowMorale = citadel.resources.morale < 40;
//     final militaryStrong = militants.length > 6;
//     final hasThreats = aliveNpcs.any((n) => n.isSuspicious);

//     int happyCount = 0;
//     int unhappyCount = 0;

//     for (final npc in militants) {
//       if (lowMorale && !hasThreats) {
//         // Moral baixo e sem ameaça = "Por que armas se precisamos comida?"
//         npc.loyalty -= 2;
//         unhappyCount++;
//       } else if (militaryStrong) {
//         // Força militar grande = orgulho e camaradagem
//         npc.loyalty += 5;
//         npc.fame += 1;
//         happyCount++;
//       } else if (hasThreats) {
//         // Há suspeitos = aprovam ainda mais
//         npc.loyalty += 4;
//         happyCount++;
//       } else {
//         // Reação padrão positiva
//         npc.loyalty += 2;
//         happyCount++;
//       }
//     }

//     // NPCs covardes sempre desaprovam militarização
//     for (final npc in aliveNpcs.where(
//       (n) => n.traits.contains(PersonalityTrait.coward),
//     )) {
//       npc.loyalty -= 1;
//       unhappyCount++;
//     }

//     // Evento contextual baseado nas reações
//     if (unhappyCount > happyCount) {
//       addEvent(
//         GameEventType.politicalEvent,
//         'Barracks ${isUpgrade ? "Melhorado" : "Construido"} - Divisão',
//         'A ${isUpgrade ? "melhoria" : "construção"} divide opiniões. '
//             '${lowMorale ? "Muitos questionam: \"Armas não nos alimentam!\"" : "Alguns temem a militarização."}',
//       );
//     } else if (militaryStrong) {
//       addEvent(
//         GameEventType.politicalEvent,
//         'Orgulho Militar!',
//         'Com ${militants.length} combatentes, a força militar celebra! '
//             'Guardas sentem-se parte de algo maior.',
//       );
//     } else if (hasThreats) {
//       addEvent(
//         GameEventType.politicalEvent,
//         'Segurança Reforçada',
//         'Diante das ameaças, a ${isUpgrade ? "melhoria" : "construção"} traz alívio. '
//             'Guardas estão vigilantes.',
//       );
//     } else {
//       addEvent(
//         GameEventType.politicalEvent,
//         'Barracks ${isUpgrade ? "Melhorado" : "Construido"}',
//         'Guardas e exploradores se sentem mais valorizados.',
//       );
//     }
//   }

//   void _processTrainingFieldReaction(String action) {
//     for (final npc in aliveNpcs.where(
//       (n) =>
//           n.profession == Profession.guard ||
//           n.profession == Profession.explorer,
//     )) {
//       npc.loyalty += 2;
//     }
//     for (final npc in aliveNpcs.where(
//       (n) => n.traits.contains(PersonalityTrait.coward),
//     )) {
//       npc.loyalty -= 1;
//     }
//     addEvent(
//       GameEventType.politicalEvent,
//       'Reacao: $action Militar',
//       'Guardas aprovam. Os mais timidos ficam desconfortaveis.',
//     );
//   }

//   void _processTempleReaction(String action) {
//     citadel.resources.morale += 5;
//     for (final npc in aliveNpcs) {
//       npc.loyalty += 1;
//     }
//     addEvent(
//       GameEventType.celebration,
//       'Fe Renovada',
//       'A $action do Templo trouxe esperanca a todos.',
//     );
//   }

//   void _processTavernReaction() {
//     citadel.resources.morale += 3;
//     // Revelar NPCs com origem obscura
//     for (int i = 0; i < npcs.length; i++) {
//       if (npcs[i].alive &&
//           npcs[i].origin.isDarkOrigin &&
//           !npcs[i].isSuspicious &&
//           rng.nextDouble() < 0.3) {
//         npcs[i] = npcs[i].copyWith(isSuspicious: true);
//         addEvent(
//           GameEventType.system,
//           'Fofoca na Taverna',
//           'Rumores indicam que ${npcs[i].name} tem passado sombrio...',
//           involvedIds: [npcs[i].id],
//         );
//       }
//     }
//     addEvent(
//       GameEventType.politicalEvent,
//       'Taverna Aberta',
//       'Fofocas e informacoes fluem livremente.',
//     );
//   }

//   void _processArenaReaction() {
//     for (final npc in aliveNpcs.where(
//       (n) => n.traits.contains(PersonalityTrait.brave),
//     )) {
//       npc.loyalty += 3;
//       npc.fame += 1;
//     }
//     addEvent(
//       GameEventType.politicalEvent,
//       'Arena Inaugurada!',
//       'Os mais bravos ja planejam seus duelos.',
//     );
//   }

//   void _processCouncilHallReaction() {
//     for (final npc in aliveNpcs) {
//       npc.loyalty += 1;
//     }
//     addEvent(
//       GameEventType.politicalEvent,
//       'Democracia Emergente',
//       'A Sala do Conselho da voz ao povo.',
//     );
//   }

//   void _processPromotionHallReaction() {
//     for (final npc in aliveNpcs.where(
//       (n) => n.traits.contains(PersonalityTrait.leader),
//     )) {
//       npc.loyalty += 3;
//     }
//     addEvent(
//       GameEventType.politicalEvent,
//       'Caminho para Grandeza',
//       'Lideres celebram as novas oportunidades de ascensao.',
//     );
//   }
// }

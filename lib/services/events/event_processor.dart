// import 'dart:math';
// import '../../models/npc.dart';
// import '../../models/citadel.dart';
// import '../../models/game_event.dart';

// /// Classe base para processadores de eventos.
// /// Fornece acesso ao estado do jogo e métodos helpers comuns.
// abstract class EventProcessor {
//   final Random rng;
//   final Citadel citadel;
//   final List<Npc> npcs;
//   final GameState state;
//   final void Function(
//     GameEventType,
//     String,
//     String, {
//     List<String>? involvedIds,
//     bool isMajor,
//   })
//   addEvent;

//   EventProcessor({
//     required this.rng,
//     required this.citadel,
//     required this.npcs,
//     required this.state,
//     required this.addEvent,
//   });

//   /// NPCs vivos
//   List<Npc> get aliveNpcs => npcs.where((n) => n.alive).toList();

//   /// População atual
//   int get population => aliveNpcs.length;

//   /// Tier atual da torre
//   int get currentTier =>
//       ((state.highestFloorCleared) ~/ 10) +
//       (state.highestFloorCleared % 10 > 0 ? 1 : 0);

//   /// Conta NPCs com determinada profissão
//   int countProfession(Profession profession) =>
//       aliveNpcs.where((n) => n.profession == profession).length;

//   /// Escolhe outro NPC diferente do fornecido
//   Npc pickOther(List<Npc> list, Npc exclude) {
//     final others = list.where((n) => n.id != exclude.id).toList();
//     return others[rng.nextInt(others.length)];
//   }
// }

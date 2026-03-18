// lib/services/rank_service.dart
//
// RankService — gerencia o sistema de estrelas e promoção de rank.
// Extraído de GameEngine para isolar responsabilidade.
// Depende de: npcs, citadel, state, _rng — injetados pelo GameEngine.

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:tower_ascension/models/npc_enums.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/game_event.dart';

class RankService {
  final Random _rng;

  RankService(this._rng);

  // ─────────────────────────────────────────────
  // ADICIONAR ESTRELA
  // ─────────────────────────────────────────────

  /// Valida e adiciona 1 estrela ao NPC alvo, consumindo 1 sacrificado do mesmo rank.
  /// Retorna mensagem de resultado + lista de eventos gerados.
  RankResult addStar({
    required String targetId,
    required String sacrificeId,
    required List<Npc> npcs,
    required Citadel citadel,
    required int currentDay,
    required int Function() nextDeathCount,
  }) {
    if (!citadel.hasBuilding(BuildingType.promotionHall)) {
      return RankResult.fail('Salão de Promoção não construído.');
    }

    final target = npcs.firstWhereOrNull((n) => n.id == targetId && n.alive);
    final sacrifice = npcs.firstWhereOrNull(
      (n) => n.id == sacrificeId && n.alive,
    );

    if (target == null) return RankResult.fail('NPC alvo não encontrado.');
    if (sacrifice == null) {
      return RankResult.fail('NPC sacrificado não encontrado.');
    }
    if (sacrifice.isFavorite) {
      return RankResult.fail('NPCs favoritos não podem ser sacrificados.');
    }
    if (sacrifice.id == target.id) {
      return RankResult.fail('Um NPC não pode se sacrificar.');
    }
    if (sacrifice.rank != target.rank) {
      return RankResult.fail('Sacrificado precisa ser do mesmo rank.');
    }
    if (target.stars >= 5) {
      return RankResult.fail(
        '${target.name} já está em 5★. Use Promover Rank.',
      );
    }

    final events = <ServiceEvent>[];

    // Consome o sacrificado
    final sacrificeEvents = _consumeSacrifice(
      sacrifice: sacrifice,
      beneficiary: target,
      npcs: npcs,
      currentDay: currentDay,
      nextDeathCount: nextDeathCount,
    );
    events.addAll(sacrificeEvents);

    target.stars++;
    target.history.add(
      '★ Ganhou estrela (${target.stars}/5) — '
      '${sacrifice.name} foi consumido. Dia $currentDay.',
    );

    events.add(
      ServiceEvent(
        type: GameEventType.upgrade,
        title:
            '${target.name} evoluiu para '
            '${target.rank.label}${'★' * target.stars}',
        description:
            '${sacrifice.name} foi sacrificado. '
            '${target.name} absorveu sua essência.',
        involvedNpcIds: [target.id, sacrifice.id],
        isMajor: target.stars == 5,
      ),
    );

    return RankResult.success(
      message:
          'Sucesso. ${target.name} agora é '
          '${target.rank.label}${'★' * target.stars}.',
      events: events,
    );
  }

  // ─────────────────────────────────────────────
  // PROMOVER RANK
  // ─────────────────────────────────────────────

  /// Tenta promover o rank do alvo. Requer 5★ e 3 sacrificados 5★ do mesmo rank.
  /// Retorna mensagem + eventos gerados.
  RankResult attemptPromotion({
    required String targetId,
    required List<String> sacrificeIds,
    required List<Npc> npcs,
    required Citadel citadel,
    required int currentDay,
    required int Function() nextDeathCount,
  }) {
    if (!citadel.hasBuilding(BuildingType.promotionHall)) {
      return RankResult.fail('Salão de Promoção não construído.');
    }
    if (sacrificeIds.length != 3) {
      return RankResult.fail('Exatamente 3 sacrificados são necessários.');
    }

    final target = npcs.firstWhereOrNull((n) => n.id == targetId && n.alive);
    if (target == null) return RankResult.fail('NPC alvo não encontrado.');
    if (target.stars < 5) {
      return RankResult.fail(
        '${target.name} precisa estar em 5★ para promover.',
      );
    }
    if (target.isPromoted) {
      return RankResult.fail(
        '${target.name} já foi promovido uma vez. Limite atingido.',
      );
    }
    if (target.rank == NpcRank.ssr) {
      return RankResult.fail('SSR é o rank máximo.');
    }

    final sacrifices = sacrificeIds
        .map((id) => npcs.firstWhereOrNull((n) => n.id == id && n.alive))
        .whereType<Npc>()
        .toList();

    if (sacrifices.length != 3) {
      return RankResult.fail('Um ou mais sacrificados não encontrados.');
    }

    for (final s in sacrifices) {
      if (s.isFavorite) {
        return RankResult.fail(
          '${s.name} é favorito e não pode ser sacrificado.',
        );
      }
      if (s.rank != target.rank) {
        return RankResult.fail(
          '${s.name} precisa ser do mesmo rank que o alvo.',
        );
      }
      if (s.stars < 5) {
        return RankResult.fail(
          '${s.name} precisa estar em 5★ para ser sacrificado na promoção.',
        );
      }
    }

    final chance = _calcChance(target, sacrifices);
    final newRank = NpcRank.values[target.rank.index + 1];
    final sacrificeNames = sacrifices.map((s) => s.name).join(', ');
    final events = <ServiceEvent>[];

    // Consome os 3 sacrificados independente do resultado
    for (final s in sacrifices) {
      events.addAll(
        _consumeSacrifice(
          sacrifice: s,
          beneficiary: target,
          npcs: npcs,
          currentDay: currentDay,
          nextDeathCount: nextDeathCount,
        ),
      );
    }

    if (_rng.nextDouble() < chance) {
      // SUCESSO
      target.rank = newRank;
      target.stars = 0;
      target.isPromoted = true;

      final roll = _rng.nextDouble();
      final newTrait =
          roll < 0.40
              ? PersonalityTrait.ambitious
              : roll < 0.70
              ? PersonalityTrait.loyal
              : PersonalityTrait.ruthless;
      if (!target.traits.contains(newTrait)) target.traits.add(newTrait);

      target.history.add(
        '◆ PROMOVIDO para ${newRank.label} — '
        '$sacrificeNames foram consumidos. Dia $currentDay.',
      );

      events.add(
        ServiceEvent(
          type: GameEventType.upgrade,
          title: '${target.name} promovido para ${newRank.label}★!',
          description:
              'O ritual foi concluído. $sacrificeNames desapareceram. '
              '${target.name} transcendeu. Traço adquirido: ${newTrait.label}.',
          involvedNpcIds: [target.id, ...sacrificeIds],
          isMajor: true,
        ),
      );

      return RankResult.success(
        message: 'SUCESSO. ${target.name} é agora ${newRank.label}★ (promovido).',
        events: events,
      );
    } else {
      // FALHA
      target.stars = 4;
      target.attributes.mentalStability =
          (target.attributes.mentalStability - 25).clamp(0, 100);
      target.traumas.add(
        'Sobreviveu ao ritual fracassado. '
        '$sacrificeNames se foram em vão. Dia $currentDay.',
      );

      events.add(
        ServiceEvent(
          type: GameEventType.mentalBreak,
          title: 'Ritual falhou — ${target.name} recuou',
          description:
              '$sacrificeNames foram consumidos mas a promoção não ocorreu. '
              '${target.name} voltou ao 4★ com traumas profundos.',
          involvedNpcIds: [target.id, ...sacrificeIds],
          isMajor: true,
        ),
      );

      return RankResult.success(
        message: 'FALHA. Os sacrifícios se foram. ${target.name} recuou para 4★.',
        events: events,
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  /// Calcula chance de promoção baseada nos atributos dos sacrificados vs alvo.
  double calcPromotionChance(Npc target, List<Npc> sacrifices) =>
      _calcChance(target, sacrifices);

  double _calcChance(Npc target, List<Npc> sacrifices) {
    if (sacrifices.isEmpty) return 0;
    final targetAvg = target.attributes.average;
    final sacrificeAvg =
        sacrifices.fold(0.0, (s, n) => s + n.attributes.average) /
        sacrifices.length;
    final ratio = (sacrificeAvg / targetAvg.clamp(1, 9999)).clamp(0.5, 2.0);

    final (min, max) = switch (target.rank) {
      NpcRank.n   => (0.50, 0.85),
      NpcRank.r   => (0.35, 0.70),
      NpcRank.sr  => (0.20, 0.50),
      NpcRank.ssr => (0.0,  0.0),
    };

    return (min + (max - min) * ((ratio - 0.5) / 1.5)).clamp(min, max);
  }

  /// Remove um NPC silenciosamente como sacrifício, gerando reações.
  List<ServiceEvent> _consumeSacrifice({
    required Npc sacrifice,
    required Npc beneficiary,
    required List<Npc> npcs,
    required int currentDay,
    required int Function() nextDeathCount,
  }) {
    sacrifice.alive = false;
    sacrifice.history.add(
      'Sacrificado no ritual de promoção de ${beneficiary.name}. '
      'Dia $currentDay.',
    );
    nextDeathCount();

    final events = <ServiceEvent>[];

    if (sacrifice.partnerId != null) {
      final partner = npcs.firstWhereOrNull(
        (n) => n.id == sacrifice.partnerId,
      );
      if (partner != null && partner.alive) {
        partner.attributes.mentalStability =
            (partner.attributes.mentalStability - 30).clamp(0, 100);
        partner.loyalty = (partner.loyalty - 15).clamp(0, 100);
        partner.traumas.add(
          '${sacrifice.name} foi sacrificado no ritual. Dia $currentDay.',
        );
        partner.wantsToLeave = true;
        partner.wantsToLeaveDay = currentDay;
      }
    }

    for (final childId in sacrifice.childrenIds) {
      final child = npcs.firstWhereOrNull(
        (n) => n.id == childId && n.alive,
      );
      if (child != null) {
        child.attributes.mentalStability =
            (child.attributes.mentalStability - 20).clamp(0, 100);
        child.traumas.add(
          '${sacrifice.name} foi sacrificado. Dia $currentDay.',
        );
      }
    }

    for (final other in npcs.where((n) => n.alive && n.id != sacrifice.id)) {
      final rel = other.relationships.firstWhereOrNull(
        (r) => r.targetId == sacrifice.id && r.affinity > 0.6,
      );
      if (rel != null) {
        other.attributes.mentalStability =
            (other.attributes.mentalStability - 15).clamp(0, 100);
        other.loyalty = (other.loyalty - 10).clamp(0, 100);
        other.traumas.add(
          'Perdeu ${sacrifice.name} num ritual. Dia $currentDay.',
        );
      }
    }

    return events;
  }
}

// ─────────────────────────────────────────────
// RESULTADO DO RANK SERVICE
// ─────────────────────────────────────────────

class RankResult {
  final bool succeeded;
  final String message;
  final List<ServiceEvent> events;

  const RankResult._({
    required this.succeeded,
    required this.message,
    required this.events,
  });

  factory RankResult.success({
    required String message,
    required List<ServiceEvent> events,
  }) => RankResult._(succeeded: true, message: message, events: events);

  factory RankResult.fail(String message) =>
      RankResult._(succeeded: false, message: message, events: const []);
}
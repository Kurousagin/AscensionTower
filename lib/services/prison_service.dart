// lib/services/prison_service.dart
//
// Gerencia: registro de crimes, rumores da taverna, abertura de
// julgamentos, votos dos jurados, sentenças e soltura automática.

import 'dart:math';
import 'package:tower_ascension/models/npc_enums.dart';

import '../models/prison.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/game_event.dart';

class PrisonService {
  final List<CrimeRecord> _crimes = [];
  final List<Trial> _trials = [];
  final List<PrisonCell> _cells = [];
  int _crimeIdCounter = 0;
  int _trialIdCounter = 0;

  // ── Accessors ─────────────────────────────────────────────

  List<CrimeRecord> get allCrimes => List.unmodifiable(_crimes);
  List<Trial> get allTrials => List.unmodifiable(_trials);
  List<Trial> get pendingTrials => _trials.where((t) => !t.isComplete).toList();
  List<PrisonCell> get cells => List.unmodifiable(_cells);

  bool isImprisoned(String npcId) => _cells.any((c) => c.npcId == npcId);
  bool isOnTrial(String npcId) =>
      _trials.any((t) => t.accusedId == npcId && !t.isComplete);

  PrisonCell? cellOf(String npcId) =>
      _cells.where((c) => c.npcId == npcId).firstOrNull;

  Trial? trialOf(String npcId) =>
      _trials.where((t) => t.accusedId == npcId && !t.isComplete).firstOrNull;

  List<CrimeRecord> crimesOf(String npcId) =>
      _crimes.where((c) => c.npcId == npcId).toList();

  int witnessedCrimesOf(String npcId) =>
      _crimes.where((c) => c.npcId == npcId && c.witnessed).length;

  // ── Registro de crime ──────────────────────────────────────
  // Chamado pelo GameEngine em _executeBetrayal / _processMentalBreak

  CrimeRecord recordCrime({
    required String npcId,
    required CrimeType type,
    required int day,
    bool witnessed = false,
  }) {
    _crimeIdCounter++;
    final record = CrimeRecord(
      id: 'crime_$_crimeIdCounter',
      npcId: npcId,
      type: type,
      day: day,
      witnessed: witnessed,
    );
    _crimes.add(record);
    return record;
  }

  // ── Rumor da Taverna ───────────────────────────────────────
  // Chamado pelo GameEngine em _processTavernEvents.
  // Tem chance de expor um crime não-testemunhado como testemunhado.
  // Retorna o crime exposto (se houver) para o engine gerar evento.

  CrimeRecord? spreadRumor(String npcId, Random rng) {
    final hidden = _crimes
        .where((c) => c.npcId == npcId && !c.witnessed && !c.rumorSpread)
        .toList();
    if (hidden.isEmpty) return null;

    // Seleciona o crime mais grave ainda oculto
    hidden.sort((a, b) => b.type.severity.compareTo(a.type.severity));
    final exposed = hidden.first;
    exposed.rumorSpread = true;

    // 60% de chance de o rumor ser suficiente para contar como evidência
    if (rng.nextDouble() < 0.6) {
      exposed.witnessed = true;
    }
    return exposed;
  }

  // ── Verificar se deve abrir julgamento automaticamente ─────
  // Retorna true se as evidências atingiram o threshold do crime

  bool shouldOpenTrial(String npcId) {
    if (isImprisoned(npcId) || isOnTrial(npcId)) return false;
    final witnessed = _crimes
        .where((c) => c.npcId == npcId && c.witnessed)
        .toList();
    if (witnessed.isEmpty) return false;
    // Pega o crime mais grave com evidências
    witnessed.sort((a, b) => b.type.severity.compareTo(a.type.severity));
    final worst = witnessed.first;
    final count = witnessed.where((c) => c.type == worst.type).length;
    return count >= worst.type.evidenceRequired;
  }

  // ── Abrir julgamento ───────────────────────────────────────

  (ArrestResult, Trial?) openTrial({
    required String npcId,
    required List<Npc> allNpcs,
    required Citadel citadel,
    required int currentDay,
    required Random rng,
  }) {
    if (!citadel.hasBuilding(BuildingType.councilHall)) {
      return (ArrestResult.noCouncilHall, null);
    }
    if (!citadel.hasBuilding(BuildingType.prison)) {
      return (ArrestResult.noPrison, null);
    }
    if (isImprisoned(npcId)) {
      return (ArrestResult.alreadyImprisoned, null);
    }
    if (isOnTrial(npcId)) {
      return (ArrestResult.alreadyOnTrial, null);
    }

    final evidence = _crimes
        .where((c) => c.npcId == npcId && c.witnessed)
        .toList();
    if (evidence.isEmpty) {
      return (ArrestResult.noCrimeEvidence, null);
    }

    evidence.sort((a, b) => b.type.severity.compareTo(a.type.severity));
    final primaryCrime = evidence.first.type;

    // Seleciona jurados: NPCs vivos, não acusados, com preferência por
    // líderes, membros do conselho e npcs com alta lealdade
    final candidates = allNpcs
        .where(
          (n) =>
              n.alive &&
              n.id != npcId &&
              !isImprisoned(n.id) &&
              n.growthStage(currentDay) == GrowthStage.adult,
        )
        .toList();

    candidates.sort((a, b) {
      double scoreA = a.loyalty * 0.3 + a.attributes.charisma * 0.4;
      double scoreB = b.loyalty * 0.3 + b.attributes.charisma * 0.4;
      if (a.profession == Profession.teacher ||
          a.profession == Profession.scribe) {
        scoreA += 20;
      }
      if (b.profession == Profession.teacher ||
          b.profession == Profession.scribe) {
        scoreB += 20;
      }
      if (a.leaderOfGroupId != null) scoreA += 15;
      if (b.leaderOfGroupId != null) scoreB += 15;
      return scoreB.compareTo(scoreA);
    });

    final jurorCount = min(5, candidates.length);
    if (jurorCount == 0) return (ArrestResult.noCrimeEvidence, null);

    final jurors = candidates.take(jurorCount).map((n) => n.id).toList();

    _trialIdCounter++;
    final trial = Trial(
      id: 'trial_$_trialIdCounter',
      accusedId: npcId,
      primaryCrime: primaryCrime,
      evidence: evidence,
      dayStarted: currentDay,
      jurorIds: jurors,
    );
    _trials.add(trial);

    return (ArrestResult.trialOpened, trial);
  }

  // ── Processar votos dos jurados (chamado no simulateDay) ───

  List<GameEvent> processTrialVotes({
    required List<Npc> allNpcs,
    required int currentDay,
    required Random rng,
    required int Function() generateEventId,
  }) {
    final events = <GameEvent>[];

    for (final trial in pendingTrials) {
      if (trial.isComplete) continue;

      final accused = allNpcs.firstWhereOrNull((n) => n.id == trial.accusedId);
      if (accused == null) {
        // NPC morreu antes do julgamento — encerra
        trial.verdict = TrialVerdict.notGuilty;
        continue;
      }

      // Jurados que ainda não votaram
      final pendingJurors = trial.jurorIds
          .where((id) => !trial.votes.any((v) => v.npcId == id))
          .toList();

      for (final jurorId in pendingJurors) {
        final juror = allNpcs.firstWhereOrNull(
          (n) => n.id == jurorId && n.alive,
        );
        if (juror == null) continue;

        // 1 jurado vota por dia (dramatismo)
        if (rng.nextDouble() > 0.6) continue;

        final vote = _generateJurorVote(juror, accused, trial, rng);
        trial.votes.add(vote);

        events.add(
          GameEvent(
            id: 'evt_${generateEventId()}',
            day: currentDay,
            type: GameEventType.politicalEvent,
            title: 'Voto no Julgamento',
            description:
                '${juror.name} votou: ${vote.guiltyVote ? "CULPADO" : "INOCENTE"}. "${vote.reason}"',
            involvedNpcIds: [jurorId, trial.accusedId],
          ),
        );

        break; // só 1 voto por dia por julgamento
      }

      // Verifica se todos votaram ou se passou muito tempo (3 dias máx)
      final daysElapsed = currentDay - trial.dayStarted;
      if (trial.allVoted || daysElapsed >= 3) {
        final resolved = _resolveVerdict(
          trial,
          accused,
          allNpcs,
          rng,
          currentDay: currentDay,
        );
        events.addAll(
          resolved.map(
            (e) => GameEvent(
              id: 'evt_${generateEventId()}',
              day: currentDay,
              type: GameEventType.politicalEvent,
              title: e.title,
              description: e.description,
              involvedNpcIds: e.involvedNpcIds,
              isMajor: e.isMajor,
            ),
          ),
        );
      }
    }

    return events;
  }

  // ── Voto individual do jurado ──────────────────────────────

  JurorVote _generateJurorVote(
    Npc juror,
    Npc accused,
    Trial trial,
    Random rng,
  ) {
    // Base: mais evidências = mais votos culpado
    double guiltyChance = 0.4 + (trial.evidence.length * 0.15);

    // Relação entre jurado e acusado
    final rel = juror.relationships
        .where((r) => r.targetId == accused.id)
        .firstOrNull;
    if (rel != null) {
      if (rel.affinity > 0.5) guiltyChance -= 0.25; // amigos defendem
      if (rel.affinity < -0.2) guiltyChance += 0.20; // inimigos condenam
    }

    // Personalidade do jurado
    if (juror.traits.contains(PersonalityTrait.analytical)) {
      guiltyChance += 0.10;
    }
    if (juror.traits.contains(PersonalityTrait.compassionate)) {
      guiltyChance -= 0.15;
    }
    if (juror.traits.contains(PersonalityTrait.pragmatic)) guiltyChance += 0.10;
    if (juror.traits.contains(PersonalityTrait.ruthless)) guiltyChance += 0.20;
    if (juror.traits.contains(PersonalityTrait.optimist)) guiltyChance -= 0.10;
    if (juror.traits.contains(PersonalityTrait.pessimist)) guiltyChance += 0.05;

    // Crime grave aumenta chance de culpado
    guiltyChance += trial.primaryCrime.severity * 0.08;

    guiltyChance = guiltyChance.clamp(0.05, 0.95);
    final isGuilty = rng.nextDouble() < guiltyChance;

    final reason = _jurorReason(juror, accused, trial, isGuilty, rng);
    return JurorVote(npcId: juror.id, guiltyVote: isGuilty, reason: reason);
  }

  String _jurorReason(
    Npc juror,
    Npc accused,
    Trial trial,
    bool guilty,
    Random rng,
  ) {
    if (guilty) {
      final guiltyReasons = [
        'As evidencias sao claras demais para ignorar.',
        'Ja ouvi rumores sobre ${accused.name} ha muito tempo.',
        'A cidadela nao pode tolerar este comportamento.',
        'O crime e grave. A pena deve ser proporcional.',
        '${accused.name} e uma ameaca para todos nos.',
        'Vi com meus proprios olhos o que ${accused.name} e capaz.',
      ];
      if (trial.primaryCrime == CrimeType.assassination) {
        return 'Assassinato nao tem desculpa. ${accused.name} deve pagar.';
      }
      return guiltyReasons[rng.nextInt(guiltyReasons.length)];
    } else {
      final innocentReasons = [
        'Nao ha provas suficientes. Pode ser engano.',
        'Conheco ${accused.name}. Ele(a) nao faria isso.',
        'Todos merecem uma segunda chance.',
        'As circunstancias eram dificeis para todos.',
        'Rumores da taverna nao sao fatos.',
        'Precisamos de mais investigacao antes de condenar.',
      ];
      if (juror.traits.contains(PersonalityTrait.compassionate)) {
        return 'Punir um inocente seria pior que deixar o culpado livre.';
      }
      return innocentReasons[rng.nextInt(innocentReasons.length)];
    }
  }

  // ── Resolver veredicto final ───────────────────────────────

  List<_EventData> _resolveVerdict(
    Trial trial,
    Npc accused,
    List<Npc> allNpcs,
    Random rng, {
    int currentDay = 0,
  }) {
    final events = <_EventData>[];
    final guilty = trial.guiltyVotes;
    final notGuilty = trial.notGuiltyVotes;
    final total = trial.votes.length;

    // Maioria simples decide; empate = inocente (benefício da dúvida)
    // Crime capital (assassinato) requer maioria qualificada (>60%)
    bool isGuilty;
    if (trial.primaryCrime == CrimeType.assassination) {
      isGuilty = total > 0 && (guilty / total) > 0.6;
    } else {
      isGuilty = guilty > notGuilty;
    }

    // Exílio: assassinato com votação unânime ou quase
    final isExile =
        trial.primaryCrime == CrimeType.assassination &&
        isGuilty &&
        (guilty / max(1, total)) >= 0.8;

    if (!isGuilty) {
      trial.verdict = TrialVerdict.notGuilty;
      accused.loyalty += 5;
      accused.fame += 2;
      events.add(
        _EventData(
          title: 'Julgamento: ${accused.name} INOCENTE',
          description:
              'O conselho declarou ${accused.name} inocente ($notGuilty x $guilty). '
              'Liberado(a) sem acusações formais.',
          involvedNpcIds: [accused.id, ...trial.jurorIds],
          isMajor: true,
        ),
      );
    } else if (isExile) {
      trial.verdict = TrialVerdict.exile;
      accused.alive = false; // exilado = removido
      events.add(
        _EventData(
          title: 'EXILIO: ${accused.name} banido!',
          description:
              'O conselho votou EXILIO por unanimidade ($guilty x $notGuilty). '
              '${accused.name} foi expulso da cidadela permanentemente.',
          involvedNpcIds: [accused.id, ...trial.jurorIds],
          isMajor: true,
        ),
      );
    } else {
      trial.verdict = TrialVerdict.guilty;
      // Calcula sentença: base + agravantes por reincidência
      final priorConvictions = _trials
          .where(
            (t) =>
                t.accusedId == accused.id &&
                t.verdict == TrialVerdict.guilty &&
                t.id != trial.id,
          )
          .length;
      trial.sentenceDays =
          trial.primaryCrime.baseSentenceDays + (priorConvictions * 3);

      _cells.add(
        PrisonCell(
          npcId: accused.id,
          dayImprisoned: currentDay, // ← usa o parâmetro
          sentenceDays: trial.sentenceDays,
          primaryCrime: trial.primaryCrime,
          verdict:
              '${trial.primaryCrime.label} — ${guilty}x$notGuilty votos — ${trial.sentenceDays} dias',
          trialId: trial.id,
        ),
      );

      accused.loyalty -= 15;
      accused.fame -= 10;
      accused.traumas.add(
        'Preso por ${trial.primaryCrime.label} no dia 0',
      ); // engine substituirá 0

      events.add(
        _EventData(
          title: 'PRESO: ${accused.name} condenado!',
          description:
              'O conselho declarou ${accused.name} CULPADO ($guilty x $notGuilty) '
              'por ${trial.primaryCrime.label}. Sentenca: ${trial.sentenceDays} dias de prisao.',
          involvedNpcIds: [accused.id, ...trial.jurorIds],
          isMajor: true,
        ),
      );
    }

    return events;
  }

  // ── Processar soltura automática ───────────────────────────

  List<String> processReleases(int currentDay) {
    final released = <String>[];
    final expired = _cells.where((c) => c.isExpired(currentDay)).toList();
    for (final cell in expired) {
      _cells.remove(cell);
      released.add(cell.npcId);
    }
    return released;
  }

  // ── Prender manualmente (ação do jogador) ──────────────────

  ArrestResult arrestManually({
    required String npcId,
    required List<Npc> allNpcs,
    required Citadel citadel,
    required int currentDay,
    required Random rng,
  }) {
    if (!citadel.hasBuilding(BuildingType.councilHall)) {
      return ArrestResult.noCouncilHall;
    }
    if (!citadel.hasBuilding(BuildingType.prison)) {
      return ArrestResult.noPrison;
    }
    if (isImprisoned(npcId)) return ArrestResult.alreadyImprisoned;
    if (isOnTrial(npcId)) return ArrestResult.alreadyOnTrial;

    final evidence = _crimes
        .where((c) => c.npcId == npcId && c.witnessed)
        .toList();
    if (evidence.isEmpty) return ArrestResult.noCrimeEvidence;

    return ArrestResult.trialOpened; // engine chama openTrial em seguida
  }

  // ── Voto do jogador ────────────────────────────────────────

  bool playerVote({required String trialId, required bool guiltyVote}) {
    final trial = _trials.firstWhereOrNull((t) => t.id == trialId);
    if (trial == null || trial.isComplete || trial.playerHasVoted) return false;
    trial.playerHasVoted = true;
    // Voto do jogador vale como 2 votos (influência do líder)
    trial.votes.add(
      JurorVote(
        npcId: 'player',
        guiltyVote: guiltyVote,
        reason: guiltyVote
            ? 'O lider da cidadela exige justica.'
            : 'O lider concede clemencia.',
      ),
    );
    if (guiltyVote) {
      trial.votes.add(
        JurorVote(
          npcId: 'player_weight',
          guiltyVote: true,
          reason: '(peso da lideranca)',
        ),
      );
    }
    return true;
  }

  // ── Soltura antecipada (graça do jogador) ──────────────────

  ReleaseResult releaseEarly(String npcId) {
    final cell = _cells.firstWhereOrNull((c) => c.npcId == npcId);
    if (cell == null) return ReleaseResult.notImprisoned;
    _cells.remove(cell);
    return ReleaseResult.released;
  }

  // ── Limpar dados ao iniciar novo jogo ─────────────────────

  void clear() {
    _crimes.clear();
    _trials.clear();
    _cells.clear();
    _crimeIdCounter = 0;
    _trialIdCounter = 0;
  }

  // ── Serialização ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'crimes': _crimes.map((c) => c.toJson()).toList(),
    'trials': _trials.map((t) => t.toJson()).toList(),
    'cells': _cells.map((c) => c.toJson()).toList(),
    'crimeIdCounter': _crimeIdCounter,
    'trialIdCounter': _trialIdCounter,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _crimes
      ..clear()
      ..addAll(
        (json['crimes'] as List<dynamic>? ?? []).map(
          (e) => CrimeRecord.fromJson(e as Map<String, dynamic>),
        ),
      );
    _trials
      ..clear()
      ..addAll(
        (json['trials'] as List<dynamic>? ?? []).map(
          (e) => Trial.fromJson(e as Map<String, dynamic>),
        ),
      );
    _cells
      ..clear()
      ..addAll(
        (json['cells'] as List<dynamic>? ?? []).map(
          (e) => PrisonCell.fromJson(e as Map<String, dynamic>),
        ),
      );
    _crimeIdCounter = json['crimeIdCounter'] as int? ?? 0;
    _trialIdCounter = json['trialIdCounter'] as int? ?? 0;
  }
}

// helper interno
class _EventData {
  final String title;
  final String description;
  final List<String> involvedNpcIds;
  final bool isMajor;
  _EventData({
    required this.title,
    required this.description,
    required this.involvedNpcIds,
    this.isMajor = false,
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }

  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

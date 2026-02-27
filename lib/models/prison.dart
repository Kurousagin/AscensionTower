// lib/models/prison.dart

enum CrimeType {
  theft,
  sabotage,
  assassination,
  rebellion,
  manipulation,
}

extension CrimeTypeExt on CrimeType {
  String get label {
    switch (this) {
      case CrimeType.theft:         return 'Roubo';
      case CrimeType.sabotage:      return 'Sabotagem';
      case CrimeType.assassination: return 'Assassinato';
      case CrimeType.rebellion:     return 'Rebeliao';
      case CrimeType.manipulation:  return 'Manipulacao';
    }
  }

  int get severity {
    switch (this) {
      case CrimeType.theft:         return 1;
      case CrimeType.manipulation:  return 2;
      case CrimeType.sabotage:      return 2;
      case CrimeType.rebellion:     return 3;
      case CrimeType.assassination: return 4;
    }
  }

  int get baseSentenceDays {
    switch (this) {
      case CrimeType.theft:         return 3;
      case CrimeType.manipulation:  return 4;
      case CrimeType.sabotage:      return 5;
      case CrimeType.rebellion:     return 7;
      case CrimeType.assassination: return 14;
    }
  }

  int get evidenceRequired {
    switch (this) {
      case CrimeType.theft:         return 2;
      case CrimeType.manipulation:  return 2;
      case CrimeType.sabotage:      return 1;
      case CrimeType.rebellion:     return 1;
      case CrimeType.assassination: return 1;
    }
  }
}

// ── Crime Record ────────────────────────────────────────────

class CrimeRecord {
  final String id;
  final String npcId;
  final CrimeType type;
  final int day;
  bool witnessed;
  bool rumorSpread;

  CrimeRecord({
    required this.id,
    required this.npcId,
    required this.type,
    required this.day,
    this.witnessed = false,
    this.rumorSpread = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'npcId': npcId, 'type': type.index,
        'day': day, 'witnessed': witnessed, 'rumorSpread': rumorSpread,
      };

  factory CrimeRecord.fromJson(Map<String, dynamic> j) => CrimeRecord(
        id: j['id'] as String? ?? '',
        npcId: j['npcId'] as String? ?? '',
        type: CrimeType.values[(j['type'] as int? ?? 0)
            .clamp(0, CrimeType.values.length - 1)],
        day: j['day'] as int? ?? 0,
        witnessed: j['witnessed'] as bool? ?? false,
        rumorSpread: j['rumorSpread'] as bool? ?? false,
      );
}

// ── Trial ───────────────────────────────────────────────────

enum TrialVerdict { pending, guilty, notGuilty, exile }

extension TrialVerdictExt on TrialVerdict {
  String get label {
    switch (this) {
      case TrialVerdict.pending:   return 'Em julgamento';
      case TrialVerdict.guilty:    return 'Culpado';
      case TrialVerdict.notGuilty: return 'Inocente';
      case TrialVerdict.exile:     return 'Exilio';
    }
  }
}

class JurorVote {
  final String npcId;
  final bool guiltyVote;
  final String reason;

  JurorVote({required this.npcId, required this.guiltyVote, required this.reason});

  Map<String, dynamic> toJson() =>
      {'npcId': npcId, 'guiltyVote': guiltyVote, 'reason': reason};

  factory JurorVote.fromJson(Map<String, dynamic> j) => JurorVote(
        npcId: j['npcId'] as String? ?? '',
        guiltyVote: j['guiltyVote'] as bool? ?? true,
        reason: j['reason'] as String? ?? '',
      );
}

class Trial {
  final String id;
  final String accusedId;
  final CrimeType primaryCrime;
  final List<CrimeRecord> evidence;
  final int dayStarted;
  final List<String> jurorIds;
  List<JurorVote> votes;
  TrialVerdict verdict;
  int sentenceDays;
  bool playerHasVoted;

  Trial({
    required this.id,
    required this.accusedId,
    required this.primaryCrime,
    required this.evidence,
    required this.dayStarted,
    required this.jurorIds,
    List<JurorVote>? votes,
    this.verdict = TrialVerdict.pending,
    this.sentenceDays = 0,
    this.playerHasVoted = false,
  }) : votes = votes ?? [];

  int get guiltyVotes    => votes.where((v) => v.guiltyVote).length;
  int get notGuiltyVotes => votes.where((v) => !v.guiltyVote).length;
  bool get isComplete    => verdict != TrialVerdict.pending;
  bool get allVoted      => votes.length >= jurorIds.length;

  Map<String, dynamic> toJson() => {
        'id': id, 'accusedId': accusedId,
        'primaryCrime': primaryCrime.index,
        'evidence': evidence.map((e) => e.toJson()).toList(),
        'dayStarted': dayStarted, 'jurorIds': jurorIds,
        'votes': votes.map((v) => v.toJson()).toList(),
        'verdict': verdict.index, 'sentenceDays': sentenceDays,
        'playerHasVoted': playerHasVoted,
      };

  factory Trial.fromJson(Map<String, dynamic> j) => Trial(
        id: j['id'] as String? ?? '',
        accusedId: j['accusedId'] as String? ?? '',
        primaryCrime: CrimeType.values[(j['primaryCrime'] as int? ?? 0)
            .clamp(0, CrimeType.values.length - 1)],
        evidence: (j['evidence'] as List<dynamic>? ?? [])
            .map((e) => CrimeRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        dayStarted: j['dayStarted'] as int? ?? 0,
        jurorIds: (j['jurorIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString()).toList(),
        votes: (j['votes'] as List<dynamic>? ?? [])
            .map((v) => JurorVote.fromJson(v as Map<String, dynamic>))
            .toList(),
        verdict: TrialVerdict.values[(j['verdict'] as int? ?? 0)
            .clamp(0, TrialVerdict.values.length - 1)],
        sentenceDays: j['sentenceDays'] as int? ?? 0,
        playerHasVoted: j['playerHasVoted'] as bool? ?? false,
      );
}

// ── Prison Cell ─────────────────────────────────────────────

class PrisonCell {
  final String npcId;
  final int dayImprisoned;
  int sentenceDays;
  final CrimeType primaryCrime;
  final String verdict;
  final String trialId;

  PrisonCell({
    required this.npcId,
    required this.dayImprisoned,
    required this.sentenceDays,
    required this.primaryCrime,
    required this.verdict,
    required this.trialId,
  });

  int remainingDays(int currentDay) =>
      (dayImprisoned + sentenceDays - currentDay).clamp(0, 9999);
  bool isExpired(int currentDay) =>
      currentDay >= dayImprisoned + sentenceDays;

  Map<String, dynamic> toJson() => {
        'npcId': npcId, 'dayImprisoned': dayImprisoned,
        'sentenceDays': sentenceDays, 'primaryCrime': primaryCrime.index,
        'verdict': verdict, 'trialId': trialId,
      };

  factory PrisonCell.fromJson(Map<String, dynamic> j) => PrisonCell(
        npcId: j['npcId'] as String? ?? '',
        dayImprisoned: j['dayImprisoned'] as int? ?? 0,
        sentenceDays: j['sentenceDays'] as int? ?? 1,
        primaryCrime: CrimeType.values[(j['primaryCrime'] as int? ?? 0)
            .clamp(0, CrimeType.values.length - 1)],
        verdict: j['verdict'] as String? ?? '',
        trialId: j['trialId'] as String? ?? '',
      );
}

// ── Results ─────────────────────────────────────────────────

enum ArrestResult {
  trialOpened,
  noCouncilHall,
  noPrison,
  noCrimeEvidence,
  alreadyImprisoned,
  alreadyOnTrial,
  notFound,
}

extension ArrestResultExt on ArrestResult {
  String get message {
    switch (this) {
      case ArrestResult.trialOpened:
        return 'Julgamento aberto. O conselho vai se reunir.';
      case ArrestResult.noCouncilHall:
        return 'Construa a Sala do Conselho para realizar julgamentos.';
      case ArrestResult.noPrison:
        return 'Construa uma Prisao para deter criminosos.';
      case ArrestResult.noCrimeEvidence:
        return 'Nao ha evidencias suficientes ainda.';
      case ArrestResult.alreadyImprisoned:
        return 'Este NPC ja esta detido.';
      case ArrestResult.alreadyOnTrial:
        return 'Este NPC ja esta sendo julgado pelo conselho.';
      case ArrestResult.notFound:
        return 'NPC nao encontrado.';
    }
  }
}

enum ReleaseResult { released, notImprisoned, notFound }
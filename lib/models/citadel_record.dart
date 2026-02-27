// lib/models/citadel_record.dart

enum RecordCategory {
  crime,
  death,
  birth,
  construction,
  towerConquest,
  political,
  honor,
  exile,
  punishment,
  decree,
}

extension RecordCategoryExt on RecordCategory {
  String get label {
    switch (this) {
      case RecordCategory.crime: return 'CRIME';
      case RecordCategory.death: return 'OBITO';
      case RecordCategory.birth: return 'NASCIMENTO';
      case RecordCategory.construction: return 'CONSTRUCAO';
      case RecordCategory.towerConquest: return 'CONQUISTA';
      case RecordCategory.political: return 'DECRETO';
      case RecordCategory.honor: return 'HONRARIA';
      case RecordCategory.exile: return 'EXILIO';
      case RecordCategory.punishment: return 'PUNICAO';
      case RecordCategory.decree: return 'ORDEM';
    }
  }

  String get colorHex {
    switch (this) {
      case RecordCategory.crime: return '#FF2244';
      case RecordCategory.death: return '#CC4444';
      case RecordCategory.birth: return '#44FF88';
      case RecordCategory.construction: return '#88AAFF';
      case RecordCategory.towerConquest: return '#FFDD44';
      case RecordCategory.political: return '#DDAA66';
      case RecordCategory.honor: return '#FFD700';
      case RecordCategory.exile: return '#FF8844';
      case RecordCategory.punishment: return '#FF4466';
      case RecordCategory.decree: return '#88CCFF';
    }
  }
}

class CitadelRecord {
  final String id;
  final int day;
  final RecordCategory category;
  final String title;
  final String body;
  final List<String> involvedIds;
  final bool isSigned; // "assinado" pela liderança
  final String? verdict; // para crimes/punicoes
  final int timestamp;

  CitadelRecord({
    required this.id,
    required this.day,
    required this.category,
    required this.title,
    required this.body,
    this.involvedIds = const [],
    this.isSigned = false,
    this.verdict,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'category': category.index,
        'title': title,
        'body': body,
        'involvedIds': involvedIds,
        'isSigned': isSigned,
        'verdict': verdict,
        'timestamp': timestamp,
      };

  factory CitadelRecord.fromJson(Map<String, dynamic> json) => CitadelRecord(
        id: json['id'] as String? ?? '',
        day: json['day'] as int? ?? 0,
        category: RecordCategory.values[
            (json['category'] as int? ?? 0).clamp(0, RecordCategory.values.length - 1)],
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        involvedIds: (json['involvedIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isSigned: json['isSigned'] as bool? ?? false,
        verdict: json['verdict'] as String?,
        timestamp: json['timestamp'] as int?,
      );
}
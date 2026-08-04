import 'package:uuid/uuid.dart';

class IeltsScore {
  final String id;
  final String? sessionId;
  final double fluency;
  final double lexical;
  final double grammar;
  final double pronunciation;
  final double overall;
  final String part; // 'part1' | 'part2' | 'part3' | 'full'
  final DateTime createdAt;

  IeltsScore({
    String? id,
    this.sessionId,
    required this.fluency,
    required this.lexical,
    required this.grammar,
    required this.pronunciation,
    required this.overall,
    this.part = 'full',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get bandLabel {
    if (overall >= 8.5) return 'Expert (9)';
    if (overall >= 7.5) return 'Very Good (8)';
    if (overall >= 6.5) return 'Good (7)';
    if (overall >= 5.5) return 'Competent (6)';
    if (overall >= 4.5) return 'Modest (5)';
    return 'Limited (4)';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'fluency': fluency,
        'lexical': lexical,
        'grammar': grammar,
        'pronunciation': pronunciation,
        'overall': overall,
        'part': part,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory IeltsScore.fromMap(Map<String, dynamic> map) => IeltsScore(
        id: map['id'],
        sessionId: map['session_id'],
        fluency: (map['fluency'] as num).toDouble(),
        lexical: (map['lexical'] as num).toDouble(),
        grammar: (map['grammar'] as num).toDouble(),
        pronunciation: (map['pronunciation'] as num).toDouble(),
        overall: (map['overall'] as num).toDouble(),
        part: map['part'] ?? 'full',
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      );
}

class PronunciationResult {
  final String id;
  final String? sessionId;
  final String text;
  final double accuracy;
  final double fluency;
  final double speedWpm;
  final int fillerCount;
  final int pauseCount;
  final double confidence;
  final DateTime createdAt;

  PronunciationResult({
    String? id,
    this.sessionId,
    required this.text,
    required this.accuracy,
    required this.fluency,
    required this.speedWpm,
    required this.fillerCount,
    required this.pauseCount,
    required this.confidence,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get overallScore => (accuracy * 0.35 + fluency * 0.30 + confidence * 0.20 +
      (speedWpm >= 100 && speedWpm <= 160 ? 1.0 : 0.5) * 0.15) * 100;
}

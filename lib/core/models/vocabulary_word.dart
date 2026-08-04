class VocabularyWord {
  final String word;
  final String definition;
  final String? example;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? ipa;
  final String? level; // A1, A2, B1, B2, C1, C2
  // Spaced repetition (SM-2)
  int sm2Interval;
  int sm2Repetitions;
  double sm2Ease;
  DateTime? nextReview;
  bool learned;

  VocabularyWord({
    required this.word,
    required this.definition,
    this.example,
    List<String>? synonyms,
    List<String>? antonyms,
    this.ipa,
    this.level,
    this.sm2Interval = 1,
    this.sm2Repetitions = 0,
    this.sm2Ease = 2.5,
    this.nextReview,
    this.learned = false,
  })  : synonyms = synonyms ?? [],
        antonyms = antonyms ?? [];

  /// SM-2 algorithm: quality 0-5
  void applyReview(int quality) {
    if (quality < 3) {
      sm2Repetitions = 0;
      sm2Interval = 1;
    } else {
      if (sm2Repetitions == 0) sm2Interval = 1;
      else if (sm2Repetitions == 1) sm2Interval = 6;
      else sm2Interval = (sm2Interval * sm2Ease).round();
      sm2Repetitions++;
    }
    sm2Ease = (sm2Ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        .clamp(1.3, 2.5);
    nextReview = DateTime.now().add(Duration(days: sm2Interval));
    if (sm2Repetitions >= 3) learned = true;
  }

  Map<String, dynamic> toMap() => {
        'word': word,
        'definition': definition,
        'example': example,
        'synonyms': synonyms.join(','),
        'antonyms': antonyms.join(','),
        'ipa': ipa,
        'level': level,
        'sm2_interval': sm2Interval,
        'sm2_repetitions': sm2Repetitions,
        'sm2_ease': sm2Ease,
        'next_review': nextReview?.millisecondsSinceEpoch,
        'learned': learned ? 1 : 0,
      };

  factory VocabularyWord.fromMap(Map<String, dynamic> map) => VocabularyWord(
        word: map['word'],
        definition: map['definition'],
        example: map['example'],
        synonyms: (map['synonyms'] as String? ?? '').isEmpty
            ? []
            : (map['synonyms'] as String).split(','),
        antonyms: (map['antonyms'] as String? ?? '').isEmpty
            ? []
            : (map['antonyms'] as String).split(','),
        ipa: map['ipa'],
        level: map['level'],
        sm2Interval: map['sm2_interval'] ?? 1,
        sm2Repetitions: map['sm2_repetitions'] ?? 0,
        sm2Ease: (map['sm2_ease'] as num? ?? 2.5).toDouble(),
        nextReview: map['next_review'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['next_review'])
            : null,
        learned: (map['learned'] ?? 0) == 1,
      );
}

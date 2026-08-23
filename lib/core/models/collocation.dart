class CollocationMatch {
  final String phrase;
  final String cefrLevel; // B2, C1, C2
  final String category; // academic, business, daily
  final String definition;
  final String exampleSentence;

  const CollocationMatch({
    required this.phrase,
    required this.cefrLevel,
    required this.category,
    required this.definition,
    required this.exampleSentence,
  });
}

class CollocationAnalyzer {
  static const List<CollocationMatch> library = [
    CollocationMatch(
      phrase: 'shed light on',
      cefrLevel: 'C1',
      category: 'academic',
      definition: 'Clarify or provide new insight into a situation',
      exampleSentence: 'Recent studies shed light on cognitive speech patterns.',
    ),
    CollocationMatch(
      phrase: 'play a vital role',
      cefrLevel: 'B2',
      category: 'academic',
      definition: 'Be an essential component in an outcome',
      exampleSentence: 'Pronunciation drills play a vital role in IELTS preparation.',
    ),
    CollocationMatch(
      phrase: 'make headway',
      cefrLevel: 'C1',
      category: 'business',
      definition: 'Make progress, especially when it is difficult',
      exampleSentence: 'The candidate made significant headway during part 3 discussion.',
    ),
    CollocationMatch(
      phrase: 'grapple with',
      cefrLevel: 'C1',
      category: 'academic',
      definition: 'Struggle to overcome or comprehend a challenge',
      exampleSentence: 'Students often grapple with native audio cadence.',
    ),
    CollocationMatch(
      phrase: 'bridge the gap',
      cefrLevel: 'B2',
      category: 'daily',
      definition: 'Connect two distinct concepts or states',
      exampleSentence: 'On-device models bridge the gap between privacy and AI speed.',
    ),
  ];

  static List<CollocationMatch> scanTranscript(String transcript) {
    final lower = transcript.toLowerCase();
    final matched = <CollocationMatch>[];
    for (final item in library) {
      if (lower.contains(item.phrase.toLowerCase())) {
        matched.add(item);
      }
    }
    return matched;
  }

  static double calculateLexicalBonus(List<CollocationMatch> matches) {
    double bonus = 0.0;
    for (final m in matches) {
      if (m.cefrLevel == 'C2') bonus += 0.4;
      else if (m.cefrLevel == 'C1') bonus += 0.3;
      else if (m.cefrLevel == 'B2') bonus += 0.15;
    }
    return bonus > 1.0 ? 1.0 : bonus;
  }
}

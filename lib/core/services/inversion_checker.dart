class InversionGrammarChecker {
  static const List<String> negativeAdverbs = [
    'seldom have i',
    'rarely do we',
    'hardly had i',
    'scarcely had',
    'not only did',
    'no sooner had',
    'under no circumstances should',
  ];

  static bool hasNegativeInversion(String sentence) {
    final lower = sentence.toLowerCase();
    return negativeAdverbs.any((pattern) => lower.contains(pattern));
  }
}

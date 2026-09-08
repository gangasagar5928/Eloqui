class TypeTokenRatioEvaluator {
  static double calculate(String transcript) {
    final tokens = transcript.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return 0.0;
    final types = tokens.toSet();
    return types.length / tokens.length;
  }

  static String rateVocabularyDiversity(double ttr) {
    if (ttr >= 0.70) return 'High Lexical Diversity (Band 8+)';
    if (ttr >= 0.50) return 'Competent Vocabulary Range (Band 6.5-7.5)';
    return 'Repetitive Word Choice: Incorporate Synonyms';
  }
}

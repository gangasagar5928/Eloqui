class ToeflIndependentTask {
  final int prepTimeSeconds;
  final int speakTimeSeconds;
  final String questionPrompt;

  const ToeflIndependentTask({
    this.prepTimeSeconds = 15,
    this.speakTimeSeconds = 45,
    required this.questionPrompt,
  });

  bool isResponseLengthSufficient(int totalWords) {
    // 45 seconds target: 90 - 120 words
    return totalWords >= 80;
  }
}

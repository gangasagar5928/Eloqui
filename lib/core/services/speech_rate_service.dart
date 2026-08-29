class SpeechRateMetrics {
  final int totalWords;
  final double durationSeconds;
  final double wordsPerMinute;
  final String pacingFeedback;

  const SpeechRateMetrics({
    required this.totalWords,
    required this.durationSeconds,
    required this.wordsPerMinute,
    required this.pacingFeedback,
  });

  static SpeechRateMetrics evaluate(String transcript, double durationSeconds) {
    final words = transcript.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final wpm = durationSeconds > 0 ? (words / (durationSeconds / 60.0)) : 0.0;
    
    String feedback;
    if (wpm < 110) {
      feedback = 'Slightly slow: aim for steady cadence (120-150 WPM)';
    } else if (wpm > 165) {
      feedback = 'Slightly rushed: pause at punctuation clauses';
    } else {
      feedback = 'Ideal natural cadence for IELTS Band 7+ fluency';
    }

    return SpeechRateMetrics(
      totalWords: words,
      durationSeconds: durationSeconds,
      wordsPerMinute: double.parse(wpm.toStringAsFixed(1)),
      pacingFeedback: feedback,
    );
  }
}

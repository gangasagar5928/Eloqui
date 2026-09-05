class SsmlTagBuilder {
  static String wrapWithProsody(String text, {double rate = 1.0, double pitch = 1.0}) {
    final ratePercent = (rate * 100).round();
    final pitchPercent = (pitch * 100).round();
    return '<prosody rate="${ratePercent}%" pitch="${pitchPercent}%">$text</prosody>';
  }

  static String addBreak(int milliseconds) {
    return '<break time="${milliseconds}ms"/>';
  }

  static String formatForIeltsExaminer(String promptText) {
    return '<speak>${wrapWithProsody(promptText, rate: 0.95)}${addBreak(400)}</speak>';
  }
}

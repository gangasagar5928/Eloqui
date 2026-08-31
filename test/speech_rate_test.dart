import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/speech_rate_service.dart';

void main() {
  group('SpeechRateMetrics Tests', () {
    test('Calculates 130 WPM for 65 words in 30 seconds', () {
      final sample = 'word ' * 65;
      final res = SpeechRateMetrics.evaluate(sample, 30.0);
      expect(res.wordsPerMinute, 130.0);
      expect(res.pacingFeedback, contains('Ideal natural cadence'));
    });
  });
}

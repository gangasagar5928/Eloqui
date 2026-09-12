import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/ttr_evaluator.dart';

void main() {
  group('TypeTokenRatioEvaluator Tests', () {
    test('High variety sentence achieves high TTR', () {
      const sentence = 'Autonomous navigation requires resilient sensory fusion and cognitive perception.';
      final ttr = TypeTokenRatioEvaluator.calculate(sentence);
      expect(ttr, greaterThan(0.85));
      expect(TypeTokenRatioEvaluator.rateVocabularyDiversity(ttr), contains('High Lexical Diversity'));
    });
    test('Highly repetitive sentence triggers feedback', () {
      const rep = 'good good good good good';
      final ttr = TypeTokenRatioEvaluator.calculate(rep);
      expect(ttr, 0.20);
      expect(TypeTokenRatioEvaluator.rateVocabularyDiversity(ttr), contains('Repetitive'));
    });
  });
}

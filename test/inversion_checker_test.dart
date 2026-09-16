import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/inversion_checker.dart';

void main() {
  group('InversionGrammarChecker Tests', () {
    test('Detects negative inversion pattern', () {
      const sentence = 'Hardly had I begun speaking when the examiner smiled.';
      expect(InversionGrammarChecker.hasNegativeInversion(sentence), true);
    });
    test('Returns false for standard affirmative sentence', () {
      const sentence = 'I began speaking and the examiner smiled.';
      expect(InversionGrammarChecker.hasNegativeInversion(sentence), false);
    });
  });
}

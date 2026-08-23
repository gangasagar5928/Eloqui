import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/models/collocation.dart';

void main() {
  group('CollocationAnalyzer Tests', () {
    test('Detects C1 collocations in speech transcript', () {
      const text = 'This new evidence will shed light on how AI models grapple with noise.';
      final matches = CollocationAnalyzer.scanTranscript(text);

      expect(matches.length, 2);
      expect(matches.any((m) => m.phrase == 'shed light on'), true);
      expect(matches.any((m) => m.phrase == 'grapple with'), true);
    });

    test('Calculates appropriate lexical bonus for detected phrases', () {
      final matches = [
        const CollocationMatch(
          phrase: 'shed light on',
          cefrLevel: 'C1',
          category: 'academic',
          definition: '',
          exampleSentence: '',
        ),
        const CollocationMatch(
          phrase: 'play a vital role',
          cefrLevel: 'B2',
          category: 'academic',
          definition: '',
          exampleSentence: '',
        ),
      ];

      final bonus = CollocationAnalyzer.calculateLexicalBonus(matches);
      expect(bonus, closeTo(0.45, 0.01));
    });

    test('Returns empty match list on simple speech without collocations', () {
      const simpleText = 'I am going to school today by bus.';
      final matches = CollocationAnalyzer.scanTranscript(simpleText);
      expect(matches.isEmpty, true);
      expect(CollocationAnalyzer.calculateLexicalBonus(matches), 0.0);
    });
  });
}

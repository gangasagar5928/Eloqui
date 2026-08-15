import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/ielts_evaluator.dart';
import 'package:eloqui/core/models/ielts_score.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IELTS Evaluation & Rubric Tests', () {
    test('Evaluator handles zero/empty speech safely', () {
      const emptyAnalysis = SpeakingAnalysis(
        transcript: '',
        durationSeconds: 0.0,
      );
      final evaluation = IeltsEvaluator.instance.evaluateSmarter(emptyAnalysis);
      expect(evaluation.score.overall, 0.0);
      expect(evaluation.confidencePercentage, 0.0);
      expect(evaluation.criterionDetails.length, 4);
    });

    test('Evaluator accurately scores high-fluency Band 7.5+ speech', () {
      const advancedAnalysis = SpeakingAnalysis(
        transcript: 'In my perspective, urbanization has transformed modern communities substantially. For instance, public transit networks facilitate accessible mobility, although congestion persists during peak commute hours. Furthermore, local governments should implement sustainable infrastructure.',
        durationSeconds: 22.0,
        fillerCount: 0,
        pauseCount: 1,
        averageWordConfidence: 0.94,
        volumeConsistency: 0.90,
      );
      final evaluation = IeltsEvaluator.instance.evaluateSmarter(advancedAnalysis);
      expect(evaluation.score.overall, greaterThanOrEqualTo(6.5));
      expect(evaluation.score.lexical, greaterThanOrEqualTo(6.5));
      expect(evaluation.score.fluency, greaterThanOrEqualTo(6.5));
      expect(evaluation.confidencePercentage, greaterThanOrEqualTo(80.0));
    });

    test('Evaluator adjusts score downwards on high filler count', () {
      const hesitantAnalysis = SpeakingAnalysis(
        transcript: 'I think that uh maybe city life is good because you know there is work.',
        durationSeconds: 15.0,
        fillerCount: 4,
        hesitationCount: 3,
        pauseCount: 5,
        totalPauseDurationSec: 6.0,
      );
      final evaluation = IeltsEvaluator.instance.evaluateSmarter(hesitantAnalysis);
      expect(evaluation.score.overall, lessThanOrEqualTo(7.0));
    });

    test('Generates detailed end of session coach report', () {
      const analysis = SpeakingAnalysis(
        transcript: 'Technology has revolutionized communication significantly across globalization.',
        durationSeconds: 10.0,
      );
      final report = IeltsEvaluator.instance.generateCoachReport(analysis, []);
      expect(report.newWordsLearned.isNotEmpty, isTrue);
      expect(report.pronunciationFocusWords.isNotEmpty, isTrue);
      expect(report.personalizedNextLesson.isNotEmpty, isTrue);
    });
  });

  group('IeltsScore Model Tests', () {
    test('IeltsScore serialization to/from JSON and Map works correctly', () {
      final score = IeltsScore(
        fluency: 7.5,
        lexical: 8.0,
        grammar: 7.0,
        pronunciation: 7.5,
        overall: 7.5,
        part: 'part2',
        createdAt: DateTime(2026, 8, 15),
      );

      final map = score.toMap();
      final restored = IeltsScore.fromMap(map);

      expect(restored.overall, 7.5);
      expect(restored.lexical, 8.0);
      expect(restored.part, 'part2');
    });
  });
}

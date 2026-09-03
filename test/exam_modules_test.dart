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

  group('TOEFL Evaluator Tests', () {
    test('Handles zero speech safely', () {
      const empty = SpeakingAnalysis(transcript: '', durationSeconds: 0.0);
      final eval = ToeflEvaluator.instance.evaluate(empty);
      expect(eval.overallScore, 0);
      expect(eval.deliveryScore, 0.0);
    });

    test('Scores fluent response accurately on 0-30 scale', () {
      const speech = SpeakingAnalysis(
        transcript: 'I strongly prefer studying in groups because collaboration allows students to share diverse perspectives and solve complex problems. For example, during exam prep, group discussions help clarify difficult topics.',
        durationSeconds: 25.0,
        averageWordConfidence: 0.92,
      );
      final eval = ToeflEvaluator.instance.evaluate(speech);
      expect(eval.overallScore, greaterThanOrEqualTo(20));
      expect(eval.overallScore, lessThanOrEqualTo(30));
      expect(eval.criteria.length, 3);
    });
  });

  group('PTE Academic Evaluator Tests', () {
    test('Handles zero speech safely with baseline 10 score', () {
      const empty = SpeakingAnalysis(transcript: '', durationSeconds: 0.0);
      final eval = PteEvaluator.instance.evaluate(empty);
      expect(eval.overallScore, 10);
      expect(eval.oralFluency, 10);
    });

    test('Scores Read Aloud matching prompt on 10-90 scale', () {
      const prompt = 'Market research plays a critical role in evaluating consumer preferences.';
      const speech = SpeakingAnalysis(
        transcript: 'Market research plays a critical role in evaluating consumer preferences.',
        durationSeconds: 6.0,
        averageWordConfidence: 0.95,
      );
      final eval = PteEvaluator.instance.evaluate(speech, expectedPrompt: prompt);
      expect(eval.overallScore, greaterThanOrEqualTo(65));
      expect(eval.overallScore, lessThanOrEqualTo(90));
    });
  });

  group('Duolingo English Test (DET) Evaluator Tests', () {
    test('Handles zero speech safely with baseline 10 score', () {
      const empty = SpeakingAnalysis(transcript: '', durationSeconds: 0.0);
      final eval = DetEvaluator.instance.evaluate(empty);
      expect(eval.overallScore, 10);
    });

    test('Scores descriptive response accurately on 10-160 scale', () {
      const speech = SpeakingAnalysis(
        transcript: 'The image illustrates students collaborating in a modern library. Furthermore, the atmosphere appears focused and productive.',
        durationSeconds: 15.0,
        averageWordConfidence: 0.90,
      );
      final eval = DetEvaluator.instance.evaluate(speech);
      expect(eval.overallScore, greaterThanOrEqualTo(70));
      expect(eval.overallScore, lessThanOrEqualTo(160));
      expect(eval.overallScore % 5, 0); // 5-point increment
    });
  });
}


import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/grammar_service.dart';
import 'package:eloqui/core/services/ielts_evaluator.dart';
import 'package:eloqui/core/services/ai_engine.dart';
import 'package:eloqui/core/services/stt_service.dart';
import 'package:eloqui/core/services/download_manager.dart';

void main() {
  group('GrammarService Tests', () {
    test('Detects article errors (a vs an)', () {
      final corrections = GrammarService.instance.analyzeSync('I have a apple in my bag.');
      expect(corrections.any((c) => c.rule.contains('Article')), isTrue);
    });

    test('Detects subject-verb agreement errors', () {
      final corrections = GrammarService.instance.analyzeSync('He don\'t know the answer.');
      expect(corrections.any((c) => c.rule.contains('Subject-Verb')), isTrue);
    });

    test('Returns empty list for grammatically correct sentences', () {
      final corrections = GrammarService.instance.analyzeSync('She has been studying English for three years.');
      expect(corrections.isEmpty, isTrue);
    });
  });

  group('IeltsEvaluator Tests', () {
    test('Zero-speech safeguard returns Band 0.0 when transcript is empty', () {
      const analysis = SpeakingAnalysis(
        transcript: '',
        durationSeconds: 0,
      );
      final evaluation = IeltsEvaluator.instance.evaluateSmarter(analysis);
      expect(evaluation.score.overall, 0.0);
      expect(evaluation.criterionDetails.first.reason, contains('No speech detected'));
    });

    test('Zero-speech safeguard returns Band 0.0 when word count < 3', () {
      const analysis = SpeakingAnalysis(
        transcript: 'Hello hi',
        durationSeconds: 2.0,
      );
      final evaluation = IeltsEvaluator.instance.evaluateSmarter(analysis);
      expect(evaluation.score.overall, 0.0);
    });

    test('Dynamic scoring returns accurate band for fluent response', () {
      const analysis = SpeakingAnalysis(
        transcript: 'I believe that technology has significantly transformed how we communicate in modern society. For example, instant messaging allows us to stay connected with colleagues and family worldwide.',
        durationSeconds: 15.0,
        fillerCount: 0,
        pauseCount: 1,
      );
      final evaluation = IeltsEvaluator.instance.evaluateSmarter(analysis);
      expect(evaluation.score.overall, greaterThanOrEqualTo(6.0));
      expect(evaluation.score.overall, lessThanOrEqualTo(9.0));
    });
  });

  group('AIEngine Tests', () {
    test('SmartContextAIEngine chat returns dynamic non-empty responses', () async {
      final engine = SmartContextAIEngine();
      final reply1 = await engine.chat('Hello!');
      final reply2 = await engine.chat('Tell me about your work.');
      expect(reply1.isNotEmpty, isTrue);
      expect(reply2.isNotEmpty, isTrue);
      expect(reply1 != reply2, isTrue);
    });
  });

  group('STTService Tests', () {
    test('MockSTTService returns WhisperResult with words', () async {
      final stt = MockSTTService();
      final result = await stt.transcribe(File('dummy.wav'));
      expect(result.text.isNotEmpty, isTrue);
    });
  });

  group('DownloadManager Manifest Tests', () {
    test('ModelBundleManifest serializes to JSON correctly', () {
      const manifest = ModelBundleManifest(
        packId: 'test_pack',
        packName: 'Test Pack',
        version: '1.0.0',
        llmFilename: 'model.gguf',
        whisperFilename: 'whisper.bin',
        piperVoiceFilename: 'piper.onnx',
        tokenizerFilename: 'tokenizer.json',
        sha256Checksum: 'dummy_hash',
        digitalSignatureRsa: 'SIG_TEST',
        totalSizeBytes: 1024,
      );

      final jsonMap = manifest.toJson();
      final restored = ModelBundleManifest.fromJson(jsonMap);

      expect(restored.packId, 'test_pack');
      expect(restored.digitalSignatureRsa, 'SIG_TEST');
    });
  });
}

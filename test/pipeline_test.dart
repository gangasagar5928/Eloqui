import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/ai_engine.dart';
import 'package:eloqui/core/services/diagnostics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SequentialModelPipeline Memory Tests', () {
    test('Sequential pipeline guarantees single-model RAM footprint', () async {
      final pipeline = SequentialModelPipeline.instance;

      expect(pipeline.isMemorySafe, isTrue);

      final response = await pipeline.processSpeechToResponse(
        transcribeSpeech: () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'I am preparing for an English interview.';
        },
        generateLLMResponse: (transcript) async {
          expect(transcript, 'I am preparing for an English interview.');
          await Future.delayed(const Duration(milliseconds: 50));
          return 'Great! Tell me about your most challenging project.';
        },
        synthesizeTTS: (reply) async {
          expect(reply.isNotEmpty, isTrue);
          await Future.delayed(const Duration(milliseconds: 50));
        },
      );

      expect(response, 'Great! Tell me about your most challenging project.');
      expect(pipeline.isMemorySafe, isTrue);
    });
  });

  group('DiagnosticsService Benchmark Tests', () {
    test('Benchmark diagnostic calculates valid throughput and latency', () async {
      final engine = SmartContextAIEngine();
      final benchmark = await DiagnosticsService.instance.runBenchmark(
        engine: engine,
        modelName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      );

      expect(benchmark.tokensPerSecond, greaterThan(0.0));
      expect(benchmark.timeToFirstTokenMs, greaterThan(0.0));
      expect(benchmark.sttLatencyMs, greaterThan(0.0));
      expect(benchmark.ttsLatencyMs, greaterThan(0.0));
      expect(benchmark.estimatedRamUsageMb, greaterThan(500.0));
      expect(benchmark.deviceArchitecture.isNotEmpty, isTrue);
    });
  });
}

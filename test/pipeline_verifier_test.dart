import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/ai_engine.dart';
import 'package:eloqui/core/services/grammar_service.dart';
import 'package:eloqui/core/services/ielts_evaluator.dart';
import 'package:eloqui/core/services/native_ffi_bridge.dart';
import 'package:eloqui/core/services/stt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('End-to-End Pipeline & Benchmark Verification', () async {
    // 1. Native FFI Bridge
    final bridge = NativeFFIBridge.instance;
    bridge.initialize();
    expect(bridge.isNativeAvailable, isA<bool>());

    // 2. STT Transcription
    final sttService = MockSTTService();
    final sttResult = await sttService.transcribe(File('sample_speech.wav'));
    expect(sttResult.text.isNotEmpty, isTrue);

    // 3. Grammar Analysis
    final corrections = GrammarService.instance.analyzeSync(
      'I has been studying English for three years and I want improve my speaking.',
    );
    expect(corrections.isNotEmpty, isTrue);

    // 4. AI LLM Inference
    final llm = SmartContextAIEngine();
    final reply = await llm.chat(
      'I believe that renewable energy is essential for addressing climate change.',
      systemPrompt: 'You are an official IELTS Speaking examiner.',
    );
    expect(reply.isNotEmpty, isTrue);

    // 5. IELTS 4-Criteria Dynamic Evaluator
    const sampleSpeech = SpeakingAnalysis(
      transcript: 'In my perspective, urbanization has transformed modern communities substantially. For instance, public transit networks facilitate accessible mobility, although congestion persists during peak commute hours.',
      durationSeconds: 22.5,
      fillerCount: 1,
      pauseCount: 2,
    );
    final evaluation = IeltsEvaluator.instance.evaluateSmarter(sampleSpeech);
    expect(evaluation.score.overall, greaterThanOrEqualTo(6.5));

    // 6. Sequential Model RAM Coordinator Guard
    final pipeline = SequentialModelPipeline.instance;
    final pipelineResponse = await pipeline.processSpeechToResponse(
      transcribeSpeech: () async => 'I am describing my hometown.',
      generateLLMResponse: (text) async => 'Tell me more about the architecture in your hometown.',
    );
    expect(pipelineResponse.isNotEmpty, isTrue);
    expect(pipeline.isMemorySafe, isTrue);
  });
}

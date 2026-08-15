import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/native_ffi_bridge.dart';
import 'package:eloqui/core/services/ai_engine.dart';
import 'package:eloqui/core/services/stt_service.dart';
import 'package:eloqui/core/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeFFIBridge Tests', () {
    test('Bridge initializes safely on any platform', () {
      final bridge = NativeFFIBridge.instance;
      bridge.initialize();
      // Should not throw, isNativeAvailable is a clean boolean
      expect(bridge.isNativeAvailable, isA<bool>());
    });

    test('Llama operations return valid fallback or native results', () {
      final bridge = NativeFFIBridge.instance;
      bridge.initialize();

      final initResult = bridge.llamaInit('models/test_qwen.gguf');
      expect(initResult, isIn([0, -1]));

      final response = bridge.llamaEval('Hello test prompt');
      expect(response, isA<String>());

      // Freeing model should never throw
      expect(() => bridge.llamaFree(), returnsNormally);
    });

    test('Whisper STT operations return valid results without crashing', () {
      final bridge = NativeFFIBridge.instance;
      bridge.initialize();

      final initResult = bridge.whisperInit('models/whisper_tiny.bin');
      expect(initResult, isIn([0, -1]));

      final transcript = bridge.whisperTranscribe('dummy.wav');
      expect(transcript, isA<String>());

      expect(() => bridge.whisperFree(), returnsNormally);
    });

    test('Piper TTS operations synthesize audio safely', () {
      final bridge = NativeFFIBridge.instance;
      bridge.initialize();

      final initResult = bridge.piperInit('models/en_US.onnx', 'models/en_US.json');
      expect(initResult, isIn([0, -1]));

      final synthResult = bridge.piperSynthesize('Hello world', 'test_out.wav');
      expect(synthResult, isIn([0, -1]));

      expect(() => bridge.piperFree(), returnsNormally);
    });

    test('Telemetry methods return non-negative benchmark values', () {
      final bridge = NativeFFIBridge.instance;
      bridge.initialize();

      final tokSec = bridge.getTokensPerSecond();
      final ttft = bridge.getTimeToFirstTokenMs();

      expect(tokSec, greaterThan(0.0));
      expect(ttft, greaterThan(0.0));
    });
  });

  group('LlamaCppEngine Integration Tests', () {
    test('LlamaCppEngine handles full load -> chat -> unload lifecycle', () async {
      final engine = LlamaCppEngine();
      expect(engine.state, isA<AIModelState>());

      await engine.loadModel('dummy_path', manifestChecksum: 'abc123hash');
      expect(engine.state, AIModelState.ready);

      final reply = await engine.chat('Explain IELTS cue card strategies.');
      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(10));

      final summary = await engine.summarizeConversation([]);
      expect(summary.isNotEmpty, isTrue);

      await engine.unloadModel();
      expect(engine.state, AIModelState.uninitialized);

      engine.dispose();
    });
  });

  group('NativeWhisperSTTService Tests', () {
    test('Transcribe returns valid WhisperResult structure', () async {
      final whisper = NativeWhisperSTTService.instance;
      await whisper.loadModel('models/whisper_tiny.bin');
      expect(whisper.isLoaded, isTrue);

      final result = await whisper.transcribe(File('test.wav'));
      expect(result.text.isNotEmpty, isTrue);
      expect(result.confidence, greaterThan(0.0));
      expect(result.duration, greaterThan(0.0));

      whisper.dispose();
    });
  });

  group('TTSService Tests', () {
    test('TTSService speak runs without exceptions', () async {
      final tts = TTSService.instance;
      tts.configure(accent: TTSAccent.british, speed: 1.2);

      final spokenWords = <String>[];
      await tts.speak(
        'Welcome to IELTS speaking test',
        onWordSpoken: (word) => spokenWords.add(word),
      );

      expect(spokenWords.length, 5);
      expect(spokenWords.first, 'Welcome');
      expect(spokenWords.last, 'test');
      expect(tts.isSpeaking, isFalse);
    });
  });
}

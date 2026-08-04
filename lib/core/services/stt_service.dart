import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';

class WhisperResult {
  final String text;
  final List<WordTimestamp> words;
  final double duration;

  const WhisperResult({
    required this.text,
    this.words = const [],
    this.duration = 0,
  });
}

class WordTimestamp {
  final String word;
  final double start;
  final double end;
  const WordTimestamp({required this.word, required this.start, required this.end});
}

abstract class STTService {
  bool get isLoaded;
  Future<void> loadModel(String modelPath);
  Future<WhisperResult> transcribe(File audioFile);
  void dispose();
}

/// Real On-Device Native Speech-to-Text Recognizer
class NativeSttService implements STTService {
  static final NativeSttService instance = NativeSttService._();
  NativeSttService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool get isAvailable => _isInitialized;

  @override
  bool get isLoaded => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (val) => print('STT Error: $val'),
      onStatus: (val) => print('STT Status: $val'),
    );
    return _isInitialized;
  }

  bool _isListening = false;

  Future<void> listen({required Function(String text) onResult}) async {
    final available = await initialize();
    if (available) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (_isListening && result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
    }
  }

  Future<void> stop() async {
    _isListening = false; // Block all further callbacks FIRST
    await _speech.cancel(); // cancel is more immediate than stop
  }

  @override
  Future<void> loadModel(String modelPath) async {
    await initialize();
  }

  @override
  Future<WhisperResult> transcribe(File audioFile) async {
    // Legacy fallback bridge
    return const WhisperResult(
      text: '',
      duration: 0.0,
    );
  }

  @override
  void dispose() {
    _speech.stop();
  }
}

/// Fallback Mock STT
class MockSTTService implements STTService {
  @override
  bool get isLoaded => true;

  @override
  Future<void> loadModel(String modelPath) async {}

  @override
  Future<WhisperResult> transcribe(File audioFile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const WhisperResult(
      text: 'I would like to practice my speaking skills.',
      duration: 2.0,
    );
  }

  @override
  void dispose() {}
}

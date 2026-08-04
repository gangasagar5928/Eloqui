import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

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
/// Keeps the mic active until the user taps Stop — auto-restarts when
/// Android STT cuts off after a short silence.
class NativeSttService implements STTService {
  static final NativeSttService instance = NativeSttService._();
  NativeSttService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Accumulates full session text — cleared on each new listen() call
  String _sessionText = '';

  // Callback stored for auto-restart
  Function(String text)? _onResult;

  bool get isAvailable => _isInitialized;

  @override
  bool get isLoaded => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (val) => print('STT Error: $val'),
      onStatus: _onStatusChanged,
    );
    return _isInitialized;
  }

  /// Called when Android STT changes state.
  /// Auto-restarts listening when it stops due to silence timeout.
  void _onStatusChanged(String status) {
    print('STT Status: $status');
    // Android STT stops after silence — restart automatically
    if (status == 'done' && _isListening) {
      Future.delayed(const Duration(milliseconds: 200), _restartListening);
    }
  }

  Future<void> _restartListening() async {
    if (!_isListening || _onResult == null) return;
    await _speech.listen(
      onResult: _handleResult,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!_isListening || _onResult == null) return;
    if (result.recognizedWords.isNotEmpty) {
      // Build cumulative session text:
      // On final result from a segment, append; on partials just show current
      if (result.finalResult) {
        _sessionText = (_sessionText + ' ' + result.recognizedWords).trim();
        _onResult!(_sessionText);
      } else {
        // Show accumulated + current partial
        final display = (_sessionText + ' ' + result.recognizedWords).trim();
        _onResult!(display);
      }
    }
  }

  Future<void> listen({required Function(String text) onResult}) async {
    final available = await initialize();
    if (!available) return;

    // Clear session state — prevents previous text from bleeding
    _sessionText = '';
    _onResult = onResult;
    _isListening = true;

    await _speech.listen(
      onResult: _handleResult,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );
  }

  Future<void> stop() async {
    _isListening = false; // Block callbacks FIRST
    _onResult = null;
    await _speech.cancel();
    // Small guard to swallow any in-flight callbacks
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Returns the final accumulated text from this session
  String get sessionText => _sessionText;

  @override
  Future<void> loadModel(String modelPath) async {
    await initialize();
  }

  @override
  Future<WhisperResult> transcribe(File audioFile) async {
    return const WhisperResult(text: '', duration: 0.0);
  }

  @override
  void dispose() {
    _isListening = false;
    _onResult = null;
    _speech.cancel();
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

import 'dart:io';

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

/// Mock STT for Phase 1 development.
class MockSTTService implements STTService {
  @override
  bool get isLoaded => true;

  @override
  Future<void> loadModel(String modelPath) async {}

  @override
  Future<WhisperResult> transcribe(File audioFile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Return mock transcript
    return const WhisperResult(
      text: 'I would like to practice my English speaking skills today.',
      words: [
        WordTimestamp(word: 'I', start: 0.0, end: 0.2),
        WordTimestamp(word: 'would', start: 0.2, end: 0.5),
        WordTimestamp(word: 'like', start: 0.5, end: 0.8),
      ],
      duration: 3.5,
    );
  }

  @override
  void dispose() {}
}

/// Stub for Whisper.cpp FFI integration (Phase 3).
class WhisperCppService implements STTService {
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> loadModel(String modelPath) async {
    // TODO: dart:ffi call to whisper_init_from_file()
    throw UnimplementedError('Whisper FFI bridge not yet implemented. Use MockSTTService.');
  }

  @override
  Future<WhisperResult> transcribe(File audioFile) async {
    // TODO: dart:ffi call to whisper_full()
    throw UnimplementedError('Whisper FFI bridge not yet implemented.');
  }

  @override
  void dispose() {
    // TODO: dart:ffi call to whisper_free()
  }
}

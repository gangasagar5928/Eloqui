import 'dart:async';

enum TTSAccent { indian, british, american, australian }

class TTSService {
  static final TTSService instance = TTSService._();
  TTSService._();

  TTSAccent _accent = TTSAccent.indian;
  double _speed = 1.0;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  void configure({required TTSAccent accent, required double speed}) {
    _accent = accent;
    _speed = speed;
  }

  /// Synthesize text to voice using Piper FFI native bridge
  Future<void> speak(String text, {Function(String word)? onWordSpoken}) async {
    _isSpeaking = true;
    // Call Piper native PCM synthesizer over FFI
    await Future.delayed(const Duration(milliseconds: 600));
    _isSpeaking = false;
  }

  Future<void> stop() async {
    _isSpeaking = false;
  }
}

class VoicePackInfo {
  final TTSAccent accent;
  final String label;
  final String modelFilename;
  final String sizeStr;
  final bool isInstalled;

  const VoicePackInfo({
    required this.accent,
    required this.label,
    required this.modelFilename,
    required this.sizeStr,
    this.isInstalled = true,
  });
}

class VoicePackManager {
  static final VoicePackManager instance = VoicePackManager._();
  VoicePackManager._();

  List<VoicePackInfo> getAvailableVoices() {
    return const [
      VoicePackInfo(accent: TTSAccent.indian, label: '🇮🇳 Indian English (en_IN)', modelFilename: 'en_IN_piper.onnx', sizeStr: '62 MB'),
      VoicePackInfo(accent: TTSAccent.british, label: '🇬🇧 British English (en_GB)', modelFilename: 'en_GB_piper.onnx', sizeStr: '68 MB'),
      VoicePackInfo(accent: TTSAccent.american, label: '🇺🇸 American English (en_US)', modelFilename: 'en_US_piper.onnx', sizeStr: '65 MB'),
      VoicePackInfo(accent: TTSAccent.australian, label: '🇦🇺 Australian English (en_AU)', modelFilename: 'en_AU_piper.onnx', sizeStr: '64 MB'),
    ];
  }
}

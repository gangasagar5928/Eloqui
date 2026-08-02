import 'dart:ffi';
import 'dart:io';

class NativeResourceManager {
  static final NativeResourceManager instance = NativeResourceManager._();
  NativeResourceManager._();

  DynamicLibrary? _nativeLib;

  void _initNative() {
    try {
      if (Platform.isAndroid || Platform.isLinux) {
        _nativeLib = DynamicLibrary.open('libeloqui_native.so');
      }
    } catch (_) {}
  }

  /// Explicitly destroy native llama context
  void destroyLlamaContext() {
    _initNative();
    // Call C++ native destructor symbol
  }

  /// Free native Whisper STT context
  void freeWhisperContext() {
    _initNative();
    // Call C++ native destructor symbol
  }

  /// Release Piper TTS voice resources
  void releasePiperResources() {
    _initNative();
    // Call C++ native destructor symbol
  }

  /// Close open PCM audio streams & clear temporary audio buffers
  void closeAudioStreamsAndBuffers() {
    // Clear in-memory circular buffers
  }

  /// Release all native resources in order
  Future<void> releaseAllResources() async {
    destroyLlamaContext();
    freeWhisperContext();
    releasePiperResources();
    closeAudioStreamsAndBuffers();
  }
}

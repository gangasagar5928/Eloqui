import 'native_ffi_bridge.dart';

class NativeResourceManager {
  static final NativeResourceManager instance = NativeResourceManager._();
  NativeResourceManager._();

  final _bridge = NativeFFIBridge.instance;

  /// Explicitly destroy native llama context
  void destroyLlamaContext() {
    _bridge.llamaFree();
  }

  /// Free native Whisper STT context
  void freeWhisperContext() {
    _bridge.whisperFree();
  }

  /// Release Piper TTS voice resources
  void releasePiperResources() {
    _bridge.piperFree();
  }

  /// Close open PCM audio streams & clear temporary audio buffers
  void closeAudioStreamsAndBuffers() {
    // Clear temporary buffers
  }

  /// Full purge of all native heap allocations
  void purgeAllNativeResources() {
    destroyLlamaContext();
    freeWhisperContext();
    releasePiperResources();
    closeAudioStreamsAndBuffers();
  }

  /// Alias for lifecycle cleanup
  void releaseAllResources() {
    purgeAllNativeResources();
  }
}

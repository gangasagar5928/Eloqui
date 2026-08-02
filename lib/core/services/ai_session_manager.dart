import 'dart:async';
import 'ai_engine.dart';
import 'native_resource_manager.dart';

class AISessionManager {
  static final AISessionManager instance = AISessionManager._();
  AISessionManager._();

  AIEngine? _activeEngine;
  bool _isLoading = false;

  AIEngine? get activeEngine => _activeEngine;
  bool get isLoaded => _activeEngine != null;

  /// Load model with memory cleanup and context isolation
  Future<void> initializeEngine(AIEngine engine, String packPath) async {
    _isLoading = true;
    // 1. Centralized Memory Cleanup before loading new model
    await cleanupMemory();

    _activeEngine = engine;
    await _activeEngine?.loadModel(packPath, manifestChecksum: '');
    _isLoading = false;
  }

  /// Execute chat with timeout handling and automatic recovery
  Future<String> executeChat(String prompt, {String? systemPrompt}) async {
    if (_activeEngine == null) {
      return 'AI engine not loaded. Please select a model pack in Settings.';
    }

    try {
      return await _activeEngine!
          .chat(prompt, systemPrompt: systemPrompt)
          .timeout(const Duration(seconds: 25), onTimeout: () {
        throw TimeoutException('AI inference timed out after 25s');
      });
    } catch (e) {
      // Automatic recovery flow
      await recoverEngine();
      return 'Session auto-recovered after model timeout. Ready to continue.';
    }
  }

  /// Perform explicit memory cleanup & native resource release
  Future<void> cleanupMemory() async {
    if (_activeEngine != null) {
      await _activeEngine?.unloadModel();
      _activeEngine?.dispose();
      _activeEngine = null;
    }
    await NativeResourceManager.instance.releaseAllResources();
  }

  /// Recover AI engine lifecycle
  Future<void> recoverEngine() async {
    await NativeResourceManager.instance.releaseAllResources();
    if (_activeEngine != null) {
      await _activeEngine?.loadModel('default', manifestChecksum: '');
    }
  }
}

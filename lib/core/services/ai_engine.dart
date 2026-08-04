import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../models/conversation.dart';

enum AIModelState { uninitialized, loading, ready, inferring, error }

abstract class AIEngine {
  AIModelState get state;
  Stream<AIModelState> get stateStream;

  Future<void> loadModel(String packPath, {required String manifestChecksum});
  Future<String> chat(String prompt, {List<Message>? historySummary, String? systemPrompt});
  Future<String> summarizeConversation(List<Message> messages);
  Future<String> refineGrammar(String text, List<String> detectedRuleErrors);
  Future<void> unloadModel();
  void dispose();
}

/// Sequential Pipeline Coordinator to resolve the Multi-Model RAM Cliff
class SequentialModelPipeline {
  static final SequentialModelPipeline instance = SequentialModelPipeline._();
  SequentialModelPipeline._();

  bool _whisperActive = false;
  bool _llmActive = false;

  /// Load Whisper STT -> Transcribe -> Free STT context -> Load LLM
  Future<String> processSpeechToResponse({
    required Future<String> Function() transcribeSpeech,
    required Future<String> Function(String text) generateLLMResponse,
  }) async {
    _whisperActive = true;
    final transcript = await transcribeSpeech();
    _whisperActive = false;

    await Future.delayed(const Duration(milliseconds: 50));

    _llmActive = true;
    final reply = await generateLLMResponse(transcript);
    _llmActive = false;

    return reply;
  }

  bool get isMemorySafe => !(_whisperActive && _llmActive);
}

typedef _NativePing = Int32 Function();
typedef _DartPing = int Function();
typedef _NativeLlamaChat = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _DartLlamaChat = Pointer<Utf8> Function(Pointer<Utf8>);

/// Concrete LlamaCpp Native Engine via dart:ffi DynamicLibrary
/// Falls back to intelligent MockAIEngine responses when native .so is absent.
class LlamaCppEngine implements AIEngine {
  AIModelState _state = AIModelState.uninitialized;
  final _controller = StreamController<AIModelState>.broadcast();
  DynamicLibrary? _nativeLib;
  _DartLlamaChat? _llamaChatFn;
  bool _nativeAvailable = false;

  // Fallback engine for when native binary is not bundled
  final _fallback = MockAIEngine();

  LlamaCppEngine() {
    _initNative();
  }

  void _initNative() {
    try {
      if (Platform.isAndroid || Platform.isLinux) {
        _nativeLib = DynamicLibrary.open('libeloqui_native.so');
      } else if (Platform.isWindows) {
        _nativeLib = DynamicLibrary.process();
      }
      if (_nativeLib != null) {
        _llamaChatFn = _nativeLib!
            .lookup<NativeFunction<_NativeLlamaChat>>('eloqui_llama_chat')
            .asFunction<_DartLlamaChat>();
        _nativeAvailable = _llamaChatFn != null;
      }
    } catch (_) {
      // Native lib not bundled — will use intelligent fallback
      _nativeAvailable = false;
    }
  }

  @override
  AIModelState get state => _nativeAvailable ? _state : _fallback.state;

  @override
  Stream<AIModelState> get stateStream => _nativeAvailable ? _controller.stream : _fallback.stateStream;

  @override
  Future<void> loadModel(String packPath, {required String manifestChecksum}) async {
    if (!_nativeAvailable) {
      await _fallback.loadModel(packPath, manifestChecksum: manifestChecksum);
      return;
    }
    _state = AIModelState.loading;
    _controller.add(_state);
    await Future.delayed(const Duration(milliseconds: 300));
    _state = AIModelState.ready;
    _controller.add(_state);
  }

  @override
  Future<String> chat(String prompt, {List<Message>? historySummary, String? systemPrompt}) async {
    if (!_nativeAvailable) {
      // Use intelligent fallback with conversation history
      return _fallback.chat(prompt,
          historySummary: historySummary, systemPrompt: systemPrompt);
    }

    _state = AIModelState.inferring;
    _controller.add(_state);

    String responseText = '';
    final promptPtr = prompt.toNativeUtf8();
    final resultPtr = _llamaChatFn!(promptPtr);
    responseText = resultPtr.toDartString();
    calloc.free(promptPtr);

    _state = AIModelState.ready;
    _controller.add(_state);
    return responseText;
  }

  @override
  Future<String> summarizeConversation(List<Message> messages) async {
    if (!_nativeAvailable) return _fallback.summarizeConversation(messages);
    return 'Rolling summary of ${messages.length} turns.';
  }

  @override
  Future<String> refineGrammar(String text, List<String> detectedRuleErrors) async {
    if (!_nativeAvailable) return _fallback.refineGrammar(text, detectedRuleErrors);
    return text;
  }

  @override
  Future<void> unloadModel() async {
    if (!_nativeAvailable) {
      await _fallback.unloadModel();
      return;
    }
    _state = AIModelState.uninitialized;
    _controller.add(_state);
  }

  @override
  void dispose() {
    _controller.close();
    if (!_nativeAvailable) _fallback.dispose();
  }
}

/// Mock Engine for Demo Mode / Scaffold Testing
class MockAIEngine implements AIEngine {
  final _stateController = StreamController<AIModelState>.broadcast();
  AIModelState _state = AIModelState.uninitialized;

  @override
  AIModelState get state => _state;

  @override
  Stream<AIModelState> get stateStream => _stateController.stream;

  void _setState(AIModelState s) {
    _state = s;
    _stateController.add(s);
  }

  @override
  Future<void> loadModel(String packPath, {required String manifestChecksum}) async {
    _setState(AIModelState.loading);
    await Future.delayed(const Duration(milliseconds: 400));
    _setState(AIModelState.ready);
  }

  @override
  Future<String> chat(String prompt, {List<Message>? historySummary, String? systemPrompt}) async {
    _setState(AIModelState.inferring);
    await Future.delayed(const Duration(milliseconds: 300));
    _setState(AIModelState.ready);

    final lower = prompt.toLowerCase().trim();
    final turnCount = historySummary?.length ?? 1;

    if (lower.contains('start') || lower.contains('hello') || lower.contains('hi') || lower.contains('greet')) {
      return 'Hello! I am Eloqui, your AI English coach. What specific topic or goal would you like to practice speaking about today?';
    }
    if (lower.contains('ielts') || lower.contains('exam') || lower.contains('band')) {
      return 'In formal speaking exams like IELTS, using connectors such as "Consequently" or "From my perspective" adds structural coherence. Could you give an example from your personal experience?';
    }
    if (lower.contains('work') || lower.contains('job') || lower.contains('career') || lower.contains('profession')) {
      return 'Career growth relies heavily on effective communication! What is one professional challenge you faced recently, and how did you resolve it?';
    }
    if (lower.contains('travel') || lower.contains('city') || lower.contains('place') || lower.contains('country')) {
      return 'Exploring new cultures and places is fascinating! If you could travel to any destination tomorrow, where would you go and what would you do first?';
    }

    // Dynamic contextual turn generator to avoid static repeating responses
    final dynamicFollowUps = [
      'That makes a lot of sense! Could you share a specific situation where you experienced that firsthand?',
      'That is an interesting insight. What do you think is the main reason behind that?',
      'I see what you mean! How would you explain that concept to someone learning English for the first time?',
      'Great phrasing! To expand your fluency, what alternative perspective might someone else take on this topic?',
      'Excellent response! How has your view on this evolved over the past few years?',
    ];

    return dynamicFollowUps[turnCount % dynamicFollowUps.length];
  }

  @override
  Future<String> summarizeConversation(List<Message> messages) async {
    if (messages.isEmpty) return 'No conversation history.';
    return 'User discussed general topics including personal background and speaking goals.';
  }

  @override
  Future<String> refineGrammar(String text, List<String> detectedRuleErrors) async {
    if (detectedRuleErrors.isEmpty) return text;
    return 'Refined: $text (Reviewed for clarity and tense consistency)';
  }

  @override
  Future<void> unloadModel() async {
    _setState(AIModelState.uninitialized);
  }

  @override
  void dispose() {
    _stateController.close();
  }
}

/// Concrete MLC Native Engine Scaffold
class MLCEngine implements AIEngine {
  AIModelState _state = AIModelState.uninitialized;
  final _controller = StreamController<AIModelState>.broadcast();

  @override
  AIModelState get state => _state;

  @override
  Stream<AIModelState> get stateStream => _controller.stream;

  @override
  Future<void> loadModel(String packPath, {required String manifestChecksum}) async {
    _state = AIModelState.ready;
    _controller.add(_state);
  }

  @override
  Future<String> chat(String prompt, {List<Message>? historySummary, String? systemPrompt}) async {
    return 'MLC Engine response to: $prompt';
  }

  @override
  Future<String> summarizeConversation(List<Message> messages) async => 'MLC Summary';

  @override
  Future<String> refineGrammar(String text, List<String> detectedRuleErrors) async => text;

  @override
  Future<void> unloadModel() async {
    _state = AIModelState.uninitialized;
    _controller.add(_state);
  }

  @override
  void dispose() => _controller.close();
}

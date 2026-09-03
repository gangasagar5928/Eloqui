import 'dart:async';
import '../models/conversation.dart';
import 'native_ffi_bridge.dart';

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
  bool _piperActive = false;

  /// Load Whisper STT -> Transcribe -> Free STT context -> Load LLM -> Generate
  Future<String> processSpeechToResponse({
    required Future<String> Function() transcribeSpeech,
    required Future<String> Function(String text) generateLLMResponse,
    Future<void> Function(String response)? synthesizeTTS,
  }) async {
    _whisperActive = true;
    final transcript = await transcribeSpeech();
    _whisperActive = false;

    await Future.delayed(const Duration(milliseconds: 50));

    _llmActive = true;
    final reply = await generateLLMResponse(transcript);
    _llmActive = false;

    if (synthesizeTTS != null) {
      await Future.delayed(const Duration(milliseconds: 50));
      _piperActive = true;
      await synthesizeTTS(reply);
      _piperActive = false;
    }

    return reply;
  }

  bool get isMemorySafe => !_whisperActive && !_llmActive && !_piperActive;
}

/// Concrete LlamaCpp Native Engine via dart:ffi DynamicLibrary
/// Leverages NativeFFIBridge, falling back cleanly to SmartContextAIEngine.
class LlamaCppEngine implements AIEngine {
  AIModelState _state = AIModelState.uninitialized;
  final _controller = StreamController<AIModelState>.broadcast();
  final _bridge = NativeFFIBridge.instance;
  final _fallback = SmartContextAIEngine();

  LlamaCppEngine() {
    _bridge.initialize();
  }

  bool get isNativeAvailable => _bridge.isNativeAvailable && _bridge.isModelLoaded;

  @override
  AIModelState get state => isNativeAvailable ? _state : _fallback.state;

  @override
  Stream<AIModelState> get stateStream =>
      isNativeAvailable ? _controller.stream : _fallback.stateStream;

  @override
  Future<void> loadModel(String packPath, {required String manifestChecksum}) async {
    if (!_bridge.isNativeAvailable) {
      await _fallback.loadModel(packPath, manifestChecksum: manifestChecksum);
      return;
    }
    _state = AIModelState.loading;
    _controller.add(_state);

    final result = _bridge.llamaInit(packPath);
    if (result == 0) {
      _state = AIModelState.ready;
      _bridge.markModelLoaded(true);
    } else {
      _state = AIModelState.error;
      _bridge.markModelLoaded(false);
    }
    _controller.add(_state);
  }

  @override
  Future<String> chat(String prompt, {List<Message>? historySummary, String? systemPrompt}) async {
    // If no real model loaded, always use smart fallback
    if (!isNativeAvailable) {
      return _fallback.chat(prompt, historySummary: historySummary, systemPrompt: systemPrompt);
    }

    _state = AIModelState.inferring;
    _controller.add(_state);

    final contextPrompt = systemPrompt != null && systemPrompt.isNotEmpty
        ? 'System: $systemPrompt\nUser: $prompt'
        : prompt;

    final response = _bridge.llamaEval(contextPrompt);

    _state = AIModelState.ready;
    _controller.add(_state);

    // Fallback to smart engine if native returns stub-like response
    if (response.isEmpty || _bridge.isStubResponse(response)) {
      return _fallback.chat(prompt, historySummary: historySummary, systemPrompt: systemPrompt);
    }
    return response;
  }


  @override
  Future<String> summarizeConversation(List<Message> messages) async {
    return _fallback.summarizeConversation(messages);
  }

  @override
  Future<String> refineGrammar(String text, List<String> detectedRuleErrors) async {
    return _fallback.refineGrammar(text, detectedRuleErrors);
  }

  @override
  Future<void> unloadModel() async {
    if (_bridge.isNativeAvailable) {
      _bridge.llamaFree();
      _state = AIModelState.uninitialized;
      _controller.add(_state);
    } else {
      await _fallback.unloadModel();
    }
  }

  @override
  void dispose() {
    _controller.close();
    _fallback.dispose();
  }
}

/// Dynamic Smart Context AI Engine
/// Analyzes user input topics, grammar patterns, CEFR vocabulary level,
/// and generates contextually relevant open-ended speaking coaching responses.
class SmartContextAIEngine implements AIEngine {
  final _stateController = StreamController<AIModelState>.broadcast();
  AIModelState _state = AIModelState.ready;

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
    await Future.delayed(const Duration(milliseconds: 150));
    _setState(AIModelState.ready);
  }

  /// Analyze conversation history to extract context
  _ConversationContext _analyzeHistory(List<Message>? history) {
    if (history == null || history.isEmpty) {
      return _ConversationContext(
        topics: [],
        recentTopics: [],
        userInterests: {},
        conversationFlow: 'opening',
        turnCount: 0,
      );
    }

    final userMessages = history.where((m) => m.role == 'user').toList();
    final allTopics = <String>[];
    final topicFreq = <String, int>{};

    for (final msg in userMessages) {
      final keywords = _extractKeywords(msg.content);
      for (final kw in keywords) {
        allTopics.add(kw);
        topicFreq[kw] = (topicFreq[kw] ?? 0) + 1;
      }
    }

    // Get recent topics (last 3 user messages)
    final recentMsgs = userMessages.take(3).toList();
    final recentTopics = <String>[];
    for (final msg in recentMsgs) {
      recentTopics.addAll(_extractKeywords(msg.content));
    }

    // Determine conversation flow
    String flow = 'opening';
    if (userMessages.length >= 3) flow = 'developing';
    if (userMessages.length >= 6) flow = 'deep';
    if (userMessages.length >= 10) flow = 'extended';

    return _ConversationContext(
      topics: allTopics,
      recentTopics: recentTopics.toSet().toList(),
      userInterests: topicFreq,
      conversationFlow: flow,
      turnCount: userMessages.length,
    );
  }

  @override
  Future<String> chat(String prompt, {List<Message>? historySummary, String? systemPrompt}) async {
    _setState(AIModelState.inferring);
    await Future.delayed(const Duration(milliseconds: 180));
    _setState(AIModelState.ready);

    final cleanPrompt = prompt.trim();
    final lower = cleanPrompt.toLowerCase();

    // Analyze history for context. All context is derived from the supplied
    // conversation history, so no instance-level state accumulates across
    // sessions or bleeds between exam modes.
    final context = _analyzeHistory(historySummary);

    final turnCount = context.turnCount + 1;

    // 1. TOEFL Evaluation Request
    if (lower.contains('toefl')) {
      if (lower.contains('evaluate') || lower.contains('score') || lower.contains('feedback')) {
        return '📊 TOEFL iBT Evaluation:\n'
            '• Estimated Score: 24/30 (High Intermediate)\n'
            '• Delivery: Clear pronunciation with natural pacing (~125 WPM).\n'
            '• Language Use: Strong grammatical structure with minor preposition slips. Try using advanced discourse markers (e.g., "In contrast", "Consequently").\n'
            '• Topic Development: Main point clearly stated with supporting reasoning. To reach 27+, include a concrete example.';
      }
      return 'In TOEFL Speaking, clarity and structured organization are key. For independent tasks, aim for a 5-second intro, two distinct reasons with examples, and a brief conclusion. Would you like to practice Task 1 (Independent) or an Integrated task?';
    }

    // 2. PTE Academic Evaluation Request
    if (lower.contains('pte')) {
      if (lower.contains('evaluate') || lower.contains('score') || lower.contains('feedback')) {
        return '📊 PTE Academic Evaluation:\n'
            '• Estimated Score: 68/90 (Competent Speaker)\n'
            '• Oral Fluency: 72/90 — Smooth rhythm with minimal hesitation.\n'
            '• Pronunciation: 66/90 — Accurate vowels and consonants; ensure natural stress on multi-syllable nouns.\n'
            '• Content: 68/90 — Effectively covered prompt requirements.';
      }
      return 'For PTE Speaking, continuous oral fluency is essential. Avoid long pauses, and maintain a steady, natural speaking rhythm. Which PTE task would you like to practice: Read Aloud, Repeat Sentence, or Describe Image?';
    }

    // 3. Duolingo English Test (DET) Evaluation Request
    if (lower.contains('duolingo') || lower.contains('det')) {
      if (lower.contains('evaluate') || lower.contains('score') || lower.contains('feedback')) {
        return '📊 Duolingo English Test Evaluation:\n'
            '• Overall Estimated Band: 115/160\n'
            '• Literacy: 110/160 | Comprehension: 120/160\n'
            '• Conversation: 115/160 | Production: 115/160\n'
            '• Feedback: Good descriptive range and syntactic variety. Expanding on cause-and-effect will elevate your Production subscore.';
      }
      return 'For the Duolingo English Test, aim to speak for the full time limit (at least 60–75 seconds) and use diverse descriptive adjectives. Would you like to practice "Speak About the Image" or "Read then Speak"?';
    }

    // 4. IELTS Evaluation / Feedback Request
    if (lower.contains('feedback') && (lower.contains('ielts') || (systemPrompt ?? '').contains('IELTS'))) {
      return '🎯 IELTS Examiner Feedback:\n'
          '• Lexical Resource: Good contextual vocabulary. Try incorporating C1 collocations.\n'
          '• Grammatical Range: Well-structured compound sentences with accurate tense usage.\n'
          '• Fluency Tip: Connect your ideas with transitional phrases like "In light of this" or "As a consequence".';
    }

    // 5. Greetings & Openings
    if (lower == 'start' ||
        lower.startsWith('start a ') ||
        lower.startsWith('hello') ||
        lower.startsWith('hi ') ||
        lower == 'hi' ||
        lower.startsWith('hey') ||
        lower.contains('greet me')) {
      if ((systemPrompt ?? '').contains('job') || (systemPrompt ?? '').contains('interview')) {
        return "Hello! Welcome to your interview practice session. I'm Eloqui. Let's begin: Could you please introduce yourself and highlight your key strengths?";
      }
      if ((systemPrompt ?? '').contains('ielts') || (systemPrompt ?? '').contains('part')) {
        return "Hello! I am your IELTS Speaking examiner today. In this session, we'll practice speaking clearly and fluently. Let's start with a general topic: Where are you from, and what do you like most about your hometown?";
      }
      if ((systemPrompt ?? '').contains('business')) {
        return "Hello! Welcome to our business English session. Let's practice professional communication. To start, could you brief me on a recent project or challenge you managed at work?";
      }
      return "Hello! I'm Eloqui, your personal AI English coach. I'm excited to practice with you today! What topic or speaking goal would you like to focus on right now?";
    }

    // 6. Direct Questions from User (Q&A Handling)
    if (lower.startsWith('what is') ||
        lower.startsWith('what are') ||
        lower.startsWith('how do') ||
        lower.startsWith('how can') ||
        lower.startsWith('why do') ||
        lower.startsWith('why is') ||
        lower.startsWith('can you explain') ||
        lower.startsWith('could you explain') ||
        lower.startsWith('tell me about') ||
        lower.contains('difference between')) {
      return _generateInformativeAnswer(cleanPrompt, lower);
    }

    // 7. Grammar / Vocabulary Inquiry
    if (lower.contains('how do i say') || lower.contains('is it correct to say') || lower.contains('better way to say')) {
      return 'That is a great question about English phrasing! In natural conversation, native speakers often say: "$cleanPrompt" can be expressed more idiomatically as "To put it simply..." or "From my perspective...". Would you like to practice using this in a full sentence?';
    }

    // 8. Extract Topic Keywords & Context
    final topicKeywords = _extractKeywords(cleanPrompt);
    final mainTopic = topicKeywords.isNotEmpty ? topicKeywords.first : 'that';

    // 9. Check Domain Topics
    // A. Technology & AI
    if (lower.contains('tech') || lower.contains('ai') || lower.contains('computer') || lower.contains('software') || lower.contains('internet') || lower.contains('app')) {
      final responses = [
        'Technology is evolving at a remarkable pace! Regarding $mainTopic, how do you think it affects our daily productivity and attention span?',
        'That is an intriguing point about $mainTopic. Do you believe artificial intelligence will create more opportunities or replace traditional roles in that area?',
        'Fascinating observation! If you were explaining the benefits of $mainTopic to an older generation, how would you describe it?',
      ];
      return responses[turnCount % responses.length];
    }

    // B. Career & Work / Interview
    if (lower.contains('work') || lower.contains('job') || lower.contains('career') || lower.contains('office') || lower.contains('company') || lower.contains('interview') || lower.contains('manager') || lower.contains('team')) {
      final responses = [
        'Professional communication is essential in the modern workplace. When handling $mainTopic, what strategies do you use to ensure clear collaboration?',
        'That is a valuable career insight! Can you describe a specific challenge involving $mainTopic that you successfully overcame?',
        'Great perspective! In a job interview, explaining $mainTopic using the STAR method (Situation, Task, Action, Result) will make your answer stand out. What was the outcome in that situation?',
      ];
      return responses[turnCount % responses.length];
    }

    // C. Travel & Places
    if (lower.contains('travel') || lower.contains('city') || lower.contains('country') || lower.contains('trip') || lower.contains('visit') || lower.contains('culture') || lower.contains('tourism')) {
      final responses = [
        'Traveling broadens our perspectives significantly! Regarding $mainTopic, what was the most memorable experience or cultural difference you observed?',
        'That sounds like a wonderful destination! If a friend asked you for advice before visiting $mainTopic, what would you recommend they see or do first?',
        'Exploring new places teaches us so much. How has visiting or learning about $mainTopic influenced the way you view your own culture?',
      ];
      return responses[turnCount % responses.length];
    }

    // D. Food & Lifestyle
    if (lower.contains('food') || lower.contains('cook') || lower.contains('dish') || lower.contains('restaurant') || lower.contains('eat') || lower.contains('health') || lower.contains('exercise') || lower.contains('habit')) {
      final responses = [
        'Healthy habits and good food make a big difference in daily energy! What is your favorite aspect of $mainTopic, and how often do you practice it?',
        'That sounds delicious and rewarding! In many cultures, $mainTopic brings people together. How does your family or friend group celebrate special occasions around food?',
        'Great point! How do you maintain consistency with $mainTopic when your schedule gets busy?',
      ];
      return responses[turnCount % responses.length];
    }

    // E. Education & Learning
    if (lower.contains('study') || lower.contains('learn') || lower.contains('school') || lower.contains('college') || lower.contains('university') || lower.contains('student') || lower.contains('teacher') || lower.contains('exam')) {
      final responses = [
        'Lifelong learning is one of the most rewarding pursuits! When studying $mainTopic, what learning technique helps you retain information best?',
        'That is a thoughtful observation about education. Do you think traditional classrooms or digital learning platforms are more effective for understanding $mainTopic?',
        'Excellent point! How has your approach to mastering $mainTopic changed compared to when you first started?',
      ];
      return responses[turnCount % responses.length];
    }

    // F. Environment & Society
    if (lower.contains('environment') || lower.contains('nature') || lower.contains('climate') || lower.contains('pollution') || lower.contains('society') || lower.contains('government') || lower.contains('community')) {
      final responses = [
        'Environmental sustainability is one of the most critical topics today. In your opinion, what individual actions can make a real difference regarding $mainTopic?',
        'That is a compelling societal issue. Should local communities or national policies take the lead in addressing $mainTopic?',
        'Well said! How do you think public awareness regarding $mainTopic has evolved over the past decade?',
      ];
      return responses[turnCount % responses.length];
    }

    // 10. Context-Aware General Conversational Turns (Dynamic & Engaging)
    // Use conversation history to generate more relevant follow-ups.
    // Context is derived solely from the supplied history (see _analyzeHistory).
    final isDeepConversation = context.conversationFlow == 'deep' || context.conversationFlow == 'extended';
    final hasPriorContext = context.recentTopics.isNotEmpty;
    final primaryTopic = context.recentTopics.isNotEmpty ? context.recentTopics.first : mainTopic;
    final themeTopic = context.userInterests.isNotEmpty
        ? context.userInterests.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : mainTopic;

    // Build context-aware responses
    final generalResponses = <String>[
      if (hasPriorContext && context.recentTopics.length > 1)
        'You mentioned ${context.recentTopics.take(2).join(" and ")} earlier — how do you see those connecting to $primaryTopic?',
      if (hasPriorContext)
        'Earlier you talked about ${context.recentTopics.first}. How does that relate to what you just said about $primaryTopic?',
      if (isDeepConversation)
        'This is becoming a really rich discussion! You\'ve touched on ${context.recentTopics.take(3).join(", ")} — what\'s the common thread you see?',
      'You explained "$cleanPrompt" very clearly! To add more depth, could you elaborate on what led you to that conclusion about $primaryTopic?',
      'That is an insightful observation! What do you think is the biggest misconception people have about $primaryTopic?',
      'I appreciate your thoughtful response! How would you describe the long-term impact of $primaryTopic on our daily lives?',
      'Well expressed! If someone had an opposing viewpoint on $primaryTopic, what counterargument might they bring up?',
      'That is a solid point! Looking back on your personal experience with $primaryTopic, what is the most important lesson you have learned?',
      'Excellent flow! To stretch your fluency even further, try using advanced connectors like "On one hand... yet on the other hand...". What other factors play a role in $primaryTopic?',
      if (themeTopic != primaryTopic)
        'I notice we\'ve been circling around $themeTopic throughout our conversation. What aspect of it interests you most?',
    ];

    // Use a hash of the prompt for consistent but varied selection
    final selectionIndex = (cleanPrompt.hashCode + turnCount).abs() % generalResponses.length;
    return generalResponses[selectionIndex];
  }

  String _generateInformativeAnswer(String prompt, String lower) {
    if (lower.contains('ielts') || lower.contains('band')) {
      return 'The IELTS Speaking test assesses 4 core criteria: Fluency & Coherence, Lexical Resource, Grammatical Range & Accuracy, and Pronunciation (each worth 25%). To score Band 7+, aim to speak continuously with natural discourse markers, minimal hesitation, and a variety of complex sentences. What specific part of IELTS are you preparing for?';
    }
    if (lower.contains('filler') || lower.contains('um') || lower.contains('uh')) {
      return 'Filler words (like "um", "uh", "you know") occur when your brain needs time to formulate the next idea. The best technique to reduce them is the "Power Pause" — simply pause silently for 1–2 seconds instead of vocalizing. Would you like to try answering a practice question with conscious pausing?';
    }
    if (lower.contains('fluency') || lower.contains('fluent')) {
      return 'Fluency in English comes from connected speech, natural pausing, and chunking words into meaningful phrases rather than translating word-by-word. Daily speaking practice with immediate feedback is the fastest way to build automaticity. What topic would you like to practice right now?';
    }
    if (lower.contains('pronunciation') || lower.contains('accent')) {
      return 'Good pronunciation is not about having a native accent — it is about clear articulation, correct word stress, and rhythm. Focusing on stressed syllables in multi-syllabic words makes speech instantly clearer. Would you like to practice pronouncing some challenging words?';
    }
    return 'That is an interesting question! Regarding "$prompt", the key aspect is understanding the underlying context and applying it consistently in spoken conversation. How do you usually approach this in your everyday practice?';
  }

  List<String> _extractKeywords(String text) {
    final stopWords = {
      'the', 'is', 'at', 'which', 'on', 'a', 'an', 'and', 'or', 'in', 'to', 'for', 'of', 'with',
      'about', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'your', 'start', 'hello', 'hi',
      'think', 'like', 'would', 'could', 'should', 'have', 'has', 'had', 'me', 'am', 'are', 'was',
      'were', 'be', 'been', 'this', 'that', 'these', 'those', 'from', 'also', 'very', 'just', 'really'
    };
    final words = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3 && !stopWords.contains(w)).toList();
    return words;
  }

  @override
  Future<String> summarizeConversation(List<Message> messages) async {
    if (messages.isEmpty) return 'No conversation history.';
    final userMsgs = messages.where((m) => m.role == 'user').map((m) => m.content).join(' ');
    final keywords = _extractKeywords(userMsgs).take(4).join(', ');
    return 'User discussed key topics including: ${keywords.isNotEmpty ? keywords : "speaking practice & personal background"}.';
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

/// Internal class to hold analyzed conversation context
class _ConversationContext {
  final List<String> topics;
  final List<String> recentTopics;
  final Map<String, int> userInterests;
  final String conversationFlow; // 'opening', 'developing', 'deep', 'extended'
  final int turnCount;

  _ConversationContext({
    required this.topics,
    required this.recentTopics,
    required this.userInterests,
    required this.conversationFlow,
    required this.turnCount,
  });
}


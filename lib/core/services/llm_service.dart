import '../models/conversation.dart';

abstract class LLMService {
  bool get isLoaded;
  Future<void> loadModel(String modelPath);
  Future<String> generate(String prompt, {List<Message>? context, String? systemPrompt});
  void dispose();
}

/// Mock LLM for development/Phase 1 — deterministic, instant responses.
class MockLLMService implements LLMService {
  @override
  bool get isLoaded => true;

  @override
  Future<void> loadModel(String modelPath) async {}

  @override
  Future<String> generate(String prompt,
      {List<Message>? context, String? systemPrompt}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _smartResponse(prompt, systemPrompt);
  }

  @override
  void dispose() {}

  String _smartResponse(String prompt, String? systemPrompt) {
    final p = prompt.toLowerCase();
    if (p.contains('hello') || p.contains('hi ') || p.contains('greet')) {
      return 'Hello! Great to meet you. How are you doing today? Let\'s have a wonderful conversation in English!';
    }
    if (p.contains('my name is') || p.contains('i am ') || p.contains("i'm ")) {
      return 'Nice to meet you! Tell me a bit more about yourself — where are you from, and what brings you to practice English today?';
    }
    if (p.contains('ielts') || p.contains('band')) {
      return 'IELTS Speaking is assessed on four criteria: Fluency & Coherence, Lexical Resource, Grammatical Range, and Pronunciation. Your target band score determines how much detail and complexity you need in your answers. Which part would you like to practice?';
    }
    if (p.contains('job') || p.contains('interview') || p.contains('work')) {
      return 'Tell me about your professional background. What position are you applying for, and what are your key strengths that make you a great candidate?';
    }
    if (p.contains('travel') || p.contains('trip') || p.contains('visit')) {
      return 'Traveling is a fantastic experience! Where are you planning to go, and how long will you be staying? Have you made all your arrangements?';
    }
    if (p.contains('food') || p.contains('restaurant') || p.contains('eat')) {
      return 'Food is such an important part of culture! What kind of cuisine do you enjoy the most? Have you tried any interesting dishes recently?';
    }
    if (p.contains('study') || p.contains('college') || p.contains('university')) {
      return 'Education opens so many doors! What are you studying, and what career path are you hoping to pursue? What\'s the most challenging aspect of your studies?';
    }
    if (p.contains('agree') || p.contains('opinion') || p.contains('think')) {
      return 'That\'s an interesting perspective. Could you elaborate on why you hold that view? Have you considered any counterarguments? In a debate, being able to address opposing viewpoints strengthens your position significantly.';
    }
    if (p.contains('pronunciation') || p.contains('sound') || p.contains('say')) {
      return 'Pronunciation is key to clear communication. Focus on word stress, vowel sounds, and connected speech. For example, in English, we often link words together — "want to" becomes "wanna" in natural speech. Would you like to practice some specific sounds?';
    }
    // Default intelligent response
    final responses = [
      'That\'s a great point! Could you tell me more about that? I\'d love to hear your thoughts in detail.',
      'Interesting! How did that make you feel, and what would you do differently if you faced that situation again?',
      'I see what you mean. Can you give me a specific example to illustrate your point?',
      'Well expressed! Now, let me challenge you a little — what are some of the downsides of that idea?',
      'Excellent! Your vocabulary is developing nicely. Try to use more complex sentence structures like conditional clauses or relative clauses in your next response.',
      'Good effort! Remember to maintain a steady pace and avoid filler words like "um" and "uh". What else would you like to discuss?',
    ];
    return responses[prompt.length % responses.length];
  }
}

/// Stub for future llama.cpp FFI integration.
/// Replace MockLLMService with this when native bridge is ready.
class LlamaCppService implements LLMService {
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> loadModel(String modelPath) async {
    // TODO: dart:ffi call to llama_model_load()
    throw UnimplementedError('llama.cpp FFI bridge not yet implemented. Use MockLLMService.');
  }

  @override
  Future<String> generate(String prompt,
      {List<Message>? context, String? systemPrompt}) async {
    // TODO: dart:ffi call to llama_eval()
    throw UnimplementedError('llama.cpp FFI bridge not yet implemented.');
  }

  @override
  void dispose() {
    // TODO: dart:ffi call to llama_free()
  }
}

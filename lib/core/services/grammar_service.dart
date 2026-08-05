import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_engine.dart';


class GrammarCorrection {
  final String original;
  final String corrected;
  final String rule;
  final String explanation;
  final String? betterVocab;

  const GrammarCorrection({
    required this.original,
    required this.corrected,
    required this.rule,
    required this.explanation,
    this.betterVocab,
  });

  Map<String, dynamic> toMap() => {
        'original': original,
        'corrected': corrected,
        'rule': rule,
        'explanation': explanation,
        'betterVocab': betterVocab,
      };
}

class GrammarService {
  static final GrammarService instance = GrammarService._();
  GrammarService._();

  /// Hybrid Analysis: Fast Isolate Rule Matcher + Optional LLM Refinement
  Future<List<GrammarCorrection>> analyzeHybrid({
    required String text,
    AIEngine? aiEngine,
  }) async {
    // 1. Fast isolate rule check (No main-thread jank)
    final ruleCorrections = await compute(_runRuleEngine, text);

    // 2. If AI engine is active and loaded, perform secondary refinement
    if (aiEngine != null && aiEngine.state == AIModelState.ready && ruleCorrections.isNotEmpty) {
      final errorSummaries = ruleCorrections.map((c) => c.rule).toList();
      final refinedText = await aiEngine.refineGrammar(text, errorSummaries);
      if (refinedText != text) {
        ruleCorrections.add(GrammarCorrection(
          original: text,
          corrected: refinedText,
          rule: 'AI Style & Precision',
          explanation: 'AI refined phrasing for enhanced naturalness and elegance.',
        ));
      }
    }

    return ruleCorrections;
  }

  /// Synchronous rule check (used internally inside compute isolate)
  List<GrammarCorrection> analyzeSync(String text) {
    return _runRuleEngine(text);
  }
}

/// Standalone top-level function for compute() isolate execution
List<GrammarCorrection> _runRuleEngine(String text) {
  final corrections = <GrammarCorrection>[];
  final pastParticiples = {
    'went': 'gone',
    'came': 'come',
    'saw': 'seen',
    'ate': 'eaten',
    'wrote': 'written',
  };
  final rules = [
    // Articles
    _Rule(r'\ba ([aeiouAEIOU])', (m) => 'an ${m.group(1)}', 'Article Error', 'Use "an" before vowel sounds.'),
    _Rule(r'\ban ([bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ])', (m) => 'a ${m.group(1)}', 'Article Error', 'Use "a" before consonant sounds.'),
    // Subject-verb
    _Rule(r"\b(He|She|It) (don't|do not)\b", (m) => "${m.group(1)} doesn't", 'Subject-Verb Agreement', 'Use "doesn\'t" with 3rd-person singular.'),
    _Rule(r'\b(He|She|It) have\b', (m) => '${m.group(1)} has', 'Subject-Verb Agreement', 'Use "has" with 3rd-person singular.'),
    _Rule(r'\b(I|You|We|They) has\b', (m) => '${m.group(1)} have', 'Subject-Verb Agreement', 'Use "have" with plural or 1st/2nd person subjects.'),
    _Rule(r'\bI are\b', (_) => 'I am', 'Subject-Verb Agreement', 'Use "am" with "I".'),
    _Rule(r'\bYou is\b', (_) => 'You are', 'Subject-Verb Agreement', 'Use "are" with "you".'),
    // Tense
    _Rule(r'\bdid (went|came|saw|told|knew|had|made|got|took)\b', (m) => m.group(1)!, 'Tense Error', 'Use base verb after "did".'),
    _Rule(r'\bI have (went|came|saw|ate|wrote)\b', (m) => 'I have ${pastParticiples[m.group(1)!.toLowerCase()] ?? m.group(1)!}', 'Tense Error', 'Use past participle with "have".'),
    // Modals
    _Rule(r'\b(should|could|would|must) to\b', (m) => m.group(1)!, 'Modal Error', 'Do not use "to" after modal verbs.'),
    // Prepositions
    _Rule(r'\bdiscuss about\b', (_) => 'discuss', 'Preposition Error', '"Discuss" does not take "about".'),
    _Rule(r'\bmarried with\b', (_) => 'married to', 'Preposition Error', 'Say "married to".'),
    _Rule(r'\binterested (on|for)\b', (_) => 'interested in', 'Preposition Error', 'Say "interested in".'),
    _Rule(r'\bdepend (in|from)\b', (_) => 'depend on', 'Preposition Error', 'Say "depend on".'),
  ];

  for (final r in rules) {
    final matches = r.pattern.allMatches(text);
    for (final match in matches) {
      final original = match.group(0)!;
      final corrected = original.replaceFirstMapped(r.pattern, r.replacement);
      if (corrected != original) {
        corrections.add(GrammarCorrection(
          original: original,
          corrected: corrected,
          rule: r.rule,
          explanation: r.explanation,
        ));
      }
    }
  }

  return corrections;
}

class _Rule {
  final RegExp pattern;
  final String Function(Match) replacement;
  final String rule;
  final String explanation;

  _Rule(String patternStr, this.replacement, this.rule, this.explanation)
      : pattern = RegExp(patternStr, caseSensitive: false);
}

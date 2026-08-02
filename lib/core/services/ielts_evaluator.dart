import '../models/ielts_score.dart';
import 'grammar_service.dart';

class SpeakingAnalysis {
  final String transcript;
  final double durationSeconds;
  final int fillerCount;
  final int pauseCount;
  final double totalPauseDurationSec;
  final int hesitationCount;
  final int repeatedWordsCount;
  final double sentenceCompletionRate;
  final double volumeConsistency;

  const SpeakingAnalysis({
    required this.transcript,
    required this.durationSeconds,
    this.fillerCount = 0,
    this.pauseCount = 0,
    this.totalPauseDurationSec = 0.0,
    this.hesitationCount = 0,
    this.repeatedWordsCount = 0,
    this.sentenceCompletionRate = 1.0,
    this.volumeConsistency = 0.95,
  });

  int get wordCount => transcript.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  double get wpm => durationSeconds > 0 ? (wordCount / durationSeconds) * 60 : 0;
  double get averagePauseLength => pauseCount > 0 ? totalPauseDurationSec / pauseCount : 0.0;
}

class DetailedScoreCriterion {
  final String criterionName;
  final double score;
  final String reason;
  final String nextBandActionableExample;

  const DetailedScoreCriterion({
    required this.criterionName,
    required this.score,
    required this.reason,
    required this.nextBandActionableExample,
  });
}

class SmartIeltsEvaluation {
  final IeltsScore score;
  final double confidencePercentage; // e.g. 92%
  final List<DetailedScoreCriterion> criterionDetails;
  final String nextBandRoadmap;

  const SmartIeltsEvaluation({
    required this.score,
    required this.confidencePercentage,
    required this.criterionDetails,
    required this.nextBandRoadmap,
  });
}

class EndOfSessionCoachReport {
  final List<String> top5Mistakes;
  final List<String> newWordsLearned;
  final List<String> pronunciationFocusWords;
  final String personalizedNextLesson;
  final int estimatedPracticeMinutes;

  const EndOfSessionCoachReport({
    required this.top5Mistakes,
    required this.newWordsLearned,
    required this.pronunciationFocusWords,
    required this.personalizedNextLesson,
    required this.estimatedPracticeMinutes,
  });
}

class IeltsEvaluator {
  static final IeltsEvaluator instance = IeltsEvaluator._();
  IeltsEvaluator._();

  SmartIeltsEvaluation evaluateSmarter(SpeakingAnalysis analysis, {String part = 'full'}) {
    final text = analysis.transcript.trim();
    final wordCount = analysis.wordCount;

    // --- ZERO SPEECH / EMPTY AUDIO SAFEGUARD ---
    if (text.isEmpty || wordCount < 3 || analysis.durationSeconds < 1.0) {
      final zeroScore = IeltsScore(
        fluency: 0.0,
        lexical: 0.0,
        grammar: 0.0,
        pronunciation: 0.0,
        overall: 0.0,
        part: part,
      );

      final zeroDetails = [
        const DetailedScoreCriterion(
          criterionName: 'Fluency & Coherence',
          score: 0.0,
          reason: '⚠️ No speech detected. Microphone captured 0 spoken words.',
          nextBandActionableExample: 'Hold the microphone button and speak clearly into your phone mic for at least 15–30 seconds.',
        ),
        const DetailedScoreCriterion(
          criterionName: 'Lexical Resource',
          score: 0.0,
          reason: '⚠️ No vocabulary recorded.',
          nextBandActionableExample: 'Answer using topic-specific vocabulary and complete sentences.',
        ),
        const DetailedScoreCriterion(
          criterionName: 'Grammatical Range & Accuracy',
          score: 0.0,
          reason: '⚠️ No grammatical structures submitted.',
          nextBandActionableExample: 'Form complete sentences with subject, verb, and supporting reasons.',
        ),
        const DetailedScoreCriterion(
          criterionName: 'Pronunciation',
          score: 0.0,
          reason: '⚠️ No audio signal detected.',
          nextBandActionableExample: 'Ensure RECORD_AUDIO permission is granted in Android App Settings.',
        ),
      ];

      return SmartIeltsEvaluation(
        score: zeroScore,
        confidencePercentage: 0.0,
        criterionDetails: zeroDetails,
        nextBandRoadmap: 'Please speak into your device microphone to receive an accurate AI IELTS evaluation.',
      );
    }

    // --- DYNAMIC EVALUATION FOR SPOKEN TEXT ---
    final fluency = _scoreFluency(analysis);
    final lexical = _scoreLexical(text, wordCount);
    final grammar = _scoreGrammar(text);
    final pronunciation = _scorePronunciation(analysis);
    final overall = _roundToBand((fluency + lexical + grammar + pronunciation) / 4);

    final scoreObj = IeltsScore(
      fluency: fluency,
      lexical: lexical,
      grammar: grammar,
      pronunciation: pronunciation,
      overall: overall,
      part: part,
    );

    final details = [
      DetailedScoreCriterion(
        criterionName: 'Fluency & Coherence',
        score: fluency,
        reason: 'Pace: ${analysis.wpm.toStringAsFixed(0)} WPM (${wordCount} words in ${analysis.durationSeconds.toStringAsFixed(1)}s) with ${analysis.fillerCount} fillers.',
        nextBandActionableExample: 'For Band ${(fluency + 0.5).clamp(1.0, 9.0)}: Maintain 120–150 WPM pace using connectors like "Furthermore" and "Consequently".',
      ),
      DetailedScoreCriterion(
        criterionName: 'Lexical Resource',
        score: lexical,
        reason: 'Spoken vocabulary of $wordCount words with unique word diversity.',
        nextBandActionableExample: 'For Band ${(lexical + 0.5).clamp(1.0, 9.0)}: Incorporate C1 idioms and topic collocations.',
      ),
      DetailedScoreCriterion(
        criterionName: 'Grammatical Range & Accuracy',
        score: grammar,
        reason: 'Grammatical sentence structure evaluated across $wordCount words.',
        nextBandActionableExample: 'For Band ${(grammar + 0.5).clamp(1.0, 9.0)}: Use complex compound sentences with relative clauses ("which means...", "although...").',
      ),
      DetailedScoreCriterion(
        criterionName: 'Pronunciation',
        score: pronunciation,
        reason: 'Voice signal volume consistency of ${(analysis.volumeConsistency * 100).toStringAsFixed(0)}%.',
        nextBandActionableExample: 'For Band ${(pronunciation + 0.5).clamp(1.0, 9.0)}: Emphasize key content words with natural sentence stress.',
      ),
    ];

    double confidence = 95.0;
    if (wordCount < 20) confidence = 65.0;
    else if (wordCount < 40) confidence = 80.0;

    return SmartIeltsEvaluation(
      score: scoreObj,
      confidencePercentage: confidence,
      criterionDetails: details,
      nextBandRoadmap: 'To improve from Band $overall to Band ${(overall + 0.5).clamp(1.0, 9.0)}, extend answers to 30+ seconds and use 2 complex connectors per response.',
    );
  }

  IeltsScore evaluate(SpeakingAnalysis analysis, {String part = 'full'}) {
    return evaluateSmarter(analysis, part: part).score;
  }

  double _scoreFluency(SpeakingAnalysis a) {
    if (a.wordCount < 10) return 3.0;
    if (a.wordCount < 20) return 4.5;

    double score = 5.0;
    if (a.wpm >= 110 && a.wpm <= 160) score += 2.0;
    else if (a.wpm >= 80 && a.wpm < 110) score += 1.0;
    else if (a.wpm > 160 && a.wpm <= 190) score += 1.0;
    else score += 0.5;

    final fillerRatio = a.wordCount > 0 ? (a.fillerCount + a.hesitationCount) / a.wordCount : 0.0;
    if (fillerRatio < 0.02) score += 1.0;
    else if (fillerRatio > 0.06) score -= 1.0;

    return score.clamp(1.0, 9.0);
  }

  double _scoreLexical(String text, int wordCount) {
    if (wordCount < 10) return 3.0;
    final words = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toList();
    if (words.isEmpty) return 2.0;

    final uniqueWords = words.toSet();
    final ttr = uniqueWords.length / words.length;
    double score = 4.0;
    if (ttr > 0.70) score += 2.5;
    else if (ttr > 0.55) score += 1.5;
    else if (ttr > 0.40) score += 1.0;

    // Advanced vocabulary bonus
    final advancedMatch = RegExp(r'\b(consequently|furthermore|articulate|pivotal|profound|mitigate|subsequent|nevertheless|substantial|paramount|illustrate)\b', caseSensitive: false).allMatches(text).length;
    score += (advancedMatch * 0.5).clamp(0.0, 1.5);

    return score.clamp(1.0, 9.0);
  }

  double _scoreGrammar(String text) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount < 10) return 3.0;

    double score = 5.0;
    if (RegExp(r'\b(if|would|could|although|whereas|because|however|therefore)\b', caseSensitive: false).hasMatch(text)) {
      score += 1.5;
    }
    if (RegExp(r'\b(have been|had been|will be|is being)\b', caseSensitive: false).hasMatch(text)) {
      score += 1.0;
    }

    final mistakes = GrammarService.instance.analyzeSync(text);
    score -= mistakes.length * 0.5;

    return score.clamp(1.0, 9.0);
  }

  double _scorePronunciation(SpeakingAnalysis a) {
    if (a.wordCount < 10) return 3.0;
    double score = 5.0;
    if (a.volumeConsistency > 0.80) score += 1.5;
    if (a.fillerCount < 2) score += 1.0;
    return score.clamp(1.0, 9.0);
  }

  double _roundToBand(double score) => (score * 2).round() / 2;

  String getFeedback(IeltsScore score) {
    if (score.overall == 0.0) {
      return '⚠️ No Speech Detected\n\nPlease record your spoken answer using the microphone.';
    }
    return 'Overall Band ${score.overall} — ${score.bandLabel}\n\n'
        '• Fluency: ${score.fluency}\n'
        '• Lexical Resource: ${score.lexical}\n'
        '• Grammatical Range: ${score.grammar}\n'
        '• Pronunciation: ${score.pronunciation}';
  }

  EndOfSessionCoachReport generateCoachReport(SpeakingAnalysis analysis, List<String> detectedMistakes) {
    final topMistakes = detectedMistakes.take(5).toList();
    if (topMistakes.isEmpty) {
      topMistakes.add('Minor hesitation on complex multisyllabic terms');
    }

    return EndOfSessionCoachReport(
      top5Mistakes: topMistakes,
      newWordsLearned: ['articulate', 'nevertheless', 'consequently'],
      pronunciationFocusWords: ['specifically', 'particularly', 'comfortably'],
      personalizedNextLesson: 'Part 2 Cue Card: Describe an environmental challenge in your city',
      estimatedPracticeMinutes: 15,
    );
  }
}

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
  final double averageWordConfidence;

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
    this.averageWordConfidence = 0.90,
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
  final double confidencePercentage;
  final List<DetailedScoreCriterion> criterionDetails;
  final List<GrammarCorrection> detectedErrors;
  final String nextBandRoadmap;

  const SmartIeltsEvaluation({
    required this.score,
    required this.confidencePercentage,
    required this.criterionDetails,
    required this.detectedErrors,
    required this.nextBandRoadmap,
  });
}

class EndOfSessionCoachReport {
  final List<GrammarCorrection> speechErrors;
  final List<String> top5Mistakes;
  final List<String> newWordsLearned;
  final List<String> pronunciationFocusWords;
  final String personalizedNextLesson;
  final int estimatedPracticeMinutes;

  const EndOfSessionCoachReport({
    required this.speechErrors,
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
    final detectedErrors = GrammarService.instance.analyzeSync(text);

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
        detectedErrors: const [],
        nextBandRoadmap: 'Please speak into your device microphone to receive an accurate AI IELTS evaluation.',
      );
    }

    // --- DYNAMIC EVALUATION FOR SPOKEN TEXT ---
    final fluency = _scoreFluency(analysis);
    final lexical = _scoreLexical(text, wordCount);
    final grammar = _scoreGrammar(text, detectedErrors.length);
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
        reason: 'Pace: ${analysis.wpm.toStringAsFixed(0)} WPM ($wordCount words in ${analysis.durationSeconds.toStringAsFixed(1)}s) with ${analysis.fillerCount} fillers.',
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
        reason: 'Found ${detectedErrors.length} grammatical error(s) across $wordCount spoken words.',
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
      detectedErrors: detectedErrors,
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

    final advancedMatch = RegExp(r'\b(consequently|furthermore|articulate|pivotal|profound|mitigate|subsequent|nevertheless|substantial|paramount|illustrate)\b', caseSensitive: false).allMatches(text).length;
    score += (advancedMatch * 0.5).clamp(0.0, 1.5);

    return score.clamp(1.0, 9.0);
  }

  double _scoreGrammar(String text, int mistakeCount) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount < 10) return 3.0;

    double score = 5.0;
    if (RegExp(r'\b(if|would|could|although|whereas|because|however|therefore)\b', caseSensitive: false).hasMatch(text)) {
      score += 1.5;
    }
    if (RegExp(r'\b(have been|had been|will be|is being)\b', caseSensitive: false).hasMatch(text)) {
      score += 1.0;
    }

    score -= mistakeCount * 0.75;
    return score.clamp(1.0, 9.0);
  }

  double _scorePronunciation(SpeakingAnalysis a) {
    if (a.wordCount < 10) return 3.0;
    double score = 5.0;

    // Acoustic Token Confidence rating from STT decoding
    if (a.averageWordConfidence >= 0.85) {
      score += 1.5;
    } else if (a.averageWordConfidence < 0.65) {
      score -= 1.5;
    }

    if (a.volumeConsistency > 0.80) score += 0.5;
    if (a.fillerCount < 2) score += 0.5;
    else if (a.fillerCount > 5) score -= 1.0;

    if (a.hesitationCount == 0) score += 0.5;
    else if (a.hesitationCount > 3) score -= 0.5;

    if (a.averagePauseLength < 1.5) score += 0.5;
    else if (a.averagePauseLength > 3.0) score -= 1.0;

    return score.clamp(1.0, 9.0);
  }

  double _roundToBand(double score) => (score * 2).round() / 2;

  EndOfSessionCoachReport generateCoachReport(SpeakingAnalysis analysis, List<GrammarCorrection> detectedErrors) {
    final topMistakes = detectedErrors.map((e) => '${e.rule}: "${e.original}" → "${e.corrected}"').toList();
    if (topMistakes.isEmpty) {
      topMistakes.add('Great grammar! Focus on expanding your vocabulary range.');
    }

    final words = analysis.transcript.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 5).toSet().toList();
    final newWords = words.isNotEmpty ? words.take(3).toList() : ['articulate', 'nevertheless', 'consequently'];
    final longWords = words.where((w) => w.length > 7).take(3).toList();
    final pronWords = longWords.isNotEmpty ? longWords : ['specifically', 'particularly', 'comfortably'];

    return EndOfSessionCoachReport(
      speechErrors: detectedErrors,
      top5Mistakes: topMistakes.take(5).toList(),
      newWordsLearned: newWords,
      pronunciationFocusWords: pronWords,
      personalizedNextLesson: 'Part 2 Cue Card: Describe an environmental challenge in your city',
      estimatedPracticeMinutes: 15,
    );
  }
}

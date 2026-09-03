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

// ---------------------------------------------------------------------------
// TOEFL iBT Evaluator (0–30 Scale)
// ---------------------------------------------------------------------------
class ToeflEvaluation {
  final int overallScore; // 0–30
  final double deliveryScore; // 0.0–4.0
  final double languageUseScore; // 0.0–4.0
  final double topicDevScore; // 0.0–4.0
  final List<DetailedScoreCriterion> criteria;
  final List<GrammarCorrection> detectedErrors;
  final String feedbackSummary;

  const ToeflEvaluation({
    required this.overallScore,
    required this.deliveryScore,
    required this.languageUseScore,
    required this.topicDevScore,
    required this.criteria,
    required this.detectedErrors,
    required this.feedbackSummary,
  });
}

class ToeflEvaluator {
  static final ToeflEvaluator instance = ToeflEvaluator._();
  ToeflEvaluator._();

  ToeflEvaluation evaluate(SpeakingAnalysis analysis, {String taskTitle = 'Task 1'}) {
    final text = analysis.transcript.trim();
    final wordCount = analysis.wordCount;
    final detectedErrors = GrammarService.instance.analyzeSync(text);

    if (text.isEmpty || wordCount < 3 || analysis.durationSeconds < 1.0) {
      return ToeflEvaluation(
        overallScore: 0,
        deliveryScore: 0.0,
        languageUseScore: 0.0,
        topicDevScore: 0.0,
        criteria: [
          const DetailedScoreCriterion(
            criterionName: 'Delivery',
            score: 0.0,
            reason: '⚠️ No speech detected.',
            nextBandActionableExample: 'Tap the mic and speak your response clearly.',
          ),
          const DetailedScoreCriterion(
            criterionName: 'Language Use',
            score: 0.0,
            reason: '⚠️ No vocabulary recorded.',
            nextBandActionableExample: 'Form complete sentences with academic vocabulary.',
          ),
          const DetailedScoreCriterion(
            criterionName: 'Topic Development',
            score: 0.0,
            reason: '⚠️ No response content.',
            nextBandActionableExample: 'State your opinion and provide 2 supporting reasons.',
          ),
        ],
        detectedErrors: const [],
        feedbackSummary: 'No spoken response recorded. Please speak into the mic to get your TOEFL score.',
      );
    }

    // 1. Delivery (0–4 scale)
    double delivery = 2.0;
    if (analysis.wpm >= 110 && analysis.wpm <= 160) delivery += 1.2;
    else if (analysis.wpm >= 80) delivery += 0.6;
    if (analysis.fillerCount == 0) delivery += 0.5;
    else if (analysis.fillerCount > 3) delivery -= 0.6;
    if (analysis.averageWordConfidence >= 0.85) delivery += 0.3;
    delivery = delivery.clamp(1.0, 4.0);

    // 2. Language Use (0–4 scale)
    double langUse = 2.5;
    if (detectedErrors.isEmpty) langUse += 1.0;
    else langUse -= (detectedErrors.length * 0.4);
    if (RegExp(r'\b(furthermore|moreover|consequently|specifically|in addition|therefore)\b', caseSensitive: false).hasMatch(text)) {
      langUse += 0.5;
    }
    langUse = langUse.clamp(1.0, 4.0);

    // 3. Topic Development (0–4 scale)
    double topicDev = 2.0;
    if (wordCount >= 80) topicDev += 1.5;
    else if (wordCount >= 50) topicDev += 1.0;
    else if (wordCount >= 30) topicDev += 0.5;
    if (RegExp(r'\b(firstly|secondly|for example|for instance|because|reason)\b', caseSensitive: false).hasMatch(text)) {
      topicDev += 0.5;
    }
    topicDev = topicDev.clamp(1.0, 4.0);

    final avgRubric = (delivery + langUse + topicDev) / 3.0; // 1.0 to 4.0
    final overall = ((avgRubric / 4.0) * 30).round().clamp(0, 30);

    final criteria = [
      DetailedScoreCriterion(
        criterionName: 'Delivery',
        score: delivery,
        reason: 'Pace: ${analysis.wpm.toStringAsFixed(0)} WPM with ${analysis.fillerCount} filler words.',
        nextBandActionableExample: 'Maintain steady rhythm and clear intonation.',
      ),
      DetailedScoreCriterion(
        criterionName: 'Language Use',
        score: langUse,
        reason: '${detectedErrors.length} grammar mistake(s) across $wordCount spoken words.',
        nextBandActionableExample: 'Use varied sentence structures and topic-specific vocabulary.',
      ),
      DetailedScoreCriterion(
        criterionName: 'Topic Development',
        score: topicDev,
        reason: '$wordCount words spoken in ${analysis.durationSeconds.toStringAsFixed(0)}s.',
        nextBandActionableExample: 'Provide two distinct reasons with concrete personal or real-world examples.',
      ),
    ];

    return ToeflEvaluation(
      overallScore: overall,
      deliveryScore: delivery,
      languageUseScore: langUse,
      topicDevScore: topicDev,
      criteria: criteria,
      detectedErrors: detectedErrors,
      feedbackSummary: 'Estimated TOEFL Speaking Score: $overall/30. '
          'Delivery: ${delivery.toStringAsFixed(1)}/4, Language Use: ${langUse.toStringAsFixed(1)}/4, Topic Development: ${topicDev.toStringAsFixed(1)}/4.',
    );
  }
}

// ---------------------------------------------------------------------------
// PTE Academic Evaluator (10–90 Scale)
// ---------------------------------------------------------------------------
class PteEvaluation {
  final int overallScore; // 10–90
  final int oralFluency; // 10–90
  final int pronunciation; // 10–90
  final int content; // 10–90
  final List<DetailedScoreCriterion> criteria;
  final List<GrammarCorrection> detectedErrors;
  final String feedbackSummary;

  const PteEvaluation({
    required this.overallScore,
    required this.oralFluency,
    required this.pronunciation,
    required this.content,
    required this.criteria,
    required this.detectedErrors,
    required this.feedbackSummary,
  });
}

class PteEvaluator {
  static final PteEvaluator instance = PteEvaluator._();
  PteEvaluator._();

  PteEvaluation evaluate(SpeakingAnalysis analysis, {String taskType = 'Read Aloud', String expectedPrompt = ''}) {
    final text = analysis.transcript.trim();
    final wordCount = analysis.wordCount;
    final detectedErrors = GrammarService.instance.analyzeSync(text);

    if (text.isEmpty || wordCount < 3 || analysis.durationSeconds < 1.0) {
      return const PteEvaluation(
        overallScore: 10,
        oralFluency: 10,
        pronunciation: 10,
        content: 10,
        criteria: [
          DetailedScoreCriterion(
            criterionName: 'Oral Fluency',
            score: 10,
            reason: '⚠️ No speech detected.',
            nextBandActionableExample: 'Speak continuously without long pauses.',
          ),
          DetailedScoreCriterion(
            criterionName: 'Pronunciation',
            score: 10,
            reason: '⚠️ No audio captured.',
            nextBandActionableExample: 'Enunciate each word clearly into the microphone.',
          ),
          DetailedScoreCriterion(
            criterionName: 'Content',
            score: 10,
            reason: '⚠️ No words recorded.',
            nextBandActionableExample: 'Cover all key prompt points or read all words accurately.',
          ),
        ],
        detectedErrors: [],
        feedbackSummary: 'No spoken response detected. PTE Minimum Score: 10/90.',
      );
    }

    // 1. Oral Fluency (10–90)
    int fluency = 50;
    if (analysis.wpm >= 120 && analysis.wpm <= 160) fluency += 25;
    else if (analysis.wpm >= 90) fluency += 15;
    if (analysis.fillerCount == 0) fluency += 10;
    else fluency -= (analysis.fillerCount * 5);
    fluency = fluency.clamp(10, 90);

    // 2. Pronunciation (10–90)
    int pron = 50;
    if (analysis.averageWordConfidence >= 0.88) pron += 30;
    else if (analysis.averageWordConfidence >= 0.75) pron += 15;
    else pron -= 15;
    if (analysis.volumeConsistency >= 0.85) pron += 10;
    pron = pron.clamp(10, 90);

    // 3. Content (10–90)
    int content = 50;
    if (expectedPrompt.isNotEmpty) {
      final promptWords = expectedPrompt.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toSet();
      final spokenWords = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toSet();
      if (promptWords.isNotEmpty) {
        final matches = spokenWords.intersection(promptWords).length;
        final matchRate = matches / promptWords.length;
        content = (matchRate * 80 + 10).round().clamp(10, 90);
      }
    } else {
      if (wordCount >= 40) content += 25;
      else if (wordCount >= 20) content += 15;
      if (detectedErrors.isEmpty) content += 10;
      else content -= (detectedErrors.length * 5);
      content = content.clamp(10, 90);
    }

    final overall = ((fluency + pron + content) / 3).round().clamp(10, 90);

    final criteria = [
      DetailedScoreCriterion(
        criterionName: 'Oral Fluency',
        score: fluency.toDouble(),
        reason: 'Pace: ${analysis.wpm.toStringAsFixed(0)} WPM with ${analysis.fillerCount} hesitation(s).',
        nextBandActionableExample: 'Keep a natural, rhythmic flow without mid-sentence pauses.',
      ),
      DetailedScoreCriterion(
        criterionName: 'Pronunciation',
        score: pron.toDouble(),
        reason: 'Acoustic confidence: ${(analysis.averageWordConfidence * 100).toStringAsFixed(0)}%.',
        nextBandActionableExample: 'Place correct word stress on multi-syllable terms.',
      ),
      DetailedScoreCriterion(
        criterionName: 'Content',
        score: content.toDouble(),
        reason: 'Captured $wordCount words matching task objectives.',
        nextBandActionableExample: 'Ensure all key information points are articulated accurately.',
      ),
    ];

    return PteEvaluation(
      overallScore: overall,
      oralFluency: fluency,
      pronunciation: pron,
      content: content,
      criteria: criteria,
      detectedErrors: detectedErrors,
      feedbackSummary: 'Estimated PTE Academic Score: $overall/90. '
          'Fluency: $fluency, Pronunciation: $pron, Content: $content.',
    );
  }
}

// ---------------------------------------------------------------------------
// Duolingo English Test (DET) Evaluator (10–160 Scale)
// ---------------------------------------------------------------------------
class DetEvaluation {
  final int overallScore; // 10–160 (steps of 5)
  final int literacy;
  final int comprehension;
  final int conversation;
  final int production;
  final List<DetailedScoreCriterion> criteria;
  final List<GrammarCorrection> detectedErrors;
  final String feedbackSummary;

  const DetEvaluation({
    required this.overallScore,
    required this.literacy,
    required this.comprehension,
    required this.conversation,
    required this.production,
    required this.criteria,
    required this.detectedErrors,
    required this.feedbackSummary,
  });
}

class DetEvaluator {
  static final DetEvaluator instance = DetEvaluator._();
  DetEvaluator._();

  DetEvaluation evaluate(SpeakingAnalysis analysis, {String taskType = 'Speak About Image'}) {
    final text = analysis.transcript.trim();
    final wordCount = analysis.wordCount;
    final detectedErrors = GrammarService.instance.analyzeSync(text);

    if (text.isEmpty || wordCount < 3 || analysis.durationSeconds < 1.0) {
      return const DetEvaluation(
        overallScore: 10,
        literacy: 10,
        comprehension: 10,
        conversation: 10,
        production: 10,
        criteria: [
          DetailedScoreCriterion(
            criterionName: 'Production & Fluency',
            score: 10,
            reason: '⚠️ No speech detected.',
            nextBandActionableExample: 'Speak aloud for at least 30–60 seconds.',
          ),
        ],
        detectedErrors: [],
        feedbackSummary: 'No spoken response detected. DET Baseline Score: 10/160.',
      );
    }

    // Subscores on 10–160 scale
    int production = 75;
    if (wordCount >= 60) production += 40;
    else if (wordCount >= 35) production += 25;
    else if (wordCount >= 20) production += 10;
    if (analysis.wpm >= 110) production += 15;
    production = _roundTo5(production.clamp(10, 160));

    int conversation = 75;
    if (analysis.fillerCount == 0) conversation += 20;
    else conversation -= (analysis.fillerCount * 5);
    if (analysis.averageWordConfidence >= 0.85) conversation += 20;
    conversation = _roundTo5(conversation.clamp(10, 160));

    int literacy = 80;
    if (detectedErrors.isEmpty) literacy += 25;
    else literacy -= (detectedErrors.length * 10);
    final advancedWords = RegExp(r'\b(depicts|illustrates|furthermore|consequently|collaborating|atmosphere|environment|perspective)\b', caseSensitive: false).allMatches(text).length;
    literacy += (advancedWords * 10);
    literacy = _roundTo5(literacy.clamp(10, 160));

    int comprehension = _roundTo5(((production + conversation + literacy) / 3).round().clamp(10, 160));
    int overall = _roundTo5(((production + conversation + literacy + comprehension) / 4).round().clamp(10, 160));

    final criteria = [
      DetailedScoreCriterion(
        criterionName: 'Production',
        score: production.toDouble(),
        reason: '$wordCount words spoken at ${analysis.wpm.toStringAsFixed(0)} WPM.',
        nextBandActionableExample: 'Expand descriptions with nuanced sensory details.',
      ),
      DetailedScoreCriterion(
        criterionName: 'Conversation',
        score: conversation.toDouble(),
        reason: 'Confidence: ${(analysis.averageWordConfidence * 100).toStringAsFixed(0)}%, ${analysis.fillerCount} filler(s).',
        nextBandActionableExample: 'Speak naturally without hesitating.',
      ),
      DetailedScoreCriterion(
        criterionName: 'Literacy',
        score: literacy.toDouble(),
        reason: '${detectedErrors.length} grammatical error(s) detected.',
        nextBandActionableExample: 'Incorporate B2/C1 academic vocabulary and varied sentence clauses.',
      ),
    ];

    return DetEvaluation(
      overallScore: overall,
      literacy: literacy,
      comprehension: comprehension,
      conversation: conversation,
      production: production,
      criteria: criteria,
      detectedErrors: detectedErrors,
      feedbackSummary: 'Estimated DET Score: $overall/160. '
          'Production: $production, Conversation: $conversation, Literacy: $literacy, Comprehension: $comprehension.',
    );
  }

  int _roundTo5(int val) => ((val + 2) ~/ 5) * 5;
}


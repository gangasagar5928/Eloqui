import '../database/db_helper.dart';

class AdaptiveStudyDay {
  final int dayNumber;
  final String title;
  final String focusArea;
  final List<String> tasks;
  final int estimatedMinutes;

  const AdaptiveStudyDay({
    required this.dayNumber,
    required this.title,
    required this.focusArea,
    required this.tasks,
    required this.estimatedMinutes,
  });
}

class AdaptivePlanner {
  static final AdaptivePlanner instance = AdaptivePlanner._();
  AdaptivePlanner._();

  /// Generate personalized 7-day study plan based on user history in SQLite
  Future<List<AdaptiveStudyDay>> generate7DayPlan() async {
    final mistakes = await DbHelper.instance.getTopMistakes(limit: 5);
    final ieltsScores = await DbHelper.instance.getIeltsScores(limit: 1);

    String weakFocus = 'Grammar Tenses & Article misuse';
    if (mistakes.isNotEmpty) {
      weakFocus = mistakes.first['category'] as String? ?? weakFocus;
    }

    double latestGrammarScore = 6.0;
    double latestFluencyScore = 6.0;
    if (ieltsScores.isNotEmpty) {
      latestGrammarScore = (ieltsScores.first['grammar'] as num).toDouble();
      latestFluencyScore = (ieltsScores.first['fluency'] as num).toDouble();
    }

    final isGrammarWeak = latestGrammarScore < 6.5;
    final isFluencyWeak = latestFluencyScore < 6.5;

    return [
      AdaptiveStudyDay(
        dayNumber: 1,
        title: 'Grammar Foundation & Weak Spots',
        focusArea: weakFocus,
        tasks: [
          'Review $weakFocus in Grammar Checker',
          'Practice 10 B2/C1 Vocabulary Flashcards',
          '5-min Daily AI Conversation in Interview Mode',
        ],
        estimatedMinutes: isGrammarWeak ? 25 : 15,
      ),
      AdaptiveStudyDay(
        dayNumber: 2,
        title: 'Fluency & Pacing Drill',
        focusArea: isFluencyWeak ? 'Targeting Low Fluency Band ($latestFluencyScore) & Filler Reduction' : 'Speaking Speed (WPM) & Pause reduction',
        tasks: [
          if (isFluencyWeak) 'Complete 3 timed 60-second speech drills without "um/uh"' else 'Read Aloud Pronunciation Drill with zero fillers',
          'IELTS Part 1 Question set (5 questions)',
        ],
        estimatedMinutes: isFluencyWeak ? 25 : 20,
      ),
      AdaptiveStudyDay(
        dayNumber: 3,
        title: 'Part 2 Cue Card Challenge',
        focusArea: 'Structured 2-minute long turn speaking',
        tasks: [
          '1-minute notes prep on random Cue Card topic',
          'Deliver 2-minute speech without stopping',
          'Review End-of-Session AI Coach Report',
        ],
        estimatedMinutes: 25,
      ),
      AdaptiveStudyDay(
        dayNumber: 4,
        title: 'Vocabulary Expansion & Idioms',
        focusArea: 'Lexical Resource (Type-Token Ratio)',
        tasks: [
          'Master 15 new domain-specific words (${isGrammarWeak ? "Grammar/Structure Focus" : "Business/IELTS"})',
          'Practice 3 common idioms in context',
        ],
        estimatedMinutes: 15,
      ),
      AdaptiveStudyDay(
        dayNumber: 5,
        title: 'Abstract Discussion & Debate',
        focusArea: 'IELTS Part 3 Complex Sentence Structures',
        tasks: [
          'Answer 3 Part 3 discussion questions using discourse markers',
          'Use conditional clauses (If... I would...)',
        ],
        estimatedMinutes: 20,
      ),
      AdaptiveStudyDay(
        dayNumber: 6,
        title: 'Pronunciation Heatmap & Sound Drills',
        focusArea: 'Connected speech & word stress',
        tasks: [
          'Shadow 3 native speech passages',
          'Run Pronunciation Analyzer on 60-second speech',
        ],
        estimatedMinutes: 15,
      ),
      AdaptiveStudyDay(
        dayNumber: 7,
        title: 'Full IELTS Mock Exam & Analytics Review',
        focusArea: 'Overall Band Assessment & Milestone Check',
        tasks: [
          'Complete Full IELTS Speaking Mock Test (Part 1, 2, 3)',
          'Generate PDF Progress Report',
        ],
        estimatedMinutes: 30,
      ),
    ];
  }
}

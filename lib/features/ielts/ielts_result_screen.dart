import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/models/ielts_score.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/database/db_helper.dart';

class IeltsResultScreen extends StatefulWidget {
  final SpeakingAnalysis? customAnalysis;
  const IeltsResultScreen({super.key, this.customAnalysis});

  @override
  State<IeltsResultScreen> createState() => _IeltsResultScreenState();
}

class _IeltsResultScreenState extends State<IeltsResultScreen> {
  late SmartIeltsEvaluation _evaluation;
  late IeltsScore _score;

  @override
  void initState() {
    super.initState();
    final analysis = widget.customAnalysis ?? const SpeakingAnalysis(
      transcript: '',
      durationSeconds: 0,
      fillerCount: 0,
      pauseCount: 0,
    );

    _evaluation = IeltsEvaluator.instance.evaluateSmarter(analysis);
    _score = _evaluation.score;
    if (_score.overall > 0) {
      _save();
    }
  }

  Future<void> _save() async {
    await DbHelper.instance.insertIeltsScore(_score.toMap());
  }

  Color _bandColor(double b) {
    if (b >= 8) return AppColors.band9;
    if (b >= 7) return AppColors.band7;
    if (b >= 6) return AppColors.band6;
    if (b >= 5) return AppColors.band5;
    return AppColors.band4;
  }

  @override
  Widget build(BuildContext context) {
    final isZeroScore = _score.overall == 0.0;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('IELTS Results'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Export PDF'),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentOrange.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accentOrange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Estimate Note: Scores are AI practice estimates based strictly on your spoken audio input. Official IELTS band scores are issued only by certified IDP/British Council examiners.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            if (isZeroScore)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic_off_outlined, color: AppColors.accent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⚠️ No Speech Detected', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('No spoken audio was captured. Please ensure microphone permission is allowed and speak clearly during the test.', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Overall band
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isZeroScore ? AppColors.gradientWarm : AppColors.gradientIELTS,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: (isZeroScore ? AppColors.accent : const Color(0xFF667EEA)).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall Band Score', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(_score.overall.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
                        Text(_score.bandLabel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            dataEntries: [
                              RadarEntry(value: _score.fluency),
                              RadarEntry(value: _score.lexical),
                              RadarEntry(value: _score.grammar),
                              RadarEntry(value: _score.pronunciation),
                            ],
                            fillColor: Colors.white.withOpacity(0.2),
                            borderColor: Colors.white,
                            borderWidth: 2,
                          ),
                        ],
                        tickCount: 3,
                        ticksTextStyle: const TextStyle(color: Colors.transparent),
                        gridBorderData: const BorderSide(color: Colors.white24),
                        tickBorderData: const BorderSide(color: Colors.transparent),
                        radarBorderData: const BorderSide(color: Colors.transparent),
                        getTitle: (i, angle) {
                          const labels = ['F', 'L', 'G', 'P'];
                          return RadarChartTitle(text: labels[i], angle: 0);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text('Score Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ScoreBar('Fluency & Coherence', _score.fluency, _bandColor(_score.fluency)),
            const SizedBox(height: 10),
            _ScoreBar('Lexical Resource', _score.lexical, _bandColor(_score.lexical)),
            const SizedBox(height: 10),
            _ScoreBar('Grammatical Range', _score.grammar, _bandColor(_score.grammar)),
            const SizedBox(height: 10),
            _ScoreBar('Pronunciation', _score.pronunciation, _bandColor(_score.pronunciation)),
            const SizedBox(height: 24),
            // Speech Errors & Detailed Corrections
            if (_evaluation.detectedErrors.isNotEmpty) ...[
              Text('Speech Errors & How to Improve', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ..._evaluation.detectedErrors.map((err) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(err.rule, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          const TextSpan(text: '❌ You said: ', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          TextSpan(text: '"${err.original}"', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          const TextSpan(text: '✅ Better: ', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          TextSpan(text: '"${err.corrected}"', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('💡 Explanation: ${err.explanation}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],
            // Evaluation Criteria Details
            Text('Detailed AI Criteria Analysis', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._evaluation.criterionDetails.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.criterionName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const Spacer(),
                      Text('Band ${c.score.toStringAsFixed(1)}', style: TextStyle(color: _bandColor(c.score), fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(c.reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 6),
                  Text('💡 Next Band Action: ${c.nextBandActionableExample}', style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, height: 1.4)),
                ],
              ),
            )),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/ielts/part1'),
                    child: const Text('Practice Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/analytics'),
                    child: const Text('View Progress'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreBar(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
              Text(score.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 9.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.darkSurface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

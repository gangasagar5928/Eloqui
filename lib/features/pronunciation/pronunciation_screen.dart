import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/services/grammar_service.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key});
  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  final _controller = TextEditingController();
  bool _analyzed = false;
  int _fillerCount = 0;
  double _score = 0;

  void _analyze() {
    final text = _controller.text;
    final fillers = RegExp(r'\b(um|uh|er|ah|like|you know)\b', caseSensitive: false).allMatches(text).length;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final score = words > 0 ? ((1 - fillers / words.clamp(1, words)) * 100).clamp(0, 100) : 0.0;
    setState(() { _fillerCount = fillers; _score = score.toDouble(); _analyzed = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Pronunciation Analyzer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.gradientSecondary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🗣 Pronunciation Analyzer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 6),
                  Text('Paste or type your speech transcript to analyze fluency, fillers, and score.',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Paste your speech transcript here…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Analyze Pronunciation'),
              ),
            ),
            if (_analyzed) ...[              
              const SizedBox(height: 24),
              Text('Analysis Results', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 14),
              _ScoreRing(score: _score),
              const SizedBox(height: 16),
              _ResultCard('🚫 Filler Words Detected', '$_fillerCount', 'um, uh, like, you know', AppColors.accent),
              const SizedBox(height: 10),
              _ResultCard('💬 Word Count', '${_controller.text.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).length}', 'words spoken', AppColors.primary),
              const SizedBox(height: 10),
              _ResultCard('🔊 Fluency Score', '${_score.toStringAsFixed(1)}%', 'based on filler ratio', AppColors.secondary),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 Tips to Improve', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('• Replace "um/uh" with a brief pause\n• Practice shadowing native speakers\n• Record yourself and listen back\n• Focus on word stress and connected speech',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ].animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

class _ScoreRing extends StatelessWidget {
  final double score;
  const _ScoreRing({required this.score});
  @override
  Widget build(BuildContext context) {
    Color color;
    if (score >= 80) color = AppColors.band9;
    else if (score >= 60) color = AppColors.band6;
    else color = AppColors.accent;
    return Center(
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 6),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${score.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 28)),
            Text('Fluency', style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  const _ResultCard(this.title, this.value, this.subtitle, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(width: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

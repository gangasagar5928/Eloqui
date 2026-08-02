import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/ielts_evaluator.dart';

const _part3Questions = [
  'How has technology changed the way people communicate today?',
  'Do you think social media has a positive or negative effect on society?',
  'Should governments invest more in education or healthcare?',
  'How important is environmental awareness in modern society?',
  'What role should AI play in the future of work?',
  'Do you think younger generations are more environmentally conscious than older ones?',
];

class Part3Screen extends StatefulWidget {
  const Part3Screen({super.key});
  @override
  State<Part3Screen> createState() => _Part3ScreenState();
}

class _Part3ScreenState extends State<Part3Screen> {
  int _qIndex = 0;
  final _controller = TextEditingController();
  bool _aiLoading = false;
  String? _aiFeedback;
  final _llm = MockLLMService();

  @override
  Widget build(BuildContext context) {
    final q = _part3Questions[_qIndex];
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('IELTS Part 3'),
        actions: [
          TextButton(
            onPressed: () => context.go('/ielts/result'),
            child: const Text('Finish', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF764BA2), const Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Discussion Question', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(q, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, height: 1.4)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: 16),
            const Text('💡 Tip: Give a full answer with reasons and examples. Use discourse markers like "Furthermore", "On the other hand", "In contrast".',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            if (_aiFeedback != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                ),
                child: Text(_aiFeedback!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              ).animate().fadeIn(duration: 300.ms),
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
                  hintText: 'Discuss your ideas here…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _aiLoading ? null : _getFeedback,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _aiLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('AI Feedback'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(_qIndex < _part3Questions.length - 1 ? 'Next Question' : 'Get Results'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _getFeedback() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() { _aiLoading = true; _aiFeedback = null; });
    final fb = await _llm.generate('Give IELTS Part 3 feedback on: "${_controller.text}"');
    if (mounted) setState(() { _aiLoading = false; _aiFeedback = fb; });
  }

  void _next() {
    final text = _controller.text.trim();
    _controller.clear();
    if (_qIndex >= _part3Questions.length - 1 || text.isNotEmpty) {
      final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final analysis = SpeakingAnalysis(
        transcript: text,
        durationSeconds: (words / 2.2).clamp(0.0, 120.0),
        fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(text).length,
      );
      context.go('/ielts/result', extra: analysis);
    } else {
      setState(() { _qIndex++; _aiFeedback = null; });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

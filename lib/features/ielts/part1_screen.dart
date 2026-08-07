import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/services/stt_service.dart';

const _part1Questions = [
  'Can you tell me your full name?',
  'Where are you from originally?',
  'Do you work or are you a student?',
  'What do you enjoy doing in your free time?',
  'How do you usually spend your weekends?',
  'Do you prefer living in a city or a rural area? Why?',
  'What kind of food do you enjoy most?',
  'How important is English in your daily life?',
  'Do you enjoy reading? What kinds of books do you like?',
  'What are your plans for the future?',
];

class Part1Screen extends StatefulWidget {
  const Part1Screen({super.key});

  @override
  State<Part1Screen> createState() => _Part1ScreenState();
}

class _Part1ScreenState extends State<Part1Screen> {
  int _qIndex = 0;
  final List<Map<String, String>> _qa = [];
  final _controller = TextEditingController();
  bool _aiLoading = false;
  bool _isRecording = false;
  String? _aiFeedback;

  Future<void> _toggleMic() async {
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final res = await Permission.microphone.request();
      if (!res.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎙️ Microphone permission is required to speak your answer.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    }

    if (_isRecording) {
      setState(() => _isRecording = false);
      await NativeSttService.instance.stop();
    } else {
      setState(() => _isRecording = true);
      await NativeSttService.instance.listen(
        onResult: (text) {
          if (mounted) {
            setState(() {
              _controller.text = text;
              _controller.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _part1Questions[_qIndex % _part1Questions.length];
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('IELTS Part 1'),
        actions: [
          TextButton(
            onPressed: _finishTest,
            child: const Text('Finish', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_qIndex + 1) / _part1Questions.length,
              backgroundColor: AppColors.darkCard,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text('Question ${_qIndex + 1} of ${_part1Questions.length}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            // Question card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientIELTS,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🗣 Examiner Question',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(question,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            // AI Feedback panel
            if (_aiFeedback != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: AppColors.secondary, size: 16),
                        SizedBox(width: 6),
                        Text('AI Feedback', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_aiFeedback!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            // Answer input
            Row(
              children: [
                Text('Your Answer', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleMic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.accent : AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isRecording ? AppColors.accent : AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(_isRecording ? Icons.stop : Icons.mic, size: 16, color: _isRecording ? Colors.white : AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _isRecording ? 'Listening...' : 'Speak Response',
                          style: TextStyle(
                            color: _isRecording ? Colors.white : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isRecording ? AppColors.accent : AppColors.darkBorder),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _isRecording ? '🎙️ Listening... Speak your answer now!' : 'Speak or type your answer here…',
                  hintStyle: TextStyle(color: _isRecording ? AppColors.accent : AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _aiLoading ? null : _getAiFeedback,
                    icon: _aiLoading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.smart_toy_outlined),
                    label: const Text('Get AI Feedback'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_qIndex < _part1Questions.length - 1 ? 'Next' : 'Finish'),
                  ),
                ),
              ],
            ),
            // Previous Q&A
            if (_qa.isNotEmpty) ...[const SizedBox(height: 24), const Divider(color: AppColors.darkBorder), const SizedBox(height: 12),
              Text('Previous Answers', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._qa.reversed.take(3).map((qa) => _PreviousAnswer(q: qa['q']!, a: qa['a']!)),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _getAiFeedback() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() { _aiLoading = true; _aiFeedback = null; });
    final feedback = await AISessionManager.instance.executeChat(
      'Give concise IELTS Part 1 feedback on this answer: "${_controller.text}". Focus on vocabulary and grammar.',
      systemPrompt: 'You are an IELTS Speaking Examiner evaluating Part 1 answers.',
    );
    if (mounted) setState(() { _aiLoading = false; _aiFeedback = feedback; });
  }

  void _nextQuestion() {
    if (_controller.text.trim().isNotEmpty) {
      _qa.add({'q': _part1Questions[_qIndex % _part1Questions.length], 'a': _controller.text});
    }
    _controller.clear();
    if (_qIndex >= _part1Questions.length - 1) {
      final allText = _qa.map((e) => e['a']).join(' ');
      final words = allText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final analysis = SpeakingAnalysis(
        transcript: allText,
        durationSeconds: (words / 2.2).clamp(0.0, 120.0),
        fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(allText).length,
      );
      context.go('/ielts/result', extra: analysis);
    } else {
      setState(() { _qIndex++; _aiFeedback = null; });
    }
  }

  void _finishTest() {
    if (_controller.text.trim().isNotEmpty) {
      _qa.add({'q': _part1Questions[_qIndex % _part1Questions.length], 'a': _controller.text});
    }
    final allText = _qa.map((e) => e['a']).join(' ').trim();
    final words = allText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final analysis = SpeakingAnalysis(
      transcript: allText,
      durationSeconds: (words / 2.2).clamp(0.0, 180.0),
      fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(allText).length,
    );
    context.go('/ielts/result', extra: analysis);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PreviousAnswer extends StatelessWidget {
  final String q;
  final String a;
  const _PreviousAnswer({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(a, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}

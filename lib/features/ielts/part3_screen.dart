import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/services/stt_service.dart';

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
  final List<Map<String, String>> _qa = [];
  bool _aiLoading = false;
  bool _isRecording = false;
  String? _aiFeedback;
  final DateTime _testStartTime = DateTime.now();

  Future<void> _stopMicOnly() async {
    if (!_isRecording) return;
    // Guard setState so this is safe to call from dispose() too.
    if (mounted) setState(() => _isRecording = false);
    _isRecording = false;
    await NativeSttService.instance.stop();
  }

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
      await _stopMicOnly();
    } else {
      setState(() => _isRecording = true);
      await NativeSttService.instance.listen(
        onResult: (text) {
          if (mounted && _isRecording) {
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
    final q = _part3Questions[_qIndex % _part3Questions.length];
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('IELTS Part 3 — Two-Way Discussion'),
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
              value: (_qIndex + 1) / _part3Questions.length,
              backgroundColor: AppColors.darkCard,
              valueColor: const AlwaysStoppedAnimation(AppColors.accentOrange),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text('Question ${_qIndex + 1} of ${_part3Questions.length}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),

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

            Row(
              children: [
                Text('Your Response', style: Theme.of(context).textTheme.titleMedium),
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
                          _isRecording ? 'Listening...' : 'Speak Answer',
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
                maxLines: 6,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _isRecording ? '🎙️ Listening... Speak your thoughts clearly!' : 'Discuss your ideas here or tap Speak…',
                  hintStyle: TextStyle(color: _isRecording ? AppColors.accent : AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (val) {
                  if (_isRecording) _stopMicOnly();
                },
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
    final fb = await AISessionManager.instance.executeChat(
      'Give IELTS Part 3 feedback on: "${_controller.text}"',
      systemPrompt: 'You are an IELTS Speaking Examiner evaluating Part 3 abstract discussion answers.',
    );
    if (mounted) setState(() { _aiLoading = false; _aiFeedback = fb; });
  }

  void _next() {
    _stopMicOnly();
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _qa.add({'q': _part3Questions[_qIndex % _part3Questions.length], 'a': text});
    }
    _controller.clear();

    if (_qIndex >= _part3Questions.length - 1) {
      _finishTest();
    } else {
      setState(() {
        _qIndex++;
        _aiFeedback = null;
      });
    }
  }

  void _finishTest() {
    _stopMicOnly();
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _qa.add({'q': _part3Questions[_qIndex % _part3Questions.length], 'a': text});
    }
    final allText = _qa.map((e) => e['a']).join(' ').trim();
    final elapsed = DateTime.now().difference(_testStartTime).inSeconds.toDouble();
    final words = allText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final analysis = SpeakingAnalysis(
      transcript: allText,
      durationSeconds: elapsed > 5 ? elapsed : (words / 2.2).clamp(0.0, 180.0),
      fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(allText).length,
      averageWordConfidence: NativeSttService.instance.lastConfidence,
    );
    context.go('/ielts/result', extra: analysis);
  }

  @override
  void dispose() {
    _stopMicOnly();
    _controller.dispose();
    super.dispose();
  }
}


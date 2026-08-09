import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';

class DetScreen extends StatefulWidget {
  const DetScreen({super.key});

  @override
  State<DetScreen> createState() => _DetScreenState();
}

class _DetScreenState extends State<DetScreen> {
  int _qIndex = 0;
  final _controller = TextEditingController();
  bool _aiLoading = false;
  String? _feedback;

  static const _detTasks = [
    (
      'Speak About the Image',
      '🖼️ Image: A group of students collaborating in a modern library with laptops.',
      'Talk about what you see in the image for 30 to 90 seconds.',
    ),
    (
      'Read then Speak',
      'Prompt: Discuss whether remote work is beneficial for entry-level employees.',
      'Speak your response for 30 to 90 seconds. Include reasons and examples.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final task = _detTasks[_qIndex % _detTasks.length];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Duolingo English Test (DET)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientWarm,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: const Text('DET Production', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const SizedBox(height: 12),
                  Text(task.$1, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(task.$2, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(task.$3, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            if (_feedback != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 DET Subscore Feedback (10 - 160)', style: TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(_feedback!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
                  ],
                ),
              ).animate().fadeIn(),
            Text('Your Answer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Type your response here…',
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
                    onPressed: _aiLoading ? null : _evaluateDetResponse,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentOrange, side: const BorderSide(color: AppColors.accentOrange)),
                    child: _aiLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Evaluate DET'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _qIndex++;
                        _feedback = null;
                      });
                    },
                    child: const Text('Next Task'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _evaluateDetResponse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _aiLoading = true);

    final res = await AISessionManager.instance.executeChat(
      'Evaluate Duolingo English Test response: "$text". Provide DET estimated score (10-160) and subscores for Literacy, Comprehension, Conversation, Production.',
    );

    if (mounted) {
      setState(() {
        _aiLoading = false;
        _feedback = res;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';

class ToeflScreen extends StatefulWidget {
  const ToeflScreen({super.key});

  @override
  State<ToeflScreen> createState() => _ToeflScreenState();
}

class _ToeflScreenState extends State<ToeflScreen> {
  int _taskIndex = 0;
  final _answerController = TextEditingController();
  bool _aiLoading = false;
  String? _feedback;

  static const _tasks = [
    (
      'Task 1: Independent Speaking',
      'Do you prefer studying alone or studying in a group? Give specific reasons and examples to support your response.',
      15, // prep seconds
      45, // speak seconds
    ),
    (
      'Task 2: Integrated Campus Situation',
      'Read the campus announcement regarding single-use plastics, then state the female student\'s opinion and her 2 main supporting arguments.',
      30,
      60,
    ),
    (
      'Task 3: Integrated Academic Concept',
      'Explain how the professor\'s example of the retail store experiment illustrates the psychological phenomenon of priming.',
      30,
      60,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final task = _tasks[_taskIndex % _tasks.length];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('TOEFL iBT Speaking Coach')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text('TOEFL iBT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                      const Spacer(),
                      Text('Prep: ${task.$3}s • Speak: ${task.$4}s',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(task.$1, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(task.$2, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            if (_feedback != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 TOEFL Score Feedback (0 - 30)', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(_feedback!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
                  ],
                ),
              ).animate().fadeIn(),
            Text('Your Response', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: TextField(
                controller: _answerController,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Type or speak your response…',
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
                    onPressed: _aiLoading ? null : _evaluateToeflResponse,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                    child: _aiLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Evaluate Response'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _answerController.clear();
                      setState(() {
                        _taskIndex++;
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

  Future<void> _evaluateToeflResponse() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    setState(() => _aiLoading = true);

    final res = await AISessionManager.instance.executeChat(
      'Evaluate TOEFL response: "$text". Give estimated TOEFL speaking score (0-30), Delivery rating, Topic Development, and Language Use feedback.',
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
    _answerController.dispose();
    super.dispose();
  }
}

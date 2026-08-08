import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';

class PteScreen extends StatefulWidget {
  const PteScreen({super.key});

  @override
  State<PteScreen> createState() => _PteScreenState();
}

class _PteScreenState extends State<PteScreen> {
  int _itemIndex = 0;
  final _answerController = TextEditingController();
  bool _aiLoading = false;
  String? _feedback;

  static const _pteTasks = [
    (
      'Read Aloud',
      'Market research plays a critical role in evaluating consumer preferences, assessing competitive landscapes, and guiding strategic product development.',
      'Read the passage aloud smoothly and naturally with correct stress and intonation.',
    ),
    (
      'Repeat Sentence',
      'The university library will be closed for maintenance during the upcoming winter recess.',
      'Listen and repeat the sentence exactly as you hear it.',
    ),
    (
      'Describe Image',
      'Global Urban Population Growth Chart (1950 - 2050)',
      'Describe the key trends, high points, low points, and conclusion shown in the graph in 40 seconds.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final task = _pteTasks[_itemIndex % _pteTasks.length];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('PTE Academic Speaking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text(task.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const SizedBox(height: 12),
                  Text(task.$2, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.4)),
                  const SizedBox(height: 8),
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
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 PTE Score Feedback (10 - 90)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
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
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Type or speak your PTE response…',
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
                    onPressed: _aiLoading ? null : _evaluatePteResponse,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondary, side: const BorderSide(color: AppColors.secondary)),
                    child: _aiLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Evaluate PTE Score'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _answerController.clear();
                      setState(() {
                        _itemIndex++;
                        _feedback = null;
                      });
                    },
                    child: const Text('Next Item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _evaluatePteResponse() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    setState(() => _aiLoading = true);

    final res = await AISessionManager.instance.executeChat(
      'Evaluate PTE Speaking item: "$text". Give estimated PTE score (10-90), Oral Fluency rating, and Pronunciation accuracy.',
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

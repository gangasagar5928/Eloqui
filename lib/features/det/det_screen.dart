import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/services/stt_service.dart';
import '../../core/widgets/glass.dart';

class DetScreen extends StatefulWidget {
  const DetScreen({super.key});

  @override
  State<DetScreen> createState() => _DetScreenState();
}

class _DetScreenState extends State<DetScreen> {
  int _qIndex = 0;
  final _controller = TextEditingController();
  bool _aiLoading = false;
  bool _isRecording = false;
  DetEvaluation? _evaluation;
  String? _aiFeedback;
  DateTime? _speakStartTime;

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

  Future<void> _stopMicOnly() async {
    if (!_isRecording) return;
    // Guard setState so this is safe to call from dispose() too.
    if (mounted) setState(() => _isRecording = false);
    _isRecording = false;
    await NativeSttService.instance.stop();
  }

  Future<void> _toggleMic() async {
    if (_isRecording) {
      await _stopMicOnly();
    } else {
      final status = await Permission.microphone.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        final res = await Permission.microphone.request();
        if (!res.isGranted) return;
      }

      _speakStartTime = DateTime.now();
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

  Future<void> _evaluateDetResponse() async {
    await _stopMicOnly();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!mounted) return;
    setState(() => _aiLoading = true);

    final task = _detTasks[_qIndex % _detTasks.length];
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final elapsed = _speakStartTime != null
        ? DateTime.now().difference(_speakStartTime!).inSeconds.toDouble()
        : (words / 2.2).clamp(3.0, 90.0);

    final analysis = SpeakingAnalysis(
      transcript: text,
      durationSeconds: elapsed,
      fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(text).length,
      averageWordConfidence: NativeSttService.instance.lastConfidence,
    );

    final evaluation = DetEvaluator.instance.evaluate(analysis, taskType: task.$1);
    final res = await AISessionManager.instance.executeChat(
      'Evaluate Duolingo English Test response for "${task.$1}": "$text". Provide DET estimated score (10-160) and subscores for Literacy, Comprehension, Conversation, Production.',
      systemPrompt: 'You are an official Duolingo English Test (DET) Examiner.',
    );

    if (mounted) {
      setState(() {
        _evaluation = evaluation;
        _aiFeedback = res;
        _aiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _detTasks[_qIndex % _detTasks.length];

    return Scaffold(
      backgroundColor: Colors.transparent,
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

            // Scorecard when evaluated
            if (_evaluation != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientWarm,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DET Estimated Band', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${_evaluation!.overallScore} / 160',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Literacy: ${_evaluation!.literacy} • Comprehension: ${_evaluation!.comprehension} • Conversation: ${_evaluation!.conversation} • Production: ${_evaluation!.production}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 16),

              ..._evaluation!.criteria.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.criterionName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(c.reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${c.score.toStringAsFixed(0)} / 160',
                        style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],

            if (_aiFeedback != null)
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
                    const Text('📊 DET Examiner Feedback', style: TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(_aiFeedback!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
                  ],
                ),
              ).animate().fadeIn(),

            // Response Box
            Row(
              children: [
                Text('Your Response', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleMic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.accent : AppColors.accentOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isRecording ? AppColors.accent : AppColors.accentOrange.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(_isRecording ? Icons.stop : Icons.mic, size: 16, color: _isRecording ? Colors.white : AppColors.accentOrange),
                        const SizedBox(width: 6),
                        Text(
                          _isRecording ? 'Listening...' : 'Speak Task',
                          style: TextStyle(
                            color: _isRecording ? Colors.white : AppColors.accentOrange,
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

            GlassSurface(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              borderColor: _isRecording ? AppColors.accent : null,
              child: TextField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _isRecording ? '🎙️ Recording... Speak your DET response clearly.' : 'Type your response here or tap Speak Task…',
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
                      _stopMicOnly();
                      _controller.clear();
                      setState(() {
                        _qIndex++;
                        _evaluation = null;
                        _aiFeedback = null;
                        _speakStartTime = null;
                      });
                    },
                    child: const Text('Next Task →'),
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

  @override
  void dispose() {
    _stopMicOnly();
    _controller.dispose();
    super.dispose();
  }
}


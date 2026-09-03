import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/services/stt_service.dart';
import '../../core/widgets/glass.dart';

class ToeflScreen extends StatefulWidget {
  const ToeflScreen({super.key});

  @override
  State<ToeflScreen> createState() => _ToeflScreenState();
}

enum _ToeflPhase { idle, prep, speaking, evaluated }

class _ToeflScreenState extends State<ToeflScreen> {
  int _taskIndex = 0;
  final _answerController = TextEditingController();
  bool _aiLoading = false;
  bool _isRecording = false;
  ToeflEvaluation? _evaluation;
  String? _aiFeedback;
  _ToeflPhase _phase = _ToeflPhase.idle;
  int _timerSeconds = 0;
  Timer? _timer;
  DateTime? _speakStartTime;

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

  void _startPrepTimer() {
    _stopMicOnly();
    final task = _tasks[_taskIndex % _tasks.length];
    _timer?.cancel();
    setState(() {
      _phase = _ToeflPhase.prep;
      _timerSeconds = task.$3;
      _evaluation = null;
      _aiFeedback = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds <= 1) {
        t.cancel();
        _startSpeakingTimer();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  Future<void> _startSpeakingTimer() async {
    _timer?.cancel();
    final task = _tasks[_taskIndex % _tasks.length];
    _speakStartTime = DateTime.now();
    _answerController.clear();
    setState(() {
      _phase = _ToeflPhase.speaking;
      _timerSeconds = task.$4;
    });

    await _startRecording();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds <= 1) {
        t.cancel();
        _finishSpeakingAndEvaluate();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final res = await Permission.microphone.request();
      if (!res.isGranted) return;
    }

    setState(() => _isRecording = true);
    await NativeSttService.instance.listen(
      onResult: (text) {
        if (mounted && _isRecording) {
          setState(() {
            _answerController.text = text;
            _answerController.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
          });
        }
      },
    );
  }

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
      await _startRecording();
    }
  }

  Future<void> _finishSpeakingAndEvaluate() async {
    _timer?.cancel();
    await _stopMicOnly();
    if (!mounted) return;
    setState(() {
      _phase = _ToeflPhase.evaluated;
      _aiLoading = true;
    });

    final task = _tasks[_taskIndex % _tasks.length];
    final text = _answerController.text.trim();
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    // When the mic was never used (typed response), estimate a natural speaking
    // duration from the word count instead of assuming the full task time.
    final elapsed = _speakStartTime != null
        ? DateTime.now().difference(_speakStartTime!).inSeconds.toDouble()
        : (words / 2.2).clamp(2.0, task.$4.toDouble());

    final analysis = SpeakingAnalysis(
      transcript: text,
      durationSeconds: elapsed.clamp(2.0, task.$4.toDouble()),
      fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(text).length,
      averageWordConfidence: NativeSttService.instance.lastConfidence,
    );

    final evaluation = ToeflEvaluator.instance.evaluate(analysis, taskTitle: task.$1);
    final aiCoach = await AISessionManager.instance.executeChat(
      'Evaluate TOEFL response for ${task.$1}: "$text". Give constructive advice.',
      systemPrompt: 'You are an official TOEFL iBT Speaking Examiner.',
    );

    if (mounted) {
      setState(() {
        _evaluation = evaluation;
        _aiFeedback = aiCoach;
        _aiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _tasks[_taskIndex % _tasks.length];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('TOEFL iBT Speaking Coach')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Prompt Card
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
            const SizedBox(height: 16),

            // Live Timer indicator
            if (_phase == _ToeflPhase.prep || _phase == _ToeflPhase.speaking)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _phase == _ToeflPhase.prep
                      ? AppColors.accentOrange.withOpacity(0.15)
                      : AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _phase == _ToeflPhase.prep ? AppColors.accentOrange : AppColors.secondary,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _phase == _ToeflPhase.prep ? Icons.timer_outlined : Icons.record_voice_over,
                      color: _phase == _ToeflPhase.prep ? AppColors.accentOrange : AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _phase == _ToeflPhase.prep ? 'Preparation Time: $_timerSeconds s' : 'Speaking Time: $_timerSeconds s',
                      style: TextStyle(
                        color: _phase == _ToeflPhase.prep ? AppColors.accentOrange : AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

            // Scorecard when evaluated
            if (_evaluation != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSecondary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated TOEFL Speaking Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text('${_evaluation!.overallScore} / 30',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                          Text(_evaluation!.feedbackSummary,
                              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 16),

              // Rubric breakdown
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
                    Text('${c.score.toStringAsFixed(1)} / 4.0',
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800, fontSize: 13)),
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
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 TOEFL Examiner Feedback', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(_aiFeedback!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
                  ],
                ),
              ).animate().fadeIn(),

            // Response Box with Mic Header
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
                          _isRecording ? 'Listening...' : 'Record Voice',
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
            GlassSurface(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              borderColor: _isRecording ? AppColors.accent : null,
              child: TextField(
                controller: _answerController,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _isRecording ? '🎙️ Listening... Speak your TOEFL response clearly.' : 'Type or speak your response…',
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

            // Controls
            Row(
              children: [
                if (_phase == _ToeflPhase.idle || _phase == _ToeflPhase.evaluated)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _startPrepTimer,
                      icon: const Icon(Icons.timer),
                      label: const Text('Start Timed Task'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (_phase == _ToeflPhase.prep)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startSpeakingTimer,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Speaking Now'),
                    ),
                  ),
                if (_phase == _ToeflPhase.speaking)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _finishSpeakingAndEvaluate,
                      icon: const Icon(Icons.stop),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      label: const Text('Stop & Score'),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _stopMicOnly();
                      _timer?.cancel();
                      _answerController.clear();
                      setState(() {
                        _taskIndex++;
                        _evaluation = null;
                        _aiFeedback = null;
                        _phase = _ToeflPhase.idle;
                      });
                    },
                    child: const Text('Next Task →'),
                  ),
                ),
              ],
            ),
            if (_phase == _ToeflPhase.idle && _evaluation == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _aiLoading ? null : _finishSpeakingAndEvaluate,
                  icon: _aiLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.score, color: AppColors.secondary),
                  label: const Text('Evaluate Typed Response', style: TextStyle(color: AppColors.secondary)),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopMicOnly();
    _answerController.dispose();
    super.dispose();
  }
}


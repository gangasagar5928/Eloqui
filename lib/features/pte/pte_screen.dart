import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/services/stt_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/glass.dart';

class PteScreen extends StatefulWidget {
  const PteScreen({super.key});

  @override
  State<PteScreen> createState() => _PteScreenState();
}

class _PteScreenState extends State<PteScreen> {
  int _itemIndex = 0;
  final _answerController = TextEditingController();
  bool _aiLoading = false;
  bool _isRecording = false;
  bool _isPlayingTts = false;
  PteEvaluation? _evaluation;
  String? _aiFeedback;
  DateTime? _speakStartTime;

  static const _pteTasks = [
    (
      'Read Aloud',
      'Market research plays a critical role in evaluating consumer preferences, assessing competitive landscapes, and guiding strategic product development.',
      'Read the passage aloud smoothly and naturally with correct stress and intonation.',
    ),
    (
      'Repeat Sentence',
      'The university library will be closed for maintenance during the upcoming winter recess.',
      'Listen to the sentence and repeat it aloud accurately.',
    ),
    (
      'Describe Image',
      'Global Urban Population Growth Chart (1950 - 2050)',
      'Describe the key trends, high points, low points, and conclusion shown in the graph in 40 seconds.',
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
              _answerController.text = text;
              _answerController.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
            });
          }
        },
      );
    }
  }

  Future<void> _playTtsPrompt(String text) async {
    if (_isPlayingTts) return;
    _stopMicOnly();
    setState(() => _isPlayingTts = true);
    await TTSService.instance.speak(text);
    if (mounted) setState(() => _isPlayingTts = false);
  }

  Future<void> _evaluatePteResponse() async {
    await _stopMicOnly();
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    if (!mounted) return;
    setState(() => _aiLoading = true);

    final task = _pteTasks[_itemIndex % _pteTasks.length];
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final elapsed = _speakStartTime != null
        ? DateTime.now().difference(_speakStartTime!).inSeconds.toDouble()
        : (words / 2.2).clamp(3.0, 60.0);

    final analysis = SpeakingAnalysis(
      transcript: text,
      durationSeconds: elapsed,
      fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(text).length,
      averageWordConfidence: NativeSttService.instance.lastConfidence,
    );

    final evaluation = PteEvaluator.instance.evaluate(
      analysis,
      taskType: task.$1,
      expectedPrompt: task.$1 == 'Repeat Sentence' || task.$1 == 'Read Aloud' ? task.$2 : '',
    );

    final res = await AISessionManager.instance.executeChat(
      'Evaluate PTE Speaking item "${task.$1}": "$text". Target: "${task.$2}". Give concise feedback.',
      systemPrompt: 'You are an official Pearson PTE Academic Examiner.',
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
    final task = _pteTasks[_itemIndex % _pteTasks.length];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('PTE Academic Speaking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientSecondary,
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
                        child: Text(task.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                      const Spacer(),
                      if (task.$1 == 'Repeat Sentence')
                        GestureDetector(
                          onTap: _isPlayingTts ? null : () => _playTtsPrompt(task.$2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Icon(_isPlayingTts ? Icons.volume_up : Icons.play_arrow, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(_isPlayingTts ? 'Playing…' : 'Listen Prompt', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(task.$2, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.4)),
                  const SizedBox(height: 8),
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
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PTE Score Breakdown', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${_evaluation!.overallScore} / 90',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Oral Fluency: ${_evaluation!.oralFluency} • Pronunciation: ${_evaluation!.pronunciation} • Content: ${_evaluation!.content}',
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
                    Text('${c.score.toStringAsFixed(0)} / 90',
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
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 Examiner Advice', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
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
                      color: _isRecording ? AppColors.accent : AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isRecording ? AppColors.accent : AppColors.secondary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(_isRecording ? Icons.stop : Icons.mic, size: 16, color: _isRecording ? Colors.white : AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          _isRecording ? 'Recording...' : 'Speak Item',
                          style: TextStyle(
                            color: _isRecording ? Colors.white : AppColors.secondary,
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
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _isRecording ? '🎙️ Recording... Speak clearly into the microphone.' : 'Type or speak your PTE response…',
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
                      _stopMicOnly();
                      _answerController.clear();
                      setState(() {
                        _itemIndex++;
                        _evaluation = null;
                        _aiFeedback = null;
                        _speakStartTime = null;
                      });
                    },
                    child: const Text('Next Item →'),
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
    _answerController.dispose();
    super.dispose();
  }
}


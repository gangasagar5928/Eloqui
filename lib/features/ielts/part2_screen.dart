import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/services/stt_service.dart';
import '../../core/widgets/glass.dart';

const _cueCards = [
  _CueCard('Describe a person who has influenced you',
    ['Who the person is', 'How you know them', 'What they have done', 'Why they influenced you']),
  _CueCard('Describe a place you love to visit',
    ['Where it is', 'What it looks like', 'What you do there', 'Why you enjoy going']),
  _CueCard('Describe a book you have read',
    ['What the book is', 'What it is about', 'When you read it', 'Why you would recommend it']),
  _CueCard('Describe a skill you would like to learn',
    ['What it is', 'Why you want to learn it', 'How you would learn it', 'How it would help you']),
];

class _CueCard {
  final String topic;
  final List<String> points;
  const _CueCard(this.topic, this.points);
}

enum _Phase { prep, speaking, done }

class Part2Screen extends StatefulWidget {
  const Part2Screen({super.key});
  @override
  State<Part2Screen> createState() => _Part2ScreenState();
}

class _Part2ScreenState extends State<Part2Screen> {
  _Phase _phase = _Phase.prep;
  int _prepSeconds = 60;
  int _speakSeconds = 120;
  Timer? _timer;
  final _notesController = TextEditingController();
  final _transcriptController = TextEditingController();
  late _CueCard _card;
  String? _aiFeedback;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _card = _cueCards[DateTime.now().second % _cueCards.length];
    _startPrep();
  }

  void _startPrep() {
    _stopMicOnly();
    setState(() => _phase = _Phase.prep);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_prepSeconds <= 1) { t.cancel(); _startSpeaking(); }
      else setState(() => _prepSeconds--);
    });
  }

  Future<void> _startSpeaking() async {
    _timer?.cancel();
    setState(() { _phase = _Phase.speaking; _speakSeconds = 120; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      // Count down to 0 so a full 120s attempt is recorded as 120s, not 119s.
      if (_speakSeconds <= 0) { t.cancel(); _done(); }
      else setState(() => _speakSeconds--);
    });
    await _startRecording();
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
            _transcriptController.text = text;
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

  void _done() {
    _timer?.cancel();
    _stopMicOnly();
    setState(() => _phase = _Phase.done);
    _getAiFeedback();
  }

  Future<void> _getAiFeedback() async {
    final text = _transcriptController.text.trim().isNotEmpty
        ? _transcriptController.text.trim()
        : _notesController.text.trim();
    final feedback = await AISessionManager.instance.executeChat(
      'Give brief IELTS Part 2 speaking feedback for topic: "${_card.topic}". Spoken response: "$text". Focus on structure and timing.',
      systemPrompt: 'You are an IELTS Speaking Examiner evaluating Part 2 Cue Cards.',
    );
    if (mounted) setState(() => _aiFeedback = feedback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('IELTS Part 2 — Cue Card'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cue card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cue Card', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(_card.topic, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  const Text('You should say:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 8),
                  ..._card.points.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ', style: TextStyle(color: Colors.white70)),
                            Expanded(child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 14))),
                          ],
                        ),
                      )),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
            const SizedBox(height: 24),
            // Timer
            _TimerWidget(phase: _phase, prepSeconds: _prepSeconds, speakSeconds: _speakSeconds),
            const SizedBox(height: 20),

            // Prep Phase Notes Area
            if (_phase == _Phase.prep) ...[
              Text('Preparation Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Jot down keywords and bullet points…',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                ),
                onChanged: (val) {
                  if (_isRecording) _stopMicOnly();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startSpeaking,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Speaking (Skip prep)'),
                ),
              ),
            ],

            // Speaking Phase Live Speech Box
            if (_phase == _Phase.speaking) ...[
              Row(
                children: [
                  Text('Spoken Transcript', style: Theme.of(context).textTheme.titleMedium),
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
                            _isRecording ? 'Recording...' : 'Resume Mic',
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
                  controller: _transcriptController,
                  maxLines: 5,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: _isRecording ? '🎙️ Speaking now... Your words appear here in real time.' : 'Speak your answer or type here…',
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _done,
                  icon: const Icon(Icons.stop),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  label: const Text('Stop & Evaluate'),
                ),
              ),
            ],

            // Done / Feedback Phase
            if (_phase == _Phase.done) ...[
              GlassSurface(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 10),
                    _aiFeedback != null
                        ? Text(_aiFeedback!, style: const TextStyle(color: AppColors.textSecondary, height: 1.5))
                        : const CircularProgressIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final spokenText = _transcriptController.text.trim().isNotEmpty
                        ? _transcriptController.text.trim()
                        : _notesController.text.trim();
                    final spokenDuration = (120 - _speakSeconds).clamp(5, 120).toDouble();
                    final analysis = SpeakingAnalysis(
                      transcript: spokenText,
                      durationSeconds: spokenDuration,
                      fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(spokenText).length,
                      averageWordConfidence: NativeSttService.instance.lastConfidence,
                    );
                    context.go('/ielts/result', extra: analysis);
                  },
                  child: const Text('View Full Score Report →'),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }
}

class _TimerWidget extends StatelessWidget {
  final _Phase phase;
  final int prepSeconds;
  final int speakSeconds;
  const _TimerWidget({required this.phase, required this.prepSeconds, required this.speakSeconds});

  @override
  Widget build(BuildContext context) {
    final (label, seconds, color) = switch (phase) {
      _Phase.prep => ('Preparation Time', prepSeconds, AppColors.accentOrange),
      _Phase.speaking => ('Speaking Time', speakSeconds, AppColors.secondary),
      _Phase.done => ('Completed', 0, AppColors.band9),
    };
    final display = '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(phase == _Phase.done ? Icons.check_circle : Icons.timer_outlined, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(phase == _Phase.done ? 'Done ✓' : display,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
        ],
      ),
    );
  }
}

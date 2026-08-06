import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/ielts_evaluator.dart';

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
  late _CueCard _card;
  String? _aiFeedback;

  @override
  void initState() {
    super.initState();
    _card = _cueCards[DateTime.now().second % _cueCards.length];
  }

  void _startPrep() {
    setState(() => _phase = _Phase.prep);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_prepSeconds <= 1) { t.cancel(); _startSpeaking(); }
      else setState(() => _prepSeconds--);
    });
  }

  void _startSpeaking() {
    setState(() { _phase = _Phase.speaking; _speakSeconds = 120; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_speakSeconds <= 1) { t.cancel(); _done(); }
      else setState(() => _speakSeconds--);
    });
  }

  void _done() {
    setState(() => _phase = _Phase.done);
    _getAiFeedback();
  }

  Future<void> _getAiFeedback() async {
    final feedback = await AISessionManager.instance.executeChat(
      'Give brief IELTS Part 2 speaking feedback for topic: ${_card.topic}. Focus on structure and timing.',
      systemPrompt: 'You are an IELTS Speaking Examiner evaluating Part 2 Cue Cards.',
    );
    if (mounted) setState(() => _aiFeedback = feedback);
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
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
            // Notes area (prep phase)
            if (_phase != _Phase.done) ...[              
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Preparation notes…',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _phase == _Phase.prep ? null
                      : _phase == _Phase.speaking ? _done : _startPrep,
                  child: Text(_phase == _Phase.speaking ? 'Stop Speaking' : 'Start (1 min prep)'),
                ),
              ),
              if (_phase == _Phase.prep)
                const SizedBox(height: 8),
              if (_phase == _Phase.prep)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _startSpeaking,
                    child: const Text('Skip prep — Start speaking now'),
                  ),
                ),
            ],
            // AI Feedback
            if (_phase == _Phase.done) ...[              
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
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
                    final notes = _notesController.text.trim();
                    final words = notes.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                    final spokenDuration = 120 - _speakSeconds;
                    final analysis = SpeakingAnalysis(
                      transcript: notes,
                      durationSeconds: spokenDuration > 0 ? spokenDuration.toDouble() : (words / 2.2).clamp(0.0, 120.0),
                      fillerCount: RegExp(r'\b(um|uh|er|like)\b', caseSensitive: false).allMatches(notes).length,
                    );
                    context.go('/ielts/result', extra: analysis);
                  },
                  child: const Text('View Full Results'),
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
  void dispose() { _timer?.cancel(); _notesController.dispose(); super.dispose(); }
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

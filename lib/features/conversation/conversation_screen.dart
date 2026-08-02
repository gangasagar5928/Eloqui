import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/models/conversation.dart';
import '../../core/services/ai_engine.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/grammar_service.dart';
import '../../core/services/ielts_evaluator.dart';
import '../../core/services/stt_service.dart';
import '../../core/database/db_helper.dart';

final _aiEngineProvider = Provider<AIEngine>((ref) {
  return AISessionManager.instance.activeEngine ?? MockAIEngine();
});

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  ConversationMode _mode = ConversationMode.daily;
  final List<Message> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  Conversation? _conversation;
  List<GrammarCorrection> _lastCorrections = [];
  String _rollingSummary = '';
  EndOfSessionCoachReport? _sessionReport;
  DateTime? _sessionStartTime;
  int _totalFillerCount = 0;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  Future<void> _startConversation() async {
    _sessionStartTime = DateTime.now();
    _totalFillerCount = 0;
    final conv = Conversation(
      title: '${_mode.label} Practice',
      mode: _mode,
    );
    await DbHelper.instance.insertConversation(conv.toMap());

    final engine = ref.read(_aiEngineProvider);
    final greeting = await engine.chat(
      'Start a ${_mode.label} conversation. Greet me and ask an opening question.',
      systemPrompt: _systemPrompt(_mode),
    );

    final msg = Message(
      conversationId: conv.id,
      role: 'assistant',
      content: greeting,
    );
    await DbHelper.instance.insertMessage(msg.toMap());

    if (mounted) {
      setState(() {
        _conversation = conv;
        _messages.add(msg);
      });
    }
  }

  String _systemPrompt(ConversationMode mode) {
    return 'You are Eloqui, an AI English speaking coach in a ${mode.label} session. '
        'Be encouraging, natural, and educational. Keep responses concise (2-4 sentences).';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _conversation == null) return;
    _controller.clear();

    // Count fillers in user text
    _totalFillerCount += RegExp(r'\b(um|uh|er|like|you know|i mean)\b', caseSensitive: false).allMatches(text).length;

    // Fast isolate-based grammar check
    final corrections = await GrammarService.instance.analyzeHybrid(
      text: text,
      aiEngine: ref.read(_aiEngineProvider),
    );

    final userMsg = Message(
      conversationId: _conversation!.id,
      role: 'user',
      content: text,
    );
    await DbHelper.instance.insertMessage(userMsg.toMap());

    if (mounted) {
      setState(() {
        _messages.add(userMsg);
        _isTyping = true;
        _lastCorrections = corrections;
      });
    }
    _scrollToBottom();

    // 8. Rolling Summary Workflow
    final engine = ref.read(_aiEngineProvider);
    if (_messages.length > 6) {
      _rollingSummary = await engine.summarizeConversation(_messages);
    }

    final reply = await engine.chat(
      text,
      historySummary: _messages,
      systemPrompt: '${_systemPrompt(_mode)}\nRolling Summary: $_rollingSummary',
    );

    final aiMsg = Message(
      conversationId: _conversation!.id,
      role: 'assistant',
      content: reply,
    );
    await DbHelper.instance.insertMessage(aiMsg.toMap());

    if (mounted) {
      setState(() {
        _messages.add(aiMsg);
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _finishSession() {
    final userMessages = _messages.where((m) => m.role == 'user').toList();
    final fullTranscript = userMessages.map((m) => m.content).join(' ');
    final elapsed = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds.toDouble()
        : fullTranscript.split(' ').length / 2.2;
    final pauseCount = (userMessages.length - 1).clamp(0, 99);

    final analysis = SpeakingAnalysis(
      transcript: fullTranscript,
      durationSeconds: elapsed.clamp(5.0, 600.0),
      fillerCount: _totalFillerCount,
      pauseCount: pauseCount,
    );
    final mistakes = _lastCorrections.map((c) => c.rule).toList();
    final report = IeltsEvaluator.instance.generateCoachReport(analysis, mistakes);

    setState(() {
      _sessionReport = report;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mode.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const Text('AI Conversation', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: AppColors.secondary),
            onPressed: _finishSession,
            tooltip: 'End Session & Report',
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_outlined),
            onPressed: _showModeSelector,
          ),
        ],
      ),
      body: _sessionReport != null
          ? _CoachReportView(report: _sessionReport!, onRestart: () {
              setState(() {
                _sessionReport = null;
                _messages.clear();
              });
              _startConversation();
            })
          : Column(
              children: [
                if (!AISessionManager.instance.isLoaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.15),
                      border: const Border(bottom: BorderSide(color: AppColors.darkBorder)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.accentOrange, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Demo Engine — GGUF AI Model Not Installed',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/settings/model-manager'),
                          child: const Text('Download →', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                if (_lastCorrections.isNotEmpty)
                  _GrammarBanner(
                      corrections: _lastCorrections,
                      onDismiss: () => setState(() => _lastCorrections = [])),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isTyping && i == _messages.length) {
                        return _TypingBubble();
                      }
                      return _MessageBubble(message: _messages[i]);
                    },
                  ),
                ),
                _InputBar(controller: _controller, onSend: _sendMessage),
              ],
            ),
    );
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Conversation Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ConversationMode.values.map((m) {
                final selected = m == _mode;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _mode = m;
                      _messages.clear();
                      _lastCorrections = [];
                    });
                    _startConversation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.gradientPrimary : null,
                      color: selected ? null : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.darkBorder),
                    ),
                    child: Text('${m.emoji} ${m.label}',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _CoachReportView extends StatelessWidget {
  final EndOfSessionCoachReport report;
  final VoidCallback onRestart;

  const _CoachReportView({required this.report, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                const Text('🤖 End-of-Session AI Coach Report',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Personalized feedback based on your responses',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Top 5 Areas for Improvement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...report.top5Mistakes.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.accentOrange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Text('Pronunciation Focus Words', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: report.pronunciationFocusWords.map((w) => Chip(
              label: Text(w),
              backgroundColor: AppColors.primary.withOpacity(0.2),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Personalized Next Lesson', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: Text(report.personalizedNextLesson,
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRestart,
              child: const Text('Start New Session'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.gradientPrimary : null,
          color: isUser ? null : AppColors.darkCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.darkBorder),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const SizedBox(
          width: 30,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _GrammarBanner extends StatelessWidget {
  final List<GrammarCorrection> corrections;
  final VoidCallback onDismiss;
  const _GrammarBanner({required this.corrections, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentOrange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: AppColors.accentOrange, size: 16),
              const SizedBox(width: 6),
              const Text('Grammar Feedback',
                  style: TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, size: 16, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ...corrections.take(2).map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${c.rule}: ${c.explanation}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _isRecording = false;

  Future<void> _toggleMic() async {
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final res = await Permission.microphone.request();
      if (!res.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎙️ Microphone permission is required to speak with Eloqui.'),
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
      // Stop recording
      setState(() => _isRecording = false);
      await NativeSttService.instance.stop();
      final text = widget.controller.text.trim();
      if (text.isNotEmpty) {
        widget.onSend(text);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No speech captured. Speak clearly or type your response.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // Start real-time speech recognition
      setState(() => _isRecording = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎙️ Listening... Speak now! Words will appear in real time.'),
          duration: Duration(seconds: 4),
        ),
      );
      await NativeSttService.instance.listen(
        onResult: (recognizedText) {
          if (mounted) {
            setState(() {
              widget.controller.text = recognizedText;
              widget.controller.selection = TextSelection.fromPosition(
                TextPosition(offset: recognizedText.length),
              );
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text('Recording spoken audio...', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggleMic,
                    child: const Text('Stop & Send →', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Mic Button
              GestureDetector(
                onTap: _toggleMic,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.accent : AppColors.darkCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: _isRecording ? AppColors.accent : AppColors.darkBorder),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.white : AppColors.secondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Speak or type your message…',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: widget.onSend,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => widget.onSend(widget.controller.text),
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

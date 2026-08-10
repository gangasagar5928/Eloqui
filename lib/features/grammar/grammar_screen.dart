import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/services/grammar_service.dart';
import '../../core/database/db_helper.dart';
import 'package:uuid/uuid.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});
  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final _controller = TextEditingController();
  List<GrammarCorrection> _corrections = [];
  String _corrected = '';
  bool _analyzed = false;

  Future<void> _check() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final corrections = await GrammarService.instance.analyzeHybrid(text: text);
    String corrected = text;
    if (corrections.isNotEmpty) {
      corrected = corrections.first.corrected;
    }
    // Save to DB
    for (final c in corrections) {
      await DbHelper.instance.insertGrammarMistake({
        'id': const Uuid().v4(),
        'session_id': null,
        'original': c.original,
        'corrected': c.corrected,
        'rule': c.rule,
        'explanation': c.explanation,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    setState(() { _corrections = corrections; _corrected = corrected; _analyzed = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Grammar Checker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.gradientWarm,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✍️ Grammar Checker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('60+ grammar rules • Instant offline check',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.6),
                decoration: const InputDecoration(
                  hintText: 'Type or paste your text here…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _check,
                icon: const Icon(Icons.spellcheck),
                label: const Text('Check Grammar'),
              ),
            ),
            if (_analyzed) ...[              
              const SizedBox(height: 24),
              if (_corrected != _controller.text) ...[                
                Text('Corrected Text', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.band9.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.band9.withOpacity(0.3)),
                  ),
                  child: Text(_corrected, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6)),
                ),
                const SizedBox(height: 20),
              ],
              if (_corrections.isEmpty)
                const _NoErrorsCard()
              else ...[                
                Text('${_corrections.length} Issue${_corrections.length != 1 ? 's' : ''} Found',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ..._corrections.asMap().entries.map((e) =>
                    _CorrectionCard(correction: e.value, index: e.key)
                        .animate(delay: Duration(milliseconds: e.key * 80))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.1, end: 0)),
              ],
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

class _NoErrorsCard extends StatelessWidget {
  const _NoErrorsCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.band9.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.band9.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Text('✅', style: TextStyle(fontSize: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No errors found!', style: TextStyle(color: AppColors.band9, fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Your grammar looks correct.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  final GrammarCorrection correction;
  final int index;
  const _CorrectionCard({required this.correction, required this.index});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(correction.rule,
                    style: const TextStyle(color: AppColors.accentOrange, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('❌ ', style: TextStyle(fontSize: 14)),
              Expanded(child: Text(correction.original,
                  style: const TextStyle(color: AppColors.accent, fontSize: 14, decoration: TextDecoration.lineThrough))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('✅ ', style: TextStyle(fontSize: 14)),
              Expanded(child: Text(correction.corrected,
                  style: const TextStyle(color: AppColors.band9, fontSize: 14, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          Text(correction.explanation,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}

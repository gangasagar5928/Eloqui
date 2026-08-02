import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../app/theme.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/vocabulary_word.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _dueCards = [];
  String _selectedLevel = 'All';
  String _selectedDomain = 'All';
  List<Map<String, dynamic>> _categorizedCards = [];
  bool _loading = true;

  static const _cefrLevels = ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _domains = ['All', 'IELTS', 'TOEFL', 'PTE', 'Business', 'Travel', 'Medical', 'Engineering', 'Daily Life'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final due = await DbHelper.instance.getDueVocabularyCards();
    final cat = await DbHelper.instance.getVocabularyByCategory(
      level: _selectedLevel == 'All' ? null : _selectedLevel,
      domain: _selectedDomain == 'All' ? null : _selectedDomain,
    );
    if (mounted) {
      setState(() {
        _dueCards = due;
        _categorizedCards = cat;
        _loading = false;
      });
    }
  }

  void _showAddCustomWordDialog() {
    final wordCtrl = TextEditingController();
    final defCtrl = TextEditingController();
    final exCtrl = TextEditingController();
    String domain = 'Daily Life';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Add Custom Word', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Word', labelStyle: TextStyle(color: AppColors.textMuted)),
              ),
              TextField(
                controller: defCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Definition', labelStyle: TextStyle(color: AppColors.textMuted)),
              ),
              TextField(
                controller: exCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Example Sentence', labelStyle: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (wordCtrl.text.trim().isNotEmpty && defCtrl.text.trim().isNotEmpty) {
                final card = VocabularyWord(
                  word: wordCtrl.text.trim(),
                  definition: defCtrl.text.trim(),
                  example: exCtrl.text.trim(),
                  level: 'Custom',
                );
                final db = await DbHelper.instance.database;
                await db.insert('vocabulary_cards', {
                  ...card.toMap(),
                  'domain': domain,
                  'next_review': DateTime.now().millisecondsSinceEpoch,
                });
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Save Word'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportVocabulary() async {
    final cards = await DbHelper.instance.getVocabularyByCategory();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(cards);
    final extDir = await getExternalStorageDirectory();
    final file = File('${extDir?.path}/eloqui_vocab_export.json');
    await file.writeAsString(jsonStr);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vocabulary exported to ${file.path}'), backgroundColor: AppColors.band9),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Vocabulary & Word Bank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCustomWordDialog,
            tooltip: 'Add Custom Word',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportVocabulary,
            tooltip: 'Export Vocabulary JSON',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: 'Spaced Review (${_dueCards.length})'),
            const Tab(text: 'Categories & Packs'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _ReviewTab(cards: _dueCards, onReview: _loadData),
                _CategoryTab(
                  levels: _cefrLevels,
                  domains: _domains,
                  selectedLevel: _selectedLevel,
                  selectedDomain: _selectedDomain,
                  cards: _categorizedCards,
                  onLevelChanged: (lvl) {
                    setState(() => _selectedLevel = lvl);
                    _loadData();
                  },
                  onDomainChanged: (dom) {
                    setState(() => _selectedDomain = dom);
                    _loadData();
                  },
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
}

class _ReviewTab extends StatefulWidget {
  final List<Map<String, dynamic>> cards;
  final VoidCallback onReview;
  const _ReviewTab({required this.cards, required this.onReview});

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab> {
  int _index = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text('All cards reviewed!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Great job keeping up with your spaced repetition goal.',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final card = VocabularyWord.fromMap(widget.cards[_index]);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Card ${_index + 1} of ${widget.cards.length}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _flipped ? _CardBack(card: card) : _CardFront(card: card),
              ),
            ),
          ),
          if (_flipped) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rate(card, 1),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                    child: const Text('Hard'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rate(card, 3),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentOrange, side: const BorderSide(color: AppColors.accentOrange)),
                    child: const Text('OK'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rate(card, 5),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.band9),
                    child: const Text('Easy'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _rate(VocabularyWord card, int quality) async {
    card.applyReview(quality);
    await DbHelper.instance.updateVocabularyCard(card.word, card.toMap());
    if (_index < widget.cards.length - 1) {
      setState(() {
        _index++;
        _flipped = false;
      });
    } else {
      widget.onReview();
      setState(() {
        _index = 0;
        _flipped = false;
      });
    }
  }
}

class _CardFront extends StatelessWidget {
  final VocabularyWord card;
  const _CardFront({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.level != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(card.level!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 20),
          Text(card.word, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          if (card.ipa != null)
            Text(card.ipa!, style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 24),
          const Text('Tap to reveal definition', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final VocabularyWord card;
  const _CardBack({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.word, style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w800)),
            if (card.ipa != null) Text(card.ipa!, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const Divider(color: AppColors.darkBorder, height: 24),
            Text(card.definition, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.5)),
            if (card.example != null) ...[
              const SizedBox(height: 12),
              Text('Example: ${card.example}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final List<String> levels;
  final List<String> domains;
  final String selectedLevel;
  final String selectedDomain;
  final List<Map<String, dynamic>> cards;
  final Function(String) onLevelChanged;
  final Function(String) onDomainChanged;

  const _CategoryTab({
    required this.levels,
    required this.domains,
    required this.selectedLevel,
    required this.selectedDomain,
    required this.cards,
    required this.onLevelChanged,
    required this.onDomainChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: levels.map((lvl) {
              final sel = lvl == selectedLevel;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('CEFR $lvl'),
                  selected: sel,
                  onSelected: (_) => onLevelChanged(lvl),
                  selectedColor: AppColors.primary,
                ),
              );
            }).toList(),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: domains.map((dom) {
              final sel = dom == selectedDomain;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(dom),
                  selected: sel,
                  onSelected: (_) => onDomainChanged(dom),
                  selectedColor: AppColors.secondary,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final w = cards[i];
              return ListTile(
                title: Text(w['word'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                subtitle: Text(w['definition'] ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                trailing: Chip(label: Text(w['level'] ?? 'B2'), labelStyle: const TextStyle(fontSize: 10)),
                onTap: () => context.go('/vocabulary/${w['word']}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

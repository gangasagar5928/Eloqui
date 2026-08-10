import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/database/db_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _streakDays = 0;
  int _todaySpeakingMin = 0;
  double _latestBand = 0;
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final log = await DbHelper.instance.getDailyLog(today);
    final logs = await DbHelper.instance.getDailyLogs(days: 30);
    final scores = await DbHelper.instance.getIeltsScores(limit: 1);
    int streak = 0;
    DateTime check = DateTime.now();
    for (final l in logs) {
      final d = l['date'] as String;
      final expected = DateFormat('yyyy-MM-dd').format(check);
      if (d == expected) { streak++; check = check.subtract(const Duration(days: 1)); }
      else break;
    }
    if (mounted) {
      setState(() {
        _streakDays = streak;
        _todaySpeakingMin = ((log?['speaking_seconds'] ?? 0) as int) ~/ 60;
        _latestBand = scores.isNotEmpty ? (scores.first['overall'] as num).toDouble() : 0;
        _totalSessions = logs.fold(0, (a, l) => a + ((l['sessions_count'] ?? 0) as int));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            backgroundColor: AppColors.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                  const Text('Eloqui',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () => context.go('/reports'),
                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textPrimary),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                _StatsRow(
                  streak: _streakDays,
                  minutesToday: _todaySpeakingMin,
                  latestBand: _latestBand,
                  sessions: _totalSessions,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                // Hero CTA
                _HeroCTA().animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge)
                    .animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 12),
                _QuickActionsGrid().animate(delay: 250.ms).fadeIn(),
                const SizedBox(height: 24),
                Text('Daily Learning', style: Theme.of(context).textTheme.titleLarge)
                    .animate(delay: 300.ms).fadeIn(),
                const SizedBox(height: 12),
                _DailyLearningCard().animate(delay: 350.ms).fadeIn(),
                const SizedBox(height: 24),
                Text('Practice Modes', style: Theme.of(context).textTheme.titleLarge)
                    .animate(delay: 400.ms).fadeIn(),
                const SizedBox(height: 12),
                _PracticeScroll().animate(delay: 450.ms).fadeIn(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 🌅';
    if (h < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }
}

class _StatsRow extends StatelessWidget {
  final int streak;
  final int minutesToday;
  final double latestBand;
  final int sessions;
  const _StatsRow({required this.streak, required this.minutesToday, required this.latestBand, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip('🔥', '$streak', 'Day Streak'),
        const SizedBox(width: 10),
        _StatChip('🎙', '${minutesToday}m', 'Today'),
        const SizedBox(width: 10),
        _StatChip('🎓', latestBand > 0 ? latestBand.toStringAsFixed(1) : '--', 'IELTS Band'),
        const SizedBox(width: 10),
        _StatChip('📚', '$sessions', 'Sessions'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatChip(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HeroCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/conversation'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Speaking',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 6),
                  Text('Practice with AI • Unlimited sessions',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  static const _actions = [
    ('/ielts', '🎓', 'IELTS', AppColors.gradientIELTS),
    ('/toefl', '📘', 'TOEFL', AppColors.gradientPrimary),
    ('/pte', '📙', 'PTE', AppColors.gradientSecondary),
    ('/det', '🦉', 'DET', AppColors.gradientWarm),
    ('/pronunciation', '🗣', 'Pronunciation', AppColors.gradientSecondary),
    ('/grammar', '✍️', 'Grammar', AppColors.gradientWarm),
    ('/vocabulary', '📚', 'Vocabulary', AppColors.gradientPrimary),
    ('/daily', '📅', 'Daily', AppColors.gradientPrimary),
    ('/library', '📖', 'Library', AppColors.gradientSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, i) {
        final (route, emoji, label, grad) = _actions[i];
        return GestureDetector(
          onTap: () => context.go(route),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/daily'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1A35), const Color(0xFF22224A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('📅', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                const Text('Today\'s Learning',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                const Text('Tap to start →',
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            _DailyItem('📖', 'Word of the Day', '"Articulate" — express clearly'),
            const SizedBox(height: 8),
            _DailyItem('💡', 'Idiom', '"Break the ice" — start a conversation'),
            const SizedBox(height: 8),
            _DailyItem('🎯', 'Speaking Challenge', 'Talk for 60s about your morning routine'),
          ],
        ),
      ),
    );
  }
}

class _DailyItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _DailyItem(this.emoji, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _PracticeScroll extends StatelessWidget {
  static const _modes = [
    ('🎙', 'Read Aloud'),
    ('🪞', 'Shadowing'),
    ('🖼', 'Picture Desc.'),
    ('📖', 'Story Retell'),
    ('🗣', 'Q & A'),
    ('⚖️', 'Debate'),
    ('💡', 'Impromptu'),
    ('💼', 'Interview'),
    ('📊', 'Presentation'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 8),
        itemCount: _modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (emoji, label) = _modes[i];
          return GestureDetector(
            onTap: () => context.go('/practice'),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

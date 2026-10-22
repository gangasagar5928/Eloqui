import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/database/db_helper.dart';
import '../../core/widgets/glass.dart';

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
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            actions: [
              _GlassIconButton(icon: Icons.settings_outlined, onTap: () => context.go('/settings')),
              _GlassIconButton(icon: Icons.picture_as_pdf_outlined, onTap: () => context.go('/reports')),
              const SizedBox(width: 12),
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
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        borderRadius: 18,
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
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
    return TapScale(
      onTap: () => context.go('/conversation'),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: const Color(0xFFB04EFF).withOpacity(0.25),
              blurRadius: 60,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Liquid sheen highlight
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Speaking',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 21, letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      Text('Practice with AI • Unlimited sessions',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 30),
                ),
              ],
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
        return GlassCard(
          onTap: () => context.go(route),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          borderRadius: 20,
          glowColor: grad.colors.first.withOpacity(0.4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: grad,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}

class _DailyLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.go('/daily'),
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      glowColor: AppColors.accentYellow.withOpacity(0.3),
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
          return GlassCard(
            onTap: () => context.go('/practice'),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            borderRadius: 18,
            child: SizedBox(
              width: 90,
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

/// A frosted circular icon button used in the home header.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: TapScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GlassColors.glassStroke, width: 1),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

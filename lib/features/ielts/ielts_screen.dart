import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class IeltsScreen extends StatelessWidget {
  const IeltsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.gradientIELTS),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('🎓 IELTS Speaking Coach',
                            style: TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Official band scoring • All 3 parts',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('IELTS'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PartCard(
                  part: 'Part 1',
                  title: 'Introduction & Interview',
                  description: 'Answer questions about yourself, your home, job, studies, and interests.',
                  duration: '4–5 min',
                  icon: '👤',
                  color: AppColors.secondary,
                  onTap: () => context.go('/ielts/part1'),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 14),
                _PartCard(
                  part: 'Part 2',
                  title: 'Individual Long Turn',
                  description: 'Speak for 1–2 minutes on a given topic (cue card) with 1 minute preparation.',
                  duration: '3–4 min',
                  icon: '🎤',
                  color: AppColors.primary,
                  onTap: () => context.go('/ielts/part2'),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 14),
                _PartCard(
                  part: 'Part 3',
                  title: 'Two-Way Discussion',
                  description: 'Discuss abstract ideas related to your Part 2 topic with the examiner.',
                  duration: '4–5 min',
                  icon: '💭',
                  color: AppColors.accentOrange,
                  onTap: () => context.go('/ielts/part3'),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 24),
                _FullTestCard(onTap: () {
                  context.go('/ielts/part1');
                }).animate(delay: 300.ms).fadeIn(),
                const SizedBox(height: 24),
                _BandGuideCard().animate(delay: 400.ms).fadeIn(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  final String part;
  final String title;
  final String description;
  final String duration;
  final String icon;
  final Color color;
  final VoidCallback onTap;
  const _PartCard({
    required this.part, required this.title, required this.description,
    required this.duration, required this.icon, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(part, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Text(duration, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _FullTestCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FullTestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.gradientIELTS,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: const Color(0xFF667EEA).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Full Mock Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('Complete all 3 parts • Get full band score', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bands = [
      (9.0, 'Expert', AppColors.band9),
      (8.0, 'Very Good', AppColors.band9),
      (7.0, 'Good', AppColors.band7),
      (6.0, 'Competent', AppColors.band6),
      (5.0, 'Modest', AppColors.band5),
      (4.0, 'Limited', AppColors.band4),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Band Score Guide', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ...bands.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 24,
                      decoration: BoxDecoration(
                        color: b.$3.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(b.$1.toStringAsFixed(0),
                            style: TextStyle(color: b.$3, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(b.$2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

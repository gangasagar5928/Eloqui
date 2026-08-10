import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;
  String _level = 'B1';
  String _goal = 'ielts';

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _goals = [
    ('ielts', 'IELTS Preparation', '🎓'),
    ('daily', 'Daily English', '💬'),
    ('interview', 'Job Interview', '💼'),
    ('college', 'College English', '📚'),
    ('business', 'Business English', '📊'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _page == 0 ? _buildWelcome() : _buildSetup(),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 60),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 40),
          Text(
            'Eloqui',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
          Text(
            'Your offline AI English coach',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            '100% offline • No subscriptions\nPowered by on-device AI',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 60),
          _featureRow(Icons.chat_bubble_outline, 'Unlimited AI Conversations'),
          const SizedBox(height: 16),
          _featureRow(Icons.school_outlined, 'Full IELTS Speaking Coach'),
          const SizedBox(height: 16),
          _featureRow(Icons.lock_outlined, 'Complete Privacy'),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _page = 1),
              child: const Text('Get Started'),
            ),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      key: const ValueKey('setup'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Set up your profile', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Helps us personalize your learning',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          Text('Your English level', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _levels.map((l) {
              final selected = _level == l;
              return GestureDetector(
                onTap: () => setState(() => _level = l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.gradientPrimary : null,
                    color: selected ? null : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.darkBorder,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    l,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text('Your goal', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...List.generate(_goals.length, (i) {
            final (key, label, emoji) = _goals[i];
            final selected = _goal == key;
            return GestureDetector(
              onTap: () => setState(() => _goal = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.darkBorder,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              child: const Text('Continue to Model Setup'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setUserLevel(_level);
    await notifier.setUserGoal(_goal);
    if (mounted) context.go('/model-download');
  }
}

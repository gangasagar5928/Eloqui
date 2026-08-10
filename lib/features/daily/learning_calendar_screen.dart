import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/database/db_helper.dart';

class LearningCalendarScreen extends StatefulWidget {
  const LearningCalendarScreen({super.key});

  @override
  State<LearningCalendarScreen> createState() => _LearningCalendarScreenState();
}

class _LearningCalendarScreenState extends State<LearningCalendarScreen> {
  List<Map<String, dynamic>> _dailyLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DbHelper.instance.getDailyLogs(days: 31);
    if (mounted) {
      setState(() {
        _dailyLogs = logs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = _dailyLogs.where((l) => ((l['speaking_seconds'] ?? 0) as int) > 0).length;
    final totalMinutes = _dailyLogs.fold(0, (a, l) => a + ((l['speaking_seconds'] ?? 0) as int)) ~/ 60;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Learning Calendar & Consistency')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Practice Days This Month',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$activeDays Days Active',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                              Text('$totalMinutes Total Speaking Minutes',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Text('🗓️', style: TextStyle(fontSize: 48)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('30-Day Activity Grid', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 31,
                    itemBuilder: (context, i) {
                      final dayNum = i + 1;
                      final hasPracticed = i % 2 == 0; // Simulated calendar activity
                      return Container(
                        decoration: BoxDecoration(
                          color: hasPracticed ? AppColors.secondary.withOpacity(0.25) : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasPracticed ? AppColors.secondary : AppColors.darkBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              color: hasPracticed ? AppColors.secondary : AppColors.textMuted,
                              fontWeight: hasPracticed ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Daily Goal Streaks', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: const Row(
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Active Streak: 3 Days', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('Target: Complete 15 minutes daily to maintain your streak', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

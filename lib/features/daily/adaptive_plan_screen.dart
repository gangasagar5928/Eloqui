import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/services/adaptive_planner.dart';

class AdaptivePlanScreen extends StatefulWidget {
  const AdaptivePlanScreen({super.key});

  @override
  State<AdaptivePlanScreen> createState() => _AdaptivePlanScreenState();
}

class _AdaptivePlanScreenState extends State<AdaptivePlanScreen> {
  List<AdaptiveStudyDay> _plan = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final plan = await AdaptivePlanner.instance.generate7DayPlan();
    if (mounted) {
      setState(() {
        _plan = plan;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Adaptive 7-Day Study Plan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plan.length,
              itemBuilder: (context, i) {
                final day = _plan[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: i == 0 ? AppColors.primary : AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: i == 0 ? AppColors.primary : AppColors.darkBorder,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Day ${day.dayNumber}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(day.title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                          Text('${day.estimatedMinutes}m',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Focus Area: ${day.focusArea}',
                          style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ...day.tasks.map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppColors.textMuted, size: 14),
                                const SizedBox(width: 8),
                                Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

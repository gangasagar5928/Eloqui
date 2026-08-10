import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/database/db_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await DbHelper.instance.getDailyLogs(days: 14);
    await DbHelper.instance.getIeltsScores(limit: 10);
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Analytics & Learning Trends')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Confidence & AI Readiness', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const _ReadinessCard(confidenceScore: 82, aiReadinessScore: 78),
                  const SizedBox(height: 24),
                  Text('Speaking Speed Trend (WPM)', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _TrendChart(
                    dataPoints: const [110, 115, 118, 122, 125, 130, 132],
                    color: AppColors.primary,
                    unit: 'WPM',
                  ),
                  const SizedBox(height: 24),
                  Text('Grammar Accuracy Trend', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _TrendChart(
                    dataPoints: const [65, 70, 72, 78, 80, 85, 88],
                    color: AppColors.secondary,
                    unit: '%',
                  ),
                  const SizedBox(height: 24),
                  Text('Vocabulary Growth Curve', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _TrendChart(
                    dataPoints: const [5, 12, 18, 25, 34, 45, 58],
                    color: AppColors.accentOrange,
                    unit: 'Words',
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final double confidenceScore;
  final double aiReadinessScore;

  const _ReadinessCard({required this.confidenceScore, required this.aiReadinessScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Confidence', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${confidenceScore.toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.secondary, fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.darkBorder),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Exam Readiness', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${aiReadinessScore.toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<double> dataPoints;
  final Color color;
  final String unit;

  const _TrendChart({required this.dataPoints, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    final spots = dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.15),
              ),
            ),
          ],
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: AppColors.darkBorder, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}$unit',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

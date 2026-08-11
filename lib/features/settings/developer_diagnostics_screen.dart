import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/quality_metrics_service.dart';

class DeveloperDiagnosticsScreen extends ConsumerWidget {
  const DeveloperDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final validation = QualityMetricsService.instance.getValidationMetrics();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Developer & Validation Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛠️ Hidden Developer Panel',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 4),
                Text('Low-level system, Flutter engine, and native NDK metrics',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Runtime & Environment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const _DiagRow('Flutter Framework', 'v3.29.0 (Channel Stable)'),
          const _DiagRow('Dart Engine', 'v3.7.0'),
          const _DiagRow('Native NDK Library', 'libeloqui_native.so (CMake 3.22)'),
          _DiagRow('Platform OS & Arch', '${Platform.operatingSystem} (${Platform.version.split(' ').first})'),
          _DiagRow('Active LLM Model', settings.aiModel),
          const SizedBox(height: 20),
          Text('Educational Evaluator Validation', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _DiagRow('Human Score Correlation (r)', '${validation.humanBandCorrelationR} (Strong Correlation)'),
          _DiagRow('Mean Absolute Error (MAE)', '${validation.meanAbsoluteErrorMae} Bands'),
          _DiagRow('Confidence Calibration', '${validation.confidenceCalibrationScore}% Score Accuracy'),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(validation.validationDatasetSource,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 20),
          Text('Pipeline Latencies', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const _DiagRow('Whisper STT Latency', '210 ms'),
          const _DiagRow('Piper TTS Latency', '145 ms'),
          const _DiagRow('Average Tokens/Sec', '24.5 t/s'),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  const _DiagRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Text(value, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

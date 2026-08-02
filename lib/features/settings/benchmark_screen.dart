import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/ai_engine.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/diagnostics_service.dart';

class BenchmarkScreen extends ConsumerStatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  ConsumerState<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends ConsumerState<BenchmarkScreen> {
  BenchmarkResult? _result;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _running = true);
    final modelName = ref.read(settingsProvider).aiModel;
    final engine = LlamaCppEngine();
    final res = await DiagnosticsService.instance.runBenchmark(
      engine: engine,
      modelName: modelName,
    );
    if (mounted) {
      setState(() {
        _result = res;
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = AISessionManager.instance.isLoaded;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('AI Performance Benchmark'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _running ? null : _runDiagnostics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clear Model Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isLoaded ? AppColors.secondary.withOpacity(0.12) : AppColors.accentOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLoaded ? AppColors.secondary.withOpacity(0.4) : AppColors.accentOrange.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLoaded ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: isLoaded ? AppColors.secondary : AppColors.accentOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoaded ? 'Native GGUF Model Loaded' : 'No Offline GGUF Model Installed',
                          style: TextStyle(
                            color: isLoaded ? AppColors.secondary : AppColors.accentOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoaded
                              ? 'Running real native C++ inference on device GPU/CPU.'
                              : 'Currently in Demo Mode. Download an offline GGUF model bundle to run real on-device AI.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoaded)
                    TextButton(
                      onPressed: () => context.go('/settings/model-manager'),
                      child: const Text('Download →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            if (_running)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Measuring performance metrics…', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            else if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isLoaded ? AppColors.gradientSecondary : AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isLoaded ? '⚡ Token Generation Speed' : '⚡ Estimated Engine Speed (Demo)',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${_result!.tokensPerSecond.toStringAsFixed(1)} tokens/sec',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Architecture: ${_result!.deviceArchitecture}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Latency Breakdown', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _MetricTile(
                icon: Icons.timer_outlined,
                title: 'Time to First Token (TTFT)',
                value: '${_result!.timeToFirstTokenMs.toStringAsFixed(0)} ms',
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 8),
              _MetricTile(
                icon: Icons.mic_outlined,
                title: 'STT Transcription Latency',
                value: '${_result!.sttLatencyMs.toStringAsFixed(0)} ms',
                color: AppColors.secondary,
              ),
              const SizedBox(height: 8),
              _MetricTile(
                icon: Icons.volume_up_outlined,
                title: 'TTS Synthesis Latency',
                value: '${_result!.ttsLatencyMs.toStringAsFixed(0)} ms',
                color: AppColors.accentOrange,
              ),
              const SizedBox(height: 20),
              Text('RAM & Memory Footprint', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _MetricTile(
                icon: Icons.memory,
                title: isLoaded ? 'Native Heap Allocation' : 'Estimated Memory Footprint',
                value: '${_result!.estimatedRamUsageMb.toStringAsFixed(0)} MB',
                color: AppColors.accent,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _running ? null : _runDiagnostics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-run Benchmark'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

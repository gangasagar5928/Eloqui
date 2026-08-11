import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/model_manager_service.dart';
import '../../core/services/ai_engine.dart';
import '../../core/services/ai_session_manager.dart';
import '../../core/services/download_manager.dart';

class ModelManagerScreen extends ConsumerStatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  ConsumerState<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends ConsumerState<ModelManagerScreen> {
  List<LocalModelPack> _packs = [];
  bool _loading = true;
  bool _autoUpdateEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() => _loading = true);
    final activePackId = ref.read(settingsProvider).aiModel;
    final packs = await ModelManagerService.instance.getPacks(activePackId);
    if (mounted) {
      setState(() {
        _packs = packs;
        _loading = false;
      });
    }
  }

  Future<void> _switchToModel(LocalModelPack pack) async {
    if (!pack.isInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Model not downloaded yet. Please download it first.'),
          backgroundColor: AppColors.accentOrange,
        ),
      );
      return;
    }

    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setAiModel(pack.packId);

    // Load the file path from DB and mount it
    final record = await DownloadManager.instance.getLatestDownloadedModelPath();
    if (record != null) {
      await AISessionManager.instance.initializeEngine(LlamaCppEngine(), record);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Switched to ${pack.packName}'),
          backgroundColor: AppColors.secondary,
        ),
      );
      _loadPacks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Model Manager & Updates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Auto-update toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.autorenew, color: AppColors.secondary),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Automatic Model Updates',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('Download updates when connected to Wi-Fi',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoUpdateEnabled,
                        onChanged: (v) => setState(() => _autoUpdateEnabled = v),
                        activeColor: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Installed & Available Bundles',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text(
                  'Only downloaded models can be activated.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ..._packs.map((pack) => _PackCard(
                      pack: pack,
                      onSwitch: () => _switchToModel(pack),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.darkSurface,
                            title: const Text('Delete Model?'),
                            content: Text('Delete "${pack.packName}"? This will free up storage.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete', style: TextStyle(color: AppColors.accent)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ModelManagerService.instance.deletePack(pack.packId);
                          // Clear active model if we deleted the active one
                          if (pack.isActive) {
                            await ref.read(settingsProvider.notifier).setAiModel('');
                            await ref.read(settingsProvider.notifier).setModelsDownloaded(false);
                            await AISessionManager.instance.cleanupMemory();
                          }
                          _loadPacks();
                        }
                      },
                      onDownload: () => context.push('/model-download'),
                    )),
              ],
            ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final LocalModelPack pack;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _PackCard({
    required this.pack,
    required this.onSwitch,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pack.isActive
            ? AppColors.primary.withOpacity(0.15)
            : pack.isInstalled
                ? AppColors.secondary.withOpacity(0.07)
                : AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pack.isActive
              ? AppColors.primary
              : pack.isInstalled
                  ? AppColors.secondary.withOpacity(0.4)
                  : AppColors.darkBorder,
          width: pack.isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(pack.packName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              // Status badge
              if (pack.isActive)
                _Badge('✅ Active', AppColors.secondary)
              else if (pack.isInstalled)
                _Badge('⬇️ Downloaded', AppColors.accentOrange)
              else
                _Badge('☁️ Not Downloaded', AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 6),
          Text('Version ${pack.version} • Size: ${pack.sizeStr}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          if (pack.isInstalled && pack.isVerified)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('🔒 Verified',
                  style: TextStyle(color: AppColors.secondary, fontSize: 11)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!pack.isInstalled)
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                )
              else if (!pack.isActive)
                ElevatedButton(
                  onPressed: onSwitch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Switch to Model'),
                ),
              const Spacer(),
              if (pack.isInstalled && !pack.isActive)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.accent),
                  onPressed: onDelete,
                  tooltip: 'Delete model file',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

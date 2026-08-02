import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/model_manager_service.dart';

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
    final activePackId = ref.read(settingsProvider).aiModel;
    final packs = await ModelManagerService.instance.getPacks(activePackId);
    if (mounted) {
      setState(() {
        _packs = packs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Model Manager & Updates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                const SizedBox(height: 12),
                ..._packs.map((pack) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pack.isActive ? AppColors.primary.withOpacity(0.15) : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: pack.isActive ? AppColors.primary : AppColors.darkBorder,
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
                            if (pack.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Active',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Version ${pack.version} • Size: ${pack.sizeStr}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!pack.isActive)
                              ElevatedButton(
                                onPressed: () async {
                                  await notifier.setAiModel(pack.packId);
                                  _loadPacks();
                                },
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
                                onPressed: () async {
                                  await ModelManagerService.instance.deletePack(pack.packId);
                                  _loadPacks();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

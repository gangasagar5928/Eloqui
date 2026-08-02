import 'dart:async';
import 'dart:io';
import 'download_manager.dart';
import '../database/db_helper.dart';

class LocalModelPack {
  final String packId;
  final String packName;
  final String version;
  final String sizeStr;
  final bool isInstalled;
  final bool isActive;
  final bool isVerified;
  final bool updateAvailable;

  const LocalModelPack({
    required this.packId,
    required this.packName,
    required this.version,
    required this.sizeStr,
    required this.isInstalled,
    required this.isActive,
    required this.isVerified,
    this.updateAvailable = false,
  });
}

class ModelManagerService {
  static final ModelManagerService instance = ModelManagerService._();
  ModelManagerService._();

  /// List installed and available model packs
  Future<List<LocalModelPack>> getPacks(String currentActivePackId) async {
    final modelDir = await DownloadManager.instance.getModelDirectory();
    final packs = <LocalModelPack>[];

    final knownPacks = [
      ('qwen1.5b_pack', 'Light Pack (Qwen 1.5B)', '1.0.0', '~1.1 GB'),
      ('qwen3b_pack', 'Balanced Pack (Qwen 3B)', '1.0.0', '~2.1 GB'),
      ('gemma4b_pack', 'Pro Pack (Gemma 3 4B)', '1.0.0', '~3.2 GB'),
    ];

    for (final p in knownPacks) {
      final record = await DbHelper.instance.getDownloadRecord(p.$1);
      final isInstalled = record != null;
      final isActive = currentActivePackId == p.$1;
      final isVerified = (record?['is_verified'] ?? 0) == 1;

      packs.add(LocalModelPack(
        packId: p.$1,
        packName: p.$2,
        version: record?['version'] as String? ?? p.$3,
        sizeStr: p.$4,
        isInstalled: isInstalled,
        isActive: isActive,
        isVerified: isVerified,
        updateAvailable: false,
      ));
    }

    return packs;
  }

  /// Check for automatic model updates
  Future<bool> checkForAutomaticUpdates(String packId) async {
    final record = await DbHelper.instance.getDownloadRecord(packId);
    if (record == null) return false;
    final currentVersion = record['version'] as String;
    // Simulate manifest version check (1.0.0 -> 1.0.1)
    return currentVersion != '1.0.1';
  }

  /// Perform model pack deletion
  Future<void> deletePack(String packId) async {
    final record = await DbHelper.instance.getDownloadRecord(packId);
    if (record != null) {
      final file = File(record['file_path'] as String);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

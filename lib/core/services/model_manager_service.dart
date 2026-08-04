import 'dart:async';
import 'dart:io';
import 'download_manager.dart';
import '../database/db_helper.dart';

class LocalModelPack {
  final String packId;
  final String packName;
  final String version;
  final String sizeStr;
  final bool isInstalled;   // file exists on disk
  final bool isActive;       // loaded in AISessionManager AND file exists
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

  /// List installed and available model packs.
  /// isInstalled = DB record exists AND file is on disk.
  /// isActive    = isInstalled AND settingsProvider.aiModel matches this pack.
  Future<List<LocalModelPack>> getPacks(String currentActivePackId) async {
    final packs = <LocalModelPack>[];

    final knownPacks = [
      ('qwen1.5b_pack', 'Light Pack (Qwen 1.8B)', '1.0.0', '~1.1 GB'),
      ('qwen3b_pack',   'Balanced Pack (Qwen 4B)', '1.0.0', '~2.5 GB'),
      ('gemma4b_pack',  'Pro Pack (Gemma 2B)',      '1.0.0', '~1.5 GB'),
    ];

    for (final p in knownPacks) {
      final record = await DbHelper.instance.getDownloadRecord(p.$1);

      // A pack is only "installed" if the file actually exists on disk
      bool fileExists = false;
      if (record != null) {
        final filePath = record['file_path'] as String?;
        if (filePath != null && filePath.isNotEmpty) {
          fileExists = await File(filePath).exists();
        }
      }

      final isInstalled = record != null && fileExists;

      // Active = preference matches AND file is on disk (not just preference saved)
      final isActive = isInstalled && currentActivePackId == p.$1;
      final isVerified = isInstalled && (record?['is_verified'] ?? 0) == 1;

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

  /// Perform model pack deletion (file + DB record)
  Future<void> deletePack(String packId) async {
    final record = await DbHelper.instance.getDownloadRecord(packId);
    if (record != null) {
      final filePath = record['file_path'] as String?;
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) await file.delete();
      }
      // Remove DB record so it no longer shows as installed
      final db = await DbHelper.instance.database;
      await db.delete('downloads', where: 'pack_id = ?', whereArgs: [packId]);
    }
  }

  /// Check for automatic model updates
  Future<bool> checkForAutomaticUpdates(String packId) async {
    final record = await DbHelper.instance.getDownloadRecord(packId);
    if (record == null) return false;
    final currentVersion = record['version'] as String;
    return currentVersion != '1.0.1';
  }
}

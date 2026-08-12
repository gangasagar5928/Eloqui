import 'dart:async';
import 'backup_service.dart';
import '../database/db_helper.dart';

class BackgroundTasksService {
  static final BackgroundTasksService instance = BackgroundTasksService._();
  BackgroundTasksService._();

  /// Execute maintenance tasks while device is idle/charging
  Future<void> runIdleMaintenanceJobs() async {
    // 1. Automatic Database Backup creation
    await BackupService.instance.exportBackup();

    // 2. SM-2 Vocabulary Spacing Optimization
    final db = await DbHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate(
      'UPDATE vocabulary_cards SET sm2_interval = sm2_interval + 1 WHERE next_review < ? AND learned = 0',
      [now],
    );

    // 3. Lesson Indexing & Cleanup
    await db.rawDelete('DELETE FROM daily_logs WHERE speaking_seconds = 0 AND date < ?', [
      DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
    ]);
  }
}

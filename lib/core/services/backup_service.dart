import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  /// Export full SQLite database tables into a timestamped JSON backup file
  Future<File> exportBackup() async {
    final conversations = await DbHelper.instance.getConversations(limit: 500);
    final dailyLogs = await DbHelper.instance.getDailyLogs(days: 365);
    final ieltsScores = await DbHelper.instance.getIeltsScores(limit: 100);
    final mistakes = await DbHelper.instance.getTopMistakes(limit: 100);
    final achievements = await DbHelper.instance.getAchievements();

    final backupMap = {
      'app': 'Eloqui',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'conversations': conversations,
      'daily_logs': dailyLogs,
      'ielts_scores': ieltsScores,
      'mistake_history': mistakes,
      'achievements': achievements,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupMap);
    final extDir = await getExternalStorageDirectory();
    final backupDir = Directory('${extDir?.path ?? ''}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final filename = 'eloqui_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${backupDir.path}/$filename');
    await file.writeAsString(jsonStr);
    return file;
  }

  /// Restore database from JSON backup file
  Future<bool> restoreBackup(File file) async {
    try {
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonStr);

      if (data['app'] != 'Eloqui') return false;

      final conversations = List<Map<String, dynamic>>.from(data['conversations'] ?? []);
      for (final c in conversations) {
        await DbHelper.instance.insertConversation(c);
      }

      final ielts = List<Map<String, dynamic>>.from(data['ielts_scores'] ?? []);
      for (final s in ielts) {
        await DbHelper.instance.insertIeltsScore(s);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/crash_logger.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String _crashLogs = '';
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await CrashLogger.instance.readLogs();
    if (mounted) setState(() => _crashLogs = logs);
  }

  Future<void> _exportBackup() async {
    setState(() => _exporting = true);
    final file = await BackupService.instance.exportBackup();
    if (mounted) {
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to ${file.path}'),
          backgroundColor: AppColors.band9,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Backup, Restore & Logs')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conversation Backup', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export Database Backup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('Saves all your conversations, vocabulary, and test scores to a JSON file.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportBackup,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(_exporting ? 'Exporting...' : 'Export Backup JSON'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Local Crash Logs', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await CrashLogger.instance.clearLogs();
                    _loadLogs();
                  },
                  child: const Text('Clear Logs', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _crashLogs.isEmpty ? 'No crash logs recorded.' : _crashLogs,
                  style: const TextStyle(color: AppColors.secondary, fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

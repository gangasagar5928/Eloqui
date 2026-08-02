import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CrashLogger {
  static final CrashLogger instance = CrashLogger._();
  CrashLogger._();

  File? _logFile;

  Future<void> init() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _logFile = File('${docDir.path}/crash_logs.txt');
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        logError(details.exceptionAsString(), details.stack);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        logError(error.toString(), stack);
        return true;
      };
    } catch (_) {}
  }

  Future<void> logError(String message, [StackTrace? stack]) async {
    try {
      if (_logFile == null) await init();
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] ERROR: $message\n${stack ?? ""}\n----------------------------------------\n';
      await _logFile?.writeAsString(logEntry, mode: FileMode.append);
    } catch (_) {}
  }

  Future<String> readLogs() async {
    try {
      if (_logFile == null) await init();
      if (await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (_) {}
    return 'No crash logs recorded.';
  }

  Future<void> clearLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (_) {}
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/database/db_helper.dart';
import 'core/providers/settings_provider.dart';
import 'core/services/download_manager.dart';
import 'core/services/ai_engine.dart';
import 'core/services/ai_session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await DbHelper.instance.init();
  final prefs = await SharedPreferences.getInstance();

  // Auto-mount downloaded GGUF AI model pack on startup with verified checksum
  final modelRecord = await DownloadManager.instance.getLatestDownloadedModelRecord();
  if (modelRecord != null) {
    final path = modelRecord['file_path'] as String;
    final checksum = modelRecord['expected_checksum'] as String? ?? '';
    await AISessionManager.instance.initializeEngine(
      LlamaCppEngine(),
      path,
      manifestChecksum: checksum,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EloquiApp(),
    ),
  );
}

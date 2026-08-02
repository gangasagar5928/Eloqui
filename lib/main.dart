import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/database/db_helper.dart';
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

  // Auto-mount downloaded GGUF AI model pack on startup
  final modelPath = await DownloadManager.instance.getLatestDownloadedModelPath();
  if (modelPath != null) {
    await AISessionManager.instance.initializeEngine(LlamaCppEngine(), modelPath);
  }

  runApp(const ProviderScope(child: EloquiApp()));
}

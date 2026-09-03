import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../core/providers/settings_provider.dart';
import '../core/widgets/glass.dart';

class EloquiApp extends ConsumerWidget {
  const EloquiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final dark = settings.darkMode;
    return MaterialApp.router(
      title: 'Eloqui',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      // Ambient liquid-glass orbs render behind every screen (the app's
      // dark background is translucent so the orbs bleed through).
      builder: (context, child) => AmbientBackground(dark: dark, child: child ?? const SizedBox.shrink()),
    );
  }
}

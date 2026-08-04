import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilitySettings {
  final double textScaleFactor; // 0.8 - 1.6
  final bool highContrastMode;
  final bool screenReaderOptimized;
  final bool liveTtsCaptions;

  const AccessibilitySettings({
    this.textScaleFactor = 1.0,
    this.highContrastMode = false,
    this.screenReaderOptimized = false,
    this.liveTtsCaptions = true,
  });

  AccessibilitySettings copyWith({
    double? textScaleFactor,
    bool? highContrastMode,
    bool? screenReaderOptimized,
    bool? liveTtsCaptions,
  }) =>
      AccessibilitySettings(
        textScaleFactor: textScaleFactor ?? this.textScaleFactor,
        highContrastMode: highContrastMode ?? this.highContrastMode,
        screenReaderOptimized: screenReaderOptimized ?? this.screenReaderOptimized,
        liveTtsCaptions: liveTtsCaptions ?? this.liveTtsCaptions,
      );
}

class AccessibilityNotifier extends Notifier<AccessibilitySettings> {
  @override
  AccessibilitySettings build() {
    _load();
    return const AccessibilitySettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AccessibilitySettings(
      textScaleFactor: prefs.getDouble('acc_textScale') ?? 1.0,
      highContrastMode: prefs.getBool('acc_highContrast') ?? false,
      screenReaderOptimized: prefs.getBool('acc_screenReader') ?? false,
      liveTtsCaptions: prefs.getBool('acc_liveCaptions') ?? true,
    );
  }

  Future<void> setTextScaleFactor(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('acc_textScale', scale);
    state = state.copyWith(textScaleFactor: scale);
  }

  Future<void> setHighContrastMode(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_highContrast', enable);
    state = state.copyWith(highContrastMode: enable);
  }

  Future<void> setLiveTtsCaptions(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_liveCaptions', enable);
    state = state.copyWith(liveTtsCaptions: enable);
  }
}

final accessibilityProvider =
    NotifierProvider<AccessibilityNotifier, AccessibilitySettings>(AccessibilityNotifier.new);

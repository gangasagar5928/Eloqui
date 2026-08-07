import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class AppSettings {
  final bool darkMode;
  final bool hasOnboarded;
  final TTSAccent ttsAccent;
  final double speechSpeed;
  final String aiModel; // 'qwen1.5b' | 'qwen3b' | 'gemma4b_q4' | 'gemma4b_q8'
  final bool modelsDownloaded;
  final String userLevel; // A1..C2
  final String userGoal;
  final int aiResponseLength; // 0=short 1=medium 2=long

  const AppSettings({
    this.darkMode = true,
    this.hasOnboarded = false,
    this.ttsAccent = TTSAccent.indian,
    this.speechSpeed = 1.0,
    this.aiModel = '',  // empty = no model downloaded/active yet
    this.modelsDownloaded = false,
    this.userLevel = 'B1',
    this.userGoal = 'daily',
    this.aiResponseLength = 1,
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? hasOnboarded,
    TTSAccent? ttsAccent,
    double? speechSpeed,
    String? aiModel,
    bool? modelsDownloaded,
    String? userLevel,
    String? userGoal,
    int? aiResponseLength,
  }) =>
      AppSettings(
        darkMode: darkMode ?? this.darkMode,
        hasOnboarded: hasOnboarded ?? this.hasOnboarded,
        ttsAccent: ttsAccent ?? this.ttsAccent,
        speechSpeed: speechSpeed ?? this.speechSpeed,
        aiModel: aiModel ?? this.aiModel,
        modelsDownloaded: modelsDownloaded ?? this.modelsDownloaded,
        userLevel: userLevel ?? this.userLevel,
        userGoal: userGoal ?? this.userGoal,
        aiResponseLength: aiResponseLength ?? this.aiResponseLength,
      );
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

class SettingsNotifier extends Notifier<AppSettings> {
  late final SharedPreferences _prefs;

  @override
  AppSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      darkMode: _prefs.getBool('darkMode') ?? true,
      hasOnboarded: _prefs.getBool('hasOnboarded') ?? false,
      ttsAccent: TTSAccent.values[_prefs.getInt('ttsAccent') ?? 0],
      speechSpeed: _prefs.getDouble('speechSpeed') ?? 1.0,
      aiModel: _normalisePack(_prefs.getString('aiModel') ?? ''),
      modelsDownloaded: _prefs.getBool('modelsDownloaded') ?? false,
      userLevel: _prefs.getString('userLevel') ?? 'B1',
      userGoal: _prefs.getString('userGoal') ?? 'daily',
      aiResponseLength: _prefs.getInt('aiResponseLength') ?? 1,
    );
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('darkMode', value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setHasOnboarded(bool value) async {
    await _prefs.setBool('hasOnboarded', value);
    state = state.copyWith(hasOnboarded: value);
  }

  Future<void> setTtsAccent(TTSAccent accent) async {
    await _prefs.setInt('ttsAccent', accent.index);
    state = state.copyWith(ttsAccent: accent);
  }

  Future<void> setAiModel(String model) async {
    await _prefs.setString('aiModel', model);
    state = state.copyWith(aiModel: model);
  }

  Future<void> setModelsDownloaded(bool value) async {
    await _prefs.setBool('modelsDownloaded', value);
    state = state.copyWith(modelsDownloaded: value);
  }

  Future<void> setUserLevel(String level) async {
    await _prefs.setString('userLevel', level);
    state = state.copyWith(userLevel: level);
  }

  Future<void> setUserGoal(String goal) async {
    await _prefs.setString('userGoal', goal);
    state = state.copyWith(userGoal: goal);
  }

  Future<void> setSpeechSpeed(double speed) async {
    await _prefs.setDouble('speechSpeed', speed);
    state = state.copyWith(speechSpeed: speed);
  }

  Future<void> setAiResponseLength(int length) async {
    await _prefs.setInt('aiResponseLength', length);
    state = state.copyWith(aiResponseLength: length);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Ensure pack ID always has the '_pack' suffix expected by ModelManagerService
String _normalisePack(String id) {
  if (id.isEmpty) return '';
  if (!id.endsWith('_pack')) return '${id}_pack';
  return id;
}

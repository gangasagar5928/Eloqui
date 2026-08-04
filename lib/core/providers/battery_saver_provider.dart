import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PowerProfile {
  eco('Eco', 'Lower CPU usage, smaller context window, max battery saving'),
  balanced('Balanced', 'Default optimal balance of responsiveness and battery'),
  performance('Performance', 'Maximum model quality, highest context size');

  final String label;
  final String description;
  const PowerProfile(this.label, this.description);
}

class BatterySaverNotifier extends Notifier<PowerProfile> {
  @override
  PowerProfile build() {
    _load();
    return PowerProfile.balanced;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('power_profile') ?? 1;
    state = PowerProfile.values[index];
  }

  Future<void> setPowerProfile(PowerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('power_profile', profile.index);
    state = profile;
  }
}

final batterySaverProvider =
    NotifierProvider<BatterySaverNotifier, PowerProfile>(BatterySaverNotifier.new);

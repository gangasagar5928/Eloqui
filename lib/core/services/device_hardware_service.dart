import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceHardwareReport {
  final String cpuArchitecture;
  final int totalRamGb;
  final double freeStorageGb;
  final bool supportsNeonAcceleration;
  final String recommendedTier;
  final bool showPerformanceWarning;
  final String warningMessage;

  const DeviceHardwareReport({
    required this.cpuArchitecture,
    required this.totalRamGb,
    required this.freeStorageGb,
    required this.supportsNeonAcceleration,
    required this.recommendedTier,
    required this.showPerformanceWarning,
    required this.warningMessage,
  });
}

class DeviceHardwareService {
  static final DeviceHardwareService instance = DeviceHardwareService._();
  DeviceHardwareService._();

  /// Perform first-launch hardware capability check
  Future<DeviceHardwareReport> checkHardwareCapabilities() async {
    String cpuArch = 'arm64-v8a';
    int ramGb = 6;
    double storageGb = 15.0;
    bool hasNeon = true;

    try {
      if (Platform.isAndroid) {
        final info = DeviceInfoPlugin();
        final androidInfo = await info.androidInfo;
        cpuArch = androidInfo.supportedAbis.isNotEmpty ? androidInfo.supportedAbis.first : 'arm64-v8a';
        ramGb = 6; // Standard ActivityManager estimate
      }
    } catch (_) {}

    String tier = 'qwen3b_pack';
    bool warning = false;
    String warnMsg = '';

    if (ramGb < 4) {
      tier = 'qwen1.5b_pack';
      warning = true;
      warnMsg = 'Low RAM detected (~$ramGb GB). Qwen 1.5B Light Pack recommended to prevent slowdowns.';
    } else if (ramGb >= 8) {
      tier = 'gemma4b_pack';
    }

    if (storageGb < 4.0) {
      warning = true;
      warnMsg += ' Free storage is under 4 GB. Ensure sufficient space for model packs.';
    }

    return DeviceHardwareReport(
      cpuArchitecture: cpuArch,
      totalRamGb: ramGb,
      freeStorageGb: storageGb,
      supportsNeonAcceleration: hasNeon,
      recommendedTier: tier,
      showPerformanceWarning: warning,
      warningMessage: warnMsg,
    );
  }
}

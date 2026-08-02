import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/battery_saver_provider.dart';
import '../../core/services/tts_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final powerProfile = ref.watch(batterySaverProvider);
    final powerNotifier = ref.read(batterySaverProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Section('Appearance & Battery'),
          _ToggleTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: settings.darkMode,
            onChanged: notifier.setDarkMode,
          ),
          _DropdownTile<PowerProfile>(
            icon: Icons.battery_charging_full,
            title: 'Power & Performance Profile',
            value: powerProfile,
            items: PowerProfile.values,
            itemLabel: (p) => p.label,
            onChanged: powerNotifier.setPowerProfile,
          ),
          const SizedBox(height: 16),
          const _Section('AI Models & Sandbox'),
          _ActionTile(
            icon: Icons.inventory_2_outlined,
            title: 'Model Manager & Updates',
            subtitle: 'Download, switch models, and auto-updates',
            onTap: () => context.go('/settings/model-manager'),
          ),
          _ActionTile(
            icon: Icons.speed_outlined,
            title: 'AI Benchmark & Diagnostics',
            subtitle: 'Measure tokens/sec, TTFT latency & RAM',
            onTap: () => context.go('/settings/benchmark'),
          ),
          const SizedBox(height: 16),
          const _Section('Speech & Accents'),
          _DropdownTile<TTSAccent>(
            icon: Icons.record_voice_over_outlined,
            title: 'AI Voice Accent',
            value: settings.ttsAccent,
            items: TTSAccent.values,
            itemLabel: (a) => switch (a) {
              TTSAccent.indian => '🇮🇳 Indian English',
              TTSAccent.british => '🇬🇧 British English',
              TTSAccent.american => '🇺🇸 American English',
              TTSAccent.australian => '🇦🇺 Australian English',
            },
            onChanged: notifier.setTtsAccent,
          ),
          _SliderTile(
            icon: Icons.speed,
            title: 'Speech Speed',
            value: settings.speechSpeed,
            min: 0.5,
            max: 2.0,
            label: '${settings.speechSpeed.toStringAsFixed(1)}x',
            onChanged: notifier.setSpeechSpeed,
          ),
          const SizedBox(height: 16),
          const _Section('Privacy & System Audit'),
          _ActionTile(
            icon: Icons.shield_outlined,
            title: 'Privacy & Local Data Dashboard',
            subtitle: 'Audit storage, models & zero-telemetry status',
            onTap: () => context.go('/settings/privacy-dashboard'),
          ),
          _ActionTile(
            icon: Icons.backup_outlined,
            title: 'Backup, Restore & Crash Logs',
            subtitle: 'Export data and inspect local crash logs',
            onTap: () => context.go('/settings/backup'),
          ),
          const SizedBox(height: 16),
          const _Section('Developer & Validation'),
          _ActionTile(
            icon: Icons.code_outlined,
            title: 'Developer Diagnostics & Validation',
            subtitle: 'Inspect Flutter version, NDK libs & score calibration',
            onTap: () => context.go('/settings/developer-diagnostics'),
          ),
          const SizedBox(height: 16),
          const _Section('About'),
          const _InfoTile(
            icon: Icons.info_outline,
            title: 'Eloqui',
            subtitle: 'Version 1.0.0 • 100% Offline • Privacy First',
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Function(bool) onChanged;
  const _ToggleTile({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T) onChanged;

  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: AppColors.darkCard,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i)))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final String label;
  final Function(double) onChanged;

  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
              Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).toInt(),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.darkBorder,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

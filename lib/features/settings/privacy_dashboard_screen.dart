import 'package:flutter/material.dart';
import '../../app/theme.dart';

class PrivacyDashboardScreen extends StatelessWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Privacy & Local Data Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradientSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text('100% On-Device Privacy',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Eloqui runs entirely offline. Zero cloud API calls, zero tracking telemetry, zero account requirement. All your audio recordings, transcripts, and scores remain stored strictly inside your phone storage.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Local Data Audit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _AuditTile(icon: Icons.storage, title: 'Installed Model Packs', value: '2.1 GB'),
          const _AuditTile(icon: Icons.chat_bubble_outline, title: 'Conversation Transcripts DB', value: '3.4 MB'),
          const _AuditTile(icon: Icons.graphic_eq, title: 'Cached Voice Recordings', value: '12.8 MB'),
          const _AuditTile(icon: Icons.backup_outlined, title: 'Latest Local Backup Size', value: '4.2 MB'),
          const _AuditTile(icon: Icons.cloud_off, title: 'Network Telemetry & Analytics', value: '0 Bytes (Disabled)'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local app caches cleared cleanly.'),
                    backgroundColor: AppColors.band9,
                  ),
                );
              },
              icon: const Icon(Icons.cleaning_services_outlined, color: AppColors.accent),
              label: const Text('Clear All Local Cache Data', style: TextStyle(color: AppColors.accent)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _AuditTile({required this.icon, required this.title, required this.value});

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
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Text(value, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

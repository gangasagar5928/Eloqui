import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/download_manager.dart';
import '../../app/theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DownloadStatus? _status;
  StreamSubscription<DownloadStatus>? _sub;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _status = DownloadManager.instance.currentStatus;
    _sub = DownloadManager.instance.statusStream.listen((s) {
      if (mounted) {
        setState(() {
          _status = s;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDownloading = _status != null && !_status!.isCompleted && !_status!.isFailed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (DownloadManager.instance.isDownloading) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.darkCard,
              title: const Text('Exit Eloqui?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'An AI Model download is running in the background. Exiting will pause the download (resumable when you reopen).',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep Downloading'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Exit App'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
          return;
        }

        // Standard double-tap back button safeguard
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit Eloqui'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            if (isDownloading)
              GestureDetector(
                onTap: () => context.go('/model-download'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: AppColors.primary,
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '⚡ ${_status!.packName}: ${_status!.statusMessage} (${(_status!.progress * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text('View →', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),
        bottomNavigationBar: _BottomNav(),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int index = 0;
    if (location.startsWith('/home')) index = 0;
    else if (location.startsWith('/conversation')) index = 1;
    else if (location.startsWith('/ielts')) index = 2;
    else if (location.startsWith('/practice')) index = 3;
    else if (location.startsWith('/analytics')) index = 4;
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/home');
          case 1: context.go('/conversation');
          case 2: context.go('/ielts');
          case 3: context.go('/practice');
          case 4: context.go('/analytics');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Speak'),
        NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'IELTS'),
        NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Practice'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Progress'),
      ],
    );
  }
}

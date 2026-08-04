import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/model_download_screen.dart';
import '../features/home/home_screen.dart';
import '../features/conversation/conversation_screen.dart';
import '../features/ielts/ielts_screen.dart';
import '../features/ielts/part1_screen.dart';
import '../features/ielts/part2_screen.dart';
import '../features/ielts/part3_screen.dart';
import '../features/ielts/ielts_result_screen.dart';
import '../core/services/ielts_evaluator.dart';
import '../features/toefl/toefl_screen.dart';
import '../features/pte/pte_screen.dart';
import '../features/det/det_screen.dart';
import '../features/pronunciation/pronunciation_screen.dart';
import '../features/grammar/grammar_screen.dart';
import '../features/vocabulary/vocabulary_screen.dart';
import '../features/vocabulary/word_detail_screen.dart';
import '../features/daily/daily_screen.dart';
import '../features/daily/adaptive_plan_screen.dart';
import '../features/daily/learning_calendar_screen.dart';
import '../features/practice/practice_hub.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/downloadable_lessons_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/model_manager_screen.dart';
import '../features/settings/benchmark_screen.dart';
import '../features/settings/backup_screen.dart';
import '../features/settings/privacy_dashboard_screen.dart';
import '../features/settings/developer_diagnostics_screen.dart';
import '../features/shell/main_shell.dart';
import '../core/providers/settings_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final hasOnboarded = ref.watch(settingsProvider.select((s) => s.hasOnboarded));
  return GoRouter(
    initialLocation: hasOnboarded ? '/home' : '/onboarding',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/model-download',
        builder: (context, state) => const ModelDownloadScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/conversation',
            builder: (context, state) => const ConversationScreen(),
          ),
          GoRoute(
            path: '/ielts',
            builder: (context, state) => const IeltsScreen(),
            routes: [
              GoRoute(
                path: 'part1',
                builder: (context, state) => const Part1Screen(),
              ),
              GoRoute(
                path: 'part2',
                builder: (context, state) => const Part2Screen(),
              ),
              GoRoute(
                path: 'part3',
                builder: (context, state) => const Part3Screen(),
              ),
              GoRoute(
                path: 'result',
                builder: (context, state) => IeltsResultScreen(
                  customAnalysis: state.extra as SpeakingAnalysis?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/toefl',
            builder: (context, state) => const ToeflScreen(),
          ),
          GoRoute(
            path: '/pte',
            builder: (context, state) => const PteScreen(),
          ),
          GoRoute(
            path: '/det',
            builder: (context, state) => const DetScreen(),
          ),
          GoRoute(
            path: '/pronunciation',
            builder: (context, state) => const PronunciationScreen(),
          ),
          GoRoute(
            path: '/grammar',
            builder: (context, state) => const GrammarScreen(),
          ),
          GoRoute(
            path: '/vocabulary',
            builder: (context, state) => const VocabularyScreen(),
            routes: [
              GoRoute(
                path: ':word',
                builder: (context, state) => WordDetailScreen(
                  word: state.pathParameters['word']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/daily',
            builder: (context, state) => const DailyScreen(),
            routes: [
              GoRoute(
                path: 'adaptive-plan',
                builder: (context, state) => const AdaptivePlanScreen(),
              ),
              GoRoute(
                path: 'calendar',
                builder: (context, state) => const LearningCalendarScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) => const PracticeHub(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryScreen(),
            routes: [
              GoRoute(
                path: 'downloadable-lessons',
                builder: (context, state) => const DownloadableLessonsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'model-manager',
                builder: (context, state) => const ModelManagerScreen(),
              ),
              GoRoute(
                path: 'benchmark',
                builder: (context, state) => const BenchmarkScreen(),
              ),
              GoRoute(
                path: 'backup',
                builder: (context, state) => const BackupScreen(),
              ),
              GoRoute(
                path: 'privacy-dashboard',
                builder: (context, state) => const PrivacyDashboardScreen(),
              ),
              GoRoute(
                path: 'developer-diagnostics',
                builder: (context, state) => const DeveloperDiagnosticsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

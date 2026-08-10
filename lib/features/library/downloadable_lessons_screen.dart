import 'package:flutter/material.dart';
import '../../app/theme.dart';

class LessonPackItem {
  final String title;
  final String category;
  final String sizeStr;
  final String description;
  final bool isInstalled;
  final IconData icon;

  const LessonPackItem({
    required this.title,
    required this.category,
    required this.sizeStr,
    required this.description,
    this.isInstalled = false,
    required this.icon,
  });
}

class DownloadableLessonsScreen extends StatefulWidget {
  const DownloadableLessonsScreen({super.key});

  @override
  State<DownloadableLessonsScreen> createState() => _DownloadableLessonsScreenState();
}

class _DownloadableLessonsScreenState extends State<DownloadableLessonsScreen> {
  final knownPacks = const [
    LessonPackItem(
      title: 'Grammar Master Pack',
      category: 'Grammar Lessons',
      sizeStr: '45 MB',
      description: '120+ structured grammar rules with interactive quizzes.',
      isInstalled: true,
      icon: Icons.spellcheck,
    ),
    LessonPackItem(
      title: 'IPA Pronunciation Drills',
      category: 'Pronunciation',
      sizeStr: '65 MB',
      description: 'Phonetic mouth shape guides and native audio drills.',
      isInstalled: false,
      icon: Icons.record_voice_over_outlined,
    ),
    LessonPackItem(
      title: 'IELTS Band 9 Mock Pack',
      category: 'IELTS Preparation',
      sizeStr: '110 MB',
      description: '50+ real exam Cue Cards and high-scoring sample audio.',
      isInstalled: true,
      icon: Icons.school_outlined,
    ),
    LessonPackItem(
      title: 'Business & Negotiation English',
      category: 'Business English',
      sizeStr: '85 MB',
      description: 'Corporate vocabulary, meeting scripts, and email etiquette.',
      isInstalled: false,
      icon: Icons.business_center_outlined,
    ),
    LessonPackItem(
      title: 'Technical Interview Simulation',
      category: 'Career & Tech',
      sizeStr: '95 MB',
      description: 'Software engineering & data science interview Q&A packs.',
      isInstalled: false,
      icon: Icons.code,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Downloadable Offline Lessons')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: knownPacks.length,
        itemBuilder: (context, i) {
          final pack = knownPacks[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(pack.icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pack.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${pack.category} • ${pack.sizeStr}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(pack.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(pack.isInstalled ? 'Pack is ready!' : 'Downloading ${pack.title}...'),
                        backgroundColor: AppColors.band9,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pack.isInstalled ? AppColors.darkCardElevated : AppColors.primary,
                    foregroundColor: pack.isInstalled ? AppColors.secondary : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(pack.isInstalled ? 'Installed' : 'Download'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

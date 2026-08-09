import 'package:flutter/material.dart';
import '../../app/theme.dart';

class WordDetailScreen extends StatelessWidget {
  final String word;
  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: Text(word)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 12),
            const Text('Definition & Example usage details', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Learning Library')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('Offline Content Library', style: TextStyle(color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}

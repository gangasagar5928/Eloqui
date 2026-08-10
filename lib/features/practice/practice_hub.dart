import 'package:flutter/material.dart';
import '../../app/theme.dart';

class PracticeHub extends StatelessWidget {
  const PracticeHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Practice Hub')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('Interactive Practice Hub', style: TextStyle(color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}

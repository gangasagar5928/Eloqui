import 'package:flutter/material.dart';
import '../../app/theme.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Daily Goal & Learning')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('Daily Practice & Goals Hub', style: TextStyle(color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}

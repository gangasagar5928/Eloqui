import 'package:flutter/material.dart';
import '../../app/theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('PDF Progress Reports')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('PDF Reports & Export Hub', style: TextStyle(color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}

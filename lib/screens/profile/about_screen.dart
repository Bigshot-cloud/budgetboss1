import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About BudgetBoss')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const FaIcon(FontAwesomeIcons.crown, size: 80, color: AppColors.gold),
            const SizedBox(height: 20),
            const Text('BudgetBoss', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Version 1.0.0', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'BudgetBoss is your ultimate financial companion, helping you track spending, save more, and build a better future.',
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            const Text('Made with ❤️ for better life', style: TextStyle(fontSize: 12, color: AppColors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

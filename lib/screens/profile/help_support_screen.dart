import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildItem(Icons.help_outline, 'FAQs'),
          _buildItem(Icons.contact_support_outlined, 'Contact Support'),
          _buildItem(Icons.feedback_outlined, 'Send Feedback'),
          _buildItem(Icons.bug_report_outlined, 'Report a Bug'),
          _buildItem(Icons.privacy_tip_outlined, 'Privacy Policy'),
          _buildItem(Icons.description_outlined, 'Terms & Conditions'),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
    );
  }
}

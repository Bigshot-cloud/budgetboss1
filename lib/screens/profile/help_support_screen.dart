import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildItem(context, Icons.help_outline, 'FAQs', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen()))),
          _buildItem(context, Icons.contact_support_outlined, 'Contact Support', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactSupportScreen()))),
          _buildItem(context, Icons.feedback_outlined, 'Send Feedback', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()))),
          _buildItem(context, Icons.bug_report_outlined, 'Report a Bug', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BugReportScreen()))),
          _buildItem(context, Icons.privacy_tip_outlined, 'Privacy Policy', () => _launchUrl('https://budgetboss.app/privacy')),
          _buildItem(context, Icons.description_outlined, 'Terms & Conditions', () => _launchUrl('https://budgetboss.app/terms')),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFaqItem(context, 'How do I add a transaction?', 'Tap the "+" button in the middle of the bottom navigation bar.'),
          _buildFaqItem(context, 'How do I change my budget?', 'Go to the "Budget" tab and tap on "This Month" to edit your monthly limit.'),
          _buildFaqItem(context, 'Is my data secure?', 'Yes, BudgetBoss uses bank-grade encryption and Firebase security to protect your data.'),
          _buildFaqItem(context, 'Can I export my records?', 'Yes, go to Profile > Export Records to generate a PDF report.'),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      title: Text(question, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Need help? Send us a message and we\'ll get back to you as soon as possible.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 30),
            CustomTextField(controller: TextEditingController(), hintText: 'Subject', prefixIcon: Icons.subject),
            const SizedBox(height: 15),
            Expanded(child: CustomTextField(controller: TextEditingController(), hintText: 'Message', prefixIcon: Icons.message)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Send Message')),
          ],
        ),
      ),
    );
  }
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('We value your feedback to help us improve BudgetBoss!', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmoji(Icons.sentiment_very_dissatisfied),
                _buildEmoji(Icons.sentiment_dissatisfied),
                _buildEmoji(Icons.sentiment_neutral),
                _buildEmoji(Icons.sentiment_satisfied),
                _buildEmoji(Icons.sentiment_very_satisfied),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(child: CustomTextField(controller: TextEditingController(), hintText: 'Your thoughts...', prefixIcon: Icons.edit)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Submit Feedback')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmoji(IconData icon) {
    return IconButton(onPressed: () {}, icon: Icon(icon, color: AppColors.gold, size: 35));
  }
}

class BugReportScreen extends StatelessWidget {
  const BugReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Bug')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Found something wrong? Let us know the details.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 30),
            CustomTextField(controller: TextEditingController(), hintText: 'What happened?', prefixIcon: Icons.bug_report),
            const SizedBox(height: 15),
            Expanded(child: CustomTextField(controller: TextEditingController(), hintText: 'Steps to reproduce...', prefixIcon: Icons.list)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Submit Report')),
          ],
        ),
      ),
    );
  }
}

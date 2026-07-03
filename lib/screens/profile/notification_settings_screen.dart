import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _budgetReminders = true;
  bool _billReminders = true;
  bool _savingsReminders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildToggle('Budget Reminders', 'Notify me when I exceed limits', _budgetReminders, (val) => setState(() => _budgetReminders = val)),
          _buildToggle('Bill Reminders', 'Alert me about upcoming bills', _billReminders, (val) => setState(() => _billReminders = val)),
          _buildToggle('Savings Reminders', 'Daily encouragement to save', _savingsReminders, (val) => setState(() => _savingsReminders = val)),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.gold),
    );
  }
}

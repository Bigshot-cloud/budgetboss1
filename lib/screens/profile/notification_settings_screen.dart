import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _budgetReminders = true;
  bool _billReminders = true;
  bool _savingsReminders = false;
  bool _goalAlerts = true;
  bool _securityAlerts = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.preferences['notifications'] != null) {
      final notify = Map<String, bool>.from(user.preferences['notifications']);
      _budgetReminders = notify['budget'] ?? true;
      _billReminders = notify['bill'] ?? true;
      _savingsReminders = notify['savings'] ?? false;
      _goalAlerts = notify['goal'] ?? true;
      _securityAlerts = notify['security'] ?? true;
    }
  }

  void _updateSettings() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      final updatedPrefs = Map<String, dynamic>.from(user.preferences);
      updatedPrefs['notifications'] = {
        'budget': _budgetReminders,
        'bill': _billReminders,
        'savings': _savingsReminders,
        'goal': _goalAlerts,
        'security': _securityAlerts,
      };
      await authProvider.updateUser(user.copyWith(preferences: updatedPrefs));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildToggle('Budget Reminders', 'Notify me when I exceed limits', _budgetReminders, (val) {
            setState(() => _budgetReminders = val);
            _updateSettings();
          }),
          _buildToggle('Bill Reminders', 'Alert me about upcoming bills', _billReminders, (val) {
            setState(() => _billReminders = val);
            _updateSettings();
          }),
          _buildToggle('Savings Reminders', 'Daily encouragement to save', _savingsReminders, (val) {
            setState(() => _savingsReminders = val);
            _updateSettings();
          }),
          _buildToggle('Goal Achievements', 'Alert me when I reach a goal', _goalAlerts, (val) {
            setState(() => _goalAlerts = val);
            _updateSettings();
          }),
          _buildToggle('Security Alerts', 'Notify me about account security', _securityAlerts, (val) {
            setState(() => _securityAlerts = val);
            _updateSettings();
          }),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      color: AppColors.navy,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.gold,
      ),
    );
  }
}

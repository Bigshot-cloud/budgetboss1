import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _selectedCurrency = 'GH₵';
  String _selectedTheme = 'Dark';
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _selectedCurrency = user.preferences['currency'] ?? 'GH₵';
      _selectedTheme = _formatThemeMode(context.read<ThemeProvider>().themeMode);
      _selectedLanguage = user.preferences['language'] == 'en' ? 'English' : 'French';
    }
  }

  String _formatThemeMode(ThemeMode mode) {
    if (mode == ThemeMode.light) return 'Light';
    if (mode == ThemeMode.dark) return 'Dark';
    return 'System';
  }

  void _updatePreference(String key, dynamic value) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      final updatedPreferences = Map<String, dynamic>.from(user.preferences);
      updatedPreferences[key] = value;
      final updatedUser = user.copyWith(preferences: updatedPreferences);
      await authProvider.updateUser(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPreferenceItem(
            'Currency',
            _selectedCurrency,
            ['GH₵', 'USD (\$)', 'EUR (€)', 'GBP (£)'],
            (value) {
              setState(() => _selectedCurrency = value!);
              _updatePreference('currency', value);
            },
          ),
          _buildPreferenceItem(
            'Theme',
            _selectedTheme,
            ['Light', 'Dark', 'System'],
            (value) {
              if (value != null) {
                setState(() => _selectedTheme = value);
                context.read<ThemeProvider>().setTheme(value);
                _updatePreference('theme', value.toLowerCase());
              }
            },
          ),
          _buildPreferenceItem(
            'Language',
            _selectedLanguage,
            ['English', 'French', 'Spanish', 'Akan'],
            (value) {
              setState(() => _selectedLanguage = value!);
              _updatePreference('language', value == 'English' ? 'en' : 'fr');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(String title, String currentVal, List<String> options, ValueChanged<String?> onChanged) {
    return Card(
      color: AppColors.navy,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        subtitle: Text(currentVal, style: const TextStyle(color: AppColors.gold)),
        trailing: Theme(
          data: Theme.of(context).copyWith(canvasColor: AppColors.navy),
          child: DropdownButton<String>(
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
            onChanged: onChanged,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: AppColors.white)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

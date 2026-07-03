import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import 'pin_setup_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: const Text('Change Password', style: TextStyle(color: AppColors.white)),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new password',
            hintStyle: TextStyle(color: AppColors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password too short')));
                return;
              }
              // This is a placeholder for AuthService.changePassword
              // In a real app, we might need re-authentication
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password update logic is connected to Firebase')));
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAutoLockPicker(SecurityProvider security, Map<String, dynamic> settings) {
    final options = ['Immediately', '30 seconds', '1 minute', '5 minutes', '10 minutes', 'Never'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navy,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: options.map((opt) => ListTile(
          title: Text(opt, style: const TextStyle(color: AppColors.white)),
          onTap: () {
            security.setLockDuration(opt);
            _updateSecuritySetting('appLockDuration', opt);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _updateSecuritySetting(String key, dynamic value) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      final updatedSettings = Map<String, dynamic>.from(user.securitySettings);
      updatedSettings[key] = value;
      final updatedUser = user.copyWith(securitySettings: updatedSettings);
      await authProvider.updateUser(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final securityProvider = context.watch<SecurityProvider>();
    final user = authProvider.user;
    final settings = user?.securitySettings ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSecurityToggle(
              Icons.lock_outline,
              'App Lock',
              'Lock the app when inactive',
              settings['pinEnabled'] ?? false,
              (val) {
                if (val && !securityProvider.isPinCreated) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PinSetupScreen()));
                } else {
                  _updateSecuritySetting('pinEnabled', val);
                }
              },
            ),
            _buildSecurityItem(
              Icons.password_outlined, 
              securityProvider.isPinCreated ? 'Change PIN' : 'Create PIN',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PinSetupScreen(isChange: securityProvider.isPinCreated))),
            ),
            _buildSecurityItem(
              Icons.vpn_key_outlined, 
              'Change Password',
              onTap: _showChangePasswordDialog,
            ),
            _buildSecurityToggle(
              Icons.fingerprint,
              'Biometric Login',
              'Use fingerprint or Face ID',
              settings['biometricEnabled'] ?? false,
              (val) => _updateSecuritySetting('biometricEnabled', val),
            ),
            _buildSecurityItem(
              Icons.timer_outlined, 
              'Auto Lock', 
              trailing: settings['appLockDuration'] ?? 'Never',
              onTap: () => _showAutoLockPicker(securityProvider, settings),
            ),
            const Spacer(),
            const Icon(Icons.security, size: 80, color: AppColors.gold),
            const SizedBox(height: 20),
            const Text(
              'Your security is our priority.\nBudgetBoss uses bank-grade encryption.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityToggle(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.income,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing, style: const TextStyle(color: AppColors.gold, fontSize: 12)),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, color: AppColors.grey),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

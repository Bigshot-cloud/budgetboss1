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
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Change Password', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
              try {
                await context.read<AuthProvider>().updateUserPassword(_passwordController.text);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: options.map((opt) => ListTile(
          title: Text(opt, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSecurityToggle(
              context,
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
              context,
              Icons.password_outlined, 
              securityProvider.isPinCreated ? 'Change PIN' : 'Create PIN',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PinSetupScreen(isChange: securityProvider.isPinCreated))),
            ),
            if (securityProvider.isPinCreated)
              _buildSecurityItem(
                context,
                Icons.delete_outline, 
                'Remove PIN',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: colorScheme.surface,
                      title: Text('Remove PIN?', style: TextStyle(color: colorScheme.onSurface)),
                      content: const Text('This will disable app lock.', style: TextStyle(color: Colors.grey)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: AppColors.expense))),
                      ],
                    )
                  );
                  if (confirm == true) {
                    await securityProvider.removePin();
                    _updateSecuritySetting('pinEnabled', false);
                  }
                },
              ),
            _buildSecurityItem(
              context,
              Icons.vpn_key_outlined, 
              'Change Password',
              onTap: _showChangePasswordDialog,
            ),
            _buildSecurityToggle(
              context,
              Icons.fingerprint,
              'Biometric Login',
              'Use fingerprint or Face ID',
              settings['biometricEnabled'] ?? false,
              (val) async {
                if (val) {
                  final success = await securityProvider.authenticateBiometrics();
                  if (success) {
                    _updateSecuritySetting('biometricEnabled', true);
                  }
                } else {
                  _updateSecuritySetting('biometricEnabled', false);
                }
              },
            ),
            _buildSecurityItem(
              context,
              Icons.timer_outlined, 
              'Auto Lock', 
              trailing: settings['appLockDuration'] ?? 'Never',
              onTap: () => _showAutoLockPicker(securityProvider, settings),
            ),
            const Spacer(),
            Icon(Icons.security, size: 80, color: AppColors.gold),
            const SizedBox(height: 20),
            Text(
              'Your security is our priority.\nBudgetBoss uses bank-grade encryption.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityToggle(BuildContext context, IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
        activeThumbColor: AppColors.gold,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSecurityItem(BuildContext context, IconData icon, String title, {String? trailing, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing, style: const TextStyle(color: AppColors.gold, fontSize: 12)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

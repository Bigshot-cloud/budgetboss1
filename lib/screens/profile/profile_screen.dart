import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/services/export_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'preferences_screen.dart';
import 'security_screen.dart';
import 'notification_settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _exportPdf(BuildContext context) async {
    final transactions = context.read<TransactionProvider>().transactions;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions to export')));
      return;
    }
    await ExportService().exportTransactionsToPdf(transactions);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: user?.profilePictureUrl != null
                  ? NetworkImage(user!.profilePictureUrl!)
                  : const NetworkImage('https://i.pravatar.cc/300?img=12'),
            ),
            const SizedBox(height: 15),
            Text(
              user?.fullName ?? 'User Name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              user?.email ?? 'email@example.com',
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold),
              ),
              child: const Text(
                'Premium',
                style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            _buildProfileItem(Icons.person_outline, 'Personal Information', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildProfileItem(Icons.settings_outlined, 'Preferences', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PreferencesScreen()));
            }),
            _buildProfileItem(Icons.security_outlined, 'Security', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen()));
            }),
            _buildProfileItem(Icons.notifications_none_outlined, 'Notification Settings', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
            }),
            _buildProfileItem(Icons.file_download_outlined, 'Export Records', onTap: () => _exportPdf(context)),
            _buildProfileItem(Icons.help_outline, 'Help & Support', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            }),
            _buildProfileItem(Icons.info_outline, 'About BudgetBoss', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            }),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.expense),
                  SizedBox(width: 10),
                  Text('Log Out', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

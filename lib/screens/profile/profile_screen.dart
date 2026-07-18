import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/services/export_service.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Use ValueKey to force image refresh when URL changes
            CircleAvatar(
              key: ValueKey(user?.profilePictureUrl),
              radius: 50,
              backgroundColor: colorScheme.surfaceContainer,
              backgroundImage: user?.profilePictureUrl != null
                  ? NetworkImage(user!.profilePictureUrl!)
                  : null,
              child: user?.profilePictureUrl == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.gold)
                  : null,
            ),
            const SizedBox(height: 15),
            Text(
              user?.fullName ?? 'User Name',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 5),
            Text(
              user?.email ?? 'email@example.com',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
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
            _buildProfileItem(context, Icons.person_outline, 'Personal Information', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildProfileItem(context, Icons.settings_outlined, 'Preferences', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PreferencesScreen()));
            }),
            _buildProfileItem(context, Icons.security_outlined, 'Security', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen()));
            }),
            _buildProfileItem(context, Icons.notifications_none_outlined, 'Notification Settings', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
            }),
            _buildProfileItem(context, Icons.file_download_outlined, 'Export Records', onTap: () => _exportPdf(context)),
            _buildProfileItem(context, Icons.help_outline, 'Help & Support', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            }),
            _buildProfileItem(context, Icons.info_outline, 'About BudgetBoss', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            }),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 55,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  // No need to navigate manually, main.dart's AuthenticationWrapper handles it
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense.withValues(alpha: 0.1),
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.expense, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

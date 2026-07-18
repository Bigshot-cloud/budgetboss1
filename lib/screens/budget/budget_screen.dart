import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  void _showEditBudgetDialog(BuildContext context, UserModel user) {
    final controller = TextEditingController(text: user.monthlyBudget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text('Edit Monthly Budget', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            hintText: 'Enter amount',
            hintStyle: TextStyle(color: AppColors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newBudget = double.tryParse(controller.text) ?? user.monthlyBudget;
              await context.read<AuthProvider>().updateUser(user.copyWith(monthlyBudget: newBudget));
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    
    final totalSpent = txProvider.monthlyExpense;
    final double budgetLimit = user?.monthlyBudget ?? 8000.0; 
    final double remaining = budgetLimit - totalSpent;
    final double percentUsed = budgetLimit > 0 ? (totalSpent / budgetLimit * 100).clamp(0, 100) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Overview'),
        actions: [
          IconButton(
            onPressed: () async {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            }, 
            icon: const Icon(Icons.calendar_today_outlined, size: 20)
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => user != null ? _showEditBudgetDialog(context, user) : null,
              child: _buildMonthSelector(context),
            ),
            const SizedBox(height: 30),
            _buildCircularProgress(context, percentUsed),
            const SizedBox(height: 40),
            _buildBudgetSummary(context, budgetLimit, totalSpent, remaining),
            const SizedBox(height: 30),
            _buildEncouragementCard(context, percentUsed),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('This Month', style: TextStyle(color: colorScheme.onSurface)),
          Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(BuildContext context, double percent) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  color: percent > 90 ? AppColors.expense : AppColors.gold,
                  value: percent,
                  showTitle: false,
                  radius: 20,
                ),
                PieChartSectionData(
                  color: colorScheme.surfaceContainer,
                  value: 100 - percent,
                  showTitle: false,
                  radius: 20,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'of budget used',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(BuildContext context, double limit, double spent, double remaining) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 20),
        _buildSummaryRow(context, 'Budget Limit', 'GH₵ ${limit.toStringAsFixed(0)}', colorScheme.onSurface),
        const SizedBox(height: 15),
        _buildSummaryRow(context, 'Total Spent', 'GH₵ ${spent.toStringAsFixed(0)}', AppColors.expense),
        const SizedBox(height: 15),
        _buildSummaryRow(context, 'Remaining', 'GH₵ ${remaining.toStringAsFixed(0)}', remaining < 0 ? AppColors.expense : AppColors.income),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String amount, Color amountColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEncouragementCard(BuildContext context, double percent) {
    final colorScheme = Theme.of(context).colorScheme;
    String title = "You're doing great! 🚀";
    String subtitle = "You're within your budget.";
    IconData icon = Icons.star;
    Color iconColor = AppColors.gold;

    if (percent >= 100) {
      title = "Budget Exceeded! ⚠️";
      subtitle = "Try to limit non-essential spending.";
      icon = Icons.warning_amber_rounded;
      iconColor = AppColors.expense;
    } else if (percent > 80) {
      title = "Almost there... 📊";
      subtitle = "You've used most of your budget.";
      icon = Icons.trending_up;
      iconColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

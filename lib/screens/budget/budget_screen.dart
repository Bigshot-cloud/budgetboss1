import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/transaction_provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final totalSpent = txProvider.totalExpense;
    // Hardcoded budget limit for now, ideally this would come from a user preference/database
    const double budgetLimit = 8000.0; 
    final double remaining = budgetLimit - totalSpent;
    final double percentUsed = (totalSpent / budgetLimit * 100).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Overview'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_today_outlined, size: 20)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 30),
            _buildCircularProgress(percentUsed),
            const SizedBox(height: 40),
            _buildBudgetSummary(budgetLimit, totalSpent, remaining),
            const SizedBox(height: 30),
            _buildEncouragementCard(percentUsed),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('This Month', style: TextStyle(color: AppColors.white)),
          Icon(Icons.keyboard_arrow_down, color: AppColors.white),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(double percent) {
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
                  color: AppColors.navy,
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
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const Text(
                'of budget used',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(double limit, double spent, double remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        const SizedBox(height: 20),
        _buildSummaryRow('Budget Limit', 'GH₵ ${limit.toStringAsFixed(0)}', AppColors.white),
        const SizedBox(height: 15),
        _buildSummaryRow('Total Spent', 'GH₵ ${spent.toStringAsFixed(0)}', AppColors.expense),
        const SizedBox(height: 15),
        _buildSummaryRow('Remaining', 'GH₵ ${remaining.toStringAsFixed(0)}', remaining < 0 ? AppColors.expense : AppColors.income),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String amount, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.grey)),
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

  Widget _buildEncouragementCard(double percent) {
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
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.darkNavy,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

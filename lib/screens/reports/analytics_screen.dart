import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Group transactions by category for expenses only
    final expenseMap = <String, double>{};
    double totalExpense = 0;
    
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        expenseMap[tx.category] = (expenseMap[tx.category] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }

    final sortedCategories = expenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      key: const ValueKey('Analytics'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPieChart(context, sortedCategories, totalExpense),
            const SizedBox(height: 40),
            _buildCategoryBreakdown(context, sortedCategories, totalExpense),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, List<MapEntry<String, double>> categories, double total) {
    final colors = [AppColors.blueAccent, AppColors.gold, Colors.purple, Colors.teal, Colors.grey];
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 5,
              centerSpaceRadius: 60,
              sections: categories.isEmpty 
                ? [PieChartSectionData(color: colorScheme.surfaceContainer, value: 1, radius: 25, showTitle: false)]
                : List.generate(categories.length, (index) {
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: categories[index].value,
                      radius: 25,
                      showTitle: false,
                    );
                  }),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GH₵ ${total.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              Text(
                'Total Spent',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, List<MapEntry<String, double>> categories, double total) {
    final colorScheme = Theme.of(context).colorScheme;
    if (categories.isEmpty) {
      return Center(child: Text('No expense data to analyze', style: TextStyle(color: colorScheme.onSurfaceVariant)));
    }

    final colors = [AppColors.blueAccent, AppColors.gold, Colors.purple, Colors.teal, Colors.grey];

    return Column(
      children: List.generate(categories.length, (index) {
        final entry = categories[index];
        final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
        return _buildCategoryItem(
          context,
          entry.key, 
          percentage, 
          entry.value, 
          colors[index % colors.length]
        );
      }),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, int percentage, double amount, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                ],
              ),
              Row(
                children: [
                  Text('$percentage%', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 15),
                  Text('GH₵ ${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: colorScheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDebtSummaryCard(),
            const SizedBox(height: 30),
            _buildDebtItem(
              'Credit Card',
              5000,
              10000,
              50,
              500,
              Icons.credit_card,
            ),
            const SizedBox(height: 20),
            _buildDebtItem(
              'Personal Loan',
              7500,
              15000,
              30,
              700,
              Icons.account_balance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Debt', style: TextStyle(color: AppColors.grey)),
              SizedBox(height: 10),
              Text(
                'GH₵ 12,500',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Paid Off', style: TextStyle(color: AppColors.grey)),
              SizedBox(height: 10),
              Text(
                '25%',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtItem(
    String title,
    double current,
    double total,
    int percentage,
    double minPayment,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(icon, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                'GH₵ $current',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(' / GH₵ $total', style: const TextStyle(color: AppColors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.darkNavy,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min. Payment: GH₵ $minPayment',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

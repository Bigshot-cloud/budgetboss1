import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildGoalCard(
            'Emergency Fund',
            3250,
            5000,
            'Dec 31, 2025',
            65,
            Icons.savings,
          ),
          const SizedBox(height: 20),
          _buildGoalCard(
            'New Laptop',
            1800,
            3000,
            'Aug 15, 2025',
            60,
            Icons.laptop,
          ),
          const SizedBox(height: 20),
          _buildGoalCard(
            'Vacation Trip',
            2100,
            4000,
            'Nov 10, 2025',
            52,
            Icons.flight,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    String title,
    double current,
    double target,
    String date,
    int percentage,
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
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: AppColors.blueAccent),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                'GH₵ $current',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                ' / GH₵ $target',
                style: const TextStyle(color: AppColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.income,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: $date',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.income),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

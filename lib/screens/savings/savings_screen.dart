import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/savings_provider.dart';
import '../../models/savings_model.dart';
import '../../widgets/custom_text_field.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final savedController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.navy,
          title: const Text('New Savings Goal', style: TextStyle(color: AppColors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: titleController, hintText: 'Goal Name', prefixIcon: Icons.star_border),
                const SizedBox(height: 15),
                CustomTextField(controller: targetController, hintText: 'Target Amount', prefixIcon: Icons.flag_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                CustomTextField(controller: savedController, hintText: 'Current Savings', prefixIcon: Icons.savings_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                ListTile(
                  title: const Text('Target Date', style: TextStyle(color: AppColors.grey)),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: const TextStyle(color: AppColors.white)),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && targetController.text.isNotEmpty) {
                  final newGoal = SavingsModel(
                    id: '',
                    title: titleController.text,
                    targetAmount: double.tryParse(targetController.text) ?? 0,
                    savedAmount: double.tryParse(savedController.text) ?? 0,
                    targetDate: selectedDate,
                  );
                  context.read<SavingsProvider>().addGoal(newGoal);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = context.watch<SavingsProvider>();
    final goals = savingsProvider.goals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(onPressed: () => _showAddGoalDialog(context), icon: const Icon(Icons.add)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSavingsSummary(savingsProvider.totalSaved, savingsProvider.totalTarget),
            const SizedBox(height: 30),
            if (goals.isEmpty)
              const Center(child: Text('No savings goals yet', style: TextStyle(color: AppColors.grey)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goals.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return _buildGoalItem(context, goal);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsSummary(double current, double target) {
    double progress = target > 0 ? current / target : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Saved', style: TextStyle(color: AppColors.grey)),
              Text(
                'GH₵ ${current.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.darkNavy,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.income),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, SavingsModel goal) {
    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<SavingsProvider>().deleteGoal(goal.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
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
                Text(goal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
                if (goal.isCompleted) const Icon(Icons.check_circle, color: AppColors.income),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target: GH₵ ${goal.targetAmount}', style: const TextStyle(color: AppColors.grey, fontSize: 14)),
                Text('${(goal.progress * 100).round()}%', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: AppColors.darkNavy,
              valueColor: AlwaysStoppedAnimation<Color>(goal.isCompleted ? AppColors.income : AppColors.gold),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal: ${DateFormat('MMM yyyy').format(goal.targetDate)}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amountController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.navy,
                        title: const Text('Add Funds', style: TextStyle(color: AppColors.white)),
                        content: CustomTextField(controller: amountController, hintText: 'Amount', prefixIcon: Icons.add, keyboardType: TextInputType.number),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              final add = double.tryParse(amountController.text) ?? 0;
                              final updated = SavingsModel(
                                id: goal.id,
                                title: goal.title,
                                targetAmount: goal.targetAmount,
                                savedAmount: goal.savedAmount + add,
                                targetDate: goal.targetDate,
                              );
                              context.read<SavingsProvider>().updateGoal(updated);
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueAccent,
                    minimumSize: const Size(80, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Add Funds', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

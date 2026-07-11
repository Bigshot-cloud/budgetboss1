import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/savings_provider.dart';
import '../../models/savings_model.dart';
import '../../widgets/custom_text_field.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  void _showGoalDialog(BuildContext context, {SavingsModel? goal}) {
    final isEditing = goal != null;
    final titleController = TextEditingController(text: goal?.title);
    final targetController = TextEditingController(text: goal?.targetAmount.toString());
    final savedController = TextEditingController(text: goal?.savedAmount.toString());
    DateTime selectedDate = goal?.targetDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          title: Text(isEditing ? 'Edit Goal' : 'New Savings Goal', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () async {
                    final date = await showDatePicker(
                        context: context, 
                        initialDate: selectedDate, 
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2100)
                    );
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
                    id: goal?.id ?? '',
                    title: titleController.text,
                    targetAmount: double.tryParse(targetController.text) ?? 0,
                    savedAmount: double.tryParse(savedController.text) ?? 0,
                    targetDate: selectedDate,
                  );
                  
                  if (isEditing) {
                    context.read<SavingsProvider>().updateGoal(newGoal);
                  } else {
                    context.read<SavingsProvider>().addGoal(newGoal);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(onPressed: () => _showGoalDialog(context), icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSavingsSummary(context, savingsProvider.totalSaved, savingsProvider.totalTarget),
          const SizedBox(height: 30),
          if (goals.isEmpty)
            Center(child: Text('No savings goals yet', style: TextStyle(color: colorScheme.onSurfaceVariant)))
          else
            ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildGoalItem(context, goal),
            )),
        ],
      ),
    );
  }

  Widget _buildSavingsSummary(BuildContext context, double current, double target) {
    final colorScheme = Theme.of(context).colorScheme;
    double progress = target > 0 ? current / target : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Saved', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              Text(
                'GH₵ ${current.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.income),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, SavingsModel goal) {
    final colorScheme = Theme.of(context).colorScheme;
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
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title, 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    if (goal.isCompleted) const Icon(Icons.check_circle, color: AppColors.income),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showGoalDialog(context, goal: goal);
                        } else if (value == 'delete') {
                          context.read<SavingsProvider>().deleteGoal(goal.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.expense))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target: GH₵ ${goal.targetAmount.toStringAsFixed(2)}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                Text('${(goal.progress * 100).round()}%', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: goal.progress.clamp(0, 1),
              backgroundColor: colorScheme.surface,
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
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amountController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: colorScheme.surfaceContainer,
                        title: Text('Add Funds', style: TextStyle(color: colorScheme.onSurface)),
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
                  child: const Text('Add Funds', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

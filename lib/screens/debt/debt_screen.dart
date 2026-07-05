import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/debt_provider.dart';
import '../../models/debt_model.dart';
import '../../widgets/custom_text_field.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({super.key});

  void _showAddDebtDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final paidController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.navy,
          title: const Text('Add New Debt', style: TextStyle(color: AppColors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: titleController, hintText: 'Debt Title', prefixIcon: Icons.title),
                const SizedBox(height: 15),
                CustomTextField(controller: amountController, hintText: 'Total Amount', prefixIcon: Icons.money, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                CustomTextField(controller: paidController, hintText: 'Already Paid', prefixIcon: Icons.check_circle_outline, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                ListTile(
                  title: const Text('Due Date', style: TextStyle(color: AppColors.grey)),
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
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final newDebt = DebtModel(
                    id: '',
                    title: titleController.text,
                    amount: double.tryParse(amountController.text) ?? 0,
                    paidAmount: double.tryParse(paidController.text) ?? 0,
                    dueDate: selectedDate,
                  );
                  context.read<DebtProvider>().addDebt(newDebt);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    final debts = debtProvider.debts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        actions: [
          IconButton(onPressed: () => _showAddDebtDialog(context), icon: const Icon(Icons.add)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDebtSummaryCard(debtProvider.totalDebt, (debtProvider.overallProgress * 100).round()),
            const SizedBox(height: 30),
            if (debts.isEmpty)
              const Center(child: Text('No debts tracked yet', style: TextStyle(color: AppColors.grey)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: debts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  return _buildDebtItem(context, debt);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryCard(double total, int percentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Debt', style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 10),
              Text(
                'GH₵ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Paid Off', style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 10),
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtItem(BuildContext context, DebtModel debt) {
    return Dismissible(
      key: Key(debt.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<DebtProvider>().deleteDebt(debt.id),
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
                Text(debt.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
                Icon(debt.isPaid ? Icons.check_circle : Icons.pending, color: debt.isPaid ? AppColors.income : AppColors.gold),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text(
                  'GH₵ ${debt.paidAmount}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
                ),
                Text(' / GH₵ ${debt.amount}', style: const TextStyle(color: AppColors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: debt.progress,
              backgroundColor: AppColors.darkNavy,
              valueColor: AlwaysStoppedAnimation<Color>(debt.isPaid ? AppColors.income : AppColors.gold),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due: ${DateFormat('MMM dd').format(debt.dueDate)}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                TextButton(
                  onPressed: () {
                    final updated = DebtModel(
                      id: debt.id,
                      title: debt.title,
                      amount: debt.amount,
                      paidAmount: debt.amount,
                      dueDate: debt.dueDate,
                      isPaid: true,
                    );
                    context.read<DebtProvider>().updateDebt(updated);
                  },
                  child: Text(debt.isPaid ? 'Paid' : 'Mark as Paid', style: TextStyle(color: debt.isPaid ? AppColors.grey : AppColors.gold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

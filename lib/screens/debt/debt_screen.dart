import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/debt_provider.dart';
import '../../models/debt_model.dart';
import '../../widgets/custom_text_field.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({super.key});

  void _showDebtDialog(BuildContext context, {DebtModel? debt}) {
    final isEditing = debt != null;
    final titleController = TextEditingController(text: debt?.title);
    final amountController = TextEditingController(text: debt?.amount.toString());
    final paidController = TextEditingController(text: debt?.paidAmount.toString());
    DateTime selectedDate = debt?.dueDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          title: Text(isEditing ? 'Edit Debt' : 'Add New Debt', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  final paid = double.tryParse(paidController.text) ?? 0;
                  
                  final newDebt = DebtModel(
                    id: debt?.id ?? '',
                    title: titleController.text,
                    amount: amount,
                    paidAmount: paid,
                    dueDate: selectedDate,
                    isPaid: paid >= amount && amount > 0,
                  );

                  if (isEditing) {
                    context.read<DebtProvider>().updateDebt(newDebt);
                  } else {
                    context.read<DebtProvider>().addDebt(newDebt);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        actions: [
          IconButton(onPressed: () => _showDebtDialog(context), icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildDebtSummaryCard(context, debtProvider.totalDebt, (debtProvider.overallProgress * 100).round()),
          const SizedBox(height: 30),
          if (debts.isEmpty)
            Center(child: Text('No debts tracked yet', style: TextStyle(color: colorScheme.onSurfaceVariant)))
          else
            ...debts.map((debt) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildDebtItem(context, debt),
            )),
        ],
      ),
    );
  }

  Widget _buildDebtSummaryCard(BuildContext context, double total, int percentage) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Debt', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Text(
                'GH₵ ${total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Paid Off', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                    debt.title, 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(debt.isPaid ? Icons.check_circle : Icons.pending, color: debt.isPaid ? AppColors.income : AppColors.gold),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showDebtDialog(context, debt: debt);
                        } else if (value == 'delete') {
                          context.read<DebtProvider>().deleteDebt(debt.id);
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
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  'GH₵ ${debt.paidAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                Text(' / GH₵ ${debt.amount.toStringAsFixed(2)}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: debt.progress,
              backgroundColor: colorScheme.surface,
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
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                TextButton(
                  onPressed: debt.isPaid ? null : () {
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
                  child: Text(debt.isPaid ? 'Paid' : 'Mark as Paid', style: TextStyle(color: debt.isPaid ? colorScheme.onSurfaceVariant : AppColors.gold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

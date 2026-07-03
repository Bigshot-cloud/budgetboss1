import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';

  void _deleteTransaction(String txId) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      await context.read<TransactionProvider>().deleteTransaction(userId, txId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    }
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> all) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return all.where((tx) => tx.date.day == now.day && tx.date.month == now.month && tx.date.year == now.year).toList();
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return all.where((tx) => tx.date.isAfter(weekAgo)).toList();
      case 'This Month':
        return all.where((tx) => tx.date.month == now.month && tx.date.year == now.year).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final filteredTx = _getFilteredTransactions(txProvider.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _selectedFilter = val),
            itemBuilder: (context) => ['All', 'Today', 'This Week', 'This Month']
                .map((f) => PopupMenuItem(value: f, child: Text(f)))
                .toList(),
          ),
        ],
      ),
      body: filteredTx.isEmpty
          ? const Center(child: Text('No transactions found', style: TextStyle(color: AppColors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filteredTx.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = filteredTx[index];
                final isIncome = tx.type == TransactionType.income;
                return Dismissible(
                  key: Key(tx.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteTransaction(tx.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.expense,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: AppColors.white),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(tx.icon, color: isIncome ? AppColors.income : AppColors.expense),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(tx.category, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'} GH₵ ${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isIncome ? AppColors.income : AppColors.expense,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(tx.date),
                              style: const TextStyle(color: AppColors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

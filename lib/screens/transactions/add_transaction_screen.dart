import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:budgetboss_app/core/constants/app_colors.dart';
import 'package:budgetboss_app/models/transaction.dart';
import 'package:budgetboss_app/providers/transaction_provider.dart';
import 'package:budgetboss_app/providers/auth_provider.dart';
import 'package:budgetboss_app/widgets/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _selectedType = TransactionType.income;
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();

  final List<String> _incomeCategories = ['Salary', 'Business', 'Freelance', 'Investment', 'Gift', 'Other'];
  final List<String> _expenseCategories = ['Food', 'Transport', 'Rent', 'Utilities', 'Shopping', 'Entertainment', 'Healthcare', 'Other'];

  void _saveTransaction() async {
    if (_amountController.text.isEmpty) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) return;

    final newTx = TransactionModel(
      id: const Uuid().v4(),
      title: _noteController.text.isEmpty ? _selectedCategory : _noteController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      type: _selectedType,
      icon: _getIconForCategory(_selectedCategory),
    );

    await context.read<TransactionProvider>().addTransaction(userId, newTx);
    if (mounted) Navigator.pop(context);
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Salary': return Icons.work_outline;
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Rent': return Icons.home_work;
      case 'Utilities': return Icons.electrical_services;
      default: return Icons.category_outlined;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () => _selectDate(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton('Income', TransactionType.income, colorScheme),
                  ),
                  Expanded(
                    child: _buildToggleButton('Expense', TransactionType.expense, colorScheme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text('Category', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            _buildCategoryDropdown(colorScheme),
            const SizedBox(height: 25),
            Text('Amount', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _amountController,
              hintText: 'GH₵ 0.00',
              prefixIcon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            Text('Date', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            _buildDatePicker(colorScheme),
            const SizedBox(height: 25),
            Text('Note (Optional)', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _noteController,
              hintText: 'Add a note...',
              prefixIcon: Icons.notes,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, TransactionType type, ColorScheme colorScheme) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = type == TransactionType.income ? _incomeCategories[0] : _expenseCategories[0];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ColorScheme colorScheme) {
    final categories = _selectedType == TransactionType.income ? _incomeCategories : _expenseCategories;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: Theme(
          data: Theme.of(context).copyWith(canvasColor: colorScheme.surfaceContainer),
          child: DropdownButton<String>(
            value: _selectedCategory,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
            items: categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    Icon(_getIconForCategory(category), color: AppColors.gold, size: 20),
                    const SizedBox(width: 15),
                    Text(category, style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) setState(() => _selectedCategory = newValue);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: TextStyle(color: colorScheme.onSurface),
            ),
            Icon(Icons.calendar_month, color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

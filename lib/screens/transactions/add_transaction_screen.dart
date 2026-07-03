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
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton('Income', TransactionType.income),
                  ),
                  Expanded(
                    child: _buildToggleButton('Expense', TransactionType.expense),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Category', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 10),
            _buildCategoryDropdown(),
            const SizedBox(height: 25),
            const Text('Amount', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _amountController,
              hintText: 'GH₵ 0.00',
              prefixIcon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            const Text('Date', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 10),
            _buildDatePicker(),
            const SizedBox(height: 25),
            const Text('Note (Optional)', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _noteController,
              hintText: 'Add a note...',
              prefixIcon: Icons.notes,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueAccent,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, TransactionType type) {
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
              color: isSelected ? AppColors.white : AppColors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _selectedType == TransactionType.income ? _incomeCategories : _expenseCategories;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: AppColors.navy,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
          items: categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Row(
                children: [
                  Icon(_getIconForCategory(category), color: AppColors.gold, size: 20),
                  const SizedBox(width: 15),
                  Text(category, style: const TextStyle(color: AppColors.white)),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) setState(() => _selectedCategory = newValue);
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(color: AppColors.white),
            ),
            const Icon(Icons.calendar_month, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

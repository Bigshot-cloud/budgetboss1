import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:budgetboss_app/core/constants/app_colors.dart';
import 'package:budgetboss_app/providers/transaction_provider.dart';
import 'package:budgetboss_app/providers/notification_provider.dart';
import 'package:budgetboss_app/models/transaction.dart';
import 'package:budgetboss_app/widgets/budget_banner_widget.dart';
import 'package:budgetboss_app/screens/ai/ai_assistant_screen.dart';
import 'package:budgetboss_app/screens/reports/analytics_screen.dart';
import 'package:budgetboss_app/screens/notifications/notifications_screen.dart';
import 'package:budgetboss_app/screens/transactions/transactions_screen.dart';
import 'package:budgetboss_app/screens/debt/debt_screen.dart';
import 'package:budgetboss_app/screens/savings/savings_screen.dart';
import 'package:budgetboss_app/core/services/sms_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOverview = true;
  String _timeFilter = 'This Month';
  final SmsService _smsService = SmsService();

  @override
  void initState() {
    super.initState();
    _startSmsListener();
  }

  void _startSmsListener() {
    _smsService.startListening((transaction) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New transaction detected: ${transaction['title']}'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_isOverview ? 'Dashboard' : 'Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (range != null) {
                setState(() {
                  _timeFilter = '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.gold),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen()));
            },
          ),
          IconButton(
            icon: Icon(_isOverview ? Icons.analytics_outlined : Icons.dashboard_outlined),
            onPressed: () {
              setState(() {
                _isOverview = !_isOverview;
              });
            },
          ),
          _buildNotificationIcon(),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.navy,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.darkNavy),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 50, color: AppColors.gold),
                  SizedBox(height: 10),
                  Text('BudgetBoss Menu', style: TextStyle(color: AppColors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.money_off, color: AppColors.expense),
              title: const Text('Debt Tracker', style: TextStyle(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings_outlined, color: AppColors.income),
              title: const Text('Savings Goals', style: TextStyle(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SavingsScreen()));
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isOverview ? _buildOverview() : const AnalyticsScreen(),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.expense,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverview() {
    final txProvider = context.watch<TransactionProvider>();
    final allTransactions = txProvider.transactions;
    
    // Filter transactions based on selected time
    final now = DateTime.now();
    final filteredTransactions = allTransactions.where((tx) {
      if (_timeFilter == 'Today') {
        return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
      } else if (_timeFilter == 'This Week') {
        return tx.date.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_timeFilter == 'This Month') {
        return tx.date.year == now.year && tx.date.month == now.month;
      }
      return true; // Default for 'Custom' or others for now
    }).toList();

    double income = 0;
    double expense = 0;
    for (var tx in filteredTransactions) {
      if (tx.type == TransactionType.income) income += tx.amount;
      else if (tx.type == TransactionType.expense) expense += tx.amount;
    }

    return SingleChildScrollView(
      key: const ValueKey('Overview'),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BudgetBannerWidget(),
            const SizedBox(height: 20),
            _buildBalanceCard(income - expense),
            const SizedBox(height: 25),
            _buildSummaryRow(income, expense),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsScreen()));
                  },
                  child: const Text('See All', style: TextStyle(color: AppColors.gold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildRecentTransactions(filteredTransactions.take(5).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: AppColors.grey, fontSize: 16),
              ),
              _buildTimeFilter(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'GH₵ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.income, size: 16),
              SizedBox(width: 5),
              Text(
                'Live Data Tracking',
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 7,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 2),
                      FlSpot(2, 5),
                      FlSpot(3, 3.1),
                      FlSpot(4, 4),
                      FlSpot(5, 3),
                      FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: AppColors.gold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.gold.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return PopupMenuButton<String>(
      onSelected: (String result) {
        setState(() {
          _timeFilter = result;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'Today', child: Text('Today')),
        const PopupMenuItem<String>(value: 'This Week', child: Text('This Week')),
        const PopupMenuItem<String>(value: 'This Month', child: Text('This Month')),
        const PopupMenuItem<String>(value: 'Custom', child: Text('Custom Range')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.darkNavy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(_timeFilter, style: const TextStyle(fontSize: 12, color: AppColors.white)),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expense) {
    return Row(
      children: [
        Expanded(child: _buildSummaryItem('Income', 'GH₵ ${income.toStringAsFixed(0)}', Icons.arrow_upward, AppColors.income)),
        const SizedBox(width: 10),
        Expanded(child: _buildSummaryItem('Expenses', 'GH₵ ${expense.toStringAsFixed(0)}', Icons.arrow_downward, AppColors.expense)),
        const SizedBox(width: 10),
        Expanded(child: _buildSummaryItem('Savings', 'GH₵ ${(income - expense).toStringAsFixed(0)}', Icons.savings_outlined, AppColors.savings)),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions yet', style: TextStyle(color: AppColors.grey)));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == TransactionType.income;
        return Container(
          padding: const EdgeInsets.all(12),
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
                    Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
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
                    '${tx.date.day}/${tx.date.month}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

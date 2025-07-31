import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expensemate_rohit/generated/app_localizations.dart';
import '../db/database_helper.dart';

class BalanceSummaryScreen extends StatefulWidget {
  const BalanceSummaryScreen({super.key});

  @override
  State<BalanceSummaryScreen> createState() => _BalanceSummaryScreenState();
}

class _BalanceSummaryScreenState extends State<BalanceSummaryScreen> {
  String selectedFilter = '';
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedFilter.isEmpty) {
      selectedFilter = AppLocalizations.of(context)!.today;
    }
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() => transactions = data.reversed.toList());
  }

  List<String> get localizedFilterOptions {
    final local = AppLocalizations.of(context)!;
    return [local.today, local.week, local.month, local.year];
  }

  List<Map<String, dynamic>> get filteredTransactions {
    final now = DateTime.now();
    final local = AppLocalizations.of(context)!;
    return transactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);
      final normalizedTxDate = DateTime(txDate.year, txDate.month, txDate.day);

      if (selectedFilter == local.today) {
        final today = DateTime(now.year, now.month, now.day);
        return normalizedTxDate == today;
      } else if (selectedFilter == local.week) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return normalizedTxDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            normalizedTxDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      } else if (selectedFilter == local.month) {
        return txDate.year == now.year && txDate.month == now.month;
      } else if (selectedFilter == local.year) {
        return txDate.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    final double incomeTotal = filteredTransactions
        .where((t) => t['type'] == 'Income')
        .fold(0.0, (sum, item) => sum + double.parse(item['amount'].toString()));

    final double expenseTotal = filteredTransactions
        .where((t) => t['type'] == 'Expense')
        .fold(0.0, (sum, item) => sum + double.parse(item['amount'].toString()));

    final double balance = incomeTotal - expenseTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.balance),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterRow(local),
            const SizedBox(height: 16),
            _buildSummaryCard(local.income, incomeTotal, Colors.green),
            _buildSummaryCard(local.expenses, expenseTotal, Colors.red),
            _buildSummaryCard(local.balance, balance,
                balance >= 0 ? Colors.blue : Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text("৳${formatAmount(amount)}",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterRow(AppLocalizations local) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: localizedFilterOptions.map((option) {
          final isSelected = selectedFilter == option;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = option),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

String formatAmount(double amount) {
  return amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
}

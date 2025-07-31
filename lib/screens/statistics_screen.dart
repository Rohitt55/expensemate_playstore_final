import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'package:expensemate_rohit/generated/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool showIncome = false;
  DateTime selectedWeekStart = _getStartOfCurrentWeek();
  List<Map<String, dynamic>> allTransactions = [];

  static DateTime _getStartOfCurrentWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() => allTransactions = data);
  }

  List<BarChartGroupData> get sideBySideWeeklyBars {
    return List.generate(7, (i) {
      final day = selectedWeekStart.add(Duration(days: i));
      double incomeTotal = 0;
      double expenseTotal = 0;

      for (var tx in allTransactions) {
        final txDate = DateTime.parse(tx['date']);
        if (txDate.year == day.year &&
            txDate.month == day.month &&
            txDate.day == day.day) {
          final amount = (tx['amount'] as num).toDouble();
          if (tx['type'] == 'Income') {
            incomeTotal += amount;
          } else if (tx['type'] == 'Expense') {
            expenseTotal += amount;
          }
        }
      }

      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: expenseTotal,
          width: 6,
          borderRadius: BorderRadius.circular(4),
          color: Colors.red,
        ),
        BarChartRodData(
          toY: incomeTotal,
          width: 6,
          borderRadius: BorderRadius.circular(4),
          color: Colors.green,
        ),
      ]);
    });
  }

  Map<String, int> get groupedByCategory {
    final weekEnd = selectedWeekStart.add(const Duration(days: 6));
    final filtered = allTransactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);
      return tx['type'] == (showIncome ? 'Income' : 'Expense') &&
          txDate.isAfter(selectedWeekStart.subtract(const Duration(days: 1))) &&
          txDate.isBefore(weekEnd.add(const Duration(days: 1)));
    });

    Map<String, int> result = {};
    for (var tx in filtered) {
      final category = tx['category'];
      final amount = (tx['amount'] as num).toDouble();
      result[category] = (result[category] ?? 0) + amount.toInt();
    }
    return result;
  }

  void _selectWeek(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedWeekStart = picked.subtract(Duration(days: picked.weekday - 1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final categoryData = groupedByCategory;
    final total = categoryData.values.fold(0, (a, b) => a + b);
    final weekRange =
        "${DateFormat('MMM d').format(selectedWeekStart)} - ${DateFormat('MMM d').format(selectedWeekStart.add(const Duration(days: 6)))}";

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title:
        Text(local.weeklyReport, style: const TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("${local.weekLabel}:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _selectWeek(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(weekRange),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildBarChart(local),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(20),
                isSelected: [!showIncome, showIncome],
                onPressed: (index) => setState(() => showIncome = index == 1),
                selectedColor: Colors.white,
                fillColor: showIncome ? Colors.green : Colors.red,
                color: Colors.black,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(local.expenseLabel),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(local.incomeLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(local.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(child: _buildCategoryList(categoryData, total, local)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(AppLocalizations local) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) =>
                  Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10)),
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: sideBySideWeeklyBars,
        groupsSpace: 12,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, int> categoryData, int total, AppLocalizations local) {
    if (categoryData.isEmpty) {
      return Center(child: Text(local.noData));
    }

    return ListView.separated(
      itemCount: categoryData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = categoryData.entries.elementAt(index);
        final percent = total == 0 ? 0.0 : entry.value / total;
        final color = showIncome ? Colors.green : Colors.red;

        // Localized category name fallback
        final categoryKey = entry.key.toLowerCase();
        final localizedCategory = {
          'food': local.category_food,
          'shopping': local.category_shopping,
          'fuel': local.category_fuel,
          'salary': local.category_salary,
          'subscription': local.category_subscription,
          'grocery': local.category_grocery,
          'personal': local.category_personal,
          'travel': local.category_travel,
          'medicine': local.category_medicine,
          'entertainment': local.category_entertainment,
          'bills': local.category_bills,
          'education': local.category_education,
          'investment': local.category_investment,
          'others': local.category_others,
        }[categoryKey] ?? entry.key;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: color),
                const SizedBox(width: 8),
                Expanded(child: Text(localizedCategory, style: const TextStyle(fontWeight: FontWeight.w500))),
                Text("৳${entry.value}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
    );
  }
}

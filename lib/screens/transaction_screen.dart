import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expensemate_rohit/generated/app_localizations.dart';
import '../db/database_helper.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<Map<String, dynamic>> transactions = [];
  late String selectedPeriod;
  late String selectedType;
  String searchQuery = '';
  DateTime selectedDate = DateTime.now();

  final TextEditingController _searchController = TextEditingController();

  List<String> get periodOptions {
    final local = AppLocalizations.of(context)!;
    return [
      local.today,
      local.week,
      local.month,
      local.year,
    ];
  }

  List<String> get typeOptions {
    final local = AppLocalizations.of(context)!;
    return [
      local.transactionsAll,
      local.income,
      local.expense,
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final local = AppLocalizations.of(context)!;
      setState(() {
        selectedPeriod = local.month;
        selectedType = local.transactionsAll;
      });
    });
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() => transactions = data.reversed.toList());
  }

  List<Map<String, dynamic>> get filteredTransactions {
    final now = selectedDate;
    final local = AppLocalizations.of(context)!;

    // Map localized type to raw DB value
    String? filterType;
    if (selectedType == local.income) {
      filterType = 'Income';
    } else if (selectedType == local.expense) {
      filterType = 'Expense';
    }

    return transactions.where((tx) {
      if (filterType != null && tx['type'] != filterType) return false;

      final txDate = DateTime.parse(tx['date']);
      final normalizedTxDate = DateTime(txDate.year, txDate.month, txDate.day);

      bool dateMatch;
      if (selectedPeriod == local.today) {
        final today = DateTime(now.year, now.month, now.day);
        dateMatch = normalizedTxDate == today;
      } else if (selectedPeriod == local.week) {
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        dateMatch = normalizedTxDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            normalizedTxDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      } else if (selectedPeriod == local.month) {
        dateMatch = txDate.year == now.year && txDate.month == now.month;
      } else if (selectedPeriod == local.year) {
        dateMatch = txDate.year == now.year;
      } else {
        dateMatch = true;
      }

      final category = (tx['category'] ?? '').toString().toLowerCase();
      final description = (tx['description'] ?? '').toString().toLowerCase();
      final amount = (tx['amount'] ?? '').toString().toLowerCase();
      final search = searchQuery.toLowerCase();

      return dateMatch &&
          (category.contains(search) || description.contains(search) || amount.contains(search));
    }).toList();
  }

  String getFormattedTransactionDate() {
    final now = selectedDate;
    final local = AppLocalizations.of(context)!;

    if (selectedPeriod == local.today) {
      return DateFormat('d/M/yyyy').format(now);
    } else if (selectedPeriod == local.week) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return "${DateFormat('d/M').format(startOfWeek)} - ${DateFormat('d/M').format(endOfWeek)}";
    } else if (selectedPeriod == local.month) {
      return DateFormat('MMMM yyyy').format(now);
    } else if (selectedPeriod == local.year) {
      return DateFormat('yyyy').format(now);
    } else {
      return DateFormat('d/M/yyyy').format(now);
    }
  }

  void _showEditDialog(Map<String, dynamic> transaction) {
    final local = AppLocalizations.of(context)!;
    final amountController = TextEditingController(text: transaction["amount"].toString());
    final categoryController = TextEditingController(text: transaction["category"]);
    final noteController = TextEditingController(text: transaction["description"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(local.editTransaction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: local.amount),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: local.category),
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: local.note),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final amountText = amountController.text.trim();
              if (amountText.isEmpty || double.tryParse(amountText) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(local.pleaseEnterValidAmount)),
                );
                return;
              }

              final updatedData = {
                'id': transaction['id'],
                'amount': double.parse(amountText),
                'category': categoryController.text,
                'description': noteController.text,
                'date': transaction['date'],
                'type': transaction['type'],
                'userEmail': transaction['userEmail'],
              };

              try {
                await DatabaseHelper.instance.updateTransaction(updatedData);
                Navigator.pop(context);
                _loadTransactions();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(local.updateFailed)),
                );
              }
            },
            child: Text(local.save),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(local.cancel),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _loadTransactions();
  }

  String formatAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: Text(local.transactionHistory, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPeriod,
                        items: periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPeriod = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        items: typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    helpText: "Select Month & Year",
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Row(
                  children: [
                    Text(
                      "${local.showing}: ${getFormattedTransactionDate()}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: local.searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(child: Text(local.noTransactionsAvailable))
                : ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                final amount = (tx["amount"] as num).toDouble();
                final isIncome = tx["type"] == 'Income';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? Colors.greenAccent : Colors.redAccent,
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ),
                    title: Text("${tx["category"]} - ৳${formatAmount(amount)}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "${tx["description"]} • ${DateFormat.yMMMd().add_jm().format(DateTime.parse(tx["date"]))}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(tx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTransaction(tx["id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

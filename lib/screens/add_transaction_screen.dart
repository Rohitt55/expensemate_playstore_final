import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'package:expensemate_rohit/generated/app_localizations.dart';


class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final List<String> _categories = [
    'Food', 'Shopping', 'Fuel', 'Salary', 'Subscription', 'Grocery',
    'Personal', 'Travel', 'Medicine', 'Entertainment', 'Bills',
    'Education', 'Investment', 'Others',
  ];

  String _selectedCategory = 'Food';
  String _selectedType = 'Income';
  DateTime _selectedDate = DateTime.now();

  /// ✅ Localized category list (refreshed in didChangeDependencies)
  late List<String> _localizedCategories;

  @override
  void initState() {
    super.initState();
    // ⚠️ Do NOT use context-dependent logic here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDateText();
    _localizedCategories = _getLocalizedCategories(AppLocalizations.of(context)!);
  }

  void _updateDateText() {
    final locale = Localizations.localeOf(context).toString();
    _dateController.text = DateFormat.yMMMd(locale).format(_selectedDate);
  }

  List<String> _getLocalizedCategories(AppLocalizations local) {
    return [
      local.category_food,
      local.category_shopping,
      local.category_fuel,
      local.category_salary,
      local.category_subscription,
      local.category_grocery,
      local.category_personal,
      local.category_travel,
      local.category_medicine,
      local.category_entertainment,
      local.category_bills,
      local.category_education,
      local.category_investment,
      local.category_others,
    ];
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateDateText();
      });
    }
  }

  void _saveTransaction() async {
    final local = AppLocalizations.of(context)!;
    final amountText = _amountController.text.trim();
    final desc = _descController.text.trim();

    if (amountText.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.allFieldsRequired)),
      );
      return;
    }

    try {
      final amount = double.parse(amountText);
      final formattedDate = _selectedDate.toIso8601String();

      await DatabaseHelper.instance.addTransaction(
        amount,
        _selectedCategory, // English name
        _selectedType,
        formattedDate,
        desc,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.transactionSaved)),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.invalidAmount)),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: Text(local.addTransaction, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(local.howMuch, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('৳', style: TextStyle(fontSize: 20)),
                ),
                hintText: local.enterAmount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            /// Localized Category Dropdown
            DropdownButtonFormField<String>(
              value: _localizedCategories[_categories.indexOf(_selectedCategory)],
              items: _localizedCategories
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (val) {
                final index = _localizedCategories.indexOf(val!);
                setState(() {
                  _selectedCategory = _categories[index]; // Store English value
                });
              },
              decoration: InputDecoration(
                labelText: local.category,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: local.description,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            /// Income / Expense Type Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(local.income),
                  selected: _selectedType == 'Income',
                  selectedColor: Colors.green,
                  onSelected: (_) => setState(() => _selectedType = 'Income'),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text(local.expense),
                  selected: _selectedType == 'Expense',
                  selectedColor: Colors.red,
                  onSelected: (_) => setState(() => _selectedType = 'Expense'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: local.date,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(local.continueButton,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

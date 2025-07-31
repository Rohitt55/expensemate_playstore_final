import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../db/database_helper.dart';
import '../main.dart'; // For LocaleProvider
import 'package:expensemate_rohit/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _monthlyBudget;
  String _currentLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget');
      _currentLang = prefs.getString('lang') ?? 'en';
    });
  }

  Future<void> _setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', langCode);
    setState(() => _currentLang = langCode);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    localeProvider.setLocale(Locale(langCode));
  }

  Future<void> _setMonthlyBudget() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.setMonthlyBudget),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "৳"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('monthly_budget', value);
                setState(() => _monthlyBudget = value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.budgetUpdated)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBudget() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('monthly_budget')) {
      await prefs.remove('monthly_budget');
      setState(() => _monthlyBudget = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.budgetRemoved)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noBudgetSet)),
      );
    }
  }

  Future<void> _setOrUpdatePin() async {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.setUpdatePin),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(labelText: "Enter 4-digit PIN"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 4 && int.tryParse(pin) != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_pin', pin);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.pinSuccess)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.invalidPin)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _removePin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('user_pin')) {
      await prefs.remove('user_pin');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pinRemoved)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noPinSet)),
      );
    }
  }

  Future<void> _confirmReset() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmReset),
        content: Text(AppLocalizations.of(context)!.confirmResetDescription),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.resetAllTransactionsForUser();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.resetAllData)),
                );
              },
              child: Text(AppLocalizations.of(context)!.yes, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: Text(local.settings, style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        backgroundColor: const Color(0xFFFDF7F0),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 8.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              leading: Icon(Icons.language, color: Colors.teal, size: 26.sp),
              title: Text(local.language,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
              trailing: DropdownButton<String>(
                value: _currentLang,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                ],
                onChanged: (value) {
                  if (value != null) _setLanguage(value);
                },
              ),
            ),
          ),
          _buildSettingTile(
            icon: Icons.attach_money,
            title: local.setMonthlyBudget,
            color: Colors.green,
            onTap: _setMonthlyBudget,
          ),
          _buildSettingTile(
            icon: Icons.remove_circle_outline,
            title: local.removeBudget,
            color: Colors.brown,
            onTap: _removeBudget,
          ),
          _buildSettingTile(
            icon: Icons.pin,
            title: local.setUpdatePin,
            color: Colors.purple,
            onTap: _setOrUpdatePin,
          ),
          _buildSettingTile(
            icon: Icons.no_encryption_gmailerrorred,
            title: local.removePin,
            color: Colors.grey,
            onTap: _removePin,
          ),
          _buildSettingTile(
            icon: Icons.delete_forever,
            title: local.resetAllData,
            color: Colors.red,
            onTap: _confirmReset,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        leading: Icon(icon, color: color, size: 26.sp),
        title: Text(title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }
}

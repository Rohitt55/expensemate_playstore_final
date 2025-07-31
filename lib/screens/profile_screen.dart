import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../pdf_helper.dart';
import 'package:expensemate_rohit/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserInfo();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('profile_image');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? '';
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', savedImage.path);

      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  Future<void> _editUserInfo() async {
    final local = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: _name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.w,
          right: 20.w,
          top: 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(local.editInfo, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              TextField(controller: nameController, decoration: InputDecoration(hintText: local.profile)),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(local.cancel)),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setString('name', nameController.text.trim());
                      Navigator.pop(context);
                      _loadUserInfo();
                    },
                    child: Text(local.save),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetProfileInfo() async {
    final local = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(local.confirmResetTitle),
        content: Text(local.confirmResetDescription),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(local.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(local.confirm)),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('profile_image');

    setState(() {
      _name = '';
      _profileImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(local.profileResetSuccess)),
    );
  }

  Future<void> _exportAsPDFWithFilters() async {
    final local = AppLocalizations.of(context)!;
    final categoryOptions = ['All', 'Income', 'Expense'];
    String selectedCategory = 'All';
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(local.exportAsPdf, style: TextStyle(fontSize: 16.sp)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: categoryOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                          child: Text(startDate != null
                              ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                              : "Start Date"),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => endDate = picked);
                            }
                          },
                          child: Text(endDate != null
                              ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                              : "End Date"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(local.cancel)),
                ElevatedButton(
                  onPressed: () async {
                    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Start date cannot be after end date")),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    try {
                      await PDFHelper.generateTransactionPdf(
                        user: {'name': _name},
                        categoryFilter: selectedCategory,
                        startDate: startDate,
                        endDate: endDate,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(local.pdfGeneratedSuccess)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(local.pdfGenerationFailed)),
                      );
                    }
                  },
                  child: Text(local.exportAsPdf),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final local = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');

    if (savedPin != null) {
      final TextEditingController pinController = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(local.pinRequired),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(labelText: local.enterPin),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(local.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text == savedPin) {
                  await prefs.remove('isLoggedIn');
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(local.incorrectPin)),
                  );
                }
              },
              child: Text(local.logout),
            ),
          ],
        ),
      );
    } else {
      await prefs.remove('isLoggedIn');
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: Text(local.profile, style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40.r,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : const AssetImage('assets/images/user.png') as ImageProvider,
                        ),
                        SizedBox(height: 8.h),
                        Text(local.tapToChangePhoto, style: TextStyle(color: Colors.blue, fontSize: 12.sp)),
                        SizedBox(height: 6.h),
                        Text(_name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                _buildProfileOption(Icons.edit, local.editInfo, _editUserInfo),
                _buildProfileOption(Icons.settings, local.settings, () => Navigator.pushNamed(context, '/settings')),
                _buildProfileOption(Icons.balance, local.balanceSummary, () => Navigator.pushNamed(context, '/balance-summary')),
                _buildProfileOption(Icons.picture_as_pdf, local.exportAsPdf, _exportAsPDFWithFilters),
                _buildProfileOption(Icons.delete_forever, local.resetProfile, _resetProfileInfo, color: Colors.red),
                _buildProfileOption(Icons.logout, local.logout, _logout, color: Colors.redAccent),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 24.sp),
        title: Text(title, style: TextStyle(color: color, fontSize: 14.sp)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
      ),
    );
  }
}

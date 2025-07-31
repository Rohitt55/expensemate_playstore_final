import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:expensemate_rohit/generated/app_localizations.dart';



import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/balance_summary_screen.dart'; // ✅ Added for balance summary screen

// Locale Provider
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('lang') ?? 'en';

  runApp(ChangeNotifierProvider(
    create: (_) {
      final provider = LocaleProvider();
      provider.setLocale(Locale(savedLang));
      return provider;
    },
    child: const ExpenseApp(),
  ));
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          title: 'ExpenseMate',
          theme: ThemeData(
            fontFamily: 'NotoSans',
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFFFDF7F0),
          ),
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('bn'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const EntryPoint(),
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/statistics': (context) => const StatisticsScreen(),
            '/transactions': (context) => const TransactionScreen(),
            '/add': (context) => const AddTransactionScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/balance-summary': (context) => const BalanceSummaryScreen(), // ✅ Added route
          },
        );
      },
    );
  }
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    String? savedPin = prefs.getString('user_pin');

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      _startScreen = const WelcomeScreen();
    } else if (savedPin != null) {
      _startScreen = _buildPinCheckScreen(savedPin);
    } else {
      _startScreen = const HomeScreen();
    }

    setState(() {});
  }

  Widget _buildPinCheckScreen(String correctPin) {
    final TextEditingController _pinController = TextEditingController();
    String? errorText;

    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF7F0),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter your PIN",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "4-digit PIN",
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_pinController.text == correctPin) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      } else {
                        setState(() {
                          errorText = "Incorrect PIN";
                        });
                      }
                    },
                    child: const Text("Unlock"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_startScreen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _startScreen!;
  }
}

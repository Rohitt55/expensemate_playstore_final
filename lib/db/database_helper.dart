import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expensemate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        category TEXT,
        type TEXT,
        date TEXT,
        description TEXT,
        userEmail TEXT
      )
    ''');
  }

  Future<int> addTransaction(double amount, String category, String type, String date, String desc) async {
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    final data = {
      'amount': amount,
      'category': category,
      'type': type,
      'date': date,
      'description': desc,
      'userEmail': email,
    };
    return await db.insert('transactions', data);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    return await db.query(
      'transactions',
      where: 'userEmail = ?',
      whereArgs: [email],
    );
  }

  Future<int> updateTransaction(Map<String, dynamic> transaction) async {
    final db = await database;

    final updateData = {
      'amount': transaction['amount'],
      'category': transaction['category'],
      'type': transaction['type'],
      'date': transaction['date'],
      'description': transaction['description'],
      'userEmail': transaction['userEmail'],
    };

    return await db.update(
      'transactions',
      updateData,
      where: 'id = ?',
      whereArgs: [transaction['id']],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> resetAllTransactionsForUser() async {
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    await db.delete(
      'transactions',
      where: 'userEmail = ?',
      whereArgs: [email],
    );
  }

}
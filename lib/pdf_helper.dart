import 'dart:io';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'db/database_helper.dart';

class PDFHelper {
  static Future<void> generateTransactionPdf({
    required Map<String, dynamic> user,
    String categoryFilter = 'All',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Intl.defaultLocale = 'en_US';

    // 🔐 Permission handling
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isDenied ||
          await Permission.storage.isDenied) {
        await Permission.manageExternalStorage.request();
        await Permission.storage.request();
      }
    }

    // 📊 Load transactions
    final allTransactions = await DatabaseHelper.instance.getAllTransactions();
    final filtered = allTransactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);
      final isAfterStart = startDate == null || txDate.isAtSameMomentAs(startDate) || txDate.isAfter(startDate);
      final isBeforeEnd = endDate == null || txDate.isAtSameMomentAs(endDate) || txDate.isBefore(endDate.add(const Duration(days: 1)));
      final matchesType = categoryFilter == 'All' || tx['type'] == categoryFilter;
      return isAfterStart && isBeforeEnd && matchesType;
    }).toList();

    final dateFormatter = DateFormat("dd MMM yyyy, hh:mm a", "en_US");

    final incomeTotal = filtered
        .where((t) => t['type'] == 'Income')
        .fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
    final expenseTotal = filtered
        .where((t) => t['type'] == 'Expense')
        .fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
    final balance = incomeTotal - expenseTotal;

    String formatAmount(double amount) =>
        amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);

    final tableRows = filtered.map((tx) {
      final formattedDate = dateFormatter.format(DateTime.parse(tx['date']));
      return """
        <tr>
          <td>$formattedDate</td>
          <td>${tx['amount']}</td>
          <td>${tx['category']}</td>
          <td>${tx['type']}</td>
          <td>${tx['description'] ?? ''}</td>
        </tr>
      """;
    }).join();

    // 🧾 HTML content
    final htmlContent = """
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: sans-serif; padding: 20px; font-size: 14px; color: #333; }
          table { width: 100%; border-collapse: collapse; margin-top: 16px; }
          th, td { border: 1px solid #333; padding: 8px; font-size: 12px; text-align: left; }
          th { background-color: #f0f0f0; }
          .summary-box { margin: 20px auto; border: 1px solid #ccc; border-radius: 8px; padding: 16px; background-color: #f9f9f9; }
          .summary-box h3 { margin: 0 0 10px; text-align: center; }
          .summary-item { display: flex; justify-content: space-between; font-weight: bold; margin: 6px 0; }
        </style>
      </head>
      <body>
        <h2>Transaction Report - ${DateTime.now().year}</h2>
        <p>User: ${user['name']}</p>
        <div class="summary-box">
          <h3>Balance Summary</h3>
          <div class="summary-item"><span>Total Income:</span><span>৳${formatAmount(incomeTotal)}</span></div>
          <div class="summary-item"><span>Total Expenses:</span><span>৳${formatAmount(expenseTotal)}</span></div>
          <div class="summary-item"><span>Balance:</span><span>৳${formatAmount(balance)}</span></div>
        </div>
        <table>
          <tr>
            <th>Date</th><th>Amount</th><th>Category</th><th>Type</th><th>Description</th>
          </tr>
          $tableRows
        </table>
      </body>
    </html>
    """;

    // 📁 Save to Downloads (user accessible)
    final Directory downloadsDir = Directory('/storage/emulated/0/Download');
    final String fileName = "transaction_report_${DateTime.now().millisecondsSinceEpoch}";

    final pdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
      htmlContent,
      downloadsDir.path,
      fileName,
    );

    final exists = await pdfFile.exists();
    if (!exists) {
      print("❌ PDF not created!");
      return;
    }

    print("✅ PDF saved at: ${pdfFile.path}");

    // 🔄 Option 1: Share PDF
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: '$fileName.pdf',
    );

    // 🔄 Option 2: Open the file (uncomment to use)
    // await OpenFile.open(pdfFile.path);
  }
}

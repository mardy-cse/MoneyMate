import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import '../models/expense.dart';
import '../controllers/expense_controller.dart';
import '../services/currency_service.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  final controller = Get.find<ExpenseController>();

  // Group expenses by month
  Map<String, List<Expense>> _groupExpensesByMonth() {
    final Map<String, List<Expense>> groupedExpenses = {};

    for (var expense in controller.expenses) {
      final monthKey = DateFormat('MMMM yyyy').format(expense.date);
      if (!groupedExpenses.containsKey(monthKey)) {
        groupedExpenses[monthKey] = [];
      }
      groupedExpenses[monthKey]!.add(expense);
    }

    // Sort by date (newest first)
    final sortedKeys = groupedExpenses.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, groupedExpenses[key]!)),
    );
  }

  // Calculate monthly statistics
  Map<String, dynamic> _calculateMonthlyStats(List<Expense> expenses) {
    double totalExpense = 0.0;
    double totalIncome = 0.0;
    Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      if (expense.amount > 0) {
        // Positive amount = Expense
        totalExpense += expense.amount;
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      } else {
        // Negative amount = Income
        totalIncome += expense.amount.abs();
        // Don't add income to category totals for expense breakdown
      }
    }

    // Get top 3 expense categories by spending (exclude income categories)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3Categories = sortedCategories.take(3).map((e) => e.key).toList();

    return {
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'balance': totalIncome - totalExpense,
      'topCategories': top3Categories,
      'categoryTotals': categoryTotals,
      'expenseCount': expenses.where((e) => e.amount > 0).length,
    };
  }

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
  }

  // Calculate today's statistics
  Map<String, dynamic> _calculateTodayStats() {
    final today = DateTime.now();
    final todayExpenses = controller.expenses.where((expense) {
      return expense.date.year == today.year &&
          expense.date.month == today.month &&
          expense.date.day == today.day;
    }).toList();

    return _calculateMonthlyStats(todayExpenses);
  }

  // Calculate this week's statistics
  Map<String, dynamic> _calculateWeeklyStats() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final weekExpenses = controller.expenses.where((expense) {
      return expense.date.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          expense.date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    return _calculateMonthlyStats(weekExpenses);
  }

  // Get expenses based on breakdown type
  List<Expense> _getExpensesByBreakdownType(String breakdownType) {
    final now = DateTime.now();

    switch (breakdownType) {
      case 'today':
        return controller.expenses.where((expense) {
          return expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.day == now.day;
        }).toList();

      case 'weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return controller.expenses.where((expense) {
          return expense.date.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              expense.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

      case 'monthly':
      default:
        return controller.expenses;
    }
  }

  // Get title based on breakdown type
  String _getReportTitle(String breakdownType) {
    switch (breakdownType) {
      case 'today':
        return "Today's Summary Report";
      case 'weekly':
        return "Weekly Summary Report";
      case 'monthly':
      default:
        return 'Monthly Summary Report';
    }
  }

  // PDF-friendly currency format without Unicode symbols
  String _formatCurrencyForPDF(double amount) {
    final currencyService = CurrencyService.instance;
    final currencyCode = currencyService.selectedCurrency.value;
    return '${amount.toStringAsFixed(2)} $currencyCode';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'bills':
      case 'rent':
        return Colors.red;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'healthcare':
        return Colors.green;
      case 'education':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
      case 'rent':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  // Download Methods
  Future<void> _generatePDFReport(String breakdownType) async {
    try {
      final pdf = pw.Document();

      // Get filtered expenses based on breakdown type
      final filteredExpenses = _getExpensesByBreakdownType(breakdownType);
      final groupedExpenses = breakdownType == 'monthly'
          ? _groupExpensesByMonth()
          : {_getReportTitle(breakdownType): filteredExpenses};

      // Calculate overall stats
      double totalExpense = 0.0;
      double totalIncome = 0.0;

      for (var expense in filteredExpenses) {
        if (expense.amount >= 0) {
          totalExpense += expense.amount;
        } else {
          totalIncome += expense.amount.abs();
        }
      }

      final balance = totalIncome - totalExpense;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  _getReportTitle(breakdownType),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Overall Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Overall Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Spent:'),
                        pw.Text(
                          _formatCurrencyForPDF(totalExpense),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Income:'),
                        pw.Text(
                          _formatCurrencyForPDF(totalIncome),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Net Balance:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${balance >= 0 ? '+' : ''}${_formatCurrencyForPDF(balance)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Monthly Breakdown (only for monthly reports)
              if (breakdownType == 'monthly') ...[
                pw.Text(
                  'Monthly Breakdown',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),

                // Add each month's data
                ...groupedExpenses.entries.map((entry) {
                  final stats = _calculateMonthlyStats(entry.value);
                  final totalExp = stats['totalExpense'] as double;
                  final totalInc = stats['totalIncome'] as double;
                  final bal = stats['balance'] as double;
                  final topCategories = stats['topCategories'] as List<String>;
                  final categoryTotals =
                      stats['categoryTotals'] as Map<String, double>;

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          entry.key,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Spent: ${_formatCurrencyForPDF(totalExp)}',
                            ),
                            pw.Text(
                              'Income: ${_formatCurrencyForPDF(totalInc)}',
                            ),
                            pw.Text(
                              'Balance: ${bal >= 0 ? '+' : ''}${_formatCurrencyForPDF(bal)}',
                            ),
                          ],
                        ),
                        if (topCategories.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Top Categories:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 5),
                          ...topCategories.map((cat) {
                            final amount = categoryTotals[cat] ?? 0.0;
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('  • $cat'),
                                  pw.Text(_formatCurrencyForPDF(amount)),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],

              // Footer
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );

      // Show PDF preview/share dialog
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      Get.snackbar(
        'Success',
        'PDF report generated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _generateCSVReport(String breakdownType) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Permission Required',
            'Storage permission is required to save CSV file',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      // Get filtered expenses based on breakdown type
      final filteredExpenses = _getExpensesByBreakdownType(breakdownType);

      List<List<dynamic>> rows = [];

      // Header row
      rows.add(['Date', 'Title', 'Category', 'Amount (BDT)', 'Note']);

      // Add filtered expenses
      for (var expense in filteredExpenses) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(expense.date),
          expense.title,
          expense.category,
          expense.amount.abs().toStringAsFixed(2),
          expense.note ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Get downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePrefix = breakdownType == 'today'
          ? 'Today'
          : breakdownType == 'weekly'
          ? 'Weekly'
          : 'Monthly';
      final fileName =
          'MoneyMate_${filePrefix}_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csv);

      Get.snackbar(
        'Success',
        'CSV report saved to Downloads folder: $fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate CSV: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Breakdown Period',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.today, color: Colors.blue),
                title: const Text("Today's Breakdown"),
                subtitle: const Text('Download today\'s report'),
                onTap: () {
                  Navigator.pop(context);
                  _showFormatOptions('today');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.calendar_view_week,
                  color: Colors.green,
                ),
                title: const Text('Weekly Breakdown'),
                subtitle: const Text('Download this week\'s report'),
                onTap: () {
                  Navigator.pop(context);
                  _showFormatOptions('weekly');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.orange),
                title: const Text('Monthly Breakdown'),
                subtitle: const Text('Download all months report'),
                onTap: () {
                  Navigator.pop(context);
                  _showFormatOptions('monthly');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showFormatOptions(String breakdownType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Download Format',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Download as PDF'),
                subtitle: const Text('Professional formatted report'),
                onTap: () {
                  Navigator.pop(context);
                  _generatePDFReport(breakdownType);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Download as CSV'),
                subtitle: const Text('For Excel or spreadsheet apps'),
                onTap: () {
                  Navigator.pop(context);
                  _generateCSVReport(breakdownType);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyChart() {
    final groupedExpenses = _groupExpensesByMonth();

    if (groupedExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take last 6 months for chart
    final chartData = groupedExpenses.entries
        .take(6)
        .toList()
        .reversed
        .toList();

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY =
        chartData
            .map((e) {
              final stats = _calculateMonthlyStats(e.value);
              return stats['totalExpense'] as double;
            })
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Spending Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          _formatCurrency(rod.toY),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < chartData.length) {
                            final monthKey = chartData[value.toInt()].key;
                            final shortMonth = monthKey
                                .split(' ')[0]
                                .substring(0, 3);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                shortMonth,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: chartData.asMap().entries.map((entry) {
                    final stats = _calculateMonthlyStats(entry.value.value);
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: stats['totalExpense'] as double,
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(String month, List<Expense> expenses) {
    final stats = _calculateMonthlyStats(expenses);
    final totalExpense = stats['totalExpense'] as double;
    final totalIncome = stats['totalIncome'] as double;
    final balance = stats['balance'] as double;
    final topCategories = stats['topCategories'] as List<String>;
    final categoryTotals = stats['categoryTotals'] as Map<String, double>;
    final expenseCount = stats['expenseCount'] as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 16,
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          title: Text(
            month,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$expenseCount expenses',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          children: [
            const Divider(height: 20),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '💸 Spent',
                    _formatCurrency(totalExpense),
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '💰 Income',
                    _formatCurrency(totalIncome),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balance >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: balance >= 0 ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        balance >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: balance >= 0 ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '💵 Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${balance >= 0 ? '+' : ''}${_formatCurrency(balance)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),

            if (topCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Top Categories
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Top Spending Categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...topCategories.map((category) {
                final amount = categoryTotals[category] ?? 0.0;
                final percentage = totalExpense > 0
                    ? (amount / totalExpense * 100).toStringAsFixed(1)
                    : '0.0';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: _getCategoryColor(category),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: double.parse(percentage) / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCategoryColor(category),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBreakdown() {
    final stats = _calculateTodayStats();
    final totalExpense = stats['totalExpense'] as double;
    final totalIncome = stats['totalIncome'] as double;
    final balance = stats['balance'] as double;
    final expenseCount = stats['expenseCount'] as int;

    if (expenseCount == 0 && totalIncome == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  "Today's Breakdown",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '💸 Spent',
                    _formatCurrency(totalExpense),
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '💰 Income',
                    _formatCurrency(totalIncome),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balance >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: balance >= 0 ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💵 Balance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${balance >= 0 ? '+' : ''}${_formatCurrency(balance)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBreakdown() {
    final stats = _calculateWeeklyStats();
    final totalExpense = stats['totalExpense'] as double;
    final totalIncome = stats['totalIncome'] as double;
    final balance = stats['balance'] as double;
    final expenseCount = stats['expenseCount'] as int;

    if (expenseCount == 0 && totalIncome == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Weekly Breakdown",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '💸 Spent',
                    _formatCurrency(totalExpense),
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '💰 Income',
                    _formatCurrency(totalIncome),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balance >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: balance >= 0 ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💵 Balance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${balance >= 0 ? '+' : ''}${_formatCurrency(balance)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummary() {
    if (controller.expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalExpense = 0.0;
    double totalIncome = 0.0;

    for (var expense in controller.expenses) {
      if (expense.amount >= 0) {
        totalExpense += expense.amount;
      } else {
        totalIncome += expense.amount.abs();
      }
    }

    final balance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Overall Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverallStat(
                'Total Spent',
                totalExpense,
                Icons.trending_down,
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildOverallStat('Total Income', totalIncome, Icons.trending_up),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${balance >= 0 ? '+' : ''}${_formatCurrency(balance)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStat(String label, double value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('summary'.tr),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showDownloadOptions,
            icon: const Icon(Icons.download),
            tooltip: 'Download Report',
          ),
          IconButton(
            onPressed: () => controller.fetchExpenses(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start adding expenses to see your monthly summary',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final groupedExpenses = _groupExpensesByMonth();

        return RefreshIndicator(
          onRefresh: () => controller.fetchExpenses(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Summary Card
                _buildOverallSummary(),

                // Spending Trend Chart
                _buildMonthlyChart(),

                // Today's Breakdown
                _buildTodayBreakdown(),

                // Weekly Breakdown
                _buildWeeklyBreakdown(),

                // Monthly Breakdown Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_list,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Monthly Breakdown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Monthly Cards
                ...groupedExpenses.entries.map((entry) {
                  return _buildMonthCard(entry.key, entry.value);
                }).toList(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }
}

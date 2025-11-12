import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../models/expense.dart';
import '../controllers/expense_controller.dart';
import '../services/currency_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final controller = Get.find<ExpenseController>();
  String _selectedPeriod = 'This Month';

  final List<String> _periods = ['This Week', 'This Month', 'Last 30 Days'];

  List<Expense> _getFilteredExpenses() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Last 30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'This Month':
      default:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    return controller.expenses.where((expense) {
      return expense.date.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();
  }

  Map<String, double> _getCategoryTotals() {
    final filteredExpenses = _getFilteredExpenses();
    final Map<String, double> categoryTotals = {};

    for (var expense in filteredExpenses) {
      // Only include expenses (positive amounts), not income
      if (expense.amount > 0) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
    }

    return categoryTotals;
  }

  Map<String, double> _getWeeklyTotals() {
    final filteredExpenses = _getFilteredExpenses();
    final Map<String, double> weeklyTotals = {};

    for (var expense in filteredExpenses) {
      // Only include expenses (positive amounts), not income
      if (expense.amount > 0) {
        String weekKey;
        if (_selectedPeriod == 'This Month' ||
            _selectedPeriod == 'Last 30 Days') {
          // Group by week
          final weekNumber = ((expense.date.day - 1) / 7).floor() + 1;
          weekKey = 'Week $weekNumber';
        } else {
          // Group by day for "This Week"
          weekKey = DateFormat('EEE').format(expense.date);
        }
        weeklyTotals[weekKey] = (weeklyTotals[weekKey] ?? 0) + expense.amount;
      }
    }

    return weeklyTotals;
  }

  // Get daily spending totals (last 7 days)
  Map<String, double> _getDailyTotals() {
    final now = DateTime.now();
    final Map<String, double> dailyTotals = {};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = DateFormat('EEE').format(date); // Mon, Tue, etc.
      dailyTotals[dayKey] = 0.0;
    }

    for (var expense in controller.expenses) {
      if (expense.amount > 0) {
        final daysAgo = now.difference(expense.date).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          final dayKey = DateFormat('EEE').format(expense.date);
          dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + expense.amount;
        }
      }
    }

    return dailyTotals;
  }

  // Get monthly spending totals (last 6 months)
  Map<String, double> _getMonthlyTotals() {
    final now = DateTime.now();
    final Map<String, double> monthlyTotals = {};

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM').format(date); // Jan, Feb, etc.
      monthlyTotals[monthKey] = 0.0;
    }

    for (var expense in controller.expenses) {
      if (expense.amount > 0) {
        final monthKey = DateFormat('MMM').format(expense.date);
        if (monthlyTotals.containsKey(monthKey)) {
          monthlyTotals[monthKey] = monthlyTotals[monthKey]! + expense.amount;
        }
      }
    }

    return monthlyTotals;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'bills':
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

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
  }

  Widget _buildPieChart() {
    final categoryTotals = _getCategoryTotals();

    if (categoryTotals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No expenses to display',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final total = categoryTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: categoryTotals.entries.map((entry) {
                final percentage = (entry.value / total * 100);

                return PieChartSectionData(
                  color: _getCategoryColor(entry.key),
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: categoryTotals.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.key}: ${_formatCurrency(entry.value)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final weeklyTotals = _getWeeklyTotals();

    if (weeklyTotals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No expenses to display',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final maxY = weeklyTotals.values.isEmpty
        ? 100.0
        : weeklyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

    final sortedEntries = weeklyTotals.entries.toList();
    final interval = maxY > 0 ? maxY / 5 : 20.0;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
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
                            value.toInt() < sortedEntries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedEntries[value.toInt()].key,
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
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        final currencyService = CurrencyService.instance;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${currencyService.selectedCurrencySymbol.value}${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 5 : 20.0,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300], strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: Theme.of(context).colorScheme.primary,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBarChart() {
    final dailyTotals = _getDailyTotals();

    if (dailyTotals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No expenses to display',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final maxY = dailyTotals.values.isEmpty
        ? 100.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

    final sortedEntries = dailyTotals.entries.toList();
    final interval = maxY > 0 ? maxY / 5 : 20.0;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
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
                            value.toInt() < sortedEntries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedEntries[value.toInt()].key,
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
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        final currencyService = CurrencyService.instance;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${currencyService.selectedCurrencySymbol.value}${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 5 : 20.0,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300], strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: Colors.blue,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart() {
    final monthlyTotals = _getMonthlyTotals();

    if (monthlyTotals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No expenses to display',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final maxY = monthlyTotals.values.isEmpty
        ? 100.0
        : monthlyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

    final sortedEntries = monthlyTotals.entries.toList();
    final interval = maxY > 0 ? maxY / 5 : 20.0;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
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
                            value.toInt() < sortedEntries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedEntries[value.toInt()].key,
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
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        final currencyService = CurrencyService.instance;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${currencyService.selectedCurrencySymbol.value}${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 5 : 20.0,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300], strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: Colors.orange,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final filteredExpenses = _getFilteredExpenses();
    // Only sum expenses (positive amounts), not income
    final expensesOnly = filteredExpenses.where((e) => e.amount > 0).toList();
    final total = expensesOnly.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final average = expensesOnly.isEmpty ? 0.0 : total / expensesOnly.length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              _selectedPeriod,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Total Spent',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Column(
                  children: [
                    const Text(
                      'Average',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(average),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Column(
                  children: [
                    const Text(
                      'Expenses',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expensesOnly.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => controller.fetchExpenses(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => controller.fetchExpenses(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Selector
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SegmentedButton<String>(
                            segments: _periods.map((period) {
                              return ButtonSegment<String>(
                                value: period,
                                label: Text(period),
                              );
                            }).toList(),
                            selected: {_selectedPeriod},
                            onSelectionChanged: (Set<String> selected) {
                              setState(() {
                                _selectedPeriod = selected.first;
                              });
                            },
                          ),
                        ),
                      ),

                      // Summary Card
                      _buildSummaryCard(),

                      // Category Distribution Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.pie_chart,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Category Distribution',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildPieChart(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Daily Spending Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Daily Spending (Last 7 Days)',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildDailyBarChart(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Weekly Spending Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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
                                Text(
                                  _selectedPeriod == 'This Week'
                                      ? 'Daily Spending (This Week)'
                                      : 'Weekly Spending',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildBarChart(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Monthly Spending Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Monthly Spending (Last 6 Months)',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildMonthlyBarChart(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

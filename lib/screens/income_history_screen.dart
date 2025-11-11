import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../models/expense.dart';
import '../controllers/expense_controller.dart';
import '../services/currency_service.dart';
import 'expense_detail_screen.dart';

class IncomeHistoryScreen extends StatefulWidget {
  const IncomeHistoryScreen({super.key});

  @override
  State<IncomeHistoryScreen> createState() => _IncomeHistoryScreenState();
}

class _IncomeHistoryScreenState extends State<IncomeHistoryScreen> {
  final controller = Get.find<ExpenseController>();
  List<Expense> _filteredIncomes = [];

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _filterIncomes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterIncomes() {
    String searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredIncomes = controller.expenses.where((expense) {
        // Only show income (negative amounts), not expenses
        if (expense.amount >= 0) return false;

        // Search filter
        bool matchesSearch =
            searchQuery.isEmpty ||
            expense.title.toLowerCase().contains(searchQuery) ||
            expense.category.toLowerCase().contains(searchQuery);

        // Date range filter
        bool matchesDateRange = true;
        if (_startDate != null && _endDate != null) {
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          final start = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
          matchesDateRange =
              expenseDate.isAfter(start.subtract(const Duration(days: 1))) &&
              expenseDate.isBefore(end.add(const Duration(days: 1)));
        }

        return matchesSearch && matchesDateRange;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterIncomes();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _filterIncomes();
  }

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.work;
      case 'business':
        return Icons.business;
      case 'investment':
        return Icons.trending_up;
      case 'freelance':
        return Icons.laptop;
      case 'gift':
        return Icons.card_giftcard;
      case 'bonus':
        return Icons.stars;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Colors.green;
      case 'business':
        return Colors.blue;
      case 'investment':
        return Colors.purple;
      case 'freelance':
        return Colors.orange;
      case 'gift':
        return Colors.pink;
      case 'bonus':
        return Colors.amber;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('income_history'.tr),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(() {
        // Trigger rebuild when expenses change
        controller.expenses.length;

        return Column(
          children: [
            // Search and Filter Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'search_incomes'.tr,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterIncomes();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => _filterIncomes(),
                  ),
                  const SizedBox(height: 12),

                  // Filter Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _startDate != null && _endDate != null
                                ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                                : 'date_range'.tr,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_startDate != null && _endDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear filter',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Summary Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_filteredIncomes.length} ${'incomes'.tr}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'total_income'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Total: ${_formatCurrency(_filteredIncomes.fold(0.0, (sum, income) => sum + income.amount.abs()))}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Income List
            Expanded(
              child: _filteredIncomes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money_off,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_incomes_found'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'try_different_filter'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredIncomes.length,
                      itemBuilder: (context, index) {
                        final income = _filteredIncomes[index];

                        return Dismissible(
                          key: Key(income.id.toString()),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Income'),
                                  content: Text(
                                    'Are you sure you want to delete "${income.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('DELETE'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) async {
                            await controller.deleteExpense(income.id!);
                            _filterIncomes();
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Get.to(
                                  () => ExpenseDetailScreen(expense: income),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Row: Avatar, Title, Amount
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _getCategoryColor(
                                            income.category,
                                          ).withOpacity(0.2),
                                          child: Icon(
                                            _getCategoryIcon(income.category),
                                            color: _getCategoryColor(
                                              income.category,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                income.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.category,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    income.category.tr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      _formatDate(income.date),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatCurrency(income.amount.abs()),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Note if available
                                    if (income.note != null &&
                                        income.note!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        income.note!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

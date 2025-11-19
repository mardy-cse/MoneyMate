import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import '../widgets/custom_search_bar.dart';
import 'debt_details_screen.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Debt> _lentDebts = [];
  List<Debt> _borrowedDebts = [];
  List<Debt> _filteredLentDebts = [];
  List<Debt> _filteredBorrowedDebts = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  double _totalLent = 0.0;
  double _totalBorrowed = 0.0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Refresh UI when tab changes
    });
    _searchController.addListener(() {
      setState(() {}); // Refresh UI to show/hide clear button
    });
    _loadDebts();
    _checkAndSyncFromFirebase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Check if we need to sync from Firebase (only once per session or if local DB is empty)
  Future<void> _checkAndSyncFromFirebase() async {
    final db = DatabaseHelper();
    final debts = await db.getDebts();

    // If local database is empty, sync from Firebase
    if (debts.isEmpty) {
      setState(() => _isSyncing = true);
      await db.syncDebtsFromFirebase();
      setState(() => _isSyncing = false);
      _loadDebts();
    }
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);

    final db = DatabaseHelper();

    // Load from local database
    final lent = await db.getDebtsByType('lent');
    final borrowed = await db.getDebtsByType('borrowed');
    final totalLent = await db.getTotalLentAmount();
    final totalBorrowed = await db.getTotalBorrowedAmount();

    setState(() {
      _lentDebts = lent;
      _borrowedDebts = borrowed;
      _filteredLentDebts = lent;
      _filteredBorrowedDebts = borrowed;
      _totalLent = totalLent;
      _totalBorrowed = totalBorrowed;
      _isLoading = false;
    });
  }

  void _filterDebts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLentDebts = _lentDebts;
        _filteredBorrowedDebts = _borrowedDebts;
      } else {
        _filteredLentDebts = _lentDebts.where((debt) {
          return debt.personName.toLowerCase().contains(query.toLowerCase()) ||
              (debt.phoneNumber?.contains(query) ?? false) ||
              (debt.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();

        _filteredBorrowedDebts = _borrowedDebts.where((debt) {
          return debt.personName.toLowerCase().contains(query.toLowerCase()) ||
              (debt.phoneNumber?.contains(query) ?? false) ||
              (debt.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  // Manual sync from Firebase
  Future<void> _syncFromFirebase() async {
    setState(() => _isSyncing = true);

    final db = DatabaseHelper();
    await db.syncDebtsFromFirebase();
    await _loadDebts();

    setState(() => _isSyncing = false);

    Get.snackbar(
      'Success',
      'Synced from cloud successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  String _formatCurrency(double amount) {
    return CurrencyService().formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt/Loan Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              tooltip: 'Sync from Cloud',
              onPressed: _syncFromFirebase,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Custom Tab Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _tabController.animateTo(0);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _tabController.index == 0
                                  ? const Color(0xFF5F7A8F)
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _tabController.index == 0
                                    ? const Color(0xFF5F7A8F)
                                    : Theme.of(context).brightness ==
                                          Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: _tabController.index == 0
                                      ? Colors.white
                                      : Theme.of(context).brightness ==
                                            Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  size: 20,
                                ),
                                Text(
                                  'Money Lent',
                                  style: TextStyle(
                                    color: _tabController.index == 0
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(_totalLent),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _tabController.index == 0
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _tabController.animateTo(1);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _tabController.index == 1
                                  ? const Color(0xFF5F7A8F)
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _tabController.index == 1
                                    ? const Color(0xFF5F7A8F)
                                    : Theme.of(context).brightness ==
                                          Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: _tabController.index == 1
                                      ? Colors.white
                                      : Theme.of(context).brightness ==
                                            Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  size: 20,
                                ),
                                Text(
                                  'Money Borrowed',
                                  style: TextStyle(
                                    color: _tabController.index == 1
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(_totalBorrowed),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _tabController.index == 1
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search Bar
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search by name, phone or description...',
                  onChanged: _filterDebts,
                ),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtList(_filteredLentDebts, 'lent'),
                      _buildDebtList(_filteredBorrowedDebts, 'borrowed'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt/Loan'),
      ),
    );
  }

  Widget _buildDebtList(List<Debt> debts, String type) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'lent' ? Icons.person_add : Icons.account_balance_wallet,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'lent'
                  ? 'No money lent to anyone'
                  : 'No money borrowed from anyone',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + button to add',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDebts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: debts.length,
        itemBuilder: (context, index) {
          final debt = debts[index];
          return _buildDebtCard(debt);
        },
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final color = debt.type == 'lent' ? Colors.green : Colors.orange;
    final progress = debt.progressPercentage / 100;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: debt.isOverdue ? Colors.red : color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showDebtDetails(debt),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      debt.type == 'lent'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (debt.phoneNumber != null)
                          Text(
                            debt.phoneNumber!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(debt.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      debt.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(debt.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatCurrency(debt.amount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatCurrency(debt.remainingAmount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: debt.isCompleted ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(
                  debt.isCompleted ? Colors.green : color,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${debt.progressPercentage.toStringAsFixed(0)}% Paid',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (debt.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          debt.isOverdue ? Icons.warning : Icons.calendar_today,
                          size: 14,
                          color: debt.isOverdue ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(debt.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: debt.isOverdue
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: debt.isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (debt.description != null && debt.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  debt.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAddDebtDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'lent';
    DateTime selectedDate = DateTime.now();
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Debt/Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'lent',
                      label: Text('Money Lent'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: 'borrowed',
                      label: Text('Money Borrowed'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Person Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Due Date (Optional)'),
                  subtitle: Text(
                    selectedDueDate != null
                        ? DateFormat('MMM d, yyyy').format(selectedDueDate!)
                        : 'Not set',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() => selectedDueDate = null);
                          },
                        ),
                      const Icon(Icons.edit),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          selectedDueDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  Get.snackbar('Error', 'Please fill required fields');
                  return;
                }

                final debt = Debt(
                  personName: nameController.text,
                  amount: double.parse(amountController.text),
                  type: selectedType,
                  description: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  date: selectedDate,
                  dueDate: selectedDueDate,
                  phoneNumber: phoneController.text.isNotEmpty
                      ? phoneController.text
                      : null,
                  createdAt: DateTime.now(),
                );

                await DatabaseHelper().insertDebt(debt);
                Navigator.pop(context);
                _loadDebts();

                Get.snackbar(
                  'Success',
                  'Debt added successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebtDetails(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DebtDetailsScreen(debt: debt)),
    ).then((_) => _loadDebts());
  }
}

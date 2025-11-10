class Budget {
  final int? id;
  final String category;
  final double amount;
  final String period; // 'monthly', 'weekly'
  final DateTime createdAt;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.period,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: map['amount'] as double,
      period: map['period'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class SavingGoal {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final DateTime createdAt;

  SavingGoal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: map['id'] as int?,
      title: map['title'] as String,
      targetAmount: map['targetAmount'] as double,
      currentAmount: map['currentAmount'] as double? ?? 0.0,
      deadline: DateTime.parse(map['deadline'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Calculate weekly savings required
  double getWeeklySavingsRequired() {
    final remaining = targetAmount - currentAmount;
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    final weeksLeft = (daysLeft / 7).ceil();

    if (weeksLeft <= 0) return remaining;
    return remaining / weeksLeft;
  }

  // Calculate progress percentage
  double getProgress() {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }
}

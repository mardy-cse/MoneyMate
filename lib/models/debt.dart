class Debt {
  final int? id;
  final String personName;
  final double amount;
  final double paidAmount;
  final String type; // 'lent' or 'borrowed'
  final String? description;
  final DateTime date;
  final DateTime? dueDate;
  final String? phoneNumber;
  final String status; // 'pending', 'partial', 'completed'
  final DateTime createdAt;

  Debt({
    this.id,
    required this.personName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.type,
    this.description,
    required this.date,
    this.dueDate,
    this.phoneNumber,
    this.status = 'pending',
    required this.createdAt,
  });

  double get remainingAmount => amount - paidAmount;
  double get progressPercentage => amount > 0 ? (paidAmount / amount * 100) : 0;
  bool get isCompleted => paidAmount >= amount;
  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isCompleted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      personName: map['personName'] as String,
      amount: map['amount'] as double,
      paidAmount: map['paidAmount'] as double? ?? 0.0,
      type: map['type'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      phoneNumber: map['phoneNumber'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Debt copyWith({
    int? id,
    String? personName,
    double? amount,
    double? paidAmount,
    String? type,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    String? phoneNumber,
    String? status,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime paymentDate;
  final String? note;
  final DateTime createdAt;

  DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as int?,
      debtId: map['debtId'] as int,
      amount: map['amount'] as double,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  DebtPayment copyWith({
    int? id,
    int? debtId,
    double? amount,
    DateTime? paymentDate,
    String? note,
    DateTime? createdAt,
  }) {
    return DebtPayment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

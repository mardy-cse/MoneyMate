class Expense {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String? voiceNotePath;
  final String? imagePath; // Image memo path

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.voiceNotePath,
    this.imagePath,
  });

  // Convert Expense object to Map for SQLite database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'voiceNotePath': voiceNotePath,
      'imagePath': imagePath,
    };
  }

  // Create Expense object from Map (from SQLite database)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      voiceNotePath: map['voiceNotePath'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }

  // Optional: Override toString for debugging
  @override
  String toString() {
    return 'Expense{id: $id, title: $title, amount: $amount, category: $category, date: $date, note: $note, voiceNotePath: $voiceNotePath, imagePath: $imagePath}';
  }

  // Optional: Create a copy of Expense with updated fields
  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? voiceNotePath,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
    );
  }
}

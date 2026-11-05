class Expense {
  final int? id; // null until the database assigns it
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Other',
  ];

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  // Used by the SQLite helper in hour 1-3
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }
}

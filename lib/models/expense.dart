import 'package:hive/hive.dart';

enum ExpenseOrigin { manual, import }

class Expense {
  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.cardId,
    this.origin = ExpenseOrigin.manual,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String? cardId;
  final ExpenseOrigin origin;

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? cardId,
    ExpenseOrigin? origin,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      cardId: cardId ?? this.cardId,
      origin: origin ?? this.origin,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'categoryId': categoryId,
        'cardId': cardId,
        'origin': origin.name,
      };

  factory Expense.fromMap(Map<dynamic, dynamic> map) => Expense(
        id: map['id'] as String,
        description: map['description'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        categoryId: map['categoryId'] as String,
        cardId: map['cardId'] as String?,
        origin: ExpenseOrigin.values.firstWhere(
          (e) => e.name == map['origin'],
          orElse: () => ExpenseOrigin.manual,
        ),
      );
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 2;

  @override
  Expense read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Expense.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeMap(obj.toMap());
  }
}

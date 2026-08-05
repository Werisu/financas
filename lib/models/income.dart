import 'package:hive/hive.dart';

class IncomeTypes {
  static const salary = 'Salário';
  static const benefit = 'Benefício';
  static const maxim = 'Maxim';
  static const freelance = 'Freelance';
  static const other = 'Outros';

  static const all = [salary, benefit, maxim, freelance, other];
}

class Income {
  Income({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String type;

  Income copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? type,
  }) {
    return Income(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type,
      };

  factory Income.fromMap(Map<dynamic, dynamic> map) => Income(
        id: map['id'] as String,
        description: map['description'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        type: (map['type'] as String?) ?? IncomeTypes.other,
      );
}

class IncomeAdapter extends TypeAdapter<Income> {
  @override
  final int typeId = 4;

  @override
  Income read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Income.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Income obj) {
    writer.writeMap(obj.toMap());
  }
}

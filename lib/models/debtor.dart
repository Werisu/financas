import 'package:hive/hive.dart';

class Debtor {
  Debtor({
    required this.id,
    required this.name,
    required this.amountOwed,
    this.notes,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final double amountOwed;
  final String? notes;
  final DateTime updatedAt;

  Debtor copyWith({
    String? id,
    String? name,
    double? amountOwed,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Debtor(
      id: id ?? this.id,
      name: name ?? this.name,
      amountOwed: amountOwed ?? this.amountOwed,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amountOwed': amountOwed,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Debtor.fromMap(Map<dynamic, dynamic> map) => Debtor(
        id: map['id'] as String,
        name: map['name'] as String,
        amountOwed: (map['amountOwed'] as num).toDouble(),
        notes: map['notes'] as String?,
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class DebtorAdapter extends TypeAdapter<Debtor> {
  @override
  final int typeId = 3;

  @override
  Debtor read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Debtor.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Debtor obj) {
    writer.writeMap(obj.toMap());
  }
}

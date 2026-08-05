import 'package:hive/hive.dart';

/// Pagamento (total ou parcial) de uma fatura de cartão.
class CardPayment {
  CardPayment({
    required this.id,
    required this.cardId,
    required this.amount,
    required this.date,
    required this.statementMonth,
    this.notes,
  });

  final String id;
  final String cardId;
  final double amount;

  /// Data em que o pagamento foi feito.
  final DateTime date;

  /// Mês de vencimento da fatura paga (ano/mês).
  final DateTime statementMonth;

  final String? notes;

  DateTime get billingMonth =>
      DateTime(statementMonth.year, statementMonth.month);

  CardPayment copyWith({
    String? id,
    String? cardId,
    double? amount,
    DateTime? date,
    DateTime? statementMonth,
    String? notes,
  }) {
    return CardPayment(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      statementMonth: statementMonth ?? this.statementMonth,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'cardId': cardId,
        'amount': amount,
        'date': date.toIso8601String(),
        'statementMonth': statementMonth.toIso8601String(),
        'notes': notes,
      };

  factory CardPayment.fromMap(Map<dynamic, dynamic> map) => CardPayment(
        id: map['id'] as String,
        cardId: map['cardId'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        statementMonth: DateTime.parse(map['statementMonth'] as String),
        notes: map['notes'] as String?,
      );
}

class CardPaymentAdapter extends TypeAdapter<CardPayment> {
  @override
  final int typeId = 5;

  @override
  CardPayment read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return CardPayment.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, CardPayment obj) {
    writer.writeMap(obj.toMap());
  }
}

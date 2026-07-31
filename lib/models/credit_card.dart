import 'package:hive/hive.dart';

class CreditCard {
  CreditCard({
    required this.id,
    required this.name,
    this.nickname,
    this.closingDay,
  });

  final String id;
  final String name;
  final String? nickname;
  final int? closingDay;

  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : name;

  CreditCard copyWith({
    String? id,
    String? name,
    String? nickname,
    int? closingDay,
  }) {
    return CreditCard(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      closingDay: closingDay ?? this.closingDay,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'closingDay': closingDay,
      };

  factory CreditCard.fromMap(Map<dynamic, dynamic> map) => CreditCard(
        id: map['id'] as String,
        name: map['name'] as String,
        nickname: map['nickname'] as String?,
        closingDay: map['closingDay'] as int?,
      );
}

class CreditCardAdapter extends TypeAdapter<CreditCard> {
  @override
  final int typeId = 1;

  @override
  CreditCard read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return CreditCard.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, CreditCard obj) {
    writer.writeMap(obj.toMap());
  }
}

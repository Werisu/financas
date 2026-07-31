import 'package:flutter/material.dart';
import 'package:financas/utils/category_icons.dart';
import 'package:hive/hive.dart';

class Category {
  Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;

  IconData get icon => CategoryIcons.resolve(iconKey);
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
      };

  factory Category.fromMap(Map<dynamic, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconKey: (map['iconKey'] as String?) ?? 'more',
      colorValue: map['colorValue'] as int,
    );
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 0;

  @override
  Category read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Category.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeMap(obj.toMap());
  }
}

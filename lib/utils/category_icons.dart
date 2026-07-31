import 'package:flutter/material.dart';

class CategoryIcons {
  static const Map<String, IconData> byName = {
    'shopping_cart': Icons.shopping_cart_outlined,
    'hospital': Icons.local_hospital_outlined,
    'car': Icons.directions_car_outlined,
    'home': Icons.home_outlined,
    'games': Icons.sports_esports_outlined,
    'school': Icons.school_outlined,
    'restaurant': Icons.restaurant_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    'more': Icons.more_horiz,
    'pets': Icons.pets_outlined,
    'fitness': Icons.fitness_center_outlined,
    'flight': Icons.flight_outlined,
  };

  static IconData resolve(String key) => byName[key] ?? Icons.category_outlined;

  static String keyFromIcon(IconData icon) {
    for (final entry in byName.entries) {
      if (entry.value.codePoint == icon.codePoint) return entry.key;
    }
    return 'more';
  }
}

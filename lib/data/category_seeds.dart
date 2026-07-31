import 'package:flutter/material.dart';
import 'package:financas/models/category.dart';

class CategorySeeds {
  static List<Category> defaults() => [
        Category(
          id: 'cat_supermercado',
          name: 'Supermercado',
          iconKey: 'shopping_cart',
          colorValue: const Color(0xFF2A9D8F).toARGB32(),
        ),
        Category(
          id: 'cat_saude',
          name: 'Saúde',
          iconKey: 'hospital',
          colorValue: const Color(0xFFE76F51).toARGB32(),
        ),
        Category(
          id: 'cat_transportes',
          name: 'Transportes',
          iconKey: 'car',
          colorValue: const Color(0xFF457B9D).toARGB32(),
        ),
        Category(
          id: 'cat_moradia',
          name: 'Moradia',
          iconKey: 'home',
          colorValue: const Color(0xFF6D597A).toARGB32(),
        ),
        Category(
          id: 'cat_lazer',
          name: 'Lazer',
          iconKey: 'games',
          colorValue: const Color(0xFFF4A261).toARGB32(),
        ),
        Category(
          id: 'cat_educacao',
          name: 'Educação',
          iconKey: 'school',
          colorValue: const Color(0xFF264653).toARGB32(),
        ),
        Category(
          id: 'cat_restaurantes',
          name: 'Restaurantes',
          iconKey: 'restaurant',
          colorValue: const Color(0xFFE9C46A).toARGB32(),
        ),
        Category(
          id: 'cat_assinaturas',
          name: 'Assinaturas',
          iconKey: 'subscriptions',
          colorValue: const Color(0xFF1D3557).toARGB32(),
        ),
        Category(
          id: 'cat_outros',
          name: 'Outros',
          iconKey: 'more',
          colorValue: const Color(0xFF8D99AE).toARGB32(),
        ),
      ];
}

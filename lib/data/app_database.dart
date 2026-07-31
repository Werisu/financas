import 'package:financas/data/category_seeds.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/credit_card.dart';
import 'package:financas/models/expense.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const categories = 'categories';
  static const cards = 'credit_cards';
  static const expenses = 'expenses';
  static const meta = 'meta';
}

class AppDatabase {
  AppDatabase._();

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ExpenseAdapter());
    }

    await Future.wait([
      Hive.openBox<Category>(HiveBoxes.categories),
      Hive.openBox<CreditCard>(HiveBoxes.cards),
      Hive.openBox<Expense>(HiveBoxes.expenses),
      Hive.openBox(HiveBoxes.meta),
    ]);

    await _seedCategoriesIfNeeded();
  }

  static Future<void> _seedCategoriesIfNeeded() async {
    final meta = Hive.box(HiveBoxes.meta);
    final categories = Hive.box<Category>(HiveBoxes.categories);
    if (meta.get('categoriesSeeded') == true && categories.isNotEmpty) {
      return;
    }
    for (final category in CategorySeeds.defaults()) {
      await categories.put(category.id, category);
    }
    await meta.put('categoriesSeeded', true);
  }

  static Box<Category> get categories =>
      Hive.box<Category>(HiveBoxes.categories);
  static Box<CreditCard> get cards => Hive.box<CreditCard>(HiveBoxes.cards);
  static Box<Expense> get expenses => Hive.box<Expense>(HiveBoxes.expenses);
}

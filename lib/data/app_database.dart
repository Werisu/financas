import 'package:financas/data/category_seeds.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/credit_card.dart';
import 'package:financas/models/debtor.dart';
import 'package:financas/models/expense.dart';
import 'package:financas/models/income.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const categories = 'categories';
  static const cards = 'credit_cards';
  static const expenses = 'expenses';
  static const debtors = 'debtors';
  static const incomes = 'incomes';
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
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DebtorAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(IncomeAdapter());
    }

    await Future.wait([
      Hive.openBox<Category>(HiveBoxes.categories),
      Hive.openBox<CreditCard>(HiveBoxes.cards),
      Hive.openBox<Expense>(HiveBoxes.expenses),
      Hive.openBox<Debtor>(HiveBoxes.debtors),
      Hive.openBox<Income>(HiveBoxes.incomes),
      Hive.openBox(HiveBoxes.meta),
    ]);
  }

  static Future<void> clearUserData() async {
    await categories.clear();
    await cards.clear();
    await expenses.clear();
    await debtors.clear();
    await incomes.clear();
  }

  static Future<void> replaceAll({
    required List<Category> categories,
    required List<CreditCard> cards,
    required List<Expense> expenses,
    required List<Debtor> debtors,
    required List<Income> incomes,
  }) async {
    await clearUserData();
    await AppDatabase.categories.putAll({
      for (final item in categories) item.id: item,
    });
    await AppDatabase.cards.putAll({
      for (final item in cards) item.id: item,
    });
    await AppDatabase.expenses.putAll({
      for (final item in expenses) item.id: item,
    });
    await AppDatabase.debtors.putAll({
      for (final item in debtors) item.id: item,
    });
    await AppDatabase.incomes.putAll({
      for (final item in incomes) item.id: item,
    });
  }

  static Future<void> seedLocalCategoriesIfEmpty() async {
    if (categories.isNotEmpty) return;
    for (final category in CategorySeeds.defaults()) {
      await categories.put(category.id, category);
    }
  }

  static Box<Category> get categories =>
      Hive.box<Category>(HiveBoxes.categories);
  static Box<CreditCard> get cards => Hive.box<CreditCard>(HiveBoxes.cards);
  static Box<Expense> get expenses => Hive.box<Expense>(HiveBoxes.expenses);
  static Box<Debtor> get debtors => Hive.box<Debtor>(HiveBoxes.debtors);
  static Box<Income> get incomes => Hive.box<Income>(HiveBoxes.incomes);
}

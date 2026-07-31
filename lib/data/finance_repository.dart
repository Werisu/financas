import 'package:financas/data/app_database.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/credit_card.dart';
import 'package:financas/models/expense.dart';

class FinanceRepository {
  List<Category> getCategories() {
    final items = AppDatabase.categories.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<void> saveCategory(Category category) async {
    await AppDatabase.categories.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await AppDatabase.categories.delete(id);
  }

  List<CreditCard> getCards() {
    final items = AppDatabase.cards.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return items;
  }

  Future<void> saveCard(CreditCard card) async {
    await AppDatabase.cards.put(card.id, card);
  }

  Future<void> deleteCard(String id) async {
    await AppDatabase.cards.delete(id);
  }

  List<Expense> getExpenses() {
    final items = AppDatabase.expenses.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> saveExpense(Expense expense) async {
    await AppDatabase.expenses.put(expense.id, expense);
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final entries = {for (final e in expenses) e.id: e};
    await AppDatabase.expenses.putAll(entries);
  }

  Future<void> deleteExpense(String id) async {
    await AppDatabase.expenses.delete(id);
  }
}

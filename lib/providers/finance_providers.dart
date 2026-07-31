import 'package:financas/data/finance_repository.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/credit_card.dart';
import 'package:financas/models/expense.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final repositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  return CategoriesNotifier(ref.watch(repositoryProvider));
});

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier(this._repo) : super([]) {
    refresh();
  }

  final FinanceRepository _repo;

  void refresh() => state = _repo.getCategories();

  Future<void> save(Category category) async {
    await _repo.saveCategory(category);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteCategory(id);
    refresh();
  }
}

final cardsProvider =
    StateNotifierProvider<CardsNotifier, List<CreditCard>>((ref) {
  return CardsNotifier(ref.watch(repositoryProvider));
});

class CardsNotifier extends StateNotifier<List<CreditCard>> {
  CardsNotifier(this._repo) : super([]) {
    refresh();
  }

  final FinanceRepository _repo;

  void refresh() => state = _repo.getCards();

  Future<void> save(CreditCard card) async {
    await _repo.saveCard(card);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteCard(id);
    refresh();
  }
}

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier(ref.watch(repositoryProvider));
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier(this._repo) : super([]) {
    refresh();
  }

  final FinanceRepository _repo;

  void refresh() => state = _repo.getExpenses();

  Future<void> save(Expense expense) async {
    await _repo.saveExpense(expense);
    refresh();
  }

  Future<void> saveAll(List<Expense> expenses) async {
    await _repo.saveExpenses(expenses);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteExpense(id);
    refresh();
  }
}

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final expenseFilterCategoryProvider = StateProvider<String?>((ref) => null);
final expenseFilterCardProvider = StateProvider<String?>((ref) => null);

final monthExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final month = ref.watch(selectedMonthProvider);
  return expenses.where((expense) => isSameMonth(expense.date, month)).toList();
});

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(monthExpensesProvider);
  final categoryId = ref.watch(expenseFilterCategoryProvider);
  final cardId = ref.watch(expenseFilterCardProvider);

  return expenses.where((expense) {
    if (categoryId != null && expense.categoryId != categoryId) return false;
    if (cardId != null && expense.cardId != cardId) return false;
    return true;
  }).toList();
});

class CategoryTotal {
  CategoryTotal({required this.category, required this.total});

  final Category category;
  final double total;
}

final monthlyTotalsProvider = Provider<List<CategoryTotal>>((ref) {
  final expenses = ref.watch(monthExpensesProvider);
  final categories = ref.watch(categoriesProvider);
  final map = <String, double>{};

  for (final expense in expenses) {
    map[expense.categoryId] = (map[expense.categoryId] ?? 0) + expense.amount;
  }

  final totals = <CategoryTotal>[];
  for (final entry in map.entries) {
    final category = categories.where((c) => c.id == entry.key);
    if (category.isEmpty) continue;
    totals.add(CategoryTotal(category: category.first, total: entry.value));
  }

  totals.sort((a, b) => b.total.compareTo(a.total));
  return totals;
});

final monthlyTotalAmountProvider = Provider<double>((ref) {
  return ref.watch(monthExpensesProvider).fold(0.0, (sum, e) => sum + e.amount);
});

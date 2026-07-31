import 'package:financas/data/finance_repository.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/credit_card.dart';
import 'package:financas/models/debtor.dart';
import 'package:financas/models/expense.dart';
import 'package:financas/models/income.dart';
import 'package:financas/services/auth_service.dart';
import 'package:financas/services/firestore_sync_service.dart';
import 'package:financas/utils/formatters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final repositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

final sessionReadyProvider = FutureProvider<User?>((ref) async {
  final auth = ref.watch(authStateProvider);
  final user = auth.asData?.value;
  final repo = ref.read(repositoryProvider);

  if (user == null) {
    await repo.unbindUser();
    return null;
  }

  await repo.bindUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );
  return user;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = await ref.watch(sessionReadyProvider.future);
  if (session == null) return null;
  final profile = await ref.read(repositoryProvider).fetchProfile();
  if (profile != null) return profile;
  return UserProfile(
    uid: session.uid,
    email: session.email,
    displayName: session.displayName,
    photoUrl: session.photoURL,
  );
});

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  ref.watch(sessionReadyProvider);
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
  ref.watch(sessionReadyProvider);
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
  ref.watch(sessionReadyProvider);
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

  Future<void> resetAll() async {
    await _repo.resetAllAccounts();
    refresh();
  }
}

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// true = visão por fatura (vencimento); false = mês da compra
final invoiceViewProvider = StateProvider<bool>((ref) => true);

final expenseFilterCategoryProvider = StateProvider<String?>((ref) => null);
final expenseFilterCardProvider = StateProvider<String?>((ref) => null);
final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

final monthExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final month = ref.watch(selectedMonthProvider);
  final invoiceView = ref.watch(invoiceViewProvider);

  return expenses.where((expense) {
    final refMonth =
        invoiceView ? expense.billingMonth : DateTime(expense.date.year, expense.date.month);
    return isSameMonth(refMonth, month);
  }).toList();
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

/// Lista da tela de Gastos: com busca, procura em todos os meses.
final expensesListProvider = Provider<List<Expense>>((ref) {
  final query = ref.watch(expenseSearchQueryProvider).trim().toLowerCase();
  final categoryId = ref.watch(expenseFilterCategoryProvider);
  final cardId = ref.watch(expenseFilterCardProvider);
  final expenses = query.isEmpty
      ? ref.watch(monthExpensesProvider)
      : ref.watch(expensesProvider);

  final filtered = expenses.where((expense) {
    if (categoryId != null && expense.categoryId != categoryId) return false;
    if (cardId != null && expense.cardId != cardId) return false;
    if (query.isNotEmpty &&
        !expense.description.toLowerCase().contains(query)) {
      return false;
    }
    return true;
  }).toList();

  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

final statementNewPurchasesProvider = Provider<List<Expense>>((ref) {
  return ref
      .watch(filteredExpensesProvider)
      .where((e) => e.isNewPurchaseOnStatement)
      .toList();
});

final statementCarryoversProvider = Provider<List<Expense>>((ref) {
  return ref
      .watch(filteredExpensesProvider)
      .where((e) => e.isCarryoverInstallment)
      .toList();
});

final statementNewPurchasesTotalProvider = Provider<double>((ref) {
  return ref
      .watch(statementNewPurchasesProvider)
      .fold(0.0, (sum, e) => sum + e.amount);
});

final statementCarryoversTotalProvider = Provider<double>((ref) {
  return ref
      .watch(statementCarryoversProvider)
      .fold(0.0, (sum, e) => sum + e.amount);
});

class CategoryTotal {
  CategoryTotal({required this.category, required this.total});

  final Category category;
  final double total;
}

final monthlyTotalsProvider = Provider<List<CategoryTotal>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
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
  return ref.watch(filteredExpensesProvider).fold(0.0, (sum, e) => sum + e.amount);
});

final debtorsProvider =
    StateNotifierProvider<DebtorsNotifier, List<Debtor>>((ref) {
  ref.watch(sessionReadyProvider);
  return DebtorsNotifier(ref.watch(repositoryProvider));
});

class DebtorsNotifier extends StateNotifier<List<Debtor>> {
  DebtorsNotifier(this._repo) : super([]) {
    refresh();
  }

  final FinanceRepository _repo;

  void refresh() => state = _repo.getDebtors();

  Future<void> save(Debtor debtor) async {
    await _repo.saveDebtor(debtor);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteDebtor(id);
    refresh();
  }
}

final debtorRankingProvider = Provider<List<Debtor>>((ref) {
  final debtors = ref.watch(debtorsProvider);
  return debtors.where((d) => d.amountOwed > 0).toList();
});

final debtorTotalOwedProvider = Provider<double>((ref) {
  return ref
      .watch(debtorRankingProvider)
      .fold(0.0, (sum, d) => sum + d.amountOwed);
});

final incomesProvider =
    StateNotifierProvider<IncomesNotifier, List<Income>>((ref) {
  ref.watch(sessionReadyProvider);
  return IncomesNotifier(ref.watch(repositoryProvider));
});

class IncomesNotifier extends StateNotifier<List<Income>> {
  IncomesNotifier(this._repo) : super([]) {
    refresh();
  }

  final FinanceRepository _repo;

  void refresh() => state = _repo.getIncomes();

  Future<void> save(Income income) async {
    await _repo.saveIncome(income);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteIncome(id);
    refresh();
  }
}

final monthIncomesProvider = Provider<List<Income>>((ref) {
  final incomes = ref.watch(incomesProvider);
  final month = ref.watch(selectedMonthProvider);
  return incomes
      .where((income) => isSameMonth(income.date, month))
      .toList();
});

final monthlyIncomeTotalProvider = Provider<double>((ref) {
  return ref
      .watch(monthIncomesProvider)
      .fold(0.0, (sum, i) => sum + i.amount);
});

import 'package:financas/data/app_database.dart';
import 'package:financas/data/category_seeds.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/credit_card.dart';
import 'package:financas/models/debtor.dart';
import 'package:financas/models/expense.dart';
import 'package:financas/models/income.dart';
import 'package:financas/services/firestore_sync_service.dart';

class FinanceRepository {
  FinanceRepository({FirestoreSyncService? syncService})
      : _sync = syncService ?? FirestoreSyncService();

  final FirestoreSyncService _sync;
  String? _uid;

  String? get uid => _uid;
  bool get isSynced => _uid != null;

  Future<void> bindUser({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    _uid = uid;
    await _sync.ensureUserProfile(
      UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      ),
    );
    await syncFromCloud();
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoBase64,
    String? photoUrl,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _sync.updateUserProfile(
      uid: uid,
      displayName: displayName,
      photoBase64: photoBase64,
      photoUrl: photoUrl,
    );
  }

  Future<UserProfile?> fetchProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    return _sync.fetchUserProfile(uid);
  }

  Future<void> unbindUser() async {
    _uid = null;
    await AppDatabase.clearUserData();
  }

  Future<void> syncFromCloud() async {
    final uid = _uid;
    if (uid == null) return;

    var categories = await _sync.fetchCategories(uid);
    if (categories.isEmpty) {
      await _sync.seedDefaultCategories(uid);
      categories = CategorySeeds.defaults();
    }

    final cards = await _sync.fetchCards(uid);
    final expenses = await _sync.fetchExpenses(uid);
    final debtors = await _sync.fetchDebtors(uid);
    final incomes = await _sync.fetchIncomes(uid);

    await AppDatabase.replaceAll(
      categories: categories,
      cards: cards,
      expenses: expenses,
      debtors: debtors,
      incomes: incomes,
    );
  }

  List<Category> getCategories() {
    final items = AppDatabase.categories.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<void> saveCategory(Category category) async {
    await AppDatabase.categories.put(category.id, category);
    final uid = _uid;
    if (uid != null) await _sync.upsertCategory(uid, category);
  }

  Future<void> deleteCategory(String id) async {
    await AppDatabase.categories.delete(id);
    final uid = _uid;
    if (uid != null) await _sync.deleteCategory(uid, id);
  }

  List<CreditCard> getCards() {
    final items = AppDatabase.cards.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return items;
  }

  Future<void> saveCard(CreditCard card) async {
    await AppDatabase.cards.put(card.id, card);
    final uid = _uid;
    if (uid != null) await _sync.upsertCard(uid, card);
  }

  Future<void> deleteCard(String id) async {
    await AppDatabase.cards.delete(id);
    final uid = _uid;
    if (uid != null) await _sync.deleteCard(uid, id);
  }

  List<Expense> getExpenses() {
    final items = AppDatabase.expenses.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> saveExpense(Expense expense) async {
    await AppDatabase.expenses.put(expense.id, expense);
    final uid = _uid;
    if (uid != null) await _sync.upsertExpense(uid, expense);
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final entries = {for (final e in expenses) e.id: e};
    await AppDatabase.expenses.putAll(entries);
    final uid = _uid;
    if (uid != null) await _sync.upsertExpenses(uid, expenses);
  }

  Future<void> deleteExpense(String id) async {
    await AppDatabase.expenses.delete(id);
    final uid = _uid;
    if (uid != null) await _sync.deleteExpense(uid, id);
  }

  List<Debtor> getDebtors() {
    final items = AppDatabase.debtors.values.toList()
      ..sort((a, b) => b.amountOwed.compareTo(a.amountOwed));
    return items;
  }

  Future<void> saveDebtor(Debtor debtor) async {
    await AppDatabase.debtors.put(debtor.id, debtor);
    final uid = _uid;
    if (uid != null) await _sync.upsertDebtor(uid, debtor);
  }

  Future<void> deleteDebtor(String id) async {
    await AppDatabase.debtors.delete(id);
    final uid = _uid;
    if (uid != null) await _sync.deleteDebtor(uid, id);
  }

  List<Income> getIncomes() {
    final items = AppDatabase.incomes.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> saveIncome(Income income) async {
    await AppDatabase.incomes.put(income.id, income);
    final uid = _uid;
    if (uid != null) await _sync.upsertIncome(uid, income);
  }

  Future<void> deleteIncome(String id) async {
    await AppDatabase.incomes.delete(id);
    final uid = _uid;
    if (uid != null) await _sync.deleteIncome(uid, id);
  }

  /// Apaga somente os gastos/lançamentos (local + nuvem).
  Future<void> resetAllAccounts() async {
    final uid = _uid;
    if (uid != null) {
      await _sync.resetFinancialData(uid);
    }
    await AppDatabase.expenses.clear();
  }
}

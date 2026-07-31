import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:financas/data/category_seeds.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/credit_card.dart';
import 'package:financas/models/expense.dart';

class FirestoreSyncService {
  FirestoreSyncService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _col(String uid, String name) =>
      _userDoc(uid).collection(name);

  Future<void> ensureUserProfile(UserProfile profile) async {
    final data = <String, dynamic>{
      'email': profile.email,
      'displayName': profile.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (profile.photoBase64 != null) {
      data['photoBase64'] = profile.photoBase64;
    }
    if (profile.photoUrl != null) {
      data['photoUrl'] = profile.photoUrl;
    }
    await _userDoc(profile.uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoBase64,
    String? photoUrl,
  }) {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) data['displayName'] = displayName;
    if (photoBase64 != null) data['photoBase64'] = photoBase64;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    return _userDoc(uid).set(data, SetOptions(merge: true));
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data() ?? {};
    return UserProfile(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      photoBase64: data['photoBase64'] as String?,
    );
  }

  Future<List<Category>> fetchCategories(String uid) async {
    final snap = await _col(uid, 'categories').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return Category.fromMap(data);
    }).toList();
  }

  Future<List<CreditCard>> fetchCards(String uid) async {
    final snap = await _col(uid, 'cards').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return CreditCard.fromMap(data);
    }).toList();
  }

  Future<List<Expense>> fetchExpenses(String uid) async {
    final snap = await _col(uid, 'expenses').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return Expense.fromMap(data);
    }).toList();
  }

  Future<void> seedDefaultCategories(String uid) async {
    final batch = _db.batch();
    for (final category in CategorySeeds.defaults()) {
      batch.set(_col(uid, 'categories').doc(category.id), category.toMap());
    }
    await batch.commit();
  }

  Future<void> upsertCategory(String uid, Category category) {
    return _col(uid, 'categories').doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory(String uid, String id) {
    return _col(uid, 'categories').doc(id).delete();
  }

  Future<void> upsertCard(String uid, CreditCard card) {
    return _col(uid, 'cards').doc(card.id).set(card.toMap());
  }

  Future<void> deleteCard(String uid, String id) {
    return _col(uid, 'cards').doc(id).delete();
  }

  Future<void> upsertExpense(String uid, Expense expense) {
    return _col(uid, 'expenses').doc(expense.id).set(expense.toMap());
  }

  Future<void> upsertExpenses(String uid, List<Expense> expenses) async {
    if (expenses.isEmpty) return;
    var batch = _db.batch();
    var count = 0;
    for (final expense in expenses) {
      batch.set(_col(uid, 'expenses').doc(expense.id), expense.toMap());
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Future<void> deleteExpense(String uid, String id) {
    return _col(uid, 'expenses').doc(id).delete();
  }

  Future<void> clearCollection(String uid, String name) async {
    while (true) {
      final snap = await _col(uid, name).limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < 400) break;
    }
  }

  Future<void> resetFinancialData(String uid) async {
    await clearCollection(uid, 'expenses');
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.photoBase64,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? photoBase64;
}

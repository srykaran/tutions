import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee.dart';

class FeeService {
  final _firestore = FirebaseFirestore.instance;

  // Get fee document for a student
  Future<Fee?> getStudentFee(String studentId) async {
    final doc = await _firestore.collection('fees').doc(studentId).get();
    if (doc.exists) {
      return Fee.fromJson(doc.data()!);
    }
    return null;
  }

  // Create or update fee document for a student
  Future<void> setStudentFee(String studentId, Fee fee) async {
    await _firestore.collection('fees').doc(studentId).set(fee.toJson());
  }

  // Add a payment (transaction) for a student
  Future<void> addPayment(String studentId, double amount) async {
    final docRef = _firestore.collection('fees').doc(studentId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Fee document does not exist for student $studentId');
      }
      final data = snapshot.data()!;
      final paidFees = (data['paidFees'] as num).toDouble() + amount;
      final transactions = List<Map<String, dynamic>>.from(
        data['transactions'] ?? [],
      );
      transactions.add({
        'date': DateTime.now().toIso8601String(),
        'amount': amount,
      });
      transaction.update(docRef, {
        'paidFees': paidFees,
        'transactions': transactions,
      });
    });
  }

  // Optionally, move transactions to a subcollection if too many
  Future<void> moveTransactionsToSubcollection(String studentId) async {
    final docRef = _firestore.collection('fees').doc(studentId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final transactions = List<Map<String, dynamic>>.from(
      data['transactions'] ?? [],
    );
    final batch = _firestore.batch();
    for (final t in transactions) {
      final subDoc = docRef.collection('transactions').doc();
      batch.set(subDoc, t);
    }
    batch.update(docRef, {'transactions': []});
    await batch.commit();
  }
}

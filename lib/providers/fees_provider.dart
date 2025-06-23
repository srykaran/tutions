import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee.dart';
import '../services/summary_dashboard_service.dart';

final feesProvider = StateNotifierProvider<FeesNotifier, Map<String, Fee>>((
  ref,
) {
  return FeesNotifier();
});

class FeesNotifier extends StateNotifier<Map<String, Fee>> {
  final _firestore = FirebaseFirestore.instance;

  FeesNotifier() : super({}) {
    loadAllFees();
  }

  Future<void> loadAllFees() async {
    print('[feesProvider] loadAllFees called');
    try {
      final snapshot = await _firestore.collection('fees').get();
      print('[feesProvider] Fetched \\${snapshot.docs.length} docs');
      final fees = <String, Fee>{};
      for (final doc in snapshot.docs) {
        print('[feesProvider] Fee doc: \\${doc.id} => \\${doc.data()}');
        final data = doc.data();
        if (data['totalFees'] == null) {
          print('[feesProvider] Skipping doc without totalFees: \\${doc.id}');
          continue;
        }
        final fee = Fee.fromJson(data);
        final studentId = data['studentId'] ?? doc.id;
        fees[studentId] = fee;
      }
      state = fees;
      print('[feesProvider] State set: \\${fees}');
    } catch (e) {
      print('[feesProvider] Error loading fees: \\${e}');
    }
  }

  Future<void> loadFeeForStudent(String studentId) async {
    try {
      final doc = await _firestore.collection('fees').doc(studentId).get();
      if (doc.exists) {
        state = {...state, studentId: Fee.fromJson(doc.data()!)};
      }
    } catch (e) {
      print('Error loading fee for student: $e');
    }
  }

  Fee? getFee(String studentId) {
    return state[studentId];
  }

  Fee? getFeeByStudentId(String studentId) {
    return state[studentId];
  }

  Future<void> setFee(String studentId, Fee fee) async {
    try {
      await _firestore.collection('fees').doc(studentId).set(fee.toJson());
      state = {...state, studentId: fee};
    } catch (e) {
      print('Error setting fee: $e');
    }
  }

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
      // Update local state
      final updatedFee = Fee(
        totalFees: (data['totalFees'] as num).toDouble(),
        paidFees: paidFees,
        transactions:
            transactions.map((t) => FeeTransaction.fromJson(t)).toList(),
      );
      state = {...state, studentId: updatedFee};
    });
    // Update summary dashboard
    await SummaryDashboardService().updateSummary(paidFeesDelta: amount);
  }

  Future<void> updateTotalFees(String studentId, double totalFees) async {
    try {
      await _firestore.collection('fees').doc(studentId).update({
        'totalFees': totalFees,
      });
      // Reload the updated fee from Firestore and update local state
      await loadFeeForStudent(studentId);
    } catch (e) {
      print('Error updating totalFees: $e');
    }
  }

  // Add a method to set fee locally after adding a new student
  void setFeeLocal(String studentId, Fee fee) {
    state = {...state, studentId: fee};
  }
}

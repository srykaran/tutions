import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final feesProvider =
    StateNotifierProvider<FeesNotifier, List<Map<String, dynamic>>>((ref) {
      return FeesNotifier();
    });

class FeesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final _firestore = FirebaseFirestore.instance;

  FeesNotifier() : super([]) {
    loadFees();
  }

  Future<void> loadFees() async {
    try {
      print('Loading fees from Firestore...');
      final snapshot = await _firestore.collection('fees').get();
      final fees =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      print('Loaded ${fees.length} fees from Firestore');
      print('Fees data: $fees');
      state = fees;
    } catch (e) {
      print('Error loading fees: $e');
    }
  }

  Future<void> addFee(Map<String, dynamic> feeData) async {
    try {
      print('Adding new fee: $feeData');
      final docRef = await _firestore.collection('fees').add(feeData);
      final newFee = {'id': docRef.id, ...feeData};
      print('Fee added with ID: ${docRef.id}');
      state = [...state, newFee];
    } catch (e) {
      print('Error adding fee: $e');
    }
  }

  Future<void> updateFee(String id, Map<String, dynamic> feeData) async {
    try {
      await _firestore.collection('fees').doc(id).update(feeData);
      state =
          state.map((fee) {
            if (fee['id'] == id) {
              return {'id': id, ...feeData};
            }
            return fee;
          }).toList();
    } catch (e) {
      print('Error updating fee: $e');
    }
  }

  Future<void> deleteFee(String id) async {
    try {
      await _firestore.collection('fees').doc(id).delete();
      state = state.where((fee) => fee['id'] != id).toList();
    } catch (e) {
      print('Error deleting fee: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFeesByStudentId(
    String studentId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('fees')
              .where('studentId', isEqualTo: studentId)
              .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting fees by student ID: $e');
      return [];
    }
  }
}

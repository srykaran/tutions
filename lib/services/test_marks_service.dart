import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/test_marks.dart';

class TestMarksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'test_marks';

  Future<void> addTestMarks(TestMarks testMarks) async {
    await _firestore.collection(_collection).doc(testMarks.id).set(testMarks.toJson());
  }

  Stream<List<TestMarks>> getBatchTestMarks(String batchId) {
    return _firestore
        .collection(_collection)
        .where('batchId', isEqualTo: batchId)
        .orderBy('testDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TestMarks.fromJson(doc.data()))
          .toList();
    });
  }

  Stream<List<TestMarks>> getStudentTestMarks(String studentId) {
    return _firestore
        .collection(_collection)
        .where('studentMarks.$studentId', isGreaterThan: 0)
        .orderBy('testDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TestMarks.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> updateTestMarks(TestMarks testMarks) async {
    await _firestore.collection(_collection).doc(testMarks.id).update(testMarks.toJson());
  }

  Future<void> deleteTestMarks(String testMarksId) async {
    await _firestore.collection(_collection).doc(testMarksId).delete();
  }

  String generateId() {
    return const Uuid().v4();
  }
} 
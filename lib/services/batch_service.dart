import '../models/batch.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  final _firestore = FirebaseFirestore.instance;
  final _batchController = StreamController<List<Batch>>.broadcast();
  StreamSubscription? _subscription;

  BatchService() {
    _initializeBatches();
  }

  void _initializeBatches() {
    _subscription?.cancel();
    _subscription = _firestore.collection('batches').snapshots().listen((snapshot) {
      final batches = snapshot.docs.map((doc) {
        final data = doc.data();
        return Batch(
          id: doc.id,
          name: data['name'] as String,
          timing: data['timing'] as String,
          description: data['description'] as String,
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: (data['endDate'] as Timestamp).toDate(),
          isVisible: data['isVisible'] as bool? ?? true,
          classGrade: data['classGrade'] as String,
          subject: data['subject'] as String,
          teacherId: data['teacherId'] as String,
          teacherName: data['teacherName'] as String?,
        );
      }).toList();
      _batchController.add(batches);
    }, onError: (e) {
      print('Error loading batches: $e');
    });
  }

  // Create a new batch
  Future<void> createBatch(Batch batch) async {
    try {
      await _firestore.collection('batches').add({
        'name': batch.name,
        'timing': batch.timing,
        'description': batch.description,
        'startDate': Timestamp.fromDate(batch.startDate),
        'endDate': Timestamp.fromDate(batch.endDate),
        'isVisible': batch.isVisible,
        'classGrade': batch.classGrade,
        'subject': batch.subject,
        'teacherId': batch.teacherId,
        'teacherName': batch.teacherName,
      });
    } catch (e) {
      throw Exception('Failed to create batch: $e');
    }
  }

  // Get all batches
  Stream<List<Batch>> getBatches() {
    return _batchController.stream;
  }

  // Update a batch
  Future<void> updateBatch(Batch batch) async {
    try {
      await _firestore.collection('batches').doc(batch.id).update({
        'name': batch.name,
        'timing': batch.timing,
        'description': batch.description,
        'startDate': Timestamp.fromDate(batch.startDate),
        'endDate': Timestamp.fromDate(batch.endDate),
        'isVisible': batch.isVisible,
        'classGrade': batch.classGrade,
        'subject': batch.subject,
        'teacherId': batch.teacherId,
        'teacherName': batch.teacherName,
      });
    } catch (e) {
      throw Exception('Failed to update batch: $e');
    }
  }

  // Delete a batch
  Future<void> deleteBatch(String batchId) async {
    try {
      await _firestore.collection('batches').doc(batchId).delete();
    } catch (e) {
      throw Exception('Failed to delete batch: $e');
    }
  }

  // Toggle batch visibility
  Future<void> toggleBatchVisibility(String batchId, bool isVisible) async {
    try {
      await _firestore.collection('batches').doc(batchId).update({
        'isVisible': isVisible,
      });
    } catch (e) {
      throw Exception('Failed to toggle batch visibility: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _batchController.close();
  }
} 
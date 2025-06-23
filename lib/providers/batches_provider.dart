import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/batch.dart';
import '../services/summary_dashboard_service.dart';

final batchesProvider = StateNotifierProvider<BatchesNotifier, List<Batch>>((
  ref,
) {
  return BatchesNotifier();
});

class BatchesNotifier extends StateNotifier<List<Batch>> {
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  BatchesNotifier() : super([]) {
    loadBatches();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void loadBatches() {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('batches')
        .snapshots()
        .listen(
          (snapshot) {
            state =
                snapshot.docs.map((doc) {
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
          },
          onError: (e) {
            print('Error loading batches: $e');
            state = [];
            // Optionally, you could add an error field to the provider for UI
          },
        );
  }

  Future<void> addBatch(Batch batch) async {
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
      // Update summary dashboard
      await SummaryDashboardService().updateSummary(batchDelta: 1);
    } catch (e) {
      print('Error adding batch: $e');
      throw e;
    }
  }

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

      state =
          state.map((b) {
            if (b.id == batch.id) {
              return batch;
            }
            return b;
          }).toList();
    } catch (e) {
      print('Error updating batch: $e');
      throw e;
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      await _firestore.collection('batches').doc(id).delete();
      state = state.where((batch) => batch.id != id).toList();
      // Update summary dashboard
      await SummaryDashboardService().updateSummary(batchDelta: -1);
    } catch (e) {
      print('Error deleting batch: $e');
      throw e;
    }
  }

  Future<void> toggleBatchVisibility(String id, bool isVisible) async {
    try {
      await _firestore.collection('batches').doc(id).update({
        'isVisible': isVisible,
      });

      state =
          state.map((batch) {
            if (batch.id == id) {
              return Batch(
                id: batch.id,
                name: batch.name,
                timing: batch.timing,
                description: batch.description,
                startDate: batch.startDate,
                endDate: batch.endDate,
                isVisible: isVisible,
                classGrade: batch.classGrade,
                subject: batch.subject,
                teacherId: batch.teacherId,
                teacherName: batch.teacherName,
              );
            }
            return batch;
          }).toList();
    } catch (e) {
      print('Error toggling batch visibility: $e');
      throw e;
    }
  }
}

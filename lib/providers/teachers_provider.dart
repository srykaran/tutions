import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final teachersProvider =
    StateNotifierProvider<TeachersNotifier, List<Map<String, dynamic>>>((ref) {
      return TeachersNotifier();
    });

class TeachersNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final _firestore = FirebaseFirestore.instance;

  TeachersNotifier() : super([]) {
    loadTeachers();
  }

  Future<void> loadTeachers() async {
    try {
      final snapshot = await _firestore.collection('teachers').get();
      if (snapshot.docs.isNotEmpty) {
        state =
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    } catch (e) {
      print('Error loading teachers: $e');
    }
  }

  Future<void> addTeacher(Map<String, dynamic> teacherData) async {
    try {
      final docRef = await _firestore.collection('teachers').add(teacherData);
      state = [
        ...state,
        {'id': docRef.id, ...teacherData},
      ];
    } catch (e) {
      print('Error adding teacher: $e');
    }
  }

  Future<void> updateTeacher(
    String id,
    Map<String, dynamic> teacherData,
  ) async {
    try {
      await _firestore.collection('teachers').doc(id).update(teacherData);
      state =
          state.map((teacher) {
            if (teacher['id'] == id) {
              return {'id': id, ...teacherData};
            }
            return teacher;
          }).toList();
    } catch (e) {
      print('Error updating teacher: $e');
    }
  }

  Future<void> deleteTeacher(String id) async {
    try {
      await _firestore.collection('teachers').doc(id).delete();
      state = state.where((teacher) => teacher['id'] != id).toList();
    } catch (e) {
      print('Error deleting teacher: $e');
    }
  }
}

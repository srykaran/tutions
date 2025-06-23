import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/summary_dashboard_service.dart';

final studentsProvider =
    StateNotifierProvider<StudentsNotifier, List<Map<String, dynamic>>>((ref) {
      return StudentsNotifier();
    });

class StudentsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final _firestore = FirebaseFirestore.instance;
  DateTime? _lastUpdated;
  static const String _cacheKey = 'students_cache';
  static const String _lastUpdatedKey = 'students_last_updated';

  StudentsNotifier() : super([]) {
    loadStudents();
  }

  Future<void> loadStudents({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        print('Attempting to load students from cache...');
        final cachedData = await _loadFromCache();
        if (cachedData != null) {
          print('Successfully loaded ${cachedData.length} students from cache');
          state = cachedData;
          return;
        }
        print('No cached data found, loading from Firestore...');
      } else {
        print('Force refresh requested, loading from Firestore...');
      }

      final snapshot = await _firestore.collection('students').get();
      final newState =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
              'active': data['active'] ?? true,
              'currentYear': data['currentYear'] ?? DateTime.now().year,
            };
          }).toList();

      print('Successfully loaded ${newState.length} students from Firestore');
      state = newState;

      await _saveToCache(newState);
    } catch (e) {
      print('Error loading students: $e');
      print('Attempting to load from cache as fallback...');
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        print(
          'Successfully loaded ${cachedData.length} students from cache as fallback',
        );
        state = cachedData;
      } else {
        print('No cached data available as fallback');
        state = [];
      }
    }
  }

  Future<List<Map<String, dynamic>>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStudents = prefs.getString(_cacheKey);
      final lastUpdated = prefs.getInt(_lastUpdatedKey);

      if (cachedStudents != null && lastUpdated != null) {
        _lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
        print('Cache last updated: ${_lastUpdated.toString()}');
        return List<Map<String, dynamic>>.from(json.decode(cachedStudents));
      }
      print('No valid cache found');
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return null;
  }

  Future<void> _saveToCache(List<Map<String, dynamic>> students) async {
    try {
      // Validate and clean data before caching
      final cleanedStudents =
          students.map((student) {
            // Ensure batchIds is always a List
            if (student['batchIds'] == null) {
              student['batchIds'] = [];
            } else if (student['batchIds'] is! List) {
              student['batchIds'] = [student['batchIds']];
            }

            // Ensure all required fields have default values
            return {
              'id': student['id'] ?? '',
              'name': student['name'] ?? '',
              'contact': student['contact'] ?? '',
              'phone': student['phone'] ?? '',
              'classGrade': student['classGrade'] ?? '',
              'batchIds': student['batchIds'],
              'profilePhotoUrl': student['profilePhotoUrl'],
              'joinedDate':
                  student['joinedDate'] ?? DateTime.now().toIso8601String(),
            };
          }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(cleanedStudents));
      await prefs.setInt(
        _lastUpdatedKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      _lastUpdated = DateTime.now();
      print('Successfully cached ${cleanedStudents.length} students');
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> addStudent(Map<String, dynamic> studentData) async {
    try {
      // Remove totalFees and paidFees
      final data = Map<String, dynamic>.from(studentData);
      double totalFees = (studentData['totalFees'] ?? 0).toDouble();
      data.remove('totalFees');
      data.remove('paidFees');
      // Ensure 'active' and 'currentYear' are present
      if (!data.containsKey('active')) data['active'] = true;
      if (!data.containsKey('currentYear'))
        data['currentYear'] = DateTime.now().year;

      final docRef = await _firestore.collection('students').add(data);
      final newStudent = {'id': docRef.id, ...data};
      state = [...state, newStudent];
      await _saveToCache(state);
      // Update summary dashboard
      await SummaryDashboardService().updateSummary(
        studentDelta: 1,
        totalFeesDelta: totalFees,
      );
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(
    String id,
    Map<String, dynamic> studentData,
  ) async {
    try {
      final currentStudent = state.firstWhere((student) => student['id'] == id);
      final updatedData = {...currentStudent, ...studentData};
      // Fetch the old totalFees from the fees collection (source of truth)
      final doc = await _firestore.collection('fees').doc(id).get();
      double oldTotalFees = 0.0;
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!['totalFees'] != null) {
        oldTotalFees = (doc.data()!['totalFees'] as num).toDouble();
      }
      double newTotalFees =
          (studentData['totalFees'] ?? oldTotalFees).toDouble();
      double diff = newTotalFees - oldTotalFees;
      updatedData.remove('totalFees');
      updatedData.remove('paidFees');
      // Allow updating 'active' if present
      if (studentData.containsKey('active')) {
        updatedData['active'] = studentData['active'];
      }

      await _firestore.collection('students').doc(id).update(updatedData);
      state =
          state.map((student) {
            if (student['id'] == id) {
              return updatedData;
            }
            return student;
          }).toList();

      await _saveToCache(state);
      // Update summary dashboard if totalFees changed
      if (diff != 0) {
        await SummaryDashboardService().updateSummary(totalFeesDelta: diff);
      }
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      // Get the student's totalFees before deleting
      final doc = await _firestore.collection('fees').doc(id).get();
      double totalFees = 0.0;
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!['totalFees'] != null) {
        totalFees = (doc.data()!['totalFees'] as num).toDouble();
      }
      await _firestore.collection('students').doc(id).delete();
      state = state.where((student) => student['id'] != id).toList();
      await _saveToCache(state);
      // Update summary dashboard
      await SummaryDashboardService().updateSummary(
        studentDelta: -1,
        totalFeesDelta: -totalFees,
      );
    } catch (e) {
      print('Error deleting student: $e');
      rethrow;
    }
  }

  DateTime? get lastUpdated => _lastUpdated;
}

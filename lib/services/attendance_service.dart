import '../models/attendance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final _firestore = FirebaseFirestore.instance;

  // Mark attendance
  Future<void> markAttendance(Attendance attendance) async {
    try {
      await _firestore.collection('attendance').add({
        'studentId': attendance.studentId,
        'batchId': attendance.batchId,
        'date': Timestamp.fromDate(attendance.date),
        'isPresent': attendance.isPresent,
        'remarks': attendance.remarks,
      });
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // Get attendance for a batch on a specific date
  Stream<List<Attendance>> getBatchAttendance(String batchId, DateTime date) {
    return _firestore
        .collection('attendance')
        .where('batchId', isEqualTo: batchId)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Attendance(
          id: doc.id,
          studentId: data['studentId']?.toString() ?? '',
          batchId: data['batchId']?.toString() ?? '',
          date: _parseDate(data['date']),
          isPresent: data['isPresent'] as bool? ?? false,
          remarks: data['remarks']?.toString(),
        );
      }).toList();
    });
  }

  // Get attendance for a student
  Stream<List<Attendance>> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Attendance(
          id: doc.id,
          studentId: data['studentId']?.toString() ?? '',
          batchId: data['batchId']?.toString() ?? '',
          date: _parseDate(data['date']),
          isPresent: data['isPresent'] as bool? ?? false,
          remarks: data['remarks']?.toString(),
        );
      }).toList();
    });
  }

  // Update attendance
  Future<void> updateAttendance(Attendance attendance) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: attendance.studentId)
          .where('date', isEqualTo: Timestamp.fromDate(attendance.date))
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'studentId': attendance.studentId,
          'batchId': attendance.batchId,
          'date': Timestamp.fromDate(attendance.date),
          'isPresent': attendance.isPresent,
          'remarks': attendance.remarks,
        });
      }
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // Get attendance summary for a batch
  Stream<Map<String, dynamic>> getBatchAttendanceSummary(String batchId) {
    return _firestore
        .collection('attendance')
        .where('batchId', isEqualTo: batchId)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        return Attendance(
          id: doc.id,
          studentId: data['studentId']?.toString() ?? '',
          batchId: data['batchId']?.toString() ?? '',
          date: _parseDate(data['date']),
          isPresent: data['isPresent'] as bool? ?? false,
          remarks: data['remarks']?.toString(),
        );
      }).toList();

      final totalClasses = records.length;
      final presentCount = records.where((record) => record.status == 'present').length;
      final absentCount = records.where((record) => record.status == 'absent').length;
      final lateCount = records.where((record) => record.status == 'late').length;

      return {
        'totalClasses': totalClasses,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
      };
    });
  }

  // Helper method to parse date from Firestore
  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    } else {
      return DateTime.now();
    }
  }
} 
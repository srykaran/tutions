import '../models/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final _firestore = FirebaseFirestore.instance;

  // Create a new student
  Future<void> createStudent(Student student) async {
    try {
      await _firestore.collection('students').add({
        'name': student.name,
        'contact': student.contact,
        'phone': student.phone,
        'classGrade': student.classGrade,
        'batchId': student.batchId,
        'joinedDate': Timestamp.fromDate(student.joinedDate),
      });
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  // Get all students
  Stream<List<Student>> getStudents() {
    return _firestore.collection('students').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Student(
          id: doc.id,
          name: data['name']?.toString() ?? '',
          contact: data['contact']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          classGrade: data['classGrade']?.toString() ?? '',
          batchId: data['batchId']?.toString() ?? '',
          profilePhotoUrl: data['profilePhotoUrl']?.toString(),
          joinedDate: _parseDate(data['joinedDate']),
          active:
              data['active'] is bool
                  ? data['active']
                  : (data['active'] ?? true),
          currentYear:
              data['currentYear'] is int
                  ? data['currentYear']
                  : (data['currentYear'] ?? DateTime.now().year),
        );
      }).toList();
    });
  }

  // Get students by batch
  Stream<List<Student>> getStudentsByBatch(String batchId) {
    return _firestore
        .collection('students')
        .where('batchIds', arrayContains: batchId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Student(
              id: doc.id,
              name: data['name']?.toString() ?? '',
              contact: data['contact']?.toString() ?? '',
              phone: data['phone']?.toString() ?? '',
              classGrade: data['classGrade']?.toString() ?? '',
              batchId: batchId, // Use the provided batchId
              profilePhotoUrl: data['profilePhotoUrl']?.toString(),
              joinedDate: _parseDate(data['joinedDate']),
              active:
                  data['active'] is bool
                      ? data['active']
                      : (data['active'] ?? true),
              currentYear:
                  data['currentYear'] is int
                      ? data['currentYear']
                      : (data['currentYear'] ?? DateTime.now().year),
            );
          }).toList();
        });
  }

  // Update a student
  Future<void> updateStudent(Student student) async {
    try {
      await _firestore.collection('students').doc(student.id).update({
        'name': student.name,
        'contact': student.contact,
        'phone': student.phone,
        'classGrade': student.classGrade,
        'batchId': student.batchId,
        'joinedDate': Timestamp.fromDate(student.joinedDate),
      });
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete a student
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Search students
  Stream<List<Student>> searchStudents(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _firestore.collection('students').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Student(
              id: doc.id,
              name: data['name']?.toString() ?? '',
              contact: data['contact']?.toString() ?? '',
              phone: data['phone']?.toString() ?? '',
              classGrade: data['classGrade']?.toString() ?? '',
              batchId: data['batchId']?.toString() ?? '',
              profilePhotoUrl: data['profilePhotoUrl']?.toString(),
              joinedDate: _parseDate(data['joinedDate']),
              active:
                  data['active'] is bool
                      ? data['active']
                      : (data['active'] ?? true),
              currentYear:
                  data['currentYear'] is int
                      ? data['currentYear']
                      : (data['currentYear'] ?? DateTime.now().year),
            );
          })
          .where(
            (student) =>
                student.name.toLowerCase().contains(lowercaseQuery) ||
                student.phone.toLowerCase().contains(lowercaseQuery),
          )
          .toList();
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

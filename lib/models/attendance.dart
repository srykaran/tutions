class Attendance {
  final String id;
  final String studentId;
  final String batchId;
  final DateTime date;
  final bool isPresent;
  final String? remarks;

  Attendance({
    required this.id,
    required this.studentId,
    required this.batchId,
    required this.date,
    required this.isPresent,
    this.remarks,
  });

  /// ✅ Derived property to fix `.status` usage in service
  String get status {
    if (isPresent) return 'present';
    if (remarks?.toLowerCase() == 'late') return 'late';
    return 'absent';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'batchId': batchId,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'remarks': remarks,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      batchId: map['batchId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      isPresent: map['isPresent'] ?? false,
      remarks: map['remarks'],
    );
  }
}

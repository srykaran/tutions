class TestMarks {
  final String id;
  final String batchId;
  final String testName;
  final String subject;
  final double totalMarks;
  final DateTime testDate;
  final Map<String, double> studentMarks; // Map of studentId to marks
  final String? remarks;

  TestMarks({
    required this.id,
    required this.batchId,
    required this.testName,
    required this.subject,
    required this.totalMarks,
    required this.testDate,
    required this.studentMarks,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'testName': testName,
      'subject': subject,
      'totalMarks': totalMarks,
      'testDate': testDate.toIso8601String(),
      'studentMarks': studentMarks,
      'remarks': remarks,
    };
  }

  factory TestMarks.fromJson(Map<String, dynamic> json) {
    return TestMarks(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      testName: json['testName'] as String,
      subject: json['subject'] as String,
      totalMarks: (json['totalMarks'] as num).toDouble(),
      testDate: DateTime.parse(json['testDate'] as String),
      studentMarks: Map<String, double>.from(json['studentMarks'] as Map),
      remarks: json['remarks'] as String?,
    );
  }
} 
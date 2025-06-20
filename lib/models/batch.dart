class Batch {
  final String? id; // Optional since Firestore will generate it
  final String name;
  final String timing;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isVisible;
  final String classGrade; // e.g., "9th", "10th"
  final String subject; // Single subject
  final String teacherId; // ID of the assigned teacher
  final String? teacherName; // Name of the assigned teacher (optional, for display)

  Batch({
    this.id, // Optional parameter
    required this.name,
    required this.timing,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isVisible = true,
    required this.classGrade,
    required this.subject,
    required this.teacherId,
    this.teacherName,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'timing': timing,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isVisible': isVisible,
      'classGrade': classGrade,
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
    };
  }

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String?,
      name: json['name'] as String,
      timing: json['timing'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isVisible: json['isVisible'] as bool? ?? true,
      classGrade: json['classGrade'] as String,
      subject: json['subject'] as String,
      teacherId: json['teacherId'] as String,
      teacherName: json['teacherName'] as String?,
    );
  }
} 
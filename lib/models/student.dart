class Student {
  final String id;
  final String name;
  final String contact;
  final String phone;
  final String classGrade;
  final String batchId;
  final String? profilePhotoUrl;
  final DateTime joinedDate;
  final bool active;
  final int currentYear;

  Student({
    required this.id,
    required this.name,
    required this.contact,
    required this.phone,
    required this.classGrade,
    required this.batchId,
    this.profilePhotoUrl,
    required this.joinedDate,
    required this.active,
    required this.currentYear,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'phone': phone,
      'classGrade': classGrade,
      'batchId': batchId,
      'profilePhotoUrl': profilePhotoUrl,
      'joinedDate': joinedDate.toIso8601String(),
      'active': active,
      'currentYear': currentYear,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      contact: json['contact'] as String,
      phone: json['phone'] as String,
      classGrade: json['classGrade'] as String,
      batchId: json['batchId'] as String,
      profilePhotoUrl: json['profilePhotoUrl'],
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      active:
          json['active'] is bool ? json['active'] : json['active'] == 'active',
      currentYear:
          json['currentYear'] is int
              ? json['currentYear']
              : int.tryParse(json['currentYear'].toString()) ??
                  DateTime.now().year,
    );
  }
}

class Fee {
  final String id;
  final String studentId;
  final String batchId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? remarks;
  final bool isPaid;
  final String status;

  Fee({
    required this.id,
    required this.studentId,
    required this.batchId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.remarks,
    this.isPaid = false,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'batchId': batchId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'remarks': remarks,
      'isPaid': isPaid,
      'status': status,
    };
  }

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      batchId: json['batchId'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      paymentMethod: json['paymentMethod'] as String?,
      remarks: json['remarks'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
    );
  }
} 
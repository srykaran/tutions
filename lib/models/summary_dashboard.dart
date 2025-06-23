class SummaryDashboard {
  final int totalStudents;
  final int totalBatches;
  final double totalFees;
  final double paidFees;

  SummaryDashboard({
    required this.totalStudents,
    required this.totalBatches,
    required this.totalFees,
    required this.paidFees,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_students': totalStudents,
      'total_batches': totalBatches,
      'total_fees': totalFees,
      'paid_fees': paidFees,
    };
  }

  factory SummaryDashboard.fromJson(Map<String, dynamic> json) {
    return SummaryDashboard(
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      totalBatches: (json['total_batches'] as num?)?.toInt() ?? 0,
      totalFees: (json['total_fees'] as num?)?.toDouble() ?? 0.0,
      paidFees: (json['paid_fees'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

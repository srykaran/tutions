class Fee {
  final double totalFees;
  final double paidFees;
  final List<FeeTransaction> transactions;

  Fee({
    required this.totalFees,
    required this.paidFees,
    required this.transactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalFees': totalFees,
      'paidFees': paidFees,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      totalFees: (json['totalFees'] as num).toDouble(),
      paidFees: (json['paidFees'] as num?)?.toDouble() ?? 0.0,
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map((t) => FeeTransaction.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FeeTransaction {
  final DateTime date;
  final double amount;

  FeeTransaction({required this.date, required this.amount});

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'amount': amount};
  }

  factory FeeTransaction.fromJson(Map<String, dynamic> json) {
    return FeeTransaction(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

import '../models/fee.dart';

class FeeService {
  final List<Fee> _fees = [];

  // Create a new fee record
  Future<void> createFee(Fee fee) async {
    try {
      _fees.add(fee);
    } catch (e) {
      throw Exception('Failed to create fee record: $e');
    }
  }

  // Get all fees for a student
  Stream<List<Fee>> getStudentFees(String studentId) async* {
    yield _fees.where((fee) => fee.studentId == studentId).toList();
  }

  // Get fees for a batch
  Stream<List<Fee>> getBatchFees(String batchId) async* {
    yield _fees.where((fee) => fee.batchId == batchId).toList();
  }

  // Update a fee record
  Future<void> updateFee(Fee fee) async {
    try {
      final index = _fees.indexWhere((f) => f.id == fee.id);
      if (index != -1) {
        _fees[index] = fee;
      }
    } catch (e) {
      throw Exception('Failed to update fee record: $e');
    }
  }

  // Delete a fee record
  Future<void> deleteFee(String feeId) async {
    try {
      _fees.removeWhere((fee) => fee.id == feeId);
    } catch (e) {
      throw Exception('Failed to delete fee record: $e');
    }
  }

  // Get fee summary for a student
  Stream<Map<String, dynamic>> getStudentFeeSummary(String studentId) async* {
    final studentFees = _fees.where((fee) => fee.studentId == studentId);
    final totalAmount = studentFees.fold(0.0, (sum, fee) => sum + fee.amount);
    final paidAmount = studentFees
        .where((fee) => fee.status == 'paid')
        .fold(0.0, (sum, fee) => sum + fee.amount);
    final pendingAmount = totalAmount - paidAmount;

    yield {
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
    };
  }
}

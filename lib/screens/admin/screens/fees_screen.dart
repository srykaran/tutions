import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/theme.dart';
import '../../../models/batch.dart';
import '../../../providers/fees_provider.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/batches_provider.dart';
import 'package:intl/intl.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedClassGrade;
  String _selectedStudent = '';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  List<Map<String, dynamic>> get _filteredStudents {
    final students = ref.watch(studentsProvider);
    print('All students: $students'); // Debug all students
    if (_selectedClassGrade == null) return [];
    final filtered = students.where((student) => 
      student['classGrade'] != null && 
      student['classGrade'] == _selectedClassGrade
    ).toList();
    print('Filtered students for grade $_selectedClassGrade: $filtered'); // Debug filtered students
    return filtered;
  }

  double get _totalFees {
    final fees = ref.watch(feesProvider);
    final students = ref.watch(studentsProvider);
    
    // Get fees from fee records
    final feeRecordsTotal = fees
        .where((fee) => fee['studentId'] == _selectedStudent)
        .fold(0.0, (sum, fee) => sum + (fee['amount'] as num).toDouble());
    
    // Get fees from student document
    final student = students.firstWhere(
      (student) => student['id'] == _selectedStudent,
      orElse: () => {'totalFees': 0.0},
    );
    final studentTotalFees = (student['totalFees'] as num?)?.toDouble() ?? 0.0;
    
    // Return the higher of the two values
    return feeRecordsTotal > studentTotalFees ? feeRecordsTotal : studentTotalFees;
  }

  double get _paidFees {
    final fees = ref.watch(feesProvider);
    final students = ref.watch(studentsProvider);
    
    // Get paid fees from fee records
    final feeRecordsPaid = fees
        .where((fee) => fee['studentId'] == _selectedStudent && fee['isPaid'] == true)
        .fold(0.0, (sum, fee) => sum + (fee['amount'] as num).toDouble());
    
    // Get paid fees from student document
    final student = students.firstWhere(
      (student) => student['id'] == _selectedStudent,
      orElse: () => {'paidFees': 0.0},
    );
    final studentPaidFees = (student['paidFees'] as num?)?.toDouble() ?? 0.0;
    
    // Return the higher of the two values
    return feeRecordsPaid > studentPaidFees ? feeRecordsPaid : studentPaidFees;
  }

  double get _pendingFees => _totalFees - _paidFees;

  @override
  void initState() {
    super.initState();
    print('FeesScreen initialized'); // Debug initialization
    // Set initial class grade if available
    final students = ref.read(studentsProvider);
    print('Available students in initState: $students'); // Debug students in init
    if (students.isNotEmpty) {
      _selectedClassGrade = students.first['classGrade'];
      print('Initial class grade set to: $_selectedClassGrade'); // Debug initial class grade
    }
    // Load fees when screen opens
    ref.read(feesProvider.notifier).loadFees();
    print('Fees loading requested'); // Debug fees loading
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    _dueDate = DateTime.now().add(const Duration(days: 7));
  }

  void _addFees() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudent.isEmpty) {
        print('No student selected for adding fees'); // Debug no student
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a student')),
        );
        return;
      }

      print('Selected student ID for adding fees: $_selectedStudent'); // Debug selected student
      final students = ref.read(studentsProvider);
      final student = students.firstWhere(
        (s) => s['id'] == _selectedStudent,
        orElse: () => {'name': 'Unknown'},
      );
      print('Selected student data: $student'); // Debug student data

      if (_selectedClassGrade == null) {
        print('No class grade selected for adding fees'); // Debug no class grade
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a class grade')),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      print('Adding fee amount: $amount'); // Debug fee amount
      
      // Add new fee record
      final feeData = {
        'title': 'Monthly Fee',
        'description': _descriptionController.text,
        'classGrade': _selectedClassGrade,
        'studentId': _selectedStudent,
        'amount': amount,
        'dueDate': _dueDate.toIso8601String(),
        'isPaid': true,
        'paidDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      print('Fee data to be added: $feeData'); // Debug fee data

      await ref.read(feesProvider.notifier).addFee(feeData);
      print('Fee added successfully'); // Debug fee addition
      _clearForm();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fees added successfully')),
      );
    }
  }

  void _toggleFeeStatus(String feeId, bool currentStatus) async {
    final fee = ref.read(feesProvider).firstWhere((f) => f['id'] == feeId);
    
    // Update fee status
    await ref.read(feesProvider.notifier).updateFee(feeId, {
      'isPaid': !currentStatus,
      'paidDate': !currentStatus ? DateTime.now().toIso8601String() : null,
    });
  }

  void _deleteFee(String feeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee'),
        content: const Text('Are you sure you want to delete this fee record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(feesProvider.notifier).deleteFee(feeId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fee deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getClassGradeDropdownItems() {
    final students = ref.watch(studentsProvider);
    final classGrades = students
        .map((student) => student['classGrade'] as String?)
        .where((grade) => grade != null)
        .map((grade) => grade!)
        .toSet()
        .toList()
      ..sort();
    return classGrades.map<DropdownMenuItem<String>>((grade) {
      return DropdownMenuItem<String>(
        value: grade,
        child: Text(grade),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fees = ref.watch(feesProvider);
    final studentFees = fees.where((fee) => fee['studentId'] == _selectedStudent).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fees Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Student',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth > 600 
                                      ? (constraints.maxWidth - 16) / 2 
                                      : constraints.maxWidth,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedClassGrade,
                                    decoration: InputDecoration(
                                      labelText: 'Class Grade',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.class_),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    items: _getClassGradeDropdownItems(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedClassGrade = value;
                                          _selectedStudent = '';
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 600 
                                      ? (constraints.maxWidth - 16) / 2 
                                      : constraints.maxWidth,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStudent.isEmpty ? null : _selectedStudent,
                                    decoration: InputDecoration(
                                      labelText: 'Student',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.person),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    items: _filteredStudents.map<DropdownMenuItem<String>>((student) {
                                      return DropdownMenuItem<String>(
                                        value: student['id'] as String,
                                        child: Text(student['name'] as String),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedStudent = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedStudent.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fee Summary',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _FeeSummaryCard(
                                  title: 'Total Fees',
                                  amount: _totalFees,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _FeeSummaryCard(
                                  title: 'Paid Fees',
                                  amount: _paidFees,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _FeeSummaryCard(
                                  title: 'Pending Fees',
                                  amount: _pendingFees,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fee History',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Add New Fee'),
                                      content: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextFormField(
                                              controller: _amountController,
                                              decoration: const InputDecoration(
                                                labelText: 'Amount',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter amount';
                                                }
                                                if (double.tryParse(value) == null) {
                                                  return 'Please enter a valid amount';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              controller: _descriptionController,
                                              decoration: const InputDecoration(
                                                labelText: 'Description',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter description';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            ListTile(
                                              title: const Text('Due Date'),
                                              subtitle: Text(
                                                DateFormat('MMM dd, yyyy').format(_dueDate),
                                              ),
                                              trailing: const Icon(Icons.calendar_today),
                                              onTap: () async {
                                                final date = await showDatePicker(
                                                  context: context,
                                                  initialDate: _dueDate,
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                                );
                                                if (date != null) {
                                                  setState(() {
                                                    _dueDate = date;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _clearForm();
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: _addFees,
                                          child: const Text('Add Fee'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Fee'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: studentFees.length,
                            itemBuilder: (context, index) {
                              final fee = studentFees[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(fee['title'] as String),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(fee['description'] as String),
                                      Text(
                                        'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(fee['dueDate'] as String))}',
                                        style: TextStyle(
                                          color: fee['isPaid'] ? Colors.green : Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${fee['amount']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          fee['isPaid'] ? Icons.check_circle : Icons.pending,
                                          color: fee['isPaid'] ? Colors.green : Colors.orange,
                                        ),
                                        onPressed: () => _toggleFeeStatus(fee['id'] as String, fee['isPaid'] as bool),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteFee(fee['id'] as String),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeeSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _FeeSummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 

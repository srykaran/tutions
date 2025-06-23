import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/theme.dart';
import '../../../models/batch.dart';
import '../../../providers/fees_provider.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/batches_provider.dart';
import 'package:intl/intl.dart';
import '../../../models/fee.dart';

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
    final filtered =
        students
            .where(
              (student) =>
                  student['classGrade'] != null &&
                  student['classGrade'] == _selectedClassGrade,
            )
            .toList();
    print(
      'Filtered students for grade $_selectedClassGrade: $filtered',
    ); // Debug filtered students
    return filtered;
  }

  Fee? get _selectedFee {
    return ref.watch(feesProvider.notifier).getFeeByStudentId(_selectedStudent);
  }

  double get _totalFees => _selectedFee?.totalFees ?? 0.0;
  double get _paidFees => _selectedFee?.paidFees ?? 0.0;
  double get _pendingFees => _totalFees - _paidFees;

  @override
  void initState() {
    super.initState();
    print('FeesScreen initialized'); // Debug initialization
    // Set initial class grade if available
    final students = ref.read(studentsProvider);
    print(
      'Available students in initState: $students',
    ); // Debug students in init
    if (students.isNotEmpty) {
      _selectedClassGrade = students.first['classGrade'];
      print(
        'Initial class grade set to: $_selectedClassGrade',
      ); // Debug initial class grade
    }
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

  void _addPayment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a student')),
        );
        return;
      }
      final amount = double.parse(_amountController.text);
      await ref
          .read(feesProvider.notifier)
          .addPayment(_selectedStudent, amount);
      _clearForm();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment added successfully')),
      );
    }
  }

  List<DropdownMenuItem<String>> _getClassGradeDropdownItems() {
    final students = ref.watch(studentsProvider);
    final classGrades =
        students
            .map((student) => student['classGrade'] as String?)
            .where((grade) => grade != null)
            .map((grade) => grade!)
            .toSet()
            .toList()
          ..sort();
    return classGrades.map<DropdownMenuItem<String>>((grade) {
      return DropdownMenuItem<String>(value: grade, child: Text(grade));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    print('Selected student: [32m$_selectedStudent[0m');
    final fee = _selectedFee;
    print('Fee object: [33m$fee[0m');
    print('All fees: [36m${ref.watch(feesProvider)}[0m');
    final transactions = fee?.transactions ?? [];
    final fees = ref.watch(feesProvider);

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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width:
                                      constraints.maxWidth > 600
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
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
                                  width:
                                      constraints.maxWidth > 600
                                          ? (constraints.maxWidth - 16) / 2
                                          : constraints.maxWidth,
                                  child: DropdownButtonFormField<String>(
                                    value:
                                        _selectedStudent.isEmpty
                                            ? null
                                            : _selectedStudent,
                                    decoration: InputDecoration(
                                      labelText: 'Student',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.person),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    items:
                                        _filteredStudents
                                            .map<DropdownMenuItem<String>>((
                                              student,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: student['id'] as String,
                                                child: Text(
                                                  student['name'] as String,
                                                ),
                                              );
                                            })
                                            .toList(),
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                                'Transactions',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Add Payment'),
                                          content: Form(
                                            key: _formKey,
                                            child: TextFormField(
                                              controller: _amountController,
                                              decoration: const InputDecoration(
                                                labelText: 'Amount',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter amount';
                                                }
                                                if (double.tryParse(value) ==
                                                    null) {
                                                  return 'Please enter a valid amount';
                                                }
                                                return null;
                                              },
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
                                              onPressed: _addPayment,
                                              child: const Text('Add Payment'),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Payment'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (transactions.isEmpty)
                            const Text('No transactions yet.'),
                          if (transactions.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final t = transactions[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      '₹${t.amount.toStringAsFixed(2)}',
                                    ),
                                    subtitle: Text(
                                      'Date: \\${t.date.toLocal()}',
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
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

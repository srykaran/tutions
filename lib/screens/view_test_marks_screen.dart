import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../models/test_marks.dart';
import '../models/batch.dart';
import '../services/test_marks_service.dart';
import '../services/student_service.dart';
import '../providers/batches_provider.dart';
import '../providers/students_provider.dart';
import '../constants/theme.dart';
import 'package:intl/intl.dart';
import 'add_test_marks_screen.dart';

class ViewTestMarksScreen extends ConsumerStatefulWidget {
  const ViewTestMarksScreen({super.key});

  @override
  ConsumerState<ViewTestMarksScreen> createState() => _ViewTestMarksScreenState();
}

class _ViewTestMarksScreenState extends ConsumerState<ViewTestMarksScreen> {
  final _testMarksService = TestMarksService();
  final _studentService = StudentService();
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedBatchId;
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  
  // Test details controllers
  final _testNameController = TextEditingController();
  final _totalMarksController = TextEditingController();
  DateTime _testDate = DateTime.now();
  
  // Student marks map
  final Map<String, TextEditingController> _studentMarksControllers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _totalMarksController.dispose();
    for (var controller in _studentMarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedBatchId != null) {
        // Use cached students from provider
        final allStudents = ref.read(studentsProvider);
        final batchStudents = allStudents.where(
          (student) => (student['batchIds'] as List).contains(_selectedBatchId)
        ).toList();
        
        setState(() {
          _filteredStudents = batchStudents.map((student) => Student(
            id: student['id'],
            name: student['name'],
            contact: student['contact'],
            phone: student['phone'],
            classGrade: student['classGrade'],
            batchId: _selectedBatchId!,
            profilePhotoUrl: student['profilePhotoUrl'],
            joinedDate: DateTime.parse(student['joinedDate']),
          )).toList();
          _initializeStudentMarksControllers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _filteredStudents = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _initializeStudentMarksControllers() {
    // Dispose old controllers
    for (var controller in _studentMarksControllers.values) {
      controller.dispose();
    }
    _studentMarksControllers.clear();

    // Create new controllers for each student
    for (var student in _filteredStudents) {
      _studentMarksControllers[student.id] = TextEditingController();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _testDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _testDate) {
      setState(() {
        _testDate = picked;
      });
    }
  }

  Future<void> _saveAllTestMarks() async {
    if (_formKey.currentState!.validate()) {
      try {
        final totalMarks = double.parse(_totalMarksController.text);
        final selectedBatch = ref.read(batchesProvider).firstWhere(
          (batch) => batch.id == _selectedBatchId,
          orElse: () => throw Exception('Selected batch not found'),
        );

        // Create a map of student marks
        final Map<String, double> studentMarks = {};
        for (var student in _filteredStudents) {
          final marksText = _studentMarksControllers[student.id]?.text;
          if (marksText != null && marksText.isNotEmpty) {
            studentMarks[student.id] = double.parse(marksText);
          }
        }
        
        final testMarks = TestMarks(
          id: _testMarksService.generateId(),
          batchId: selectedBatch.id!,
          testName: _testNameController.text,
          subject: selectedBatch.subject,
          totalMarks: totalMarks,
          testDate: _testDate,
          studentMarks: studentMarks,
        );

        await _testMarksService.addTestMarks(testMarks);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test marks saved successfully')),
          );
          // Clear the form
          _testNameController.clear();
          _totalMarksController.clear();
          for (var controller in _studentMarksControllers.values) {
            controller.clear();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving test marks: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(batchesProvider);
    final lastUpdated = ref.read(studentsProvider.notifier).lastUpdated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Marks'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Last updated: ${DateFormat('MMM d, h:mm a').format(lastUpdated)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(studentsProvider.notifier).loadStudents(forceRefresh: true);
              _loadStudents(); // Reload students after refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing student list...')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Test Marks',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              // Batch Filter
              DropdownButtonFormField<String>(
                value: _selectedBatchId,
                decoration: const InputDecoration(
                  labelText: 'Select Batch',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                items: batches.map((batch) {
                  return DropdownMenuItem(
                    value: batch.id,
                    child: Text('${batch.name} (${batch.subject})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBatchId = value;
                    _loadStudents();
                  });
                },
              ),
              const SizedBox(height: 24),
              // Test Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Test Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_testDate),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _testNameController,
                              decoration: const InputDecoration(
                                labelText: 'Test Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.assignment),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter test name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _totalMarksController,
                              decoration: const InputDecoration(
                                labelText: 'Total Marks',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.grade),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter total marks';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Test Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_testDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Students List with Marks Input
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredStudents.isEmpty
                        ? const Center(child: Text('No students found in this batch'))
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Student Name',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Marks',
                                        style: Theme.of(context).textTheme.titleMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = _filteredStudents[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                              child: Text(
                                                student.name[0].toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    student.name,
                                                    style: Theme.of(context).textTheme.titleMedium,
                                                  ),
                                                  Text(
                                                    'Class: ${student.classGrade}',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: TextFormField(
                                                controller: _studentMarksControllers[student.id],
                                                decoration: const InputDecoration(
                                                  labelText: 'Marks',
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                ),
                                                textAlign: TextAlign.center,
                                                keyboardType: TextInputType.number,
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Required';
                                                  }
                                                  if (double.tryParse(value) == null) {
                                                    return 'Invalid';
                                                  }
                                                  final marks = double.parse(value);
                                                  final totalMarks = double.tryParse(_totalMarksController.text) ?? 0;
                                                  if (marks > totalMarks) {
                                                    return 'Max: $totalMarks';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveAllTestMarks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Save All Marks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentTestMarksScreen extends StatefulWidget {
  final Student student;

  const StudentTestMarksScreen({super.key, required this.student});

  @override
  State<StudentTestMarksScreen> createState() => _StudentTestMarksScreenState();
}

class _StudentTestMarksScreenState extends State<StudentTestMarksScreen> {
  final TestMarksService _testMarksService = TestMarksService();
  Stream<List<TestMarks>>? _testMarksStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTestMarks();
  }

  Future<void> _loadTestMarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _testMarksStream = _testMarksService.getStudentTestMarks(widget.student.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading test marks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Marks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTestMarks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<TestMarks>>(
              stream: _testMarksStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No test marks found'),
                  );
                }

                final testMarks = snapshot.data!;
                return ListView.builder(
                  itemCount: testMarks.length,
                  itemBuilder: (context, index) {
                    final test = testMarks[index];
                    final studentMark = test.studentMarks[widget.student.id] ?? 0.0;
                    final percentage = (studentMark / test.totalMarks) * 100;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    test.testName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  '${studentMark}/${test.totalMarks}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Subject: ${test.subject}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${DateFormat('dd/MM/yyyy').format(test.testDate)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: studentMark / test.totalMarks,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage >= 60
                                    ? Colors.green
                                    : percentage >= 40
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTestMarksScreen(
                student: widget.student,
              ),
            ),
          ).then((_) => _loadTestMarks());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 
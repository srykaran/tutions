import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/theme.dart';
import '../../../models/attendance.dart';
import '../../../models/student.dart';
import '../../../models/batch.dart';
import '../../../providers/batches_provider.dart';
import '../../../providers/students_provider.dart';
import '../../../services/student_service.dart';
import '../../../services/attendance_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _attendanceMap = {};
  final StudentService _studentService = StudentService();
  final AttendanceService _attendanceService = AttendanceService();
  List<Student> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _loadStudents() {
    if (_selectedBatchId != null) {
      setState(() {
        _isLoading = true;
      });
      
      print('Loading students for batch: $_selectedBatchId');
      // Use cached students from provider
      final allStudents = ref.read(studentsProvider);
      print('Total students in cache: ${allStudents.length}');
      
      final batchStudents = allStudents.where(
        (student) {
          // Safely handle batchIds
          final batchIds = student['batchIds'];
          if (batchIds == null) {
            print('Student ${student['name']} has no batchIds');
            return false;
          }
          
          // Convert to List if it's not already
          final List<dynamic> batchIdList = batchIds is List ? batchIds : [batchIds];
          final hasBatch = batchIdList.contains(_selectedBatchId);
          print('Student ${student['name']} batchIds: $batchIdList, hasBatch: $hasBatch');
          return hasBatch;
        }
      ).toList();
      
      print('Found ${batchStudents.length} students in batch');
      
      setState(() {
        _students = batchStudents.map((student) {
          // Safely parse the joinedDate
          DateTime joinedDate;
          try {
            joinedDate = DateTime.parse(student['joinedDate'] ?? DateTime.now().toIso8601String());
          } catch (e) {
            print('Error parsing joinedDate for student ${student['name']}, using current date');
            joinedDate = DateTime.now();
          }

          return Student(
            id: student['id'],
            name: student['name'] ?? '',
            contact: student['contact'] ?? '',
            phone: student['phone'] ?? '',
            classGrade: student['classGrade'] ?? '',
            batchId: _selectedBatchId!,
            profilePhotoUrl: student['profilePhotoUrl'],
            joinedDate: joinedDate,
          );
        }).toList();
        _initializeAttendanceMap();
        _isLoading = false;
      });
    }
  }

  void _initializeAttendanceMap() {
    _attendanceMap.clear();
    for (var student in _students) {
      _attendanceMap[student.id] = true; // Default to present
    }
    print('Initialized attendance map for ${_students.length} students');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _markAttendance() async {
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch first')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final batch = await FirebaseFirestore.instance
          .collection('batches')
          .doc(_selectedBatchId)
          .get();

      if (!batch.exists) {
        throw Exception('Batch not found');
      }

      final batchData = batch.data() as Map<String, dynamic>;
      final batchName = batchData['name'] as String;

      // Create a single attendance document for the batch
      final attendanceCollection = FirebaseFirestore.instance.collection('attendance');
      
      // Get list of absent students' names
      final absentStudents = _students
          .where((student) => _attendanceMap[student.id] == false)
          .map((student) => student.name)
          .toList();

      // Create a new document with batch ID and date as part of the ID
      final docId = '${_selectedBatchId}_${DateFormat('yyyyMMdd').format(_selectedDate)}';
      
      await attendanceCollection.doc(docId).set({
        'batchId': _selectedBatchId,
        'batchName': batchName,
        'date': Timestamp.fromDate(_selectedDate),
        'absentStudents': absentStudents,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark attendance: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(batchesProvider);
    final lastUpdated = ref.read(studentsProvider.notifier).lastUpdated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
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
              print('Manual refresh requested');
              ref.read(studentsProvider.notifier).loadStudents(forceRefresh: true);
              _loadStudents(); // Reload students after refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing student list...')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedBatchId,
                            decoration: const InputDecoration(
                              labelText: 'Select Batch',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.class_),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: batches.map((batch) {
                              return DropdownMenuItem(
                                value: batch.id,
                                child: Text(batch.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              print('Batch selected: $value');
                              if (value != null) {
                                setState(() {
                                  _selectedBatchId = value;
                                  _loadStudents();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_students.isEmpty && _selectedBatchId != null)
                const Center(
                  child: Text('No students found in this batch'),
                )
              else if (_students.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final isPresent = _attendanceMap[student.id] ?? true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                backgroundImage: student.profilePhotoUrl != null
                                    ? NetworkImage(student.profilePhotoUrl!)
                                    : null,
                                child: student.profilePhotoUrl == null
                                    ? Text(
                                        student.name[0],
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      student.classGrade,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _attendanceMap[student.id] = !isPresent;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !isPresent ? Colors.red : Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Absent'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              if (_students.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _markAttendance,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 
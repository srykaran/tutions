import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../constants/theme.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/batches_provider.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';
import 'package:intl/intl.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _searchQuery = '';
  String? _selectedClass;
  String? _selectedBatchId;

  void _deleteStudent(String id) {
    ref.read(studentsProvider.notifier).deleteStudent(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Student deleted')));
  }

  List<Map<String, dynamic>> _getFilteredStudents(
    List<Map<String, dynamic>> students,
  ) {
    return students.where((student) {
      // Search by name
      final nameMatch = student['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      // Filter by class
      final classMatch =
          _selectedClass == null || student['classGrade'] == _selectedClass;

      // Filter by batch
      final batchMatch =
          _selectedBatchId == null ||
          (student['batchIds'] as List<dynamic>?)?.contains(_selectedBatchId) ==
              true;

      return nameMatch && classMatch && batchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsProvider);
    final batches = ref.watch(batchesProvider);
    final lastUpdated = ref.read(studentsProvider.notifier).lastUpdated;

    // Get unique classes from batches
    final classes =
        batches.map((batch) => batch.classGrade).toSet().toList()..sort();

    // Filter students based on search and filters
    final filteredStudents = _getFilteredStudents(students);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: AppTheme.primaryColor,
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
              ref
                  .read(studentsProvider.notifier)
                  .loadStudents(forceRefresh: true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing student list...')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddStudentScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search and Filter Section
            Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filters Row
                Row(
                  children: [
                    // Class Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClass,
                        decoration: InputDecoration(
                          labelText: 'Filter by Class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Classes'),
                          ),
                          ...classes.map((className) {
                            return DropdownMenuItem<String>(
                              value: className,
                              child: Text(className),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClass = value;
                            _selectedBatchId =
                                null; // Reset batch filter when class changes
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Batch Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBatchId,
                        decoration: InputDecoration(
                          labelText: 'Filter by Batch',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Batches'),
                          ),
                          ...batches
                              .where(
                                (batch) =>
                                    _selectedClass == null ||
                                    batch.classGrade == _selectedClass,
                              )
                              .map((batch) {
                                return DropdownMenuItem<String>(
                                  value: batch.id.toString(),
                                  child: Text(
                                    '${batch.name} (${batch.timing})',
                                  ),
                                );
                              })
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedBatchId = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  filteredStudents.isEmpty
                      ? const Center(child: Text('No students found'))
                      : ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          final studentBatches = (student['batchIds']
                                  as List<dynamic>?)
                              ?.map((batchId) {
                                try {
                                  return batches.firstWhere(
                                    (batch) =>
                                        batch.id.toString() ==
                                        batchId.toString(),
                                  );
                                } catch (e) {
                                  return null;
                                }
                              })
                              .whereType<dynamic>()
                              .map((batch) => '${batch.name} (${batch.timing})')
                              .join(', ');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.1),
                                backgroundImage:
                                    student['profilePhotoUrl'] != null
                                        ? NetworkImage(
                                          student['profilePhotoUrl'],
                                        )
                                        : null,
                                child:
                                    student['profilePhotoUrl'] == null
                                        ? Text(
                                          student['name'][0],
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                              title: Text(student['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${student['classGrade']} - ${student['schoolName']}',
                                  ),
                                  if (studentBatches != null &&
                                      studentBatches.isNotEmpty)
                                    Text(
                                      'Batches: $studentBatches',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => EditStudentScreen(
                                                student: student,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _deleteStudent(student['id']),
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
    );
  }
}

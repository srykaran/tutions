import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/theme.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/batches_provider.dart';

class EditStudentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> student;

  const EditStudentScreen({super.key, required this.student});

  @override
  ConsumerState<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends ConsumerState<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _schoolNameController;
  String? _selectedClass;
  List<String> _selectedBatchIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student['name']);
    _contactController = TextEditingController(text: widget.student['contact']);
    _phoneController = TextEditingController(text: widget.student['phone']);
    _schoolNameController = TextEditingController(
      text: widget.student['schoolName'],
    );
    _selectedClass = widget.student['classGrade'];
    _selectedBatchIds = List<String>.from(widget.student['batchIds'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    super.dispose();
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newBatchIds = _selectedBatchIds.map((id) => id.toString()).toList();
      final double totalFees = newBatchIds.length * 2000.0;

      final updatedStudent = {
        'name': _nameController.text,
        'contact': _contactController.text,
        'phone': _phoneController.text,
        'schoolName': _schoolNameController.text,
        'classGrade': _selectedClass,
        'batchIds': newBatchIds,
        'totalFees': totalFees,
      };

      print(
        'Updating student \\${widget.student['id']} with: \\${updatedStudent}',
      );

      await ref
          .read(studentsProvider.notifier)
          .updateStudent(widget.student['id'], updatedStudent);

      // Force reload students from Firestore
      await ref
          .read(studentsProvider.notifier)
          .loadStudents(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating student: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBatches =
        ref.watch(batchesProvider).where((batch) => batch.isVisible).toList();
    final classes =
        allBatches.map((batch) => batch.classGrade).toSet().toList()..sort();
    final filteredBatches =
        _selectedClass != null
            ? allBatches
                .where((batch) => batch.classGrade == _selectedClass)
                .toList()
            : allBatches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Student'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contact_phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact person name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _schoolNameController,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter school name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                ),
                items:
                    classes.map((className) {
                      return DropdownMenuItem<String>(
                        value: className,
                        child: Text(className),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                    _selectedBatchIds =
                        []; // Clear selected batches when class changes
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a class';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Batches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_selectedClass == null)
                const Text('Please select a class first')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBatches.length,
                  itemBuilder: (context, index) {
                    final batch = filteredBatches[index];
                    return CheckboxListTile(
                      title: Text('${batch.name} (${batch.timing})'),
                      subtitle: Text(batch.subject),
                      value: _selectedBatchIds.contains(batch.id.toString()),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedBatchIds.add(batch.id.toString());
                          } else {
                            _selectedBatchIds.remove(batch.id.toString());
                          }
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

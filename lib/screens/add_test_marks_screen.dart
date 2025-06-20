import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/test_marks.dart';
import '../services/test_marks_service.dart';
import '../providers/batches_provider.dart';

class AddTestMarksScreen extends ConsumerStatefulWidget {
  final Student student;

  const AddTestMarksScreen({
    super.key,
    required this.student,
  });

  @override
  ConsumerState<AddTestMarksScreen> createState() => _AddTestMarksScreenState();
}

class _AddTestMarksScreenState extends ConsumerState<AddTestMarksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _marksController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _remarksController = TextEditingController();
  final _testMarksService = TestMarksService();
  DateTime _testDate = DateTime.now();

  @override
  void dispose() {
    _testNameController.dispose();
    _marksController.dispose();
    _totalMarksController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _testDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _testDate) {
      setState(() {
        _testDate = picked;
      });
    }
  }

  Future<void> _saveTestMarks() async {
    if (_formKey.currentState!.validate()) {
      try {
        final totalMarks = double.parse(_totalMarksController.text);
        final marks = double.parse(_marksController.text);
        
        if (marks > totalMarks) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marks cannot be greater than total marks'),
            ),
          );
          return;
        }

        // Get the batch to get its subject
        final batch = ref.read(batchesProvider).firstWhere(
          (batch) => batch.id == widget.student.batchId,
          orElse: () => throw Exception('Batch not found'),
        );

        final testMarks = TestMarks(
          id: _testMarksService.generateId(),
          batchId: widget.student.batchId,
          testName: _testNameController.text,
          subject: batch.subject,
          totalMarks: totalMarks,
          testDate: _testDate,
          studentMarks: {widget.student.id: marks},
        );

        await _testMarksService.addTestMarks(testMarks);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test marks saved successfully')),
          );
          Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Test Marks'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _testNameController,
                decoration: const InputDecoration(
                  labelText: 'Test Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter test name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalMarksController,
                decoration: const InputDecoration(
                  labelText: 'Total Marks',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _marksController,
                decoration: const InputDecoration(
                  labelText: 'Marks Obtained',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter marks obtained';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Test Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_testDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTestMarks,
                  child: const Text('Save Test Marks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
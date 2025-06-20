import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/theme.dart';
import '../../../widgets/teacher_card.dart';
import '../../../widgets/teacher_form.dart';
import '../../../providers/teachers_provider.dart';

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _educationController = TextEditingController();
  String? _selectedSubject;
  String? _selectedExperience;
  bool _isLoading = false;

  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
  ];

  final List<String> _experienceLevels = [
    '0-2 years',
    '2-5 years',
    '5-10 years',
    '10+ years',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Teacher'),
            content: SingleChildScrollView(
              child: TeacherForm(
                formKey: _formKey,
                nameController: _nameController,
                emailController: _emailController,
                phoneController: _phoneController,
                educationController: _educationController,
                selectedSubject: _selectedSubject,
                selectedExperience: _selectedExperience,
                subjects: _subjects,
                experienceLevels: _experienceLevels,
                onSubjectChanged: (value) {
                  setState(() => _selectedSubject = value);
                },
                onExperienceChanged: (value) {
                  setState(() => _selectedExperience = value);
                },
                isLoading: _isLoading,
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
                onPressed: _isLoading ? null : _handleAddTeacher,
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _educationController.clear();
    if (mounted) {
      setState(() {
        _selectedSubject = null;
        _selectedExperience = null;
      });
    }
  }

  Future<void> _handleAddTeacher() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (mounted) {
          setState(() => _isLoading = true);
        }

        final teacherData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'subject': _selectedSubject,
          'education': _educationController.text,
          'experience': _selectedExperience,
          'isActive': true,
        };

        await ref.read(teachersProvider.notifier).addTeacher(teacherData);

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add teacher: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Teachers',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddTeacherDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return TeacherCard(
                    teacher: teacher,
                    onEdit: () {
                      // TODO: Implement edit functionality
                    },
                    onDelete: () async {
                      try {
                        await ref
                            .read(teachersProvider.notifier)
                            .deleteTeacher(teacher['id']);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teacher deleted successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to delete teacher: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      }
                    },
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

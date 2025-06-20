import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeacherForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController educationController;
  final String? selectedSubject;
  final String? selectedExperience;
  final List<String> subjects;
  final List<String> experienceLevels;
  final Function(String?) onSubjectChanged;
  final Function(String?) onExperienceChanged;
  final bool isLoading;

  const TeacherForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.educationController,
    required this.selectedSubject,
    required this.selectedExperience,
    required this.subjects,
    required this.experienceLevels,
    required this.onSubjectChanged,
    required this.onExperienceChanged,
    this.isLoading = false,
  });

  @override
  State<TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherForm> {
  final _inputDecoration = const InputDecoration(
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNameField(),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildSubjectDropdown(),
          const SizedBox(height: 16),
          _buildEducationField(),
          const SizedBox(height: 16),
          _buildExperienceDropdown(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: widget.nameController,
      decoration: _inputDecoration.copyWith(
        labelText: 'Full Name',
        prefixIcon: const Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter teacher name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: widget.emailController,
      decoration: _inputDecoration.copyWith(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: widget.phoneController,
      decoration: _inputDecoration.copyWith(
        labelText: 'Phone Number',
        prefixIcon: const Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        if (value.length != 10) {
          return 'Please enter a valid 10-digit phone number';
        }
        return null;
      },
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      value: widget.selectedSubject,
      decoration: _inputDecoration.copyWith(
        labelText: 'Subject',
        prefixIcon: const Icon(Icons.book),
      ),
      items: widget.subjects.map((subject) {
        return DropdownMenuItem(
          value: subject,
          child: Text(subject),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a subject';
        }
        return null;
      },
      onChanged: widget.onSubjectChanged,
    );
  }

  Widget _buildEducationField() {
    return TextFormField(
      controller: widget.educationController,
      decoration: _inputDecoration.copyWith(
        labelText: 'Education',
        prefixIcon: const Icon(Icons.school),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter education details';
        }
        return null;
      },
    );
  }

  Widget _buildExperienceDropdown() {
    return DropdownButtonFormField<String>(
      value: widget.selectedExperience,
      decoration: _inputDecoration.copyWith(
        labelText: 'Experience',
        prefixIcon: const Icon(Icons.work),
      ),
      items: widget.experienceLevels.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(level),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select experience level';
        }
        return null;
      },
      onChanged: widget.onExperienceChanged,
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../constants/theme.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/batches_provider.dart';
import '../../../services/cloudinary_service.dart';
import 'add_student_screen.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _classGradeController = TextEditingController();
  final _addressController = TextEditingController();
  final _schoolNameController = TextEditingController();
  List<String> _selectedBatchIds = [];
  String? _selectedClass;
  File? _selectedImage;

  // Add this field to store image bytes for web
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _classGradeController.dispose();
    _addressController.dispose();
    _schoolNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final originalSize = file.size;
        print('Original image size: ${(originalSize / 1024).toStringAsFixed(2)}KB');
        
        if (kIsWeb) {
          // For web, we'll use the bytes directly
          if (file.bytes != null) {
            final compressedBytes = await FlutterImageCompress.compressWithList(
              file.bytes!,
              minHeight: 1024,
              minWidth: 1024,
              quality: 85,
            );
            
            print('First compression size: ${(compressedBytes.length / 1024).toStringAsFixed(2)}KB');
            
            if (compressedBytes.length > 100 * 1024) {
              final secondCompressedBytes = await FlutterImageCompress.compressWithList(
                compressedBytes,
                minHeight: 800,
                minWidth: 800,
                quality: 70,
              );
              print('Second compression size: ${(secondCompressedBytes.length / 1024).toStringAsFixed(2)}KB');
              setState(() {
                _selectedImageBytes = secondCompressedBytes;
              });
            } else {
              setState(() {
                _selectedImageBytes = compressedBytes;
              });
            }
          }
        } else {
          // For mobile, we'll use files
          if (file.path != null) {
            final tempDir = await getTemporaryDirectory();
            final tempPath = tempDir.path;
            
            final compressedBytes = await FlutterImageCompress.compressWithFile(
              file.path!,
              minHeight: 1024,
              minWidth: 1024,
              quality: 85,
            );
            
            if (compressedBytes != null) {
              print('First compression size: ${(compressedBytes.length / 1024).toStringAsFixed(2)}KB');
              
              if (compressedBytes.length > 100 * 1024) {
                final tempFile = File(path.join(tempPath, 'temp_${DateTime.now().millisecondsSinceEpoch}.jpg'));
                await tempFile.writeAsBytes(compressedBytes);
                
                final secondCompressedBytes = await FlutterImageCompress.compressWithFile(
                  tempFile.path,
                  minHeight: 800,
                  minWidth: 800,
                  quality: 70,
                );
                
                await tempFile.delete();
                
                if (secondCompressedBytes != null) {
                  print('Second compression size: ${(secondCompressedBytes.length / 1024).toStringAsFixed(2)}KB');
                  final finalFile = File(path.join(tempPath, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'));
                  await finalFile.writeAsBytes(secondCompressedBytes);
                  setState(() {
                    _selectedImage = finalFile;
                  });
                }
              } else {
                final finalFile = File(path.join(tempPath, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'));
                await finalFile.writeAsBytes(compressedBytes);
                setState(() {
                  _selectedImage = finalFile;
                });
              }
            }
          }
        }
        
        // Show compression result to user
        final finalSize = kIsWeb ? _selectedImageBytes!.length : _selectedImage!.lengthSync();
        final compressionRatio = (originalSize / finalSize).toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image compressed from ${(originalSize / 1024).toStringAsFixed(1)}KB to ${(finalSize / 1024).toStringAsFixed(1)}KB (${compressionRatio}x smaller)'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error picking or compressing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _contactController.clear();
    _phoneController.clear();
    _classGradeController.clear();
    _addressController.clear();
    _schoolNameController.clear();
    setState(() {
      _selectedBatchIds = [];
      _selectedClass = null;
      _selectedImage = null;
    });
  }

  void _addStudent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBatchIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one batch')),
        );
        return;
      }

      try {
        String? profilePhotoUrl;
        if (_selectedImage != null || _selectedImageBytes != null) {
          final cloudinaryService = CloudinaryService();
          if (kIsWeb && _selectedImageBytes != null) {
            profilePhotoUrl = await cloudinaryService.uploadImageFromBytes(_selectedImageBytes!);
          } else if (_selectedImage != null) {
            profilePhotoUrl = await cloudinaryService.uploadImage(_selectedImage!);
          }
        }

        // Calculate total fees based on number of selected batches (2000 per batch)
        final totalFees = _selectedBatchIds.length * 2000;

        final studentData = {
          'name': _nameController.text,
          'contact': _contactController.text,
          'phone': _phoneController.text,
          'classGrade': _classGradeController.text,
          'address': _addressController.text,
          'schoolName': _schoolNameController.text,
          'batchIds': _selectedBatchIds,
          'joinedDate': DateTime.now().toIso8601String(),
          'profilePhotoUrl': profilePhotoUrl,
          'totalFees': totalFees,
          'paidFees': 0, // Initialize paid fees as 0
        };

        await ref.read(studentsProvider.notifier).addStudent(studentData);
        _clearForm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding student: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBatches = ref.watch(batchesProvider).where((batch) => batch.isVisible).toList();
    final classes = allBatches.map((batch) => batch.classGrade).toSet().toList()..sort();
    final filteredBatches = _selectedClass != null
        ? allBatches.where((batch) => batch.classGrade == _selectedClass).toList()
        : allBatches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student'),
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
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: _selectedImage != null || _selectedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _selectedImage!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
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
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter EmailID';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _classGradeController.text.isEmpty ? null : _classGradeController.text,
                decoration: const InputDecoration(
                  labelText: 'Class Grade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                ),
                items: const [
                  DropdownMenuItem(value: '9th', child: Text('9th')),
                  DropdownMenuItem(value: '10th', child: Text('10th')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select class grade';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    _classGradeController.text = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Filter by Class',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_list),
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
                    _selectedBatchIds = []; // Clear selected batches when class changes
                  });
                },
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select Batches',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Divider(height: 1),
                    if (filteredBatches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No batches available for the selected class',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
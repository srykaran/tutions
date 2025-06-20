import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/theme.dart';
import '../../../models/attendance.dart';
import '../../../models/batch.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/attendance_service.dart';
import 'package:intl/intl.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  String? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();
  final AttendanceService _attendanceService = AttendanceService();
  List<Batch> _teacherBatches = [];
  bool _isLoading = false;
  String? _teacherId;
  String? _errorMessage;
  Map<String, Map<String, dynamic>> _batchAttendance = {};

  @override
  void initState() {
    super.initState();
    _loadTeacherBatches();
  }

  Future<void> _loadTeacherBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      print('Loading batches for user email: ${user.email}'); // Debug log

      // First, get the user document from the users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      print('User document data: ${userDoc.data()}'); // Debug log

      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      // Get the email from the user document to ensure we use the exact same case
      final userEmail = userDoc.data()?['email'] as String?;
      if (userEmail == null) {
        setState(() {
          _errorMessage = 'Email not found in user profile';
          _isLoading = false;
        });
        return;
      }

      // Now get the teacher's profile from the teachers collection using the exact email
      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .get();

      print('Teacher query results: ${teacherQuery.docs.length} documents found'); // Debug log
      print('Searching for email: $userEmail'); // Debug log

      if (teacherQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Teacher profile not found. Please contact administrator.';
          _isLoading = false;
        });
        return;
      }

      final teacherData = teacherQuery.docs.first.data();
      _teacherId = teacherQuery.docs.first.id;
      print('Found teacher ID: $_teacherId'); // Debug log
      print('Teacher data: $teacherData'); // Debug log

      // Now fetch batches assigned to this teacher
      final batchesSnapshot = await FirebaseFirestore.instance
          .collection('batches')
          .where('teacherId', isEqualTo: _teacherId)
          .get();

      print('Found ${batchesSnapshot.docs.length} batches for teacher'); // Debug log

      setState(() {
        _teacherBatches = batchesSnapshot.docs.map((doc) {
          final data = doc.data();
          return Batch(
            id: doc.id,
            name: data['name'] as String,
            timing: data['timing'] as String,
            description: data['description'] as String,
            startDate: (data['startDate'] as Timestamp).toDate(),
            endDate: (data['endDate'] as Timestamp).toDate(),
            isVisible: data['isVisible'] as bool? ?? true,
            classGrade: data['classGrade'] as String,
            subject: data['subject'] as String,
            teacherId: data['teacherId'] as String,
            teacherName: data['teacherName'] as String?,
          );
        }).toList();
        _isLoading = false;
      });

      // Load attendance for all batches
      for (var batch in _teacherBatches) {
        await _loadBatchAttendance(batch.id!);
      }
    } catch (e) {
      print('Error in _loadTeacherBatches: $e'); // Debug log
      setState(() {
        _errorMessage = 'Error loading batches: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBatchAttendance(String batchId) async {
    try {
      final today = DateTime.now();
      final docId = '${batchId}_${DateFormat('yyyyMMdd').format(today)}';
      
      final attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(docId)
          .get();

      if (attendanceDoc.exists) {
        final data = attendanceDoc.data()!;
        setState(() {
          _batchAttendance[batchId] = data;
        });
      } else {
        setState(() {
          _batchAttendance[batchId] = {
            'absentStudents': [],
            'date': Timestamp.fromDate(today),
          };
        });
      }
    } catch (e) {
      print('Error loading attendance for batch $batchId: $e');
    }
  }

  void _showAttendanceDialog(Batch batch) {
    final attendanceData = _batchAttendance[batch.id] ?? {};
    final absentStudents = attendanceData['absentStudents'] as List<dynamic>? ?? [];
    final date = attendanceData['date'] as Timestamp? ?? Timestamp.fromDate(DateTime.now());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Today\'s Attendance - ${batch.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(date.toDate())}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (absentStudents.isEmpty)
                const Text('No absent students today')
              else ...[
                const Text(
                  'Absent Students:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: absentStudents.length,
                    itemBuilder: (context, index) {
                      final studentName = absentStudents[index] as String;
                      return ListTile(
                        title: Text(studentName),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(Batch batch) {
    final attendanceData = _batchAttendance[batch.id] ?? {};
    final absentStudents = attendanceData['absentStudents'] as List<dynamic>? ?? [];
    final absentCount = absentStudents.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAttendanceDialog(batch),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      batch.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      batch.classGrade,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    batch.timing,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.book, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    batch.subject,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                batch.description,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(batch.startDate)} - ${DateFormat('dd/MM/yyyy').format(batch.endDate)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (attendanceData.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: absentCount > 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$absentCount Absent',
                        style: TextStyle(
                          color: absentCount > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Batches',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeacherBatches,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_teacherBatches.isEmpty)
                const Center(
                  child: Text('No batches assigned yet'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _teacherBatches.length,
                    itemBuilder: (context, index) {
                      final batch = _teacherBatches[index];
                      return _buildBatchCard(batch);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 
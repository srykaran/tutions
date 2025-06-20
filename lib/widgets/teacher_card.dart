import 'package:flutter/material.dart';
import '../constants/theme.dart';

class TeacherCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _buildAvatar(),
        title: Text(
          teacher['name'] ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          teacher['subject'] ?? 'No Subject',
          style: TextStyle(color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', teacher['email'] ?? 'No Email'),
                _buildDetailRow('Phone', teacher['phone'] ?? 'No Phone'),
                _buildDetailRow('Education', teacher['education'] ?? 'No Education'),
                _buildDetailRow('Experience', teacher['experience'] ?? 'No Experience'),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      child: Text(
        (teacher['name'] ?? '?')[0].toUpperCase(),
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('Edit'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          label: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
} 
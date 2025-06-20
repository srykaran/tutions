import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/batch.dart';

class BatchCard extends StatelessWidget {
  final Batch batch;
  final VoidCallback onDelete;

  const BatchCard({
    super.key,
    required this.batch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildDescription(),
            const SizedBox(height: 8),
            _buildDateRange(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                batch.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                batch.timing,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      batch.description,
      style: TextStyle(
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildDateRange() {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '${DateFormat('dd/MM/yyyy').format(batch.startDate)} - ${DateFormat('dd/MM/yyyy').format(batch.endDate)}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 
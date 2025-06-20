import 'package:flutter/material.dart';
import '../../../constants/theme.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Sankalp Academy',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          // Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              final childAspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.0;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildSummaryCard(
                    context,
                    'Total Students',
                    '150',
                    Icons.people,
                    AppTheme.primaryColor,
                  ),
                  _buildSummaryCard(
                    context,
                    'Total Fees',
                    '₹2,50,000',
                    Icons.payments,
                    AppTheme.successColor,
                  ),
                  _buildSummaryCard(
                    context,
                    'Total Batches',
                    '12',
                    Icons.class_,
                    AppTheme.secondaryColor,
                  ),
                  _buildSummaryCard(
                    context,
                    'Pending Fees',
                    '₹45,000',
                    Icons.pending_actions,
                    AppTheme.errorColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        final activities = [
          {'title': 'New Student Registration', 'time': '2 hours ago'},
          {'title': 'Fee Payment Received', 'time': '3 hours ago'},
          {'title': 'New Batch Created', 'time': '5 hours ago'},
          {'title': 'Homework Assigned', 'time': '1 day ago'},
          {'title': 'Attendance Marked', 'time': '1 day ago'},
        ];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.notifications,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              activities[index]['title']!,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              activities[index]['time']!,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Handle activity tap
            },
          ),
        );
      },
    );
  }
} 
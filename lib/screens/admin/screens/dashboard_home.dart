import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/theme.dart';
import '../../../services/summary_dashboard_service.dart';
import '../../../models/summary_dashboard.dart';
import '../../../main.dart'; // for firebaseProvider

class DashboardHome extends ConsumerStatefulWidget {
  const DashboardHome({super.key});

  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  late Future<SummaryDashboard> _summaryFuture;

  @override
  void initState() {
    super.initState();
    // Do not call getSummary here; wait for Firebase in build
  }

  @override
  Widget build(BuildContext context) {
    final firebaseInit = ref.watch(firebaseProvider);
    return firebaseInit.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Firebase init error: $err')),
      data: (_) => _buildDashboardContent(context),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    // Only call getSummary after Firebase is ready
    _summaryFuture = SummaryDashboardService().getSummary();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Welcome to Sankalp Academy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              Tooltip(
                message:
                    'Platform is in testing mode. Keep manual records too to be safe from data loss.',
                child: Chip(
                  label: Text(
                    'Beta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Summary Cards
          FutureBuilder<SummaryDashboard>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildSummaryGrid(
                  totalStudents: 0,
                  totalFees: 0.0,
                  totalBatches: 0,
                  paidFees: 0.0,
                  pendingFees: 0.0,
                  error: 'Error loading summary',
                );
              }
              final summary =
                  snapshot.data ??
                  SummaryDashboard(
                    totalStudents: 0,
                    totalBatches: 0,
                    totalFees: 0.0,
                    paidFees: 0.0,
                  );
              final pendingFees = summary.totalFees - summary.paidFees;
              return _buildSummaryGrid(
                totalStudents: summary.totalStudents,
                totalFees: summary.totalFees,
                totalBatches: summary.totalBatches,
                paidFees: summary.paidFees,
                pendingFees: pendingFees,
              );
            },
          ),
          const SizedBox(height: 24),
          // 🚧 Upcoming student, teacher, parent app soon...
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction, size: 48, color: Colors.black54),
                  SizedBox(height: 16),
                  Text(
                    'Upcoming Student, Teacher & Parent Apps',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We are working hard to bring dedicated apps for students, teachers, and parents very soon. Stay tuned for updates!',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid({
    required int totalStudents,
    required double totalFees,
    required int totalBatches,
    required double paidFees,
    required double pendingFees,
    String? error,
  }) {
    return Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(error, style: TextStyle(color: Colors.red)),
          ),
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
                  totalStudents.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
                _buildSummaryCard(
                  context,
                  'Total Fees',
                  '₹${totalFees.toStringAsFixed(0)}',
                  Icons.payments,
                  AppTheme.successColor,
                ),
                _buildSummaryCard(
                  context,
                  'Total Batches',
                  totalBatches.toString(),
                  Icons.class_,
                  AppTheme.secondaryColor,
                ),
                _buildSummaryCard(
                  context,
                  'Pending Fees',
                  '₹${pendingFees.toStringAsFixed(0)}',
                  Icons.pending_actions,
                  AppTheme.errorColor,
                ),
              ],
            );
          },
        ),
      ],
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
              child: Icon(Icons.notifications, color: AppTheme.primaryColor),
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

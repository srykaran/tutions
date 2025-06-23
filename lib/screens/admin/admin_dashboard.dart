import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import 'screens/dashboard_home.dart';
import 'screens/teachers_screen.dart';
import 'screens/batches_screen.dart';
import 'screens/students_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/homework_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import '../../providers/auth_provider.dart';
import '../view_test_marks_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardHome();
      case 1:
        return const TeachersScreen();
      case 2:
        return const BatchesScreen();
      case 3:
        return const StudentsScreen();
      case 4:
        return const AttendanceScreen();
      case 5:
        return const FeesScreen();
      case 6:
        return const ViewTestMarksScreen();
      case 7:
        return const SettingsScreen();
      default:
        return const DashboardHome();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sankalp Academy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              final user = ref.read(authProvider).user;
              final userRole = ref.read(authProvider).userRole;

              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Profile'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Email'),
                            subtitle: Text(user?.email ?? 'Not available'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.work),
                            title: const Text('Role'),
                            subtitle: Text(
                              userRole?.toUpperCase() ?? 'Not available',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(dashboardProvider.notifier).setSelectedIndex(index);
          if (context.mounted) {
            Navigator.pop(context); // Close drawer
          }
        },
        children: const [
          NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Teachers'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: Text('Batches'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: Text('Students'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: Text('Attendance'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: Text('Fees'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: Text('Test Marks'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Settings'),
          ),
        ],
      ),
      body: _getScreen(selectedIndex),
    );
  }
}

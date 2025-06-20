import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';

// Add a FutureProvider for Firebase initialization
final firebaseProvider = FutureProvider<FirebaseApp>((ref) async {
  return await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseInit = ref.watch(firebaseProvider);
    return MaterialApp(
      title: 'Sankalp Academy',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: firebaseInit.when(
        loading: () => const SplashScreen(),
        error:
            (err, stack) => Scaffold(
              body: Center(child: Text('Firebase init error:\n\n\$err')),
            ),
        data: (_) => const _AppContent(),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/teacher-dashboard': (context) => const TeacherDashboard(),
      },
    );
  }
}

// Simple splash screen widget
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AppContent extends ConsumerWidget {
  const _AppContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // User is logged in, check role
          final userRole = ref.watch(authProvider).userRole;
          if (userRole == 'admin') {
            return const AdminDashboard();
          } else if (userRole == 'teacher') {
            return const TeacherDashboard();
          } else {
            // Unknown role, show login screen
            return const LoginScreen();
          }
        }
        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? userRole;
  final String? userId;
  final User? user;

  AuthState({
    this.isAuthenticated = false,
    this.userRole,
    this.userId,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userRole,
    String? userId,
    User? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState()) {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      print('AuthProvider: Auth state changed. User: ${user?.email}');
      if (user != null) {
        try {
          // Get user role from Firestore
          print('AuthProvider: Fetching user role from Firestore');
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          print('AuthProvider: Firestore user data: ${userDoc.data()}');
          final userRole = userDoc.data()?['role'] as String?;
          
          if (userRole == null) {
            print('AuthProvider: User role not found');
            await _auth.signOut();
            return;
          }
          
          print('AuthProvider: User role retrieved: $userRole');
          print('AuthProvider: Firebase Auth email: ${user.email}');
          print('AuthProvider: Firebase Auth UID: ${user.uid}');
          
          // Store user data in secure storage
          await _storage.write(key: 'userId', value: user.uid);
          await _storage.write(key: 'userRole', value: userRole);
          await _storage.write(key: 'userEmail', value: user.email);
          
          state = state.copyWith(
            isAuthenticated: true,
            userId: user.uid,
            userRole: userRole,
            user: user,
          );
          
          print('AuthProvider: State updated successfully');
        } catch (e) {
          print('AuthProvider: Error updating state: $e');
          await _auth.signOut();
        }
      } else {
        // Clear secure storage when user logs out
        await _storage.deleteAll();
        state = AuthState();
        print('AuthProvider: User logged out, state cleared');
      }
    });

    // Check for existing session on startup
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      print('AuthProvider: Checking for existing session');
      final userId = await _storage.read(key: 'userId');
      final userRole = await _storage.read(key: 'userRole');
      final userEmail = await _storage.read(key: 'userEmail');

      if (userId != null && userRole != null && userEmail != null) {
        print('AuthProvider: Found existing session for user: $userEmail');
        // The auth state listener will handle updating the state
      } else {
        print('AuthProvider: No existing session found');
      }
    } catch (e) {
      print('AuthProvider: Error checking existing session: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      print('AuthProvider: Checking Firebase initialization...');
      if (Firebase.apps.isEmpty) {
        print('AuthProvider: Firebase not initialized, attempting to initialize...');
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBtAsUdptZUemLv5h3HD36Y4lmFIxovd-U",
            appId: "1:518253249676:android:ed88a7d9f6861a2e0a27a9",
            messagingSenderId: "518253249676",
            projectId: "sankalpacademy-66de9",
            storageBucket: "sankalpacademy-66de9.firebasestorage.app",
          ),
        );
        print('AuthProvider: Firebase initialized successfully');
      }

      print('AuthProvider: Attempting to sign in with email: $email');
      
      // Set persistence only for web platform
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
      }
      
      UserCredential? userCredential;
      try {
        // Try to sign in first
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // Check if user exists
        try {
          final methods = await _auth.fetchSignInMethodsForEmail(email);
          if (methods.isEmpty) {
            // User doesn't exist, create new user
            print('AuthProvider: User not found, creating new user');
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            // Create user document in Firestore with teacher role
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'role': 'teacher',
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });
            print('AuthProvider: New user created with teacher role');
          } else {
            // User exists but password is wrong
            throw FirebaseAuthException(
              code: 'wrong-password',
              message: 'Wrong password provided.',
            );
          }
        } catch (e) {
          // Re-throw other errors
          throw e;
        }
      }
      
      print('AuthProvider: Firebase Auth successful. User ID: ${userCredential.user?.uid}');
      print('AuthProvider: Firebase Auth email: ${userCredential.user?.email}');
      
      if (userCredential.user != null) {
        // Get user role from Firestore
        print('AuthProvider: Fetching user role from Firestore');
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        print('AuthProvider: Firestore user data: ${userDoc.data()}');
        
        final userRole = userDoc.data()?['role'] as String? ?? 'teacher';
        
        print('AuthProvider: User role retrieved: $userRole');
        
        // Store user data in secure storage
        await _storage.write(key: 'userId', value: userCredential.user!.uid);
        await _storage.write(key: 'userRole', value: userRole);
        await _storage.write(key: 'userEmail', value: userCredential.user!.email);
        
        state = state.copyWith(
          isAuthenticated: true,
          userId: userCredential.user!.uid,
          userRole: userRole,
          user: userCredential.user,
        );
        
        print('AuthProvider: State updated successfully');
      } else {
        print('AuthProvider: User credential is null after successful authentication');
        throw 'Authentication failed: User data is missing';
      }
    } catch (e) {
      print('AuthProvider: Error during login: $e');
      throw _handleAuthException(e);
    }
  }

  Future<void> logout() async {
    try {
      print('AuthProvider: Attempting to sign out');
      await _auth.signOut();
      await _storage.deleteAll();
      state = AuthState();
      print('AuthProvider: Sign out successful');
    } catch (e) {
      print('AuthProvider: Error during logout: $e');
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(dynamic e) {
    print('AuthProvider: Handling auth exception: $e');
    if (e is FirebaseAuthException) {
      print('AuthProvider: Firebase Auth Exception code: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred.';
  }
} 
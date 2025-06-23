import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase with options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  print('Starting migration of student fees...');

  final studentsSnapshot = await firestore.collection('students').get();
  print('Found ${studentsSnapshot.docs.length} students.');

  for (final studentDoc in studentsSnapshot.docs) {
    final studentId = studentDoc.id;
    final data = studentDoc.data();
    final totalFees = (data['totalFees'] as num?)?.toDouble() ?? 0.0;
    final paidFees = (data['paidFees'] as num?)?.toDouble() ?? 0.0;

    final feeDoc = await firestore.collection('fees').doc(studentId).get();
    if (feeDoc.exists) {
      print('Fee doc already exists for student $studentId, skipping.');
      continue;
    }

    await firestore.collection('fees').doc(studentId).set({
      'studentId': studentId,
      'totalFees': totalFees,
      'paidFees': paidFees,
      'transactions': [],
    });
    print(
      'Created fee doc for student $studentId: totalFees=$totalFees, paidFees=$paidFees',
    );
  }

  print('Migration complete.');
}

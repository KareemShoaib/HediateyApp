import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth auth;

  const String testEmail = 'testuser@example.com'; // Test email
  const String testPassword = 'password123'; // Test password

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    firestore = FirebaseFirestore.instance;
    auth = FirebaseAuth.instance;

    // Ensure test user exists
    try {
      await auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
    } catch (e) {
      // If the user already exists, we can ignore this error
      print('Test user already exists: $e');
    }
  });

  tearDownAll(() async {
    // Optionally delete the test user and cleanup
    final user = auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  });

  test('Add event to Firestore', () async {
    // Log in with test email and password
    final userCredential = await auth.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
    );
    final userId = userCredential.user?.uid;

    expect(userId, isNotNull);

    // Add an event to Firestore
    const testEventName = 'Integration Test Event';
    const testLocation = 'Integration Test Location';
    final testDate = DateTime.now();

    await firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .add({
      'name': testEventName,
      'location': testLocation,
      'date': testDate.toIso8601String(),
    });

    // Verify the event exists in Firestore
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .where('name', isEqualTo: testEventName)
        .get();

    expect(snapshot.docs, isNotEmpty);
    expect(snapshot.docs.first['name'], testEventName);
    expect(snapshot.docs.first['location'], testLocation);
  });
}

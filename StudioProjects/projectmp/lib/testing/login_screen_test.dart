import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:projectmp/login_page.dart';
import 'package:projectmp/signup_page.dart';
import 'package:projectmp/welcome_page.dart';
import 'mocks.dart';

// Mock dependencies
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Widget Tests', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
    });

    testWidgets('renders all widgets correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Verify presence of all fields
      expect(find.text('Welcome to Hedieaty'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows SnackBar when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Find the Login button using its unique key
      final loginButton = find.byKey(const Key('loginButton'));
      await tester.tap(loginButton);
      await tester.pump();

      // Verify SnackBar shows up
      expect(find.text('Email and Password cannot be empty'), findsOneWidget);
    });



    testWidgets('navigates to Sign Up page when Sign Up is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Tap the Sign Up button
      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify navigation to SignUpPage
      expect(find.byType(SignUpPage), findsOneWidget);
    });

  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectmp/login_page.dart';
import 'package:projectmp/signup_page.dart';
import 'package:projectmp/welcome_page.dart';

void main() {
  testWidgets(
      'Displays Login Page Elements Correctly', (WidgetTester tester) async {
    // Load the LoginScreen widget
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Verify UI components
    expect(find.text('Login'), findsOneWidget); // AppBar Title
    expect(find.text('Welcome to Hedieaty'), findsOneWidget); // Welcome Text
    expect(find.byType(TextFormField),
        findsNWidgets(2)); // Email and Password fields
    expect(find.byType(ElevatedButton),
        findsNWidgets(2)); // Login and Sign Up buttons
  });

  testWidgets('Displays error message when fields are empty', (
      WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Tap the Login button without entering email or password
    final loginButton = find.byKey(const Key('loginButton'));
    await tester.tap(loginButton);
    await tester.pump();

    // Check for error SnackBar
    expect(find.text('Email and Password cannot be empty'), findsOneWidget);
  });

  testWidgets('Navigates to Sign Up page when Sign Up button is pressed', (
      WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Tap the Sign Up button
    final signUpButton = find.text('Sign Up');
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    // Verify that SignUpPage is loaded
    expect(find.byType(SignUpPage), findsOneWidget);
  });
}
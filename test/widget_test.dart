import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// This links this test file directly to the custom code you wrote in main.dart
import 'package:centsible/main.dart';

void main() {
  testWidgets('Centsible Auth UI initial load test', (WidgetTester tester) async {
    // 1. Build our updated CentsibleApp instead of MyApp
    await tester.pumpWidget(const CentsibleApp());

    // 2. Verify that the login text fields and UI elements exist on startup
    expect(find.text('Centsible Login'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // 3. Verify that the Register link text is visible
    expect(find.text("Don't have an account? Register here"), findsOneWidget);
  });
}
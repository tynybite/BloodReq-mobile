// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:bloodreq/main.dart';

void main() {
  testWidgets('BloodReq app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BloodReqApp());

    // Allow time for AuthProvider's 5-second timeout to complete
    await tester.pump(const Duration(seconds: 6));

    // Wait for any remaining animations
    // await tester.pumpAndSettle(); // Infinite animation causes timeout

    // Verify that the app starts without crashing
    expect(find.byType(BloodReqApp), findsOneWidget);
  });
}

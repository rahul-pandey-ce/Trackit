import 'package:flutter_test/flutter_test.dart';
import 'package:trackit/main.dart';
import 'package:trackit/screens/login_screen.dart';

void main() {
  testWidgets('Smoke test: Verify login screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrackItApp());

    // Verify that the login screen is showing.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('TrackIt Login'), findsOneWidget);
  });
}

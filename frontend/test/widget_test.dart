import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AutoRentalApp());

    // Verify that home screen renders
    expect(find.text('AutoRental'), findsWidgets);
  });
}

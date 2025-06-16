// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:placement_act_cell/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlacementActCellApp());

    // Verify that the app loads with the landing page
    expect(find.text('PlacementActCell'), findsOneWidget);
    expect(find.text('Continue as Student'), findsOneWidget);
    expect(find.text('Continue as TPO'), findsOneWidget);
    expect(find.text('Continue as Company'), findsOneWidget);
  });
}

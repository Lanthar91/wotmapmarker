import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wotpositonmarker/main.dart';

void main() {
  testWidgets('shows start message', (WidgetTester tester) async {
    await tester.pumpWidget(const WotMapEditor());
    expect(find.text('Select an image to start'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Life Countdown app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeCountdownApp());

    expect(find.text('My Countdown'), findsOneWidget);
    expect(find.text('Every day counts.'), findsOneWidget);
  });
}
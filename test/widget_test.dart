import 'package:flutter_test/flutter_test.dart';
import 'package:lokasee_flutter/main.dart';

void main() {
  testWidgets('Lokasee app renders splash screen', (tester) async {
    await tester.pumpWidget(const LokaseeApp());
    expect(find.text('Lokasee'), findsOneWidget);
  });
}

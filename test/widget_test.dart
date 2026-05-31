import 'package:flutter_test/flutter_test.dart';
import 'package:autohut/main.dart';

void main() {
  testWidgets('AutoHut smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoHutApp());
    expect(find.text('AutoHut'), findsWidgets);
  });
}

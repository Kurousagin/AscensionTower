import 'package:flutter_test/flutter_test.dart';
import 'package:tower_ascension/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TowerApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('SECOND HUMANITY'), findsOneWidget);
  });
}

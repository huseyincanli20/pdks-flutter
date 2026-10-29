import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdks_flutter/main.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  testWidgets('PDKS App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PdksState(),
        child: const PdksApp(),
      ),
    );
    expect(find.byType(PdksApp), findsOneWidget);
  });
}

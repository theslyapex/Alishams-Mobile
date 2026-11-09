import 'package:alishams_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ALISHAMS app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterGoApp()));
    await tester.pump();
    expect(find.byType(FlutterGoApp), findsOneWidget);
  });
}

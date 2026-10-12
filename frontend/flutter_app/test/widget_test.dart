import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/app.dart';

void main() {
  testWidgets('App boots and renders splash brand name', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MindoraApp()),
    );

    // flutter_animate attaches animated children in a post-frame callback,
    // so we pump twice to settle the first frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MINDORA'), findsWidgets);

    // Drain the splash timer (1.6s) and any follow-up animations so no
    // pending timers leak into the test harness.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
  });
}

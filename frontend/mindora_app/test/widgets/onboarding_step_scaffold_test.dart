import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/presentation/shared_widgets/onboarding_step_scaffold.dart';

void main() {
  Widget build({required VoidCallback? onNext, VoidCallback? onBack, int stepIndex = 2, int totalSteps = 11}) {
    return MaterialApp(
      home: OnboardingStepScaffold(
        stepIndex: stepIndex,
        totalSteps: totalSteps,
        title: 'Choose your language',
        onNext: onNext,
        onBack: onBack,
        content: const Text('step content'),
      ),
    );
  }

  testWidgets('renders title and content', (tester) async {
    await tester.pumpWidget(build(onNext: () {}));
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('step content'), findsOneWidget);
  });

  testWidgets('progress bar reflects stepIndex/totalSteps', (tester) async {
    await tester.pumpWidget(build(onNext: () {}, stepIndex: 4, totalSteps: 10));
    final progress = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progress.value, closeTo(5 / 10, 0.001)); // (stepIndex + 1) / totalSteps
  });

  testWidgets('back button hidden on the first step (onBack == null)', (tester) async {
    await tester.pumpWidget(build(onNext: () {}, onBack: null));
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('back button shown and tappable when onBack is provided', (tester) async {
    var backTapped = false;
    await tester.pumpWidget(build(onNext: () {}, onBack: () => backTapped = true));
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backTapped, isTrue);
  });

  testWidgets('next button disabled when onNext is null (e.g. no selection made yet)', (tester) async {
    await tester.pumpWidget(build(onNext: null));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('next button enabled and fires callback when onNext is provided', (tester) async {
    var nextTapped = false;
    await tester.pumpWidget(build(onNext: () => nextTapped = true));
    await tester.tap(find.byType(ElevatedButton));
    expect(nextTapped, isTrue);
  });
}

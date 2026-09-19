import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/domain/quizzes/quiz_entity.dart';
import 'package:mindora_app/presentation/features/quizzes/quiz_results_screen.dart';

void main() {
  const result = AttemptResultEntity(
    attemptId: 'attempt-1',
    score: 66.7,
    results: [
      QuestionResultEntity(
        questionId: 'q1', prompt: 'What is a derivative?', chosenAnswer: 'Rate of change',
        correctAnswer: 'Rate of change', isCorrect: true,
      ),
      QuestionResultEntity(
        questionId: 'q2', prompt: 'What is an integral?', chosenAnswer: 'Wrong answer',
        correctAnswer: 'Area under a curve', isCorrect: false,
      ),
    ],
  );

  testWidgets('shows the rounded overall score', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuizResultsScreen(result: result)));
    expect(find.text('67%'), findsOneWidget); // 66.7 rounds to 67
  });

  testWidgets('shows every question prompt and its correct answer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuizResultsScreen(result: result)));
    expect(find.text('What is a derivative?'), findsOneWidget);
    expect(find.text('What is an integral?'), findsOneWidget);
    expect(find.textContaining('Area under a curve'), findsOneWidget);
  });

  testWidgets('shows "Your answer" only for the incorrect question, not the correct one', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuizResultsScreen(result: result)));
    expect(find.textContaining('Your answer: Wrong answer'), findsOneWidget);
    expect(find.textContaining('Your answer: Rate of change'), findsNothing);
  });

  testWidgets('renders one check icon and one cancel icon matching correctness', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuizResultsScreen(result: result)));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });
}

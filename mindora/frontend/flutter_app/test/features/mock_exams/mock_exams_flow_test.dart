import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindora_app/core/design/theme/app_theme.dart';
import 'package:mindora_app/features/mock_exams/data/mock_exam_providers.dart';
import 'package:mindora_app/features/mock_exams/data/mock_exam_repository.dart';
import 'package:mindora_app/features/mock_exams/domain/mock_exam_models.dart';
import 'package:mindora_app/features/mock_exams/presentation/screens/create_mock_exam_screen.dart';
import 'package:mindora_app/features/mock_exams/presentation/screens/mock_exam_results_screen.dart';
import 'package:mindora_app/features/mock_exams/presentation/screens/take_mock_exam_screen.dart';
import 'package:mindora_app/l10n/app_strings.dart';

class _FakeMockExamRepository extends MockExamRepository {
  _FakeMockExamRepository() : super(Dio());

  String? createdQuestionMode;
  String? createdSubject;
  final Map<String, String> submittedAnswers = {};
  bool submitCalled = false;

  final List<MockQuestion> _questions = const [
    MockQuestion(
      id: 'q-1',
      position: 1,
      questionType: 'mcq',
      prompt: 'What is the derivative of x^2?',
      options: [
        MockQuestionOption(label: 'A', text: '2x'),
        MockQuestionOption(label: 'B', text: 'x^2'),
        MockQuestionOption(label: 'C', text: '2'),
      ],
      difficulty: 'medium',
      points: 1,
    ),
    MockQuestion(
      id: 'q-2',
      position: 2,
      questionType: 'true_false',
      prompt: 'Every differentiable function is continuous.',
      options: [
        MockQuestionOption(label: 'True', text: 'True'),
        MockQuestionOption(label: 'False', text: 'False'),
      ],
      difficulty: 'medium',
      points: 1,
    ),
  ];

  @override
  Future<MockExam> create({
    required String title,
    required String subject,
    String? academicLevel,
    int questionCount = 10,
    int durationMinutes = 30,
    String difficulty = 'medium',
    String questionMode = 'mixed',
    List<String> sourceDocumentIds = const [],
  }) async {
    createdSubject = subject;
    createdQuestionMode = questionMode;
    return MockExam(
      id: 'exam-1',
      title: title,
      subject: subject,
      academicLevel: academicLevel,
      questionCount: 2,
      durationMinutes: durationMinutes,
      difficulty: difficulty,
      status: 'ready',
      createdAt: DateTime.utc(2026, 11, 20),
      questions: _questions,
    );
  }

  @override
  Future<MockExam> get(String id) async {
    return MockExam(
      id: id,
      title: 'Calculus Practice',
      subject: 'Mathematics',
      academicLevel: 'GCE_AL',
      questionCount: 2,
      durationMinutes: 15,
      difficulty: 'medium',
      status: 'ready',
      createdAt: DateTime.utc(2026, 11, 20),
      questions: _questions,
    );
  }

  @override
  Future<MockExam> start(String id) async {
    return MockExam(
      id: id,
      title: 'Calculus Practice',
      subject: 'Mathematics',
      academicLevel: 'GCE_AL',
      questionCount: 2,
      durationMinutes: 15,
      difficulty: 'medium',
      status: 'in_progress',
      startedAt: DateTime.utc(2026, 11, 20),
      createdAt: DateTime.utc(2026, 11, 20),
      questions: _questions,
    );
  }

  @override
  Future<MockExam> submitAnswer({
    required String examId,
    required String questionId,
    required String answer,
    int? timeSpentSeconds,
  }) async {
    submittedAnswers[questionId] = answer;
    return start(examId);
  }

  @override
  Future<MockExamResults> submit(String id) async {
    submitCalled = true;
    return results(id);
  }

  @override
  Future<MockExamResults> results(String id) async {
    return MockExamResults(
      exam: MockExam(
        id: id,
        title: 'Calculus Practice',
        subject: 'Mathematics',
        academicLevel: 'GCE_AL',
        questionCount: 2,
        durationMinutes: 15,
        difficulty: 'medium',
        status: 'graded',
        score: 50,
        correctCount: 1,
        wrongCount: 1,
        skippedCount: 0,
        createdAt: DateTime.utc(2026, 11, 20),
        questions: _questions,
      ),
      answers: [
        AnswerResult(
          questionId: 'q-1',
          userAnswer: submittedAnswers['q-1'] ?? 'A',
          isCorrect: true,
          pointsAwarded: 1,
          correctAnswer: 'A',
          explanation: 'Power rule gives d/dx(x^2) = 2x.',
        ),
        const AnswerResult(
          questionId: 'q-2',
          userAnswer: 'False',
          isCorrect: false,
          pointsAwarded: 0,
          correctAnswer: 'True',
          explanation: 'Differentiability always implies continuity.',
        ),
      ],
      feedbackSummary: 'Good understanding of differentiation.',
      topicBreakdown: const {
        'Derivatives': {'correct': 1, 'total': 1},
        'Continuity': {'correct': 0, 'total': 1},
      },
    );
  }
}

Widget _wrapRouter(
  _FakeMockExamRepository repo, {
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/mock-exams/create',
        builder: (_, __) => const CreateMockExamScreen(),
      ),
      GoRoute(
        path: '/mock-exams/:id',
        builder: (_, s) => Scaffold(
          body: Text('Exam Detail ${s.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/mock-exams/:id/take',
        builder: (_, s) => TakeMockExamScreen(examId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/mock-exams/:id/results',
        builder: (_, s) =>
            MockExamResultsScreen(examId: s.pathParameters['id']!),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      mockExamRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [AppStrings.delegate],
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('C3 configures question format and generates mock exam',
      (tester) async {
    final repo = _FakeMockExamRepository();
    await tester.pumpWidget(
      _wrapRouter(repo, initialLocation: '/mock-exams/create'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MCQ'));
    await tester.pumpAndSettle();

    final submitBtn = find.text('Generate exam with AI');
    await tester.scrollUntilVisible(
      submitBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(repo.createdQuestionMode, 'mcq');
    expect(repo.createdSubject, 'Mathematics');
    expect(find.text('Exam Detail exam-1'), findsOneWidget);
  });

  testWidgets('C3 runs live timer, locks answer, navigates, and grades server-side',
      (tester) async {
    final repo = _FakeMockExamRepository();
    await tester.pumpWidget(
      _wrapRouter(repo, initialLocation: '/mock-exams/exam-1/take'),
    );
    await tester.pumpAndSettle();

    // Countdown timer visible in AppBar (15:00 or 14:59)
    expect(find.textContaining('1'), findsWidgets);
    expect(find.text('What is the derivative of x^2?'), findsOneWidget);

    // Select option A and lock answer
    await tester.tap(find.text('2x'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lock answer'));
    await tester.pumpAndSettle();

    expect(find.text('Locked'), findsOneWidget);
    expect(repo.submittedAnswers['q-1'], 'A');

    // Attempt to change locked Q1 answer to B -> must stay A
    await tester.tap(find.text('x^2'));
    await tester.pumpAndSettle();
    expect(repo.submittedAnswers['q-1'], 'A');

    // Navigate Next -> Q2, then Previous -> Q1 stays locked
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('Every differentiable function is continuous.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);

    // Navigate Next -> Q2, select True, Finish -> Results
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('True').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish').last);
    await tester.pumpAndSettle();

    expect(repo.submitCalled, isTrue);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Performance by topic'), findsOneWidget);
    expect(find.text('Derivatives'), findsOneWidget);
    expect(find.text('Detailed corrections'), findsOneWidget);
    expect(
      find.text('Power rule gives d/dx(x^2) = 2x.'),
      findsOneWidget,
    );
  });
}

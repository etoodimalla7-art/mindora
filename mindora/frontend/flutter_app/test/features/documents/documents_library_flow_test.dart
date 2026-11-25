import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/core/design/theme/app_theme.dart';
import 'package:mindora_app/features/documents/data/documents_providers.dart';
import 'package:mindora_app/features/documents/data/documents_repository.dart';
import 'package:mindora_app/features/documents/data/local_downloads_store.dart';
import 'package:mindora_app/features/documents/domain/document_models.dart';
import 'package:mindora_app/features/documents/presentation/screens/document_detail_screen.dart';
import 'package:mindora_app/features/documents/presentation/screens/documents_library_screen.dart';
import 'package:mindora_app/features/documents/presentation/screens/my_downloads_screen.dart';
import 'package:mindora_app/l10n/app_strings.dart';

class _FakeDocumentsRepository extends DocumentsRepository {
  _FakeDocumentsRepository() : super(Dio());

  int balance = 3;
  final List<Map<String, String?>> recordedFilters = [];
  String? lastDownloadedId;

  static final _docs = <Document>[
    Document(
      id: 'doc-math-1',
      ownerId: 'owner-other',
      title: 'Calculus Integrals Summary',
      description: 'Detailed notes covering Riemann sums and integration by parts.',
      category: 'Mathematics',
      academicLevel: 'Terminale',
      language: 'en',
      isExamRelated: true,
      originalFilename: 'calculus_integrals.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 245760,
      pageCount: 12,
      status: 'approved',
      downloadCount: 18,
      qualityScore: 0.92,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 2),
      analysis: const DocumentAnalysis(
        summary: 'Concise integral calculus formulas and solved examples.',
        keywords: ['integrals', 'calculus'],
      ),
    ),
    Document(
      id: 'doc-phys-2',
      ownerId: 'owner-other',
      title: 'Mécanique Newtonienne',
      description: 'Cours complet de dynamique et cinématique pour Terminale.',
      category: 'Physics',
      academicLevel: 'Terminale',
      language: 'fr',
      isExamRelated: false,
      originalFilename: 'mecanique.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 512000,
      pageCount: 20,
      status: 'approved',
      downloadCount: 7,
      qualityScore: 0.88,
      createdAt: DateTime.utc(2026, 11, 3),
      updatedAt: DateTime.utc(2026, 11, 4),
    ),
  ];

  @override
  Future<List<Document>> listLibrary({
    String? category,
    String? academicLevel,
    String? language,
    String? search,
  }) async {
    recordedFilters.add({
      'category': category,
      'academicLevel': academicLevel,
      'language': language,
      'search': search,
    });
    return _docs.where((d) {
      if (category != null && d.category != category) return false;
      if (academicLevel != null && d.academicLevel != academicLevel) return false;
      if (language != null && d.language != language) return false;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        if (!d.title.toLowerCase().contains(q) &&
            !d.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<Document> get(String id) async {
    return _docs.firstWhere((d) => d.id == id);
  }

  @override
  Future<CreditBalance> credits() async => CreditBalance(
        balance: balance,
        signupBonus: 3,
        contributionReward: 5,
        downloadCost: 1,
        history: const [],
      );

  @override
  Future<DownloadResult> download(String id) async {
    lastDownloadedId = id;
    balance = balance > 0 ? balance - 1 : 0;
    return DownloadResult(
      download: DownloadRecord(
        id: 'dl-1',
        documentId: id,
        creditsSpent: 1,
        downloadedAt: DateTime.utc(2026, 11, 20),
        sizeBytes: 245760,
      ),
      remainingBalance: balance,
    );
  }

  @override
  Future<List<int>> fetchFileBytes(String id) async => [1, 2, 3, 4];
}

class _InMemoryDownloadsStore implements LocalDownloadsStore {
  final List<LocalDownloadedDocument> items = [];

  @override
  Future<List<LocalDownloadedDocument>> list() async => List.of(items);

  @override
  Future<LocalDownloadedDocument> save({
    required Document document,
    required List<int> bytes,
  }) async {
    final saved = LocalDownloadedDocument(
      documentId: document.id,
      title: document.title,
      originalFilename: document.originalFilename,
      mimeType: document.mimeType,
      sizeBytes: bytes.isNotEmpty ? bytes.length : document.sizeBytes,
      language: document.language,
      category: document.category,
      academicLevel: document.academicLevel,
      localPath: '/tmp/${document.originalFilename}',
      downloadedAt: DateTime.utc(2026, 11, 20),
    );
    items.removeWhere((e) => e.documentId == document.id);
    items.insert(0, saved);
    return saved;
  }

  @override
  Future<void> remove(String documentId) async {
    items.removeWhere((e) => e.documentId == documentId);
  }
}

Widget _wrapTestApp(
  Widget child, {
  required _FakeDocumentsRepository repo,
  required _InMemoryDownloadsStore store,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      documentsRepositoryProvider.overrideWithValue(repo),
      localDownloadsStoreProvider.overrideWithValue(store),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [AppStrings.delegate],
      home: child,
    ),
  );
}

void main() {
  testWidgets('C1 Library lists documents and filters by language and search',
      (tester) async {
    final repo = _FakeDocumentsRepository();
    final store = _InMemoryDownloadsStore();

    await tester.pumpWidget(
      _wrapTestApp(const DocumentsLibraryScreen(), repo: repo, store: store),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calculus Integrals Summary'), findsOneWidget);
    expect(find.text('Mécanique Newtonienne'), findsOneWidget);
    expect(find.text('3 cr'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Calculus');
    await tester.pumpAndSettle();

    expect(find.text('Calculus Integrals Summary'), findsOneWidget);
    expect(find.text('Mécanique Newtonienne'), findsNothing);
    expect(repo.recordedFilters.last['search'], 'Calculus');
  });

  testWidgets('C1 Document detail renders metadata and downloads using credit',
      (tester) async {
    final repo = _FakeDocumentsRepository();
    final store = _InMemoryDownloadsStore();

    await tester.pumpWidget(
      _wrapTestApp(
        const DocumentDetailScreen(documentId: 'doc-math-1'),
        repo: repo,
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calculus Integrals Summary'), findsOneWidget);
    expect(find.text('240 KB'), findsOneWidget);
    expect(find.text('Subject: Mathematics'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Download'), 200);
    expect(find.text('1 credit required'), findsOneWidget);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(repo.lastDownloadedId, 'doc-math-1');
    expect(repo.balance, 2);
    expect(store.items.length, 1);
    expect(store.items.first.documentId, 'doc-math-1');
  });

  testWidgets('C1 Document detail blocks download when credits are zero',
      (tester) async {
    final repo = _FakeDocumentsRepository()..balance = 0;
    final store = _InMemoryDownloadsStore();

    await tester.pumpWidget(
      _wrapTestApp(
        const DocumentDetailScreen(documentId: 'doc-math-1'),
        repo: repo,
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Download'), 200);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(repo.lastDownloadedId, isNull);
    expect(store.items, isEmpty);
    expect(
      find.textContaining('Not enough credits'),
      findsOneWidget,
    );
  });

  testWidgets('C1 MyDownloadsScreen displays saved files and supports deletion',
      (tester) async {
    final repo = _FakeDocumentsRepository();
    final store = _InMemoryDownloadsStore();
    await store.save(
      document: _FakeDocumentsRepository._docs.first,
      bytes: const [1, 2, 3, 4],
    );

    await tester.pumpWidget(
      _wrapTestApp(const MyDownloadsScreen(), repo: repo, store: store),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calculus Integrals Summary'), findsOneWidget);
    expect(find.text('calculus_integrals.pdf'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(store.items, isEmpty);
    expect(find.text('No local downloads yet'), findsOneWidget);
  });
}

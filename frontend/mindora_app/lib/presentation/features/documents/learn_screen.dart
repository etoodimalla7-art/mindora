import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../providers/documents_providers.dart';
import '../../shared_widgets/empty_state.dart';
import 'widgets/document_status_chip.dart';

/// "Learn" tab: courses, documents, past papers, flashcards, quizzes
/// (sections 17-30, 38-40) are reached from here via contextual
/// navigation, per section 71. Now shows the contributor's real
/// documents (section 28's contribution history) instead of a
/// permanent placeholder.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  void _showStudyOptions(BuildContext context, String topicTitle, String documentId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.style_rounded),
              title: const Text('Review flashcards'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/flashcards', extra: {'topicTitle': topicTitle, 'sourceDocumentId': documentId});
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_rounded),
              title: const Text('Take a quiz'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/quiz', extra: {'topicTitle': topicTitle, 'sourceDocumentId': documentId});
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(myDocumentsProvider);

    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: const Text('Learn'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.toll_outlined),
                tooltip: 'Credits & Subscription',
                onPressed: () => context.push('/credits'),
              ),
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: 'Mock Exam',
                onPressed: () => context.push('/mock-exam/setup'),
              ),
              IconButton(
                icon: const Icon(Icons.history_edu_rounded),
                tooltip: 'Past Papers',
                onPressed: () => context.push('/learn/past-papers'),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Upload a document',
                onPressed: () => context.push('/learn/upload'),
              ),
            ],
          ),
          Expanded(
            child: documentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => EmptyState(
                icon: Icons.wifi_off_rounded,
                title: "Couldn't load your documents",
                message: 'Check your connection and try again.',
              ),
              data: (documents) {
                if (documents.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: EmptyState(
                          icon: Icons.menu_book_rounded,
                          title: 'No courses yet',
                          message:
                              'Upload a course document or browse the past papers '
                              'library to get started.',
                          actionLabel: 'Upload a document',
                          onAction: () => context.push('/learn/upload'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: TextButton(
                          onPressed: () => context.push('/learn/past-papers'),
                          child: const Text('Browse past papers instead'),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return Card(
                      child: ListTile(
                        title: Text(doc.title ?? doc.originalFilename),
                        subtitle: Text(doc.category ?? 'No category set'),
                        trailing: DocumentStatusChip(status: doc.status),
                        onTap: doc.title == null
                            ? null
                            : () => _showStudyOptions(context, doc.title!, doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

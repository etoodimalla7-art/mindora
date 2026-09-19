import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared_widgets/empty_state.dart';

/// Study planner entry (sections 31-34). Exam-mode and subject-mode plan
/// creation flows now live under create/exam and create/subject.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(title: const Text('Planner'), automaticallyImplyLeading: false),
          Expanded(
            child: EmptyState(
              icon: Icons.event_note_rounded,
              title: 'No study plan yet',
              message:
                  "Tell us what exam you're preparing for and we'll build "
                  'your first personalized plan.',
              actionLabel: 'Create study plan',
              onAction: () => context.push('/planner/create'),
            ),
          ),
        ],
      ),
    );
  }
}

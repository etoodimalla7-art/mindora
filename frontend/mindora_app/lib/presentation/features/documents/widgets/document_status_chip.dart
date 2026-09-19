import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../domain/documents/document_entity.dart';

/// Section 27: maps the raw status string to a label + color so the UI
/// never shows a bare enum value.
class DocumentStatusChip extends StatelessWidget {
  const DocumentStatusChip({super.key, required this.status});
  final String status;

  (String, Color) _presentation(BuildContext context) {
    final theme = Theme.of(context);
    switch (documentStatusFromString(status)) {
      case DocumentStatus.approved:
        return ('Approved', Colors.green.shade700);
      case DocumentStatus.underReview:
        return ('Under review', theme.colorScheme.primary);
      case DocumentStatus.needsRevision:
        return ('Needs revision', theme.colorScheme.error);
      case DocumentStatus.rejected:
        return ('Rejected', theme.colorScheme.error);
      case DocumentStatus.processing:
        return ('Processing', theme.colorScheme.secondary);
      default:
        return ('Draft', theme.colorScheme.onSurfaceVariant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _presentation(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin/admin_repository.dart';
import '../../domain/admin/review_item_entity.dart';
import 'core_providers.dart';

final adminRepositoryProvider = Provider((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

final reviewQueueProvider = FutureProvider.autoDispose<List<ReviewQueueItemEntity>>((ref) {
  return ref.watch(adminRepositoryProvider).getReviewQueue();
});

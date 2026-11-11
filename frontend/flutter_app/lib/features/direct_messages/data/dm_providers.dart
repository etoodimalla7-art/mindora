import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/dm_models.dart';
import 'dm_repository.dart';

final dmRepositoryProvider = Provider<DmRepository>(
  (ref) => DmRepository(ref.watch(dioProvider)),
);

final dmConversationsProvider = FutureProvider<List<DirectConversation>>(
  (ref) async => ref.watch(dmRepositoryProvider).listConversations(),
);

final dmDetailProvider =
    FutureProvider.family<DirectConversation, String>((ref, id) async {
  return ref.watch(dmRepositoryProvider).getConversation(id);
});

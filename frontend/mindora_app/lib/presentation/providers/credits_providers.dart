import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/credits/credits_repository.dart';
import 'core_providers.dart';

final creditsRepositoryProvider = Provider((ref) {
  return CreditsRepository(ref.watch(apiClientProvider));
});

final creditBalanceProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(creditsRepositoryProvider).getBalance();
});

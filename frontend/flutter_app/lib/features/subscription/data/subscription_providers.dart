import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/models.dart';
import 'subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(dioProvider)),
);

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).listPlans();
});

final mySubscriptionProvider = FutureProvider<Subscription?>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getMySubscription();
});

final subscriptionHistoryProvider =
    FutureProvider<List<Subscription>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).listHistory();
});

final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).listPayments();
});

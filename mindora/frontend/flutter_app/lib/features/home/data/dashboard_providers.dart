import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/dashboard_models.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

final dashboardProvider = FutureProvider<Dashboard>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetch();
});

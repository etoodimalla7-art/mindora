import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/users/users_repository.dart';
import '../../domain/users/current_user_entity.dart';
import 'core_providers.dart';

final usersRepositoryProvider = Provider((ref) {
  return UsersRepository(ref.watch(apiClientProvider));
});

final currentUserProvider = FutureProvider.autoDispose<CurrentUserEntity>((ref) {
  return ref.watch(usersRepositoryProvider).getMe();
});

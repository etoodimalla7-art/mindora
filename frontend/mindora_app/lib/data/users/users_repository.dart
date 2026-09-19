import '../../core/network/api_client.dart';
import '../../domain/users/current_user_entity.dart';

class UsersRepository {
  UsersRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<CurrentUserEntity> getMe() async {
    final response = await _apiClient.dio.get('/users/me');
    return CurrentUserEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }
}

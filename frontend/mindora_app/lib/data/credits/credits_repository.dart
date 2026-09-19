import '../../core/network/api_client.dart';
import '../../domain/credits/credits_entity.dart';

class CreditsRepository {
  CreditsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<int> getBalance() async {
    final response = await _apiClient.dio.get('/credits/balance');
    return (response.data as Map<String, dynamic>)['data']['balance'] as int;
  }

  Future<List<CreditTransactionEntity>> getHistory() async {
    final response = await _apiClient.dio.get('/credits/history');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => CreditTransactionEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SubscriptionPlanEntity>> getPlans() async {
    final response = await _apiClient.dio.get('/subscriptions/plans');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => SubscriptionPlanEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> subscribe(String planCode) async {
    await _apiClient.dio.post('/subscriptions/subscribe', data: {'plan_code': planCode});
  }

  Future<void> cancelSubscription() async {
    await _apiClient.dio.post('/subscriptions/cancel');
  }

  /// Returns whether a real file is available yet (document_id set) —
  /// past papers seeded without a linked document (Phase 6's dev seed,
  /// or any not yet approved through Phase 16's moderation workflow)
  /// spend the credit but have no file to serve yet.
  Future<bool> downloadPastPaper(String pastPaperId) async {
    final response = await _apiClient.dio.post('/past-papers/$pastPaperId/download');
    return (response.data as Map<String, dynamic>)['data']['available'] as bool;
  }
}

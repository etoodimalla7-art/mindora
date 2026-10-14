import 'package:dio/dio.dart';

import '../domain/models.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._dio);
  final Dio _dio;

  Future<List<Plan>> listPlans() async {
    final r = await _dio.get('/subscriptions/plans');
    return (r.data as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Subscription?> getMySubscription() async {
    final r = await _dio.get('/subscriptions/me');
    if (r.data == null) return null;
    return Subscription.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Subscription>> listHistory() async {
    final r = await _dio.get('/subscriptions/history');
    return (r.data as List)
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> listPayments() async {
    final r = await _dio.get('/subscriptions/payments');
    return (r.data as List)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CheckoutSession> startCheckout(String planCode) async {
    final r = await _dio.post(
      '/subscriptions/checkout',
      data: {'plan_code': planCode},
    );
    return CheckoutSession.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Subscription?> confirmPayment(String reference) async {
    final r = await _dio.post(
      '/subscriptions/confirm',
      data: {'reference': reference},
    );
    final data = r.data as Map<String, dynamic>;
    final sub = data['subscription'];
    if (sub == null) return null;
    return Subscription.fromJson(sub as Map<String, dynamic>);
  }

  Future<void> cancel() async {
    await _dio.post('/subscriptions/cancel');
  }
}

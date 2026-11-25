import 'package:dio/dio.dart';

import '../domain/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<Dashboard> fetch() async {
    final response = await _dio.get('/dashboard');
    return Dashboard.fromJson(response.data as Map<String, dynamic>);
  }
}

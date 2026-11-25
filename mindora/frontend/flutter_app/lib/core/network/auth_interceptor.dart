import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.ref);
  final Ref ref;
  final _store = TokenStore();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Do not attach auth to public endpoints
    if (options.path.startsWith('/auth/')) {
      return handler.next(options);
    }
    final token = await _store.access;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Phase 3.x will add automatic refresh-on-401.
    handler.next(err);
  }
}

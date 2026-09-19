import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

/// Single Dio instance for the whole app. Base URL is the only thing you
/// change between environments — everything else (auth header injection,
/// automatic token refresh) is handled once, here.
class ApiClient {
  ApiClient(this._tokenStorage, {String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:8000/api/v1',
          ),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthError = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path.contains('/auth/refresh');
          if (isAuthError && !isRefreshCall) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final clone = await _retry(error.requestOptions);
              return handler.resolve(clone);
            }
            await _tokenStorage.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      final data = response.data['data'] as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(method: requestOptions.method, headers: requestOptions.headers);
    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

/// Extracts the safe user-facing message the backend envelope always
/// carries on error (see api/core/errors.py `envelope()`), falling back
/// to a generic message if something unexpected happened before the
/// server could respond at all (e.g. no network).
String extractApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return "We couldn't reach the server. Check your connection and try again.";
    }
  }
  return 'Something went wrong. Please try again.';
}

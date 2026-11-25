import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Client for OTP endpoints.
class OtpApi {
  OtpApi(this._dio);
  final Dio _dio;

  /// Send a 6-digit code to the given email.
  /// purpose: 'verify_email' | 'reset_password'
  Future<void> sendOtp({
    required String email,
    String purpose = 'verify_email',
  }) async {
    await _dio.post('/auth/send-otp', data: {
      'email': email,
      'purpose': purpose,
    });
    // Dev hint: in dev (SMTP not configured), the code is logged server-side
    // Check your backend terminal: tail -f /tmp/uvicorn.log | grep "verification code"
    debugPrint('[OTP] Code sent to $email (check backend logs in dev)');
  }

  /// Verify the code. Returns is_verified from response.
  Future<bool> verifyOtp({
    required String email,
    required String code,
    String purpose = 'verify_email',
  }) async {
    final r = await _dio.post('/auth/verify-otp', data: {
      'email': email,
      'code': code,
      'purpose': purpose,
    });
    return (r.data as Map<String, dynamic>)['is_verified'] as bool? ?? false;
  }
}

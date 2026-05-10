import '../../api_console/data/hackathon_api_client.dart';
import '../domain/auth_models.dart';
import '../domain/google_integration_models.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    return statusCode == null ? message : 'HTTP $statusCode: $message';
  }
}

class AuthRepository {
  const AuthRepository({HackathonApiClient client = const HackathonApiClient()})
    : _client = client;

  final HackathonApiClient _client;

  Future<AuthUser> signUp({
    required String baseUrl,
    required String email,
    required String fullName,
    required String phone,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'POST',
      path: '/api/v1/auth/signup',
      body: {
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'timezone': 'Asia/Ulaanbaatar',
        'language': 'mn',
      },
    );
    return AuthUser.fromData(result.data);
  }

  Future<void> sendOtp({required String baseUrl, required String email}) async {
    await _request(
      baseUrl: baseUrl,
      method: 'POST',
      path: '/api/v1/auth/otp/send',
      body: {'email': email},
    );
  }

  Future<AuthSession> verifyOtp({
    required String baseUrl,
    required String email,
    required String otp,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'POST',
      path: '/api/v1/auth/otp/verify',
      body: {'email': email, 'otp': otp},
    );
    return AuthSession.fromData(result.data);
  }

  Future<AuthSession> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'POST',
      path: '/api/v1/auth/refresh',
      body: {'refresh': refreshToken},
    );
    return AuthSession.fromData(result.data);
  }

  Future<AuthUser> me({
    required String baseUrl,
    required String accessToken,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/api/v1/auth/me',
      token: accessToken,
    );
    return AuthUser.fromData(result.data);
  }

  /// JSON includes OAuth URL field — open in browser to link Google.
  Future<Uri> googleConnectUri({
    required String baseUrl,
    required String accessToken,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/integrations/google/connect',
      token: accessToken,
    );
    final url = parseGoogleConnectUrl(result.data);
    if (url == null || url.isEmpty) {
      throw const AuthApiException('No Google OAuth URL in response.');
    }
    return Uri.parse(url);
  }

  Future<GoogleIntegrationStatus> googleIntegrationStatus({
    required String baseUrl,
    required String accessToken,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/integrations/google/status',
      token: accessToken,
    );
    return GoogleIntegrationStatus.fromData(result.data);
  }

  Future<ApiCallResult> _request({
    required String baseUrl,
    required String method,
    required String path,
    String? token,
    Map<String, Object?>? body,
  }) async {
    final result = await _client.request(
      baseUrl: baseUrl,
      method: method,
      path: path,
      token: token,
      body: body,
    );
    if (!result.isSuccess) {
      throw AuthApiException(
        result.rawBody.isEmpty ? 'Request failed.' : result.rawBody,
        statusCode: result.statusCode,
      );
    }
    return result;
  }
}

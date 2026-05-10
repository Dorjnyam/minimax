import 'hackathon_api_client.dart';

class HackathonApiRepository {
  const HackathonApiRepository({
    HackathonApiClient client = const HackathonApiClient(),
  }) : _client = client;

  final HackathonApiClient _client;

  Future<ApiCallResult> health(String baseUrl) {
    return _get(baseUrl, '/healthz');
  }

  Future<ApiCallResult> signUp({
    required String baseUrl,
    required String email,
    required String fullName,
    required String phone,
  }) {
    return _post(baseUrl, '/api/v1/auth/signup', {
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'timezone': 'Asia/Ulaanbaatar',
      'language': 'mn',
    });
  }

  Future<ApiCallResult> sendOtp(String baseUrl, String email) {
    return _post(baseUrl, '/api/v1/auth/otp/send', {'email': email});
  }

  Future<ApiCallResult> verifyOtp({
    required String baseUrl,
    required String email,
    required String otp,
  }) {
    return _post(baseUrl, '/api/v1/auth/otp/verify', {
      'email': email,
      'otp': otp,
    });
  }

  Future<ApiCallResult> refresh(String baseUrl, String refreshToken) {
    return _post(baseUrl, '/api/v1/auth/refresh', {'refresh': refreshToken});
  }

  Future<ApiCallResult> me(String baseUrl, String token) {
    return _get(baseUrl, '/api/v1/auth/me', token: token);
  }

  Future<ApiCallResult> myAgent(String baseUrl, String token) {
    return _get(baseUrl, '/api/v1/agents/me', token: token);
  }

  Future<ApiCallResult> tools(String baseUrl, String token) {
    return _get(baseUrl, '/api/v1/agents/tools', token: token);
  }

  Future<ApiCallResult> createAgent(String baseUrl, String token) {
    return _post(baseUrl, '/api/v1/agents/', {
      'name': 'Baigalaa',
      'system_prompt':
          'Та монгол хэлээр товч, тодорхой хариулдаг туслах агент.',
      'model': 'gpt-4o-mini',
      'temperature': 0.2,
      'tools': ['get_current_time', 'echo'],
    }, token: token);
  }

  Future<ApiCallResult> runAgent({
    required String baseUrl,
    required String token,
    required String agentId,
    required String input,
  }) {
    return _post(baseUrl, '/api/v1/agents/$agentId/run', {
      'input': input,
    }, token: token);
  }

  Future<ApiCallResult> createConversation({
    required String baseUrl,
    required String token,
    required String title,
  }) {
    return _post(baseUrl, '/api/v1/chat/conversations', {
      'title': title,
    }, token: token);
  }

  Future<ApiCallResult> conversations(String baseUrl, String token) {
    return _get(baseUrl, '/api/v1/chat/conversations', token: token);
  }

  Future<ApiCallResult> messages({
    required String baseUrl,
    required String token,
    required String conversationId,
  }) {
    return _get(
      baseUrl,
      '/api/v1/chat/conversations/$conversationId/messages',
      token: token,
    );
  }

  Future<ApiCallResult> createGroup({
    required String baseUrl,
    required String token,
    required String name,
  }) {
    return _post(baseUrl, '/api/v1/groups/', {'name': name}, token: token);
  }

  Future<ApiCallResult> groups(String baseUrl, String token) {
    return _get(baseUrl, '/api/v1/groups/', token: token);
  }

  Future<ApiCallResult> joinGroup({
    required String baseUrl,
    required String token,
    required String inviteCode,
  }) {
    return _post(baseUrl, '/api/v1/groups/join', {
      'invite_code': inviteCode,
    }, token: token);
  }

  Future<ApiCallResult> updateLocation({
    required String baseUrl,
    required String token,
    required double lat,
    required double lng,
    required String address,
  }) {
    return _post(baseUrl, '/api/v1/location/update', {
      'lat': lat,
      'lng': lng,
      'address': address,
      'accuracy': 10.0,
    }, token: token);
  }

  Future<ApiCallResult> groupLocations({
    required String baseUrl,
    required String token,
    required String groupId,
  }) {
    return _get(baseUrl, '/api/v1/groups/$groupId/locations', token: token);
  }

  Future<ApiCallResult> _get(String baseUrl, String path, {String? token}) {
    return _client.request(
      baseUrl: baseUrl,
      method: 'GET',
      path: path,
      token: token,
    );
  }

  Future<ApiCallResult> _post(
    String baseUrl,
    String path,
    Map<String, Object?> body, {
    String? token,
  }) {
    return _client.request(
      baseUrl: baseUrl,
      method: 'POST',
      path: path,
      token: token,
      body: body,
    );
  }
}

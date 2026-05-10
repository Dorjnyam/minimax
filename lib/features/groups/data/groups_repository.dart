import '../../../shared/constants/baigalaa_constants.dart';
import '../../api_console/data/hackathon_api_client.dart';
import '../../auth/data/auth_storage.dart' show AuthStorage, SecureAuthStorage;
import '../../auth/data/session_refresh_service.dart';
import '../domain/group_models.dart';

/// Lists groups, joins by invite code, and loads member locations (Bearer token).
class GroupsRepository {
  GroupsRepository({
    HackathonApiClient client = const HackathonApiClient(),
    AuthStorage authStorage = const SecureAuthStorage(),
    required SessionRefreshService sessionRefresh,
  }) : _client = client,
       _authStorage = authStorage,
       _sessionRefresh = sessionRefresh;

  final HackathonApiClient _client;
  final AuthStorage _authStorage;
  final SessionRefreshService _sessionRefresh;

  Future<String> _token() async {
    var token = (await _sessionRefresh.ensureAccessToken())?.trim();
    token ??= (await _authStorage.read(apiAccessTokenStorageKey))?.trim();
    if (token == null || token.isEmpty) {
      token = defaultHackathonAccessToken.trim();
    }
    if (token.isEmpty) {
      throw StateError('Please log in again.');
    }
    return token;
  }

  Future<String> _baseUrl() async {
    final stored = (await _authStorage.read(apiBaseUrlStorageKey))?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return defaultApiBaseUrl;
  }

  /// GET `/api/v1/groups/`
  Future<List<GroupSummary>> listGroups() async {
    final baseUrl = await _baseUrl();
    final token = await _token();
    final result = await _client.request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/api/v1/groups/',
      token: token,
    );
    if (!result.isSuccess) {
      throw StateError(
        _apiFailure(result.data, 'Groups failed: HTTP ${result.statusCode}'),
      );
    }
    return _parseGroupList(result.data);
  }

  /// POST `/api/v1/groups/join`
  Future<void> joinGroup(String inviteCode) async {
    final code = inviteCode.trim();
    if (code.isEmpty) {
      throw StateError('Урилгын код хоосон байна.');
    }
    final baseUrl = await _baseUrl();
    final token = await _token();
    final result = await _client.request(
      baseUrl: baseUrl,
      method: 'POST',
      path: '/api/v1/groups/join',
      token: token,
      body: {'invite_code': code},
    );
    if (!result.isSuccess) {
      throw StateError(
        _apiFailure(result.data, 'Нэгдэж чадсангүй: HTTP ${result.statusCode}'),
      );
    }
  }

  /// GET `/api/v1/groups/{id}/locations`
  Future<List<GroupMemberLocation>> groupLocations(String groupId) async {
    final id = groupId.trim();
    if (id.isEmpty) {
      throw StateError('Бүлгийн ID байхгүй.');
    }
    final baseUrl = await _baseUrl();
    final token = await _token();
    final result = await _client.request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/api/v1/groups/$id/locations',
      token: token,
    );
    if (!result.isSuccess) {
      throw StateError(
        _apiFailure(
          result.data,
          'Байршил ачаалж чадсангүй: HTTP ${result.statusCode}',
        ),
      );
    }
    return _parseLocations(result.data);
  }

  static String _apiFailure(Object? data, String fallback) {
    if (data is Map) {
      final map = Map<String, Object?>.from(data);
      final msg = map['message']?.toString().trim();
      if (msg != null && msg.isNotEmpty) return msg;
      final err = map['error']?.toString().trim();
      if (err != null && err.isNotEmpty) return err;
    }
    return fallback;
  }

  static List<GroupSummary> _parseGroupList(Object? root) {
    if (root is List) return _parseGroupItems(root);
    if (root is! Map) return [];
    final m = Map<String, Object?>.from(root);
    final block = m['data'];
    if (block is! List) return [];
    return _parseGroupItems(block);
  }

  static List<GroupSummary> _parseGroupItems(List<dynamic> block) {
    return block
        .map((e) {
          if (e is! Map) return null;
          return GroupSummary.fromJson(
            Map<String, Object?>.from(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        })
        .whereType<GroupSummary>()
        .toList();
  }

  static List<GroupMemberLocation> _parseLocations(Object? root) {
    if (root is List) return _parseLocationItems(root);
    if (root is! Map) return [];
    final m = Map<String, Object?>.from(root);
    final block = m['data'];
    if (block is! List) return [];
    return _parseLocationItems(block);
  }

  static List<GroupMemberLocation> _parseLocationItems(List<dynamic> block) {
    return block
        .map((e) {
          if (e is! Map) return null;
          return GroupMemberLocation.fromJson(
            Map<String, Object?>.from(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        })
        .whereType<GroupMemberLocation>()
        .toList();
  }
}

import '../../../shared/constants/baigalaa_constants.dart';
import '../../api_console/data/hackathon_api_client.dart';
import '../../auth/data/auth_storage.dart' show AuthStorage, SecureAuthStorage;
import '../../auth/data/session_refresh_service.dart';
import '../domain/reminder.dart';

typedef AccessTokenProvider = Future<String?> Function();

/// Lists reminders from the hackathon API (Bearer token).
class RemindersRepository {
  RemindersRepository({
    HackathonApiClient client = const HackathonApiClient(),
    AuthStorage authStorage = const SecureAuthStorage(),
    required SessionRefreshService sessionRefresh,
  }) : _client = client,
       _authStorage = authStorage,
       _sessionRefresh = sessionRefresh;

  final HackathonApiClient _client;
  final AuthStorage _authStorage;
  final SessionRefreshService _sessionRefresh;

  Future<String> _token({required String baseUrl}) async {
    var token =
        (await _sessionRefresh.ensureAccessToken(baseUrl: baseUrl))?.trim();
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

  /// GET `/api/v1/agents/reminders?status=all&limit=…` — filter open/closed in the UI.
  ///
  /// Use **no** trailing slash: this backend returns **404** for `…/reminders/` but
  /// **200** for `…/reminders`. (Groups uses `/api/v1/groups/` — route conventions differ.)
  Future<List<Reminder>> fetchReminders({int limit = 50}) async {
    final baseUrl = await _baseUrl();
    final token = await _token(baseUrl: baseUrl);
    final result = await _client.request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/api/v1/agents/reminders',
      token: token,
      queryParameters: {
        'status': 'all',
        'limit': '$limit',
      },
    );
    if (!result.isSuccess) {
      throw StateError(
        _apiFailure(
          result.data,
          'Reminders failed: HTTP ${result.statusCode}',
        ),
      );
    }
    return _parseReminders(result.data);
  }

  static String _apiFailure(Object? data, String fallback) {
    if (data is Map) {
      final m = Map<String, Object?>.from(data);
      final msg = m['message']?.toString().trim();
      if (msg != null && msg.isNotEmpty) return msg;
      final err = m['error']?.toString().trim();
      if (err != null && err.isNotEmpty) return err;
    }
    return fallback;
  }

  List<Reminder> _parseReminders(Object? data) {
    if (data is! Map) return [];
    final envelope = Map<String, Object?>.from(data);
    Object? block = envelope['data'] ?? data;
    if (block is List) {
      return _mapReminderList(block);
    }
    if (block is! Map) return [];
    final inner = Map<String, Object?>.from(block);
    final raw = inner['reminders'];
    if (raw is! List) return [];
    return _mapReminderList(raw);
  }

  static List<Reminder> _mapReminderList(List<dynamic> raw) {
    return raw
        .map((e) {
          if (e is! Map) return null;
          return Reminder.fromJson(
            Map<String, Object?>.from(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        })
        .whereType<Reminder>()
        .toList();
  }
}

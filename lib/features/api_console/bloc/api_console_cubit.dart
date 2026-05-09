import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../data/hackathon_api_client.dart';
import '../data/hackathon_api_repository.dart';
import 'api_console_state.dart';

class ApiConsoleCubit extends Cubit<ApiConsoleState> {
  ApiConsoleCubit({
    required HackathonApiRepository repository,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _repository = repository,
       _storage = storage,
       super(const ApiConsoleState());

  final HackathonApiRepository _repository;
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    final values = await Future.wait([
      _read(apiBaseUrlStorageKey),
      _read(apiAccessTokenStorageKey),
      _read(apiRefreshTokenStorageKey),
      _read(apiAgentIdStorageKey),
      _read(apiConversationIdStorageKey),
      _read(apiGroupIdStorageKey),
    ]);
    emit(
      state.copyWith(
        baseUrl: _storedBaseUrl(values[0]),
        accessToken: values[1] ?? '',
        refreshToken: values[2] ?? '',
        agentId: values[3] ?? '',
        conversationId: values[4] ?? '',
        groupId: values[5] ?? '',
      ),
    );
  }

  String _storedBaseUrl(String? _) => defaultApiBaseUrl;

  Future<void> saveBaseUrl(String _) async {
    await _write(apiBaseUrlStorageKey, defaultApiBaseUrl);
    emit(state.copyWith(baseUrl: defaultApiBaseUrl));
  }

  Future<void> health(String baseUrl) {
    return _perform(
      title: 'Health Check',
      baseUrl: baseUrl,
      action: (url) => _repository.health(url),
    );
  }

  Future<void> signUp({
    required String baseUrl,
    required String email,
    required String fullName,
    required String phone,
  }) {
    return _perform(
      title: 'Sign Up',
      baseUrl: baseUrl,
      action: (url) => _repository.signUp(
        baseUrl: url,
        email: email,
        fullName: fullName,
        phone: phone,
      ),
    );
  }

  Future<void> sendOtp(String baseUrl, String email) {
    return _perform(
      title: 'OTP Send',
      baseUrl: baseUrl,
      action: (url) => _repository.sendOtp(url, email),
    );
  }

  Future<void> verifyOtp({
    required String baseUrl,
    required String email,
    required String otp,
  }) {
    return _perform(
      title: 'OTP Verify',
      baseUrl: baseUrl,
      action: (url) =>
          _repository.verifyOtp(baseUrl: url, email: email, otp: otp),
      onSuccess: _saveTokens,
    );
  }

  Future<void> refresh(String baseUrl) {
    return _perform(
      title: 'Refresh Token',
      baseUrl: baseUrl,
      action: (url) => _repository.refresh(url, state.refreshToken),
      onSuccess: _saveTokens,
    );
  }

  Future<void> me(String baseUrl) {
    return _authCall('Me', baseUrl, (url, token) => _repository.me(url, token));
  }

  Future<void> myAgent(String baseUrl) {
    return _authCall('My Agent', baseUrl, (url, token) {
      return _repository.myAgent(url, token);
    }, onSuccess: _saveAgentId);
  }

  Future<void> tools(String baseUrl) {
    return _authCall(
      'Tools List',
      baseUrl,
      (url, token) => _repository.tools(url, token),
    );
  }

  Future<void> createAgent(String baseUrl) {
    return _authCall('Agent Create', baseUrl, (url, token) {
      return _repository.createAgent(url, token);
    }, onSuccess: _saveAgentId);
  }

  Future<void> runAgent(String baseUrl, String agentId, String input) {
    final id = agentId.trim().isNotEmpty ? agentId.trim() : state.agentId;
    return _authCall('Agent Run', baseUrl, (url, token) {
      return _repository.runAgent(
        baseUrl: url,
        token: token,
        agentId: id,
        input: input,
      );
    }, onSuccess: (result) => _saveValue(apiAgentIdStorageKey, id));
  }

  Future<void> createConversation(String baseUrl, String title) {
    return _authCall('Conversation Create', baseUrl, (url, token) {
      return _repository.createConversation(
        baseUrl: url,
        token: token,
        title: title,
      );
    }, onSuccess: _saveConversationId);
  }

  Future<void> conversations(String baseUrl) {
    return _authCall('Conversation List', baseUrl, (url, token) {
      return _repository.conversations(url, token);
    });
  }

  Future<void> messages(String baseUrl, String conversationId) {
    final id = conversationId.trim().isNotEmpty
        ? conversationId.trim()
        : state.conversationId;
    return _authCall(
      'Messages List',
      baseUrl,
      (url, token) {
        return _repository.messages(
          baseUrl: url,
          token: token,
          conversationId: id,
        );
      },
      onSuccess: (_) => _saveValue(apiConversationIdStorageKey, id),
    );
  }

  Future<void> createGroup(String baseUrl, String name) {
    return _authCall('Group Create', baseUrl, (url, token) {
      return _repository.createGroup(baseUrl: url, token: token, name: name);
    }, onSuccess: _saveGroupId);
  }

  Future<void> groups(String baseUrl) {
    return _authCall('Group List', baseUrl, (url, token) {
      return _repository.groups(url, token);
    });
  }

  Future<void> updateLocation({
    required String baseUrl,
    required String lat,
    required String lng,
    required String address,
  }) {
    return _authCall('Location Update', baseUrl, (url, token) {
      return _repository.updateLocation(
        baseUrl: url,
        token: token,
        lat: double.tryParse(lat) ?? 47.9184676,
        lng: double.tryParse(lng) ?? 106.9177016,
        address: address,
      );
    });
  }

  Future<void> groupLocations(String baseUrl, String groupId) {
    final id = groupId.trim().isNotEmpty ? groupId.trim() : state.groupId;
    return _authCall(
      'Group Locations',
      baseUrl,
      (url, token) {
        return _repository.groupLocations(
          baseUrl: url,
          token: token,
          groupId: id,
        );
      },
      onSuccess: (_) => _saveValue(apiGroupIdStorageKey, id),
    );
  }

  Future<void> _authCall(
    String title,
    String baseUrl,
    Future<ApiCallResult> Function(String url, String token) action, {
    Future<void> Function(ApiCallResult result)? onSuccess,
  }) {
    return _perform(
      title: title,
      baseUrl: baseUrl,
      action: (url) => action(url, state.accessToken),
      onSuccess: onSuccess,
    );
  }

  Future<void> _perform({
    required String title,
    required String baseUrl,
    required Future<ApiCallResult> Function(String baseUrl) action,
    Future<void> Function(ApiCallResult result)? onSuccess,
  }) async {
    final cleanBase = defaultApiBaseUrl;
    await saveBaseUrl(cleanBase);
    emit(
      state.copyWith(
        status: ApiConsoleStatus.loading,
        lastTitle: title,
        clearStatusCode: true,
      ),
    );
    try {
      final result = await action(cleanBase);
      if (result.isSuccess && onSuccess != null) {
        await onSuccess(result);
      }
      emit(
        state.copyWith(
          status: result.isSuccess
              ? ApiConsoleStatus.success
              : ApiConsoleStatus.failure,
          lastTitle: title,
          lastStatusCode: result.statusCode,
          lastBody: _prettyRedacted(result.data, result.rawBody),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ApiConsoleStatus.failure,
          lastTitle: title,
          lastBody: error.toString(),
          clearStatusCode: true,
        ),
      );
    }
  }

  Future<void> _saveTokens(ApiCallResult result) async {
    final access = _find(result.data, const [
      'access',
      'access_token',
      'token',
    ]);
    final refresh = _find(result.data, const ['refresh', 'refresh_token']);
    if (access != null) {
      await _write(apiAccessTokenStorageKey, access);
    }
    if (refresh != null) {
      await _write(apiRefreshTokenStorageKey, refresh);
    }
    emit(
      state.copyWith(
        accessToken: access ?? state.accessToken,
        refreshToken: refresh ?? state.refreshToken,
      ),
    );
  }

  Future<void> _saveAgentId(ApiCallResult result) async {
    final id = _find(result.data, const ['agent_id', 'id']);
    if (id != null) {
      await _saveValue(apiAgentIdStorageKey, id);
    }
  }

  Future<void> _saveConversationId(ApiCallResult result) async {
    final id = _find(result.data, const ['conversation_id', 'id']);
    if (id != null) {
      await _saveValue(apiConversationIdStorageKey, id);
    }
  }

  Future<void> _saveGroupId(ApiCallResult result) async {
    final id = _find(result.data, const ['group_id', 'id']);
    if (id != null) {
      await _saveValue(apiGroupIdStorageKey, id);
    }
  }

  Future<void> _saveValue(String key, String value) async {
    await _write(key, value);
    emit(switch (key) {
      apiAgentIdStorageKey => state.copyWith(agentId: value),
      apiConversationIdStorageKey => state.copyWith(conversationId: value),
      apiGroupIdStorageKey => state.copyWith(groupId: value),
      _ => state,
    });
  }

  String? _find(Object? data, List<String> keys) {
    if (data is Map) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
      for (final value in data.values) {
        final found = _find(value, keys);
        if (found != null) {
          return found;
        }
      }
    }
    if (data is List) {
      for (final item in data) {
        final found = _find(item, keys);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  String _prettyRedacted(Object? data, String raw) {
    final redacted = _redact(data);
    if (redacted == null) {
      return raw;
    }
    return const JsonEncoder.withIndent('  ').convert(redacted);
  }

  Object? _redact(Object? data) {
    if (data is Map) {
      return data.map((key, value) {
        final lower = key.toString().toLowerCase();
        final hidden =
            lower.contains('token') || lower == 'access' || lower == 'refresh';
        return MapEntry(key, hidden ? '<redacted>' : _redact(value));
      });
    }
    if (data is List) {
      return data.map(_redact).toList();
    }
    return data;
  }

  Future<String?> _read(String key) async {
    try {
      return _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }
}

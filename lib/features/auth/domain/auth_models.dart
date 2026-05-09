import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  bool get hasAccessToken => accessToken.trim().isNotEmpty;

  factory AuthSession.empty() {
    return const AuthSession(accessToken: '', refreshToken: '');
  }

  factory AuthSession.fromData(Object? data) {
    return AuthSession(
      accessToken: _find(data, const ['access', 'access_token', 'token']) ?? '',
      refreshToken: _find(data, const ['refresh', 'refresh_token']) ?? '',
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthUser extends Equatable {
  const AuthUser({
    required this.email,
    required this.fullName,
    required this.phone,
  });

  final String email;
  final String fullName;
  final String phone;

  bool get isEmpty => email.isEmpty && fullName.isEmpty && phone.isEmpty;

  factory AuthUser.empty() {
    return const AuthUser(email: '', fullName: '', phone: '');
  }

  factory AuthUser.fromData(Object? data) {
    final map = _findUserMap(data);
    return AuthUser(
      email: '${map['email'] ?? ''}',
      fullName: '${map['full_name'] ?? map['fullName'] ?? ''}',
      phone: '${map['phone'] ?? ''}',
    );
  }

  @override
  List<Object?> get props => [email, fullName, phone];
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

Map<Object?, Object?> _findUserMap(Object? data) {
  if (data is Map) {
    final hasUserFields =
        data.containsKey('email') ||
        data.containsKey('full_name') ||
        data.containsKey('fullName') ||
        data.containsKey('phone');
    if (hasUserFields) {
      return data;
    }
    for (final value in data.values) {
      final found = _findUserMap(value);
      if (found.isNotEmpty) {
        return found;
      }
    }
  }
  if (data is List) {
    for (final item in data) {
      final found = _findUserMap(item);
      if (found.isNotEmpty) {
        return found;
      }
    }
  }
  return const {};
}

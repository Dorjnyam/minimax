import 'package:equatable/equatable.dart';

/// GET `/integrations/google/status` — shape may vary; parse defensively.
class GoogleIntegrationStatus extends Equatable {
  const GoogleIntegrationStatus({
    required this.connected,
    this.email = '',
    this.raw,
  });

  final bool connected;
  final String email;
  final Object? raw;

  factory GoogleIntegrationStatus.fromData(Object? data) {
    if (data is! Map) {
      return const GoogleIntegrationStatus(connected: false);
    }
    final map = Map<Object?, Object?>.from(data);
    final inner = map['data'];
    final source = inner is Map ? Map<Object?, Object?>.from(inner) : map;

    bool connected = false;
    final c = source['connected'] ?? source['is_connected'] ?? map['connected'];
    if (c is bool) {
      connected = c;
    } else {
      final s = c?.toString().toLowerCase();
      connected = s == 'true' || s == '1' || s == 'yes';
    }

    var email = '${source['email'] ?? source['google_email'] ?? map['email'] ?? ''}'
        .trim();

    return GoogleIntegrationStatus(
      connected: connected,
      email: email,
      raw: data,
    );
  }

  @override
  List<Object?> get props => [connected, email];
}

/// Extract OAuth URL from GET `/integrations/google/connect` JSON.
String? parseGoogleConnectUrl(Object? data) {
  if (data is! Map) return null;
  final map = Map<Object?, Object?>.from(data);
  final inner = map['data'];
  final source = inner is Map ? Map<Object?, Object?>.from(inner) : map;

  const keys = [
    'url',
    'authorization_url',
    'authorizationUrl',
    'connect_url',
    'connectUrl',
    'oauth_url',
    'auth_url',
  ];
  for (final k in keys) {
    final v = source[k] ?? map[k];
    if (v != null) {
      final s = v.toString().trim();
      if (s.startsWith('http://') || s.startsWith('https://')) {
        return s;
      }
    }
  }
  return null;
}

import 'dart:convert';

import 'maps_command.dart';

/// Parses backend payloads where `type` is `maps_navigate`, `maps_route`, etc.
///
/// Supports:
/// - Root-level `{ "type": "maps_navigate", ... }`
/// - Nested under merged `data`
/// - **`assistant_audio`** frames that put map actions in **`actions`**: e.g.
///   `"actions":[{"type":"maps_navigate","lat":...,"name":"..."}]`
MapsCommand? parseSocketMapsCommand(Object? raw) {
  final flat = flattenSocketPayload(raw);
  if (flat == null) return null;

  final fromRoot = mapsCommandFromTypedActionMap(flat);
  if (fromRoot != null) return fromRoot;

  final actions = flat['actions'];
  if (actions is List) {
    for (final item in actions) {
      if (item is Map) {
        final cmd = mapsCommandFromTypedActionMap(Map<String, dynamic>.from(item));
        if (cmd != null) return cmd;
      }
    }
  }

  return null;
}

/// Maps tool shapes (`maps_navigate`, …) to [MapsCommand].
MapsCommand? mapsCommandFromTypedActionMap(Map<String, dynamic> m) {
  if (_hasHttpsMapsUrl(m)) return null;
  final type = m['type']?.toString();
  return switch (type) {
    'maps_navigate' => _mapsNavigate(m),
    'maps_route' => _mapsRoute(m),
    'maps_suggest' => _mapsSuggest(m),
    'maps_place' => _mapsPlace(m),
    _ => null,
  };
}

/// Flatten nested `data` for socket JSON (merged assistant payloads).
Map<String, dynamic>? flattenSocketPayload(Object? raw) {
  if (raw == null) return null;
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      final decoded = jsonDecode(t);
      return flattenSocketPayload(decoded);
    } catch (_) {
      return null;
    }
  }
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final inner = map['data'];
  if (inner is Map) {
    return {...map, ...Map<String, dynamic>.from(inner)};
  }
  return map;
}

bool _hasHttpsMapsUrl(Map<String, dynamic> m) {
  final urlStr = m['maps_url']?.toString().trim() ?? '';
  if (urlStr.isEmpty) return false;
  final uri = Uri.tryParse(urlStr);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http');
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

MapsCommand? _mapsNavigate(Map<String, dynamic> m) {
  final lat = _toDouble(m['lat']);
  final lng = _toDouble(m['lng']);
  if (lat == null || lng == null) return null;
  final name = m['name']?.toString().trim() ?? '';
  final query = name.isNotEmpty ? name : '$lat,$lng';
  return MapsCommand.navigate(query);
}

MapsCommand? _mapsRoute(Map<String, dynamic> m) {
  final dlat = _toDouble(m['destination_lat'] ?? m['dest_lat']);
  final dlng = _toDouble(m['destination_lng'] ?? m['dest_lng']);
  if (dlat != null && dlng != null) {
    return MapsCommand.navigate('$dlat,$dlng');
  }
  final lat = _toDouble(m['lat']);
  final lng = _toDouble(m['lng']);
  if (lat != null && lng != null) {
    return MapsCommand.navigate('$lat,$lng');
  }
  return null;
}

MapsCommand? _mapsSuggest(Map<String, dynamic> m) {
  final q = m['query']?.toString().trim() ??
      m['q']?.toString().trim() ??
      m['keyword']?.toString().trim() ??
      '';
  if (q.isEmpty) return null;
  return MapsCommand.search(q);
}

MapsCommand? _mapsPlace(Map<String, dynamic> m) {
  final name = m['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) {
    return MapsCommand.search(name);
  }
  final lat = _toDouble(m['lat']);
  final lng = _toDouble(m['lng']);
  if (lat != null && lng != null) {
    return MapsCommand.search('$lat,$lng');
  }
  final placeId =
      m['place_id']?.toString().trim() ?? m['placeId']?.toString().trim() ?? '';
  if (placeId.isNotEmpty) {
    return MapsCommand.search(placeId);
  }
  return null;
}

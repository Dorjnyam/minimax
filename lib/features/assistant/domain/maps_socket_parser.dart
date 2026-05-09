import 'dart:convert';

import 'maps_command.dart';

/// Parses backend payloads where `type` is `maps_navigate`, `maps_route`, etc.
MapsCommand? parseSocketMapsCommand(Object? raw) {
  final flat = _flattenPayload(raw);
  if (flat == null) return null;
  final type = flat['type']?.toString();
  return switch (type) {
    'maps_navigate' => _mapsNavigate(flat),
    'maps_route' => _mapsRoute(flat),
    'maps_suggest' => _mapsSuggest(flat),
    'maps_place' => _mapsPlace(flat),
    _ => null,
  };
}

Map<String, dynamic>? _flattenPayload(Object? raw) {
  if (raw == null) return null;
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      final decoded = jsonDecode(t);
      return _flattenPayload(decoded);
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

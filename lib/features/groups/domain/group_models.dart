bool _parseBool(Object? v) {
  if (v == true) return true;
  if (v == false) return false;
  if (v is num) return v != 0;
  final s = v?.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

DateTime? _parseIso(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// GET `/api/v1/groups/` item.
class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final DateTime? createdAt;

  factory GroupSummary.fromJson(Map<String, Object?> json) {
    return GroupSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      inviteCode: json['invite_code']?.toString() ?? '',
      createdAt: _parseIso(json['created_at']),
    );
  }
}

/// GET `/api/v1/groups/{id}/locations` row.
class GroupMemberLocation {
  const GroupMemberLocation({
    required this.userId,
    required this.fullName,
    required this.shareLocation,
    this.lat,
    this.lng,
    this.address,
    this.accuracy,
    this.updatedAt,
  });

  final String userId;
  final String fullName;
  final bool shareLocation;
  final double? lat;
  final double? lng;
  final String? address;
  final double? accuracy;
  final DateTime? updatedAt;

  bool get hasCoords =>
      lat != null && lng != null && shareLocation;

  factory GroupMemberLocation.fromJson(Map<String, Object?> json) {
    final loc = json['location'];
    Map<String, Object?>? m;
    if (loc is Map) {
      m = Map<String, Object?>.from(
        loc.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    double? d(Object? x) =>
        x is num ? x.toDouble() : double.tryParse('$x');

    return GroupMemberLocation(
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      shareLocation: _parseBool(json['share_location']),
      lat: m != null ? d(m['lat']) : null,
      lng: m != null ? d(m['lng']) : null,
      address: m != null ? m['address']?.toString() : null,
      accuracy: m != null ? d(m['accuracy']) : null,
      updatedAt: m != null ? _parseIso(m['updated_at']) : null,
    );
  }
}

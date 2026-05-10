import 'maps_command.dart';
import 'maps_socket_parser.dart';
import 'assistant_follow_up_action.dart';

/// Builds ordered follow-ups from `assistant_audio.actions[]` (and root tool-shaped maps).
///
/// Gmail/calendar payloads that appear only under `tool_calls[].result` (no `actions[]`)
/// are out of scope until the backend mirrors them into `actions`.
List<AssistantFollowUp> parseAssistantFollowUps(Object? raw) {
  final flat = flattenSocketPayload(raw);
  if (flat == null) return const [];

  final out = <AssistantFollowUp>[];
  final actions = flat['actions'];

  if (actions is List) {
    for (final item in actions) {
      if (item is Map) {
        _appendForActionMap(Map<String, dynamic>.from(item), out);
      }
    }
  }

  if (out.isEmpty) {
    final rootType = flat['type']?.toString();
    if (rootType != null &&
        rootType != 'assistant_audio' &&
        actions == null) {
      _appendForActionMap(flat, out);
    }
  }

  return out;
}

void _appendForActionMap(Map<String, dynamic> m, List<AssistantFollowUp> out) {
  final type = m['type']?.toString() ?? '';
  final event = m['event']?.toString() ?? '';

  switch (type) {
    case 'maps_navigate':
    case 'maps_route':
    case 'maps_suggest':
    case 'maps_place':
      _appendMapsAction(m, out);
      return;
    case 'group_location':
      if (event == 'group_member_location') {
        _appendGroupMemberLocation(m, out);
      }
      return;
    case 'contact':
      switch (event) {
        case 'contact_save':
        case 'contact_search':
        case 'contact_list':
          _appendContactDeepLinks(m, out);
          return;
        case 'contact_message':
        case 'message':
          _appendContactSmsDeepLink(m, out);
          return;
        case 'contact_error':
          return;
        default:
          return;
      }
    case 'memory':
      return;
    case 'task_reminder':
      _appendReminderIfUrl(m, out);
      return;
    case 'weather':
      return;
    default:
      return;
  }
}

void _appendMapsAction(Map<String, dynamic> m, List<AssistantFollowUp> out) {
  final urlStr = m['maps_url']?.toString().trim() ?? '';
  if (urlStr.isNotEmpty) {
    final uri = Uri.tryParse(urlStr);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http')) {
      final label = m['name']?.toString().trim() ?? '';
      out.add(
        AssistantFollowUpOpenUri(
          uri: uri,
          confirmationMessage: label.isNotEmpty
              ? 'Opening directions to $label.'
              : 'Opening Maps.',
        ),
      );
      return;
    }
  }
  final cmd = mapsCommandFromTypedActionMap(m);
  if (cmd != null) {
    out.add(AssistantFollowUpMaps(command: cmd));
  }
}

void _appendGroupMemberLocation(
  Map<String, dynamic> m,
  List<AssistantFollowUp> out,
) {
  if (m['ok'] == false) return;
  final data = m['data'];
  if (data is! Map) return;
  final members = data['members'];
  if (members is! List) return;

  for (final item in members) {
    if (item is! Map) continue;
    final loc = item['location'];
    if (loc is! Map) continue;
    final lat = _toDouble(loc['lat']);
    final lng = _toDouble(loc['lng']);
    if (lat == null || lng == null) continue;

    var name = '';
    final member = item['member'];
    if (member is Map) {
      name = member['full_name']?.toString().trim() ?? '';
    }
    final query = name.isNotEmpty ? name : '$lat,$lng';
    out.add(AssistantFollowUpMaps(command: MapsCommand.navigate(query)));
    break;
  }
}

void _appendContactDeepLinks(
  Map<String, dynamic> m,
  List<AssistantFollowUp> out,
) {
  final data = m['data'];
  if (data is! Map) return;
  final map = Map<String, dynamic>.from(data);

  Map<String, dynamic>? contactObj;
  final single = map['contact'];
  if (single is Map) {
    contactObj = Map<String, dynamic>.from(single);
  } else {
    final list = map['contacts'];
    if (list is List && list.isNotEmpty && list.first is Map) {
      contactObj = Map<String, dynamic>.from(list.first as Map);
    }
  }
  if (contactObj == null) return;

  final phone = contactObj['phone']?.toString().trim() ?? '';
  final email = contactObj['email']?.toString().trim() ?? '';
  final name = contactObj['name']?.toString().trim() ?? '';

  if (phone.isNotEmpty) {
    final tel = _telUri(phone);
    if (tel != null) {
      out.add(
        AssistantFollowUpOpenUri(
          uri: tel,
          confirmationMessage:
              name.isNotEmpty ? 'Calling $name.' : 'Opening phone dialer.',
        ),
      );
    }
  }
  if (email.isNotEmpty) {
    out.add(
      AssistantFollowUpOpenUri(
        uri: Uri.parse('mailto:$email'),
        confirmationMessage: name.isNotEmpty
            ? 'Opening mail for $name.'
            : 'Opening mail.',
      ),
    );
  }
}

/// Opens the default SMS app (`sms:`) when backend sends
/// `{ "type": "contact", "event": "message" | "contact_message", "data": { ... } }`.
void _appendContactSmsDeepLink(
  Map<String, dynamic> m,
  List<AssistantFollowUp> out,
) {
  final data = m['data'];
  if (data is! Map) return;
  final map = Map<String, dynamic>.from(data);

  Map<String, dynamic>? contactObj;
  final single = map['contact'];
  if (single is Map) {
    contactObj = Map<String, dynamic>.from(single);
  } else {
    final list = map['contacts'];
    if (list is List && list.isNotEmpty && list.first is Map) {
      contactObj = Map<String, dynamic>.from(list.first as Map);
    }
  }
  if (contactObj == null) return;

  final phone = contactObj['phone']?.toString().trim() ?? '';
  final name = contactObj['name']?.toString().trim() ?? '';
  final body = _firstNonEmpty([
    contactObj['body'],
    contactObj['message'],
    contactObj['text'],
  ]);

  if (phone.isEmpty) return;

  final sms = _smsUri(phone, body: body);
  if (sms == null) return;

  out.add(
    AssistantFollowUpOpenUri(
      uri: sms,
      confirmationMessage: name.isNotEmpty
          ? 'Opening messages for $name.'
          : 'Opening messages.',
    ),
  );
}

String? _firstNonEmpty(List<Object?> values) {
  for (final v in values) {
    final t = v?.toString().trim() ?? '';
    if (t.isNotEmpty) return t;
  }
  return null;
}

/// SMS / messaging app URI (prefilled body optional).
Uri? _smsUri(String rawPhone, {String? body}) {
  var digits = rawPhone.replaceAll(RegExp(r'[\s\-().]'), '');
  if (digits.isEmpty) return null;
  if (!digits.startsWith('+')) {
    if (RegExp(r'^\d{8}$').hasMatch(digits)) {
      digits = '+976$digits';
    }
  }
  final b = body?.trim();
  if (b != null && b.isNotEmpty) {
    return Uri.parse(
      'sms:$digits?body=${Uri.encodeComponent(b)}',
    );
  }
  return Uri.parse('sms:$digits');
}

void _appendReminderIfUrl(Map<String, dynamic> m, List<AssistantFollowUp> out) {
  final event = m['event']?.toString();
  if (event == 'reminder_error') return;

  final url = _findFirstHttpsUrl(m['data']);
  if (url == null) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  out.add(
    AssistantFollowUpOpenUri(
      uri: uri,
      confirmationMessage: 'Opening link.',
    ),
  );
}

String? _findFirstHttpsUrl(Object? node) {
  if (node == null) return null;
  if (node is String) {
    final t = node.trim();
    if (t.startsWith('https://') || t.startsWith('http://')) return t;
    return null;
  }
  if (node is Map) {
    for (final e in node.entries) {
      if ('${e.key}' == 'calendar_link') {
        final s = e.value?.toString().trim();
        if (s != null &&
            (s.startsWith('https://') || s.startsWith('http://'))) {
          return s;
        }
      }
      final nested = _findFirstHttpsUrl(e.value);
      if (nested != null) return nested;
    }
  }
  if (node is List) {
    for (final e in node) {
      final nested = _findFirstHttpsUrl(e);
      if (nested != null) return nested;
    }
  }
  return null;
}

Uri? _telUri(String raw) {
  var digits = raw.replaceAll(RegExp(r'[\s\-().]'), '');
  if (digits.isEmpty) return null;
  if (!digits.startsWith('+')) {
    if (RegExp(r'^\d{8}$').hasMatch(digits)) {
      digits = '+976$digits';
    }
  }
  // Hierarchical `tel` URI: keep E.164 in [path] (avoids `+` host ambiguities in some parsers).
  return Uri(scheme: 'tel', path: digits);
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

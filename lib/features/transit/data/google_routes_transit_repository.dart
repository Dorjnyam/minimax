import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/transit_models.dart';
import 'transit_repository.dart';

typedef TransitHttpPost =
    Future<http.Response> Function(
      Uri uri, {
      Map<String, String>? headers,
      Object? body,
    });

class GoogleRoutesTransitRepository implements TransitRepository {
  const GoogleRoutesTransitRepository({
    TransitHttpPost? post,
    TransitRepository fallback = const MockTransitRepository(),
  }) : _post = post ?? http.post,
       _fallback = fallback;

  static final _endpoint = Uri.https(
    'routes.googleapis.com',
    '/directions/v2:computeRoutes',
  );

  static final _fieldMask = [
    'routes.duration',
    'routes.localizedValues',
    'routes.legs.steps.travelMode',
    'routes.legs.steps.localizedValues',
    'routes.legs.steps.transitDetails',
  ].join(',');

  final TransitHttpPost _post;
  final TransitRepository _fallback;

  @override
  Future<List<TransitRouteOption>> findBusOptions({
    required String origin,
    required String destination,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      return _fallback.findBusOptions(origin: origin, destination: destination);
    }

    final response = await _post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey.trim(),
        'X-Goog-FieldMask': _fieldMask,
      },
      body: jsonEncode(_requestBody(origin, destination)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Google Routes failed: ${response.statusCode}');
    }

    return GoogleRoutesTransitParser.parse(
      jsonDecode(response.body) as Map<String, dynamic>,
      origin: origin,
      destination: destination,
    );
  }

  Map<String, Object?> _requestBody(String origin, String destination) {
    return {
      'origin': {'address': origin},
      'destination': {'address': destination},
      'travelMode': 'TRANSIT',
      'computeAlternativeRoutes': true,
      'transitPreferences': {
        'allowedTravelModes': ['BUS'],
        'routingPreference': 'FEWER_TRANSFERS',
      },
    };
  }
}

class GoogleRoutesTransitParser {
  const GoogleRoutesTransitParser._();

  static List<TransitRouteOption> parse(
    Map<String, dynamic> data, {
    required String origin,
    required String destination,
  }) {
    final routes = data['routes'];
    if (routes is! List) {
      return const [];
    }

    return routes
        .whereType<Map<String, dynamic>>()
        .map(
          (route) =>
              _parseRoute(route, origin: origin, destination: destination),
        )
        .whereType<TransitRouteOption>()
        .toList(growable: false);
  }

  static TransitRouteOption? _parseRoute(
    Map<String, dynamic> route, {
    required String origin,
    required String destination,
  }) {
    final steps = _routeSteps(route);
    final transitSteps = steps
        .map(_transitDetails)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    if (transitSteps.isEmpty) {
      return null;
    }

    final busNumbers = <String>[];
    final routeNames = <String>[];
    final stops = <TransitStop>[];
    final routeSteps = <TransitStep>[];

    for (final step in steps) {
      final transit = _transitDetails(step);
      if (transit == null) {
        routeSteps.add(_walkingStep(step));
        continue;
      }
      final line = _map(transit['transitLine']);
      final stopDetails = _map(transit['stopDetails']);
      final shortName = _string(line['nameShort']);
      final lineName = _string(line['name']);
      final number = shortName.isEmpty ? lineName : shortName;
      if (number.isNotEmpty) {
        busNumbers.add(number);
      }
      if (lineName.isNotEmpty) {
        routeNames.add(lineName);
      }

      final departure = _map(stopDetails['departureStop']);
      final arrival = _map(stopDetails['arrivalStop']);
      final localized = _map(transit['localizedValues']);
      final departureTime = _localizedTime(localized['departureTime']);
      final arrivalTime = _localizedTime(localized['arrivalTime']);
      final fromStop = _string(departure['name'], fallback: origin);
      final toStop = _string(arrival['name'], fallback: destination);

      stops.add(TransitStop(name: fromStop, time: departureTime));
      stops.add(TransitStop(name: toStop, time: arrivalTime));
      routeSteps.add(
        TransitStep(
          title: 'Ride ${number.isEmpty ? 'bus' : number}',
          detail: '$fromStop to $toStop',
          minutes: _minutesBetween(departureTime, arrivalTime),
        ),
      );
    }

    final firstTransit = transitSteps.first;
    final lastTransit = transitSteps.last;
    final firstStop = _map(_map(firstTransit['stopDetails'])['departureStop']);
    final lastStop = _map(_map(lastTransit['stopDetails'])['arrivalStop']);
    final firstTimes = _map(firstTransit['localizedValues']);
    final lastTimes = _map(lastTransit['localizedValues']);

    return TransitRouteOption(
      busNumber: _joinUnique(busNumbers, fallback: 'Bus'),
      routeName: _joinUnique(routeNames, fallback: 'Transit route'),
      headsign: _string(lastTransit['headsign'], fallback: destination),
      fromStop: _string(firstStop['name'], fallback: origin),
      toStop: _string(lastStop['name'], fallback: destination),
      departureTime: _localizedTime(firstTimes['departureTime']),
      arrivalTime: _localizedTime(lastTimes['arrivalTime']),
      totalMinutes: _durationMinutes(route),
      walkMinutes: _walkMinutes(routeSteps),
      transferCount: transitSteps.length - 1,
      stops: _dedupeStops(stops),
      steps: routeSteps,
    );
  }

  static List<Map<String, dynamic>> _routeSteps(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List || legs.isEmpty) {
      return const [];
    }
    final firstLeg = _map(legs.first);
    final steps = firstLeg['steps'];
    return steps is List
        ? steps.whereType<Map<String, dynamic>>().toList()
        : [];
  }

  static Map<String, dynamic>? _transitDetails(Map<String, dynamic> step) {
    final details = step['transitDetails'];
    return details is Map<String, dynamic> ? details : null;
  }

  static TransitStep _walkingStep(Map<String, dynamic> step) {
    final values = _map(step['localizedValues']);
    final duration = _string(_map(values['staticDuration'])['text']);
    return TransitStep(
      title: 'Walk',
      detail: duration.isEmpty ? 'Walking segment' : duration,
      minutes: _durationTextMinutes(duration),
    );
  }

  static int _durationMinutes(Map<String, dynamic> route) {
    final duration = _string(route['duration']);
    final seconds = int.tryParse(duration.replaceAll('s', '')) ?? 0;
    if (seconds > 0) {
      return (seconds / 60).ceil();
    }
    final localized = _map(route['localizedValues']);
    return _durationTextMinutes(_string(_map(localized['duration'])['text']));
  }

  static int _walkMinutes(List<TransitStep> steps) {
    return steps
        .where((step) => step.title.toLowerCase().contains('walk'))
        .fold<int>(0, (total, step) => total + step.minutes);
  }

  static int _minutesBetween(String start, String end) {
    final startParts = start.split(':').map(int.tryParse).toList();
    final endParts = end.split(':').map(int.tryParse).toList();
    if (startParts.length < 2 || endParts.length < 2) {
      return 0;
    }
    final startMinutes = (startParts[0] ?? 0) * 60 + (startParts[1] ?? 0);
    var endMinutes = (endParts[0] ?? 0) * 60 + (endParts[1] ?? 0);
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }
    return endMinutes - startMinutes;
  }

  static int _durationTextMinutes(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static String _localizedTime(Object? value) {
    final map = _map(value);
    final time = _string(_map(map['time'])['text']);
    return time.isEmpty ? '--:--' : time;
  }

  static List<TransitStop> _dedupeStops(List<TransitStop> stops) {
    final seen = <String>{};
    return [
      for (final stop in stops)
        if (seen.add('${stop.name}-${stop.time}')) stop,
    ];
  }

  static String _joinUnique(List<String> values, {required String fallback}) {
    final unique = values.where((value) => value.isNotEmpty).toSet().toList();
    return unique.isEmpty ? fallback : unique.join(' + ');
  }

  static Map<String, dynamic> _map(Object? value) {
    return value is Map<String, dynamic> ? value : const {};
  }

  static String _string(Object? value, {String fallback = ''}) {
    final string = value?.toString() ?? '';
    return string.isEmpty ? fallback : string;
  }
}

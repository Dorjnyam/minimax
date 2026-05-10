import 'package:url_launcher/url_launcher.dart';

import '../../features/assistant/domain/maps_command.dart';

typedef UrlLaunch = Future<bool> Function(Uri uri, LaunchMode mode);

class MapsLauncherService {
  const MapsLauncherService({UrlLaunch? launch})
    : _launch = launch ?? _defaultLaunch;

  final UrlLaunch _launch;

  Future<void> launch(MapsCommand command) async {
    for (final uri in _urisFor(command)) {
      if (await _launchBestEffort(uri)) {
        return;
      }
    }
    throw StateError('Could not open Google Maps.');
  }

  /// Same strategy as [AssistantFollowUpLauncher] for tel/sms — many OEMs reject one mode.
  Future<bool> _launchBestEffort(Uri uri) async {
    const modes = <LaunchMode>[
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.externalNonBrowserApplication,
    ];
    for (final mode in modes) {
      try {
        if (await _launch(uri, mode)) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  static List<Uri> _urisFor(MapsCommand command) {
    return switch (command.type) {
      MapsCommandType.currentLocation => [
        _geoSearchUri('current location'),
        _mapsSearchUri('current location'),
      ],
      MapsCommandType.search => _searchUris(command.query),
      MapsCommandType.directions => _routeUris(command),
    };
  }

  /// Prefer direct [geo:lat,lng] when the backend sends a coordinate pair (opens Maps reliably).
  static List<Uri> _searchUris(String query) {
    final coords = _parseCoordinatePair(query);
    if (coords != null) {
      final lat = coords.lat;
      final lng = coords.lng;
      return [
        Uri.parse('geo:$lat,$lng'),
        _geoSearchUri(query),
        _mapsSearchUri(query),
      ];
    }
    return [
      _geoSearchUri(query),
      _mapsSearchUri(query),
    ];
  }

  /// `"47.9189,106.9176"` from agent / socket — not free text labels.
  static ({double lat, double lng})? _parseCoordinatePair(String query) {
    final t = query.trim();
    final comma = t.indexOf(',');
    if (comma <= 0 || comma >= t.length - 1) {
      return null;
    }
    final lat = double.tryParse(t.substring(0, comma).trim());
    final lng = double.tryParse(t.substring(comma + 1).trim());
    if (lat == null || lng == null) {
      return null;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }
    return (lat: lat, lng: lng);
  }

  static List<Uri> _routeUris(MapsCommand command) {
    final webUri = _mapsDirectionsUri(command);
    final coord = _parseCoordinatePair(command.query);
    final canUseAndroidNavigation =
        command.routeAction == MapsRouteAction.navigate &&
        command.travelMode != MapsTravelMode.transit &&
        command.waypoints.isEmpty;

    final out = <Uri>[];
    if (coord != null) {
      out.add(Uri.parse('geo:${coord.lat},${coord.lng}'));
    }
    if (!canUseAndroidNavigation) {
      out.add(webUri);
      return out;
    }
    out.add(_googleNavigationUri(command));
    out.add(webUri);
    return out;
  }

  static Uri _geoSearchUri(String query) {
    return Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
  }

  static Uri _googleNavigationUri(MapsCommand command) {
    final params = <String>[
      'q=${Uri.encodeComponent(command.query)}',
      if (command.travelMode != null)
        'mode=${_androidMode(command.travelMode!)}',
      if (command.avoid.isNotEmpty)
        'avoid=${command.avoid.map(_androidAvoid).join()}',
    ];
    return Uri.parse('google.navigation:${params.join('&')}');
  }

  static Uri _mapsSearchUri(String query) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  static Uri _mapsDirectionsUri(MapsCommand command) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': command.query,
      if (command.travelMode != null)
        'travelmode': _webMode(command.travelMode!),
      if (command.routeAction == MapsRouteAction.navigate)
        'dir_action': 'navigate',
      if (command.waypoints.isNotEmpty)
        'waypoints': command.waypoints.join('|'),
      if (command.avoid.isNotEmpty)
        'avoid': command.avoid.map(_webAvoid).join(','),
    });
  }

  static String _webMode(MapsTravelMode mode) {
    return switch (mode) {
      MapsTravelMode.driving => 'driving',
      MapsTravelMode.walking => 'walking',
      MapsTravelMode.bicycling => 'bicycling',
      MapsTravelMode.twoWheeler => 'two-wheeler',
      MapsTravelMode.transit => 'transit',
    };
  }

  static String _androidMode(MapsTravelMode mode) {
    return switch (mode) {
      MapsTravelMode.driving => 'd',
      MapsTravelMode.walking => 'w',
      MapsTravelMode.bicycling => 'b',
      MapsTravelMode.twoWheeler => 'l',
      MapsTravelMode.transit => 'd',
    };
  }

  static String _webAvoid(MapsAvoid avoid) {
    return switch (avoid) {
      MapsAvoid.tolls => 'tolls',
      MapsAvoid.highways => 'highways',
      MapsAvoid.ferries => 'ferries',
    };
  }

  static String _androidAvoid(MapsAvoid avoid) {
    return switch (avoid) {
      MapsAvoid.tolls => 't',
      MapsAvoid.highways => 'h',
      MapsAvoid.ferries => 'f',
    };
  }

  static Future<bool> _defaultLaunch(Uri uri, LaunchMode mode) {
    return launchUrl(uri, mode: mode);
  }
}

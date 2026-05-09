import 'package:url_launcher/url_launcher.dart';

import '../../features/assistant/domain/maps_command.dart';

typedef UrlLaunch = Future<bool> Function(Uri uri, LaunchMode mode);

class MapsLauncherService {
  const MapsLauncherService({UrlLaunch? launch})
    : _launch = launch ?? _defaultLaunch;

  final UrlLaunch _launch;

  Future<void> launch(MapsCommand command) async {
    for (final uri in _urisFor(command)) {
      final didLaunch = await _launch(uri, LaunchMode.externalApplication);
      if (didLaunch) {
        return;
      }
    }
    throw StateError('Could not open Google Maps.');
  }

  static List<Uri> _urisFor(MapsCommand command) {
    return switch (command.type) {
      MapsCommandType.currentLocation => [
        _geoSearchUri('current location'),
        _mapsSearchUri('current location'),
      ],
      MapsCommandType.search => [
        _geoSearchUri(command.query),
        _mapsSearchUri(command.query),
      ],
      MapsCommandType.directions => _routeUris(command),
    };
  }

  static List<Uri> _routeUris(MapsCommand command) {
    final webUri = _mapsDirectionsUri(command);
    final canUseAndroidNavigation =
        command.routeAction == MapsRouteAction.navigate &&
        command.travelMode != MapsTravelMode.transit &&
        command.waypoints.isEmpty;

    if (!canUseAndroidNavigation) {
      return [webUri];
    }
    return [_googleNavigationUri(command), webUri];
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

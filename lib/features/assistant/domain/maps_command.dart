import 'package:equatable/equatable.dart';

enum MapsCommandType { currentLocation, search, directions }

enum MapsRouteAction { preview, navigate }

enum MapsTravelMode { driving, walking, bicycling, twoWheeler, transit }

enum MapsAvoid { tolls, highways, ferries }

class MapsCommand extends Equatable {
  const MapsCommand({
    required this.type,
    required this.query,
    this.routeAction = MapsRouteAction.preview,
    this.travelMode,
    this.avoid = const [],
    this.waypoints = const [],
  });

  const MapsCommand.currentLocation()
    : type = MapsCommandType.currentLocation,
      query = 'current location',
      routeAction = MapsRouteAction.preview,
      travelMode = null,
      avoid = const [],
      waypoints = const [];

  const MapsCommand.search(this.query)
    : type = MapsCommandType.search,
      routeAction = MapsRouteAction.preview,
      travelMode = null,
      avoid = const [],
      waypoints = const [];

  const MapsCommand.directions(
    this.query, {
    this.travelMode = MapsTravelMode.driving,
    this.routeAction = MapsRouteAction.preview,
    this.avoid = const [],
    this.waypoints = const [],
  }) : type = MapsCommandType.directions;

  const MapsCommand.navigate(
    this.query, {
    this.travelMode = MapsTravelMode.driving,
    this.avoid = const [],
    this.waypoints = const [],
  }) : type = MapsCommandType.directions,
       routeAction = MapsRouteAction.navigate;

  final MapsCommandType type;
  final String query;
  final MapsRouteAction routeAction;
  final MapsTravelMode? travelMode;
  final List<MapsAvoid> avoid;
  final List<String> waypoints;

  String get confirmation {
    return switch (type) {
      MapsCommandType.currentLocation => 'Opening your location in Maps.',
      MapsCommandType.search => 'Searching Maps for $query.',
      MapsCommandType.directions => _routeConfirmation,
    };
  }

  String get _routeConfirmation {
    final mode = travelMode?.label ?? 'default';
    final action = routeAction == MapsRouteAction.navigate
        ? 'Starting'
        : 'Opening';
    return '$action $mode route to $query.';
  }

  @override
  List<Object?> get props => [
    type,
    query,
    routeAction,
    travelMode,
    avoid,
    waypoints,
  ];
}

extension MapsTravelModeLabel on MapsTravelMode {
  String get label {
    return switch (this) {
      MapsTravelMode.driving => 'driving',
      MapsTravelMode.walking => 'walking',
      MapsTravelMode.bicycling => 'bicycling',
      MapsTravelMode.twoWheeler => 'two-wheeler',
      MapsTravelMode.transit => 'transit',
    };
  }
}

extension MapsAvoidLabel on MapsAvoid {
  String get label {
    return switch (this) {
      MapsAvoid.tolls => 'tolls',
      MapsAvoid.highways => 'highways',
      MapsAvoid.ferries => 'ferries',
    };
  }
}

class MapsCommandParser {
  const MapsCommandParser();

  MapsCommand? parse(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) {
      return null;
    }

    if (text.contains('my location') ||
        text.contains('current location') ||
        text.contains('where am i')) {
      return const MapsCommand.currentLocation();
    }

    final directions = _afterAny(text, const [
      'directions to ',
      'direction to ',
      'navigate to ',
      'take me to ',
      'route to ',
    ]);
    if (directions != null) {
      final destination = _cleanRouteDestination(directions);
      final mode = _modeFrom(text) ?? MapsTravelMode.driving;
      final avoid = _avoidFrom(text);
      if (text.contains('navigate to ') || text.contains('take me to ')) {
        return MapsCommand.navigate(
          _title(destination),
          travelMode: mode,
          avoid: avoid,
        );
      }
      return MapsCommand.directions(
        _title(destination),
        travelMode: mode,
        avoid: avoid,
      );
    }

    final search = _afterAny(text, const [
      'search for ',
      'search ',
      'find ',
      'show me ',
    ]);
    if (search != null) {
      return MapsCommand.search(_title(search));
    }

    if (text.contains(' near me')) {
      return MapsCommand.search(_title(text));
    }

    return null;
  }

  String? _afterAny(String text, List<String> prefixes) {
    for (final prefix in prefixes) {
      final index = text.indexOf(prefix);
      if (index >= 0) {
        final value = text.substring(index + prefix.length).trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  MapsTravelMode? _modeFrom(String text) {
    if (text.contains('walk')) {
      return MapsTravelMode.walking;
    }
    if (text.contains('bike') || text.contains('bicycle')) {
      return MapsTravelMode.bicycling;
    }
    if (text.contains('two wheeler') || text.contains('motorcycle')) {
      return MapsTravelMode.twoWheeler;
    }
    if (text.contains('transit') || text.contains('bus')) {
      return MapsTravelMode.transit;
    }
    if (text.contains('drive') || text.contains('car')) {
      return MapsTravelMode.driving;
    }
    return null;
  }

  List<MapsAvoid> _avoidFrom(String text) {
    return [
      if (text.contains('avoid toll')) MapsAvoid.tolls,
      if (text.contains('avoid highway')) MapsAvoid.highways,
      if (text.contains('avoid ferr')) MapsAvoid.ferries,
    ];
  }

  String _cleanRouteDestination(String value) {
    return value
        .replaceAll(RegExp(r'\bby (car|bike|bicycle|bus)\b'), '')
        .replaceAll(RegExp(r'\bwalking\b'), '')
        .replaceAll(RegExp(r'\bdriving\b'), '')
        .replaceAll(
          RegExp(r'\bavoid (tolls|toll|highways|highway|ferries|ferry)\b'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _title(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

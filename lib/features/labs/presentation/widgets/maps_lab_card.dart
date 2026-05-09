import 'package:flutter/material.dart';

import '../../../assistant/domain/maps_command.dart';

class MapsLabCard extends StatefulWidget {
  const MapsLabCard({super.key, required this.onLaunch});

  final ValueChanged<MapsCommand> onLaunch;

  @override
  State<MapsLabCard> createState() => _MapsLabCardState();
}

class _MapsLabCardState extends State<MapsLabCard> {
  final _destinationController = TextEditingController(
    text: 'Sukhbaatar Square',
  );
  final _waypointController = TextEditingController(
    text: 'Chinggis Khaan National Museum',
  );

  @override
  void dispose() {
    _destinationController.dispose();
    _waypointController.dispose();
    super.dispose();
  }

  String get _destination {
    final value = _destinationController.text.trim();
    return value.isEmpty ? 'Sukhbaatar Square' : value;
  }

  String get _waypoint => _waypointController.text.trim();

  void _launch(MapsCommand command) => widget.onLaunch(command);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Google Maps', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'Type any place or address',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 12),
            _PrimaryMapActions(destination: _destination, onLaunch: _launch),
            const SizedBox(height: 16),
            const _SectionTitle('Route preview modes'),
            const SizedBox(height: 8),
            _RouteModeGrid(
              destination: _destination,
              action: MapsRouteAction.preview,
              onLaunch: _launch,
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Start navigation'),
            const SizedBox(height: 8),
            _RouteModeGrid(
              destination: _destination,
              action: MapsRouteAction.navigate,
              onLaunch: _launch,
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Avoid options'),
            const SizedBox(height: 8),
            _AvoidRouteButtons(destination: _destination, onLaunch: _launch),
            const SizedBox(height: 16),
            const _SectionTitle('Waypoint route'),
            const SizedBox(height: 8),
            TextField(
              controller: _waypointController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Waypoint',
                hintText: 'Optional place to route through',
                prefixIcon: Icon(Icons.alt_route),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _waypoint.isEmpty
                  ? null
                  : () => _launch(
                      MapsCommand.directions(
                        _destination,
                        waypoints: [_waypoint],
                      ),
                    ),
              icon: const Icon(Icons.alt_route),
              label: const Text('Route Via Waypoint'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryMapActions extends StatelessWidget {
  const _PrimaryMapActions({required this.destination, required this.onLaunch});

  final String destination;
  final ValueChanged<MapsCommand> onLaunch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => onLaunch(const MapsCommand.currentLocation()),
          icon: const Icon(Icons.my_location),
          label: const Text('Open My Location'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => onLaunch(const MapsCommand.search('Coffee Near Me')),
          icon: const Icon(Icons.search),
          label: const Text('Search Coffee Near Me'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => onLaunch(MapsCommand.directions(destination)),
          icon: const Icon(Icons.route),
          label: const Text('Show Route Alternatives'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => onLaunch(
            MapsCommand.directions(
              destination,
              travelMode: MapsTravelMode.transit,
            ),
          ),
          icon: const Icon(Icons.directions_bus),
          label: const Text('Transit / Bus Options'),
        ),
      ],
    );
  }
}

class _RouteModeGrid extends StatelessWidget {
  const _RouteModeGrid({
    required this.destination,
    required this.action,
    required this.onLaunch,
  });

  final String destination;
  final MapsRouteAction action;
  final ValueChanged<MapsCommand> onLaunch;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MapsTravelMode.values.map((mode) {
        return ActionChip(
          avatar: Icon(_iconFor(mode), size: 18),
          label: Text(mode.label),
          onPressed: () => onLaunch(
            action == MapsRouteAction.navigate
                ? MapsCommand.navigate(destination, travelMode: mode)
                : MapsCommand.directions(destination, travelMode: mode),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(MapsTravelMode mode) {
    return switch (mode) {
      MapsTravelMode.driving => Icons.directions_car,
      MapsTravelMode.walking => Icons.directions_walk,
      MapsTravelMode.bicycling => Icons.directions_bike,
      MapsTravelMode.twoWheeler => Icons.two_wheeler,
      MapsTravelMode.transit => Icons.directions_transit,
    };
  }
}

class _AvoidRouteButtons extends StatelessWidget {
  const _AvoidRouteButtons({required this.destination, required this.onLaunch});

  final String destination;
  final ValueChanged<MapsCommand> onLaunch;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AvoidChip(
          label: 'No tolls',
          destination: destination,
          avoid: const [MapsAvoid.tolls],
          onLaunch: onLaunch,
        ),
        _AvoidChip(
          label: 'No highways',
          destination: destination,
          avoid: const [MapsAvoid.highways],
          onLaunch: onLaunch,
        ),
        _AvoidChip(
          label: 'No ferries',
          destination: destination,
          avoid: const [MapsAvoid.ferries],
          onLaunch: onLaunch,
        ),
        _AvoidChip(
          label: 'Avoid all',
          destination: destination,
          avoid: const [MapsAvoid.tolls, MapsAvoid.highways, MapsAvoid.ferries],
          onLaunch: onLaunch,
        ),
      ],
    );
  }
}

class _AvoidChip extends StatelessWidget {
  const _AvoidChip({
    required this.label,
    required this.destination,
    required this.avoid,
    required this.onLaunch,
  });

  final String label;
  final String destination;
  final List<MapsAvoid> avoid;
  final ValueChanged<MapsCommand> onLaunch;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.tune, size: 18),
      label: Text(label),
      onPressed: () =>
          onLaunch(MapsCommand.navigate(destination, avoid: avoid)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

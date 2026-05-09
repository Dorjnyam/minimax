import 'package:flutter/material.dart';

import '../../domain/transit_models.dart';

class TransitRouteCard extends StatelessWidget {
  const TransitRouteCard({super.key, required this.option});

  final TransitRouteOption option;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RouteHeader(option: option),
            const SizedBox(height: 12),
            _RouteMeta(option: option),
            const SizedBox(height: 12),
            _StopPreview(stops: option.stops),
            const Divider(height: 24),
            _StepList(steps: option.steps),
          ],
        ),
      ),
    );
  }
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.option});

  final TransitRouteOption option;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF007C89),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            option.busNumber,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.routeName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              Text(
                'toward ${option.headsign}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.58)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteMeta extends StatelessWidget {
  const _RouteMeta({required this.option});

  final TransitRouteOption option;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(icon: Icons.schedule, label: option.summary),
        _MetaChip(
          icon: Icons.departure_board,
          label: '${option.departureTime} - ${option.arrivalTime}',
        ),
      ],
    );
  }
}

class _StopPreview extends StatelessWidget {
  const _StopPreview({required this.stops});

  final List<TransitStop> stops;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stops.map((stop) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Color(0xFF007C89)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(stop.time),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps});

  final List<TransitStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.directions, size: 18, color: Color(0xFF52616B)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      step.detail,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Text('${step.minutes}m'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

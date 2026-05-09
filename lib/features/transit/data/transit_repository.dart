import '../domain/transit_models.dart';

abstract interface class TransitRepository {
  Future<List<TransitRouteOption>> findBusOptions({
    required String origin,
    required String destination,
    String? apiKey,
  });
}

class MockTransitRepository implements TransitRepository {
  const MockTransitRepository();

  @override
  Future<List<TransitRouteOption>> findBusOptions({
    required String origin,
    required String destination,
    String? apiKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final cleanOrigin = origin.trim().isEmpty
        ? 'State Department Store Ulaanbaatar'
        : origin;
    final cleanDestination = destination.trim().isEmpty
        ? 'Sukhbaatar Square Ulaanbaatar'
        : destination;

    return [
      _directOption(cleanOrigin, cleanDestination),
      _transferOption(cleanOrigin, cleanDestination),
      _expressOption(cleanOrigin, cleanDestination),
    ];
  }

  TransitRouteOption _directOption(String origin, String destination) {
    return TransitRouteOption(
      busNumber: '5',
      routeName: 'Peace Avenue Line',
      headsign: destination,
      fromStop: '$origin Stop',
      toStop: '$destination Stop',
      departureTime: '10:12',
      arrivalTime: '10:39',
      totalMinutes: 27,
      walkMinutes: 6,
      transferCount: 0,
      stops: const [
        TransitStop(name: 'Central Post Office', time: '10:19'),
        TransitStop(name: 'State Department Store', time: '10:27'),
        TransitStop(name: 'Sukhbaatar Square', time: '10:39'),
      ],
      steps: const [
        TransitStep(
          title: 'Walk to nearest stop',
          detail: 'Use the closest stop from origin',
          minutes: 4,
        ),
        TransitStep(
          title: 'Ride Bus 5',
          detail: 'Stay on until destination stop',
          minutes: 21,
        ),
        TransitStep(
          title: 'Walk to destination',
          detail: 'Short final walk',
          minutes: 2,
        ),
      ],
    );
  }

  TransitRouteOption _transferOption(String origin, String destination) {
    return TransitRouteOption(
      busNumber: '7 + 23',
      routeName: 'One transfer route',
      headsign: destination,
      fromStop: '$origin Stop',
      toStop: '$destination Stop',
      departureTime: '10:16',
      arrivalTime: '10:51',
      totalMinutes: 35,
      walkMinutes: 8,
      transferCount: 1,
      stops: const [
        TransitStop(name: 'Origin District Stop', time: '10:16'),
        TransitStop(name: 'Central Transfer Stop', time: '10:31'),
        TransitStop(name: 'Destination District Stop', time: '10:51'),
      ],
      steps: const [
        TransitStep(
          title: 'Walk to Bus 7',
          detail: 'Board toward city center',
          minutes: 3,
        ),
        TransitStep(
          title: 'Ride Bus 7',
          detail: 'Exit at Central Transfer Stop',
          minutes: 15,
        ),
        TransitStep(
          title: 'Transfer to Bus 23',
          detail: 'Use the same-side platform',
          minutes: 5,
        ),
        TransitStep(
          title: 'Ride Bus 23',
          detail: 'Exit near destination',
          minutes: 12,
        ),
      ],
    );
  }

  TransitRouteOption _expressOption(String origin, String destination) {
    return TransitRouteOption(
      busNumber: 'X3',
      routeName: 'Limited stop route',
      headsign: destination,
      fromStop: '$origin Express Stop',
      toStop: '$destination Express Stop',
      departureTime: '10:24',
      arrivalTime: '10:46',
      totalMinutes: 22,
      walkMinutes: 10,
      transferCount: 0,
      stops: const [
        TransitStop(name: 'Express Origin', time: '10:24'),
        TransitStop(name: 'Peace Avenue', time: '10:34'),
        TransitStop(name: 'Express Destination', time: '10:46'),
      ],
      steps: const [
        TransitStep(
          title: 'Walk to express stop',
          detail: 'Longer walk, faster bus',
          minutes: 7,
        ),
        TransitStep(
          title: 'Ride Express X3',
          detail: 'Limited stop service',
          minutes: 14,
        ),
        TransitStep(
          title: 'Walk to destination',
          detail: 'Short final walk',
          minutes: 3,
        ),
      ],
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/transit/data/transit_repository.dart';

void main() {
  test(
    'mock transit repository returns bus options for a destination',
    () async {
      final options = await const MockTransitRepository().findBusOptions(
        origin: 'Current Location',
        destination: 'Sukhbaatar Square',
      );

      expect(options, hasLength(3));
      expect(options.first.busNumber, '5');
      expect(options.first.stops, isNotEmpty);
      expect(options.first.steps, isNotEmpty);
    },
  );
}

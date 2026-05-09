import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/transit/data/google_routes_transit_repository.dart';

void main() {
  test('parser extracts bus numbers and stop details from Google response', () {
    final options = GoogleRoutesTransitParser.parse(
      _sampleTransitResponse,
      origin: 'Origin',
      destination: 'Destination',
    );

    expect(options, hasLength(1));
    expect(options.first.busNumber, '5 + 23');
    expect(options.first.transferCount, 1);
    expect(options.first.departureTime, '10:12');
    expect(options.first.arrivalTime, '10:47');
    expect(options.first.stops.map((stop) => stop.name), contains('Stop A'));
  });
}

const _sampleTransitResponse = {
  'routes': [
    {
      'duration': '2100s',
      'legs': [
        {
          'steps': [
            {
              'travelMode': 'WALK',
              'localizedValues': {
                'staticDuration': {'text': '4 min'},
              },
            },
            {
              'travelMode': 'TRANSIT',
              'transitDetails': {
                'headsign': 'Central',
                'localizedValues': {
                  'departureTime': {
                    'time': {'text': '10:12'},
                  },
                  'arrivalTime': {
                    'time': {'text': '10:29'},
                  },
                },
                'stopDetails': {
                  'departureStop': {'name': 'Stop A'},
                  'arrivalStop': {'name': 'Transfer Stop'},
                },
                'transitLine': {'name': 'Peace Avenue Line', 'nameShort': '5'},
              },
            },
            {
              'travelMode': 'TRANSIT',
              'transitDetails': {
                'headsign': 'Destination',
                'localizedValues': {
                  'departureTime': {
                    'time': {'text': '10:34'},
                  },
                  'arrivalTime': {
                    'time': {'text': '10:47'},
                  },
                },
                'stopDetails': {
                  'departureStop': {'name': 'Transfer Stop'},
                  'arrivalStop': {'name': 'Stop B'},
                },
                'transitLine': {'name': 'Square Connector', 'nameShort': '23'},
              },
            },
          ],
        },
      ],
    },
  ],
};

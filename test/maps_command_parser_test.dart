import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/assistant/domain/maps_command.dart';

void main() {
  const parser = MapsCommandParser();

  test('recognizes current location commands', () {
    expect(
      parser.parse('show my location'),
      const MapsCommand.currentLocation(),
    );
  });

  test('recognizes directions commands', () {
    expect(
      parser.parse('directions to Sukhbaatar Square'),
      const MapsCommand.directions('Sukhbaatar Square'),
    );
  });

  test('recognizes route modes and avoid options', () {
    expect(
      parser.parse('walking directions to Sukhbaatar Square avoid tolls'),
      const MapsCommand.directions(
        'Sukhbaatar Square',
        travelMode: MapsTravelMode.walking,
        avoid: [MapsAvoid.tolls],
      ),
    );
  });

  test('recognizes navigation commands', () {
    expect(
      parser.parse('navigate to Sukhbaatar Square by bike avoid ferries'),
      const MapsCommand.navigate(
        'Sukhbaatar Square',
        travelMode: MapsTravelMode.bicycling,
        avoid: [MapsAvoid.ferries],
      ),
    );
  });

  test('recognizes search commands', () {
    expect(
      parser.parse('search coffee near me'),
      const MapsCommand.search('Coffee Near Me'),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/assistant/bloc/assistant_cubit.dart';
import 'package:minimax/features/assistant/data/assistant_repository.dart';
import 'package:minimax/features/assistant/domain/maps_command.dart';
import 'package:minimax/shared/services/maps_launcher_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('suggestion chip action dispatches a maps command', () async {
    Uri? launchedUri;
    final maps = MapsLauncherService(
      launch: (uri, mode) async {
        launchedUri = uri;
        expect(mode, LaunchMode.externalApplication);
        return true;
      },
    );
    final cubit = AssistantCubit(
      repository: const MockAssistantRepository(),
      mapsLauncher: maps,
    );

    await cubit.runSuggestion(AssistantSuggestion.coffeeNearMe);

    expect(cubit.state.status, AssistantStatus.idle);
    expect(cubit.state.lastCommand, const MapsCommand.search('Coffee Near Me'));
    expect(launchedUri?.scheme, 'geo');
    await cubit.close();
  });

  test('directions preview sends Google Maps route parameters', () async {
    Uri? launchedUri;
    final maps = MapsLauncherService(
      launch: (uri, _) async {
        launchedUri = uri;
        return true;
      },
    );

    await maps.launch(
      const MapsCommand.directions(
        'Sukhbaatar Square',
        travelMode: MapsTravelMode.walking,
        avoid: [MapsAvoid.tolls, MapsAvoid.highways],
        waypoints: ['Chinggis Khaan National Museum'],
      ),
    );

    expect(launchedUri?.scheme, 'https');
    expect(launchedUri?.path, '/maps/dir/');
    expect(launchedUri?.queryParameters['travelmode'], 'walking');
    expect(launchedUri?.queryParameters['avoid'], 'tolls,highways');
    expect(
      launchedUri?.queryParameters['waypoints'],
      'Chinggis Khaan National Museum',
    );
  });

  test('navigation command tries Android navigation intent first', () async {
    Uri? launchedUri;
    final maps = MapsLauncherService(
      launch: (uri, _) async {
        launchedUri = uri;
        return true;
      },
    );

    await maps.launch(
      const MapsCommand.navigate(
        'Sukhbaatar Square',
        travelMode: MapsTravelMode.bicycling,
        avoid: [MapsAvoid.tolls, MapsAvoid.ferries],
      ),
    );

    expect(launchedUri?.scheme, 'google.navigation');
    expect(launchedUri.toString(), contains('mode=b'));
    expect(launchedUri.toString(), contains('avoid=tf'));
  });
}

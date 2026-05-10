import 'package:url_launcher/url_launcher.dart';

import '../../features/assistant/domain/assistant_follow_up_action.dart';
import 'maps_launcher_service.dart';

typedef FollowUpUrlLaunch = Future<bool> Function(Uri uri, LaunchMode mode);

Future<bool> _defaultFollowUpLaunch(Uri uri, LaunchMode mode) {
  return launchUrl(uri, mode: mode);
}

/// Tries several [LaunchMode]s — OEM dialers / sms handlers often reject one mode.
Future<bool> _launchOpenUriBestEffort(
  FollowUpUrlLaunch launch,
  Uri uri,
) async {
  const modes = <LaunchMode>[
    LaunchMode.externalApplication,
    LaunchMode.platformDefault,
    LaunchMode.externalNonBrowserApplication,
  ];
  for (final mode in modes) {
    try {
      final ok = await launch(uri, mode);
      if (ok) return true;
    } catch (_) {}
  }
  return false;
}

/// Runs [AssistantFollowUp] steps after assistant audio (Maps, tel/sms/mail/https).
class AssistantFollowUpLauncher {
  AssistantFollowUpLauncher({
    required MapsLauncherService mapsLauncher,
    FollowUpUrlLaunch? launch,
  }) : _mapsLauncher = mapsLauncher,
       _launch = launch ?? _defaultFollowUpLaunch;

  final MapsLauncherService _mapsLauncher;
  final FollowUpUrlLaunch _launch;

  Future<void> runAll(List<AssistantFollowUp> actions) async {
    for (final action in actions) {
      if (action is AssistantFollowUpMaps) {
        await _mapsLauncher.launch(action.command);
      } else if (action is AssistantFollowUpOpenUri) {
        final ok = await _launchOpenUriBestEffort(_launch, action.uri);
        if (!ok) {
          throw StateError('Could not open: ${action.uri}');
        }
      }
    }
  }
}

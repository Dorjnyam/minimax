import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/assistant/domain/assistant_follow_up_action.dart';
import 'package:minimax/features/assistant/domain/assistant_follow_up_parser.dart';
import 'package:minimax/shared/services/assistant_follow_up_launcher.dart';
import 'package:minimax/shared/services/maps_launcher_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('AssistantFollowUpLauncher opens tel uri', () async {
    final launched = <Uri>[];
    final launcher = AssistantFollowUpLauncher(
      mapsLauncher: const MapsLauncherService(),
      launch: (uri, mode) async {
        launched.add(uri);
        expect(mode, LaunchMode.externalApplication);
        return true;
      },
    );

    await launcher.runAll([
      AssistantFollowUpOpenUri(
        uri: Uri.parse('tel:+97699112233'),
        confirmationMessage: 'Calling.',
      ),
    ]);

    expect(launched.single.toString(), 'tel:+97699112233');
  });

  test('parseAssistantFollowUps opens sms for contact / message', () {
    final ups = parseAssistantFollowUps({
      'actions': [
        {
          'type': 'contact',
          'event': 'message',
          'data': {
            'contact': {
              'phone': '99112233',
              'name': 'Батаа',
              'body': 'Сайн уу',
            },
          },
        },
      ],
    });

    expect(ups, hasLength(1));
    final first = ups.single;
    expect(first, isA<AssistantFollowUpOpenUri>());
    final open = first as AssistantFollowUpOpenUri;
    expect(open.uri.scheme, 'sms');
    expect(open.uri.toString(), contains('+97699112233'));
    expect(open.uri.toString(), contains('body='));
  });

  test('parseAssistantFollowUps sms supports contact_message event', () {
    final ups = parseAssistantFollowUps({
      'type': 'contact',
      'event': 'contact_message',
      'data': {
        'contact': {'phone': '+97688112233'},
      },
    });

    expect(ups, hasLength(1));
    final open = ups.single as AssistantFollowUpOpenUri;
    expect(open.uri.scheme, 'sms');
    expect(open.uri.toString(), 'sms:+97688112233');
  });
}

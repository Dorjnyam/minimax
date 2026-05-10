import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/auth/domain/google_integration_models.dart';

void main() {
  test('parseGoogleConnectUrl reads nested url keys', () {
    expect(
      parseGoogleConnectUrl({
        'data': {'authorization_url': 'https://accounts.google.com/o/oauth2'},
      }),
      'https://accounts.google.com/o/oauth2',
    );
    expect(
      parseGoogleConnectUrl({'url': 'https://example.com/connect'}),
      'https://example.com/connect',
    );
    expect(parseGoogleConnectUrl({'foo': 'bar'}), isNull);
  });

  test('GoogleIntegrationStatus.fromData parses connected and email', () {
    final s = GoogleIntegrationStatus.fromData({
      'connected': true,
      'email': 'u@gmail.com',
    });
    expect(s.connected, isTrue);
    expect(s.email, 'u@gmail.com');

    final nested = GoogleIntegrationStatus.fromData({
      'data': {'is_connected': true, 'google_email': 'x@gmail.com'},
    });
    expect(nested.connected, isTrue);
    expect(nested.email, 'x@gmail.com');
  });
}

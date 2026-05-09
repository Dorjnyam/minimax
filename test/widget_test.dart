import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:minimax/app/baigalaa_app.dart';
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/assistant/bloc/assistant_cubit.dart';
import 'package:minimax/features/assistant/data/assistant_repository.dart';
import 'package:minimax/features/assistant/presentation/assistant_page.dart';
import 'package:minimax/features/profile/presentation/baigalaa_profile_page.dart';
import 'package:minimax/features/assistant/services/assistant_audio_recorder.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';
import 'package:minimax/features/auth/data/auth_storage.dart';
import 'package:minimax/features/auth/data/session_refresh_service.dart';
import 'package:minimax/shared/services/maps_launcher_service.dart';
import 'package:minimax/shared/constants/baigalaa_constants.dart';

void main() {
  testWidgets('First launch opens login screen immediately', (tester) async {
    await tester.pumpWidget(BaigalaaApp(authStorage: MemoryAuthStorage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Тавтай морилно уу', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Бүртгэл байхгүй юу? Бүртгүүлэх', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('И-МЭЙЛ', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Saved session opens assistant shell with PageView', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      BaigalaaApp(
        authRepository: _profileRepository(),
        authStorage: MemoryAuthStorage({
          apiBaseUrlStorageKey: 'http://api.test',
          apiAccessTokenStorageKey: 'a1',
        }),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Turn off the light'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('Assistant page displays recognized speech text', (tester) async {
    final cubit = AssistantCubit(
      repository: const MockAssistantRepository(),
      mapsLauncher: MapsLauncherService(launch: (_, _) async => true),
      accessTokenProvider: const FixedAccessTokenProvider('t'),
    );
    await cubit.submitText('hello baigalaa');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const AssistantPage(),
        ),
      ),
    );

    expect(find.text('You said'), findsOneWidget);
    expect(find.text('hello baigalaa'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Assistant page displays saved m4a path', (tester) async {
    final cubit = AssistantCubit(
      repository: const MockAssistantRepository(),
      mapsLauncher: MapsLauncherService(launch: (_, _) async => true),
      accessTokenProvider: const FixedAccessTokenProvider('t'),
      audioRecorder: _FakeAudioRecorder(),
    );
    await cubit.submitText('hello baigalaa');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const AssistantPage(),
        ),
      ),
    );

    expect(find.textContaining('Saved m4a'), findsOneWidget);
    expect(find.textContaining('.m4a'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Assistant message preview opens chat history sheet', (
    tester,
  ) async {
    final cubit = AssistantCubit(
      repository: const MockAssistantRepository(),
      mapsLauncher: MapsLauncherService(launch: (_, _) async => true),
      accessTokenProvider: const FixedAccessTokenProvider('t'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const AssistantPage(),
        ),
      ),
    );

    expect(find.text('Messages'), findsOneWidget);
    await tester.tap(find.text('Messages'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No messages yet'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Baigalaa profile hub shows sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BaigalaaProfilePage()),
    );
    expect(find.text('Profile & settings'), findsOneWidget);
    expect(find.text('GROUPS & FRIENDS'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
  });
}

AuthRepository _profileRepository() {
  return AuthRepository(
    client: HackathonApiClient(
      send: (method, uri, headers, body) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'email': 'themargad@gmail.com',
              'full_name': 'User',
              'phone': '80197747',
            }),
          ),
          200,
        );
      },
    ),
  );
}

class _FakeAudioRecorder implements AssistantAudioRecorder {
  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> start() async => 'C:\\recordings\\test.m4a';

  @override
  Future<bool> waitForSilence({
    Duration minDuration = const Duration(milliseconds: 1200),
    Duration silenceDuration = const Duration(milliseconds: 1500),
    Duration maxDuration = const Duration(seconds: 12),
    double voiceThresholdDb = -45,
  }) async {
    return true;
  }

  @override
  Future<String?> stop() async => 'C:\\recordings\\test.m4a';
}

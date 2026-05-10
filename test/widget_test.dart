import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:minimax/app/baigalaa_app.dart';
import 'package:minimax/app/shell_navigation_scope.dart';
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/assistant/bloc/assistant_cubit.dart';
import 'package:minimax/features/assistant/data/assistant_repository.dart';
import 'package:minimax/features/assistant/presentation/assistant_page.dart';
import 'package:minimax/features/profile/presentation/baigalaa_profile_page.dart';
import 'package:minimax/features/auth/bloc/auth_cubit.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';
import 'package:minimax/features/auth/data/auth_storage.dart';
import 'package:minimax/features/auth/domain/auth_models.dart';
import 'package:minimax/features/auth/gate/auth_gate_cubit.dart';
import 'package:minimax/features/auth/data/session_refresh_service.dart';
import 'package:minimax/shared/services/maps_launcher_service.dart';
import 'package:minimax/shared/constants/baigalaa_constants.dart';

void main() {
  testWidgets('First launch opens login screen immediately', (tester) async {
    await tester.pumpWidget(BaigalaaApp(authStorage: MemoryAuthStorage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Нэвтрэх', skipOffstage: false), findsWidgets);
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
        home: ShellNavigationScope(
          goToPage: (_) {},
          child: BlocProvider.value(
            value: cubit,
            child: const AssistantPage(),
          ),
        ),
      ),
    );

    expect(find.text('You said'), findsOneWidget);
    expect(find.text('hello baigalaa'), findsOneWidget);
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
        home: ShellNavigationScope(
          goToPage: (_) {},
          child: BlocProvider.value(
            value: cubit,
            child: const AssistantPage(),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Messages'), findsOneWidget);
    await tester.tap(find.byTooltip('Messages'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No messages yet'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Baigalaa profile hub shows sections', (tester) async {
    final repo = AuthRepository(
      client: HackathonApiClient(
        send: (method, uri, headers, body) async {
          if (uri.path.contains('/integrations/google/status')) {
            return http.Response(
              jsonEncode({'connected': false}),
              200,
            );
          }
          return http.Response('{}', 200);
        },
      ),
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: repo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>(
              create: (context) {
                final cubit = AuthCubit(repository: context.read<AuthRepository>());
                cubit.emit(
                  cubit.state.copyWith(
                    baseUrl: 'http://api.test',
                    session: const AuthSession(
                      accessToken: 'token',
                      refreshToken: '',
                    ),
                    user: const AuthUser(
                      email: 'u@test.com',
                      fullName: 'Test User',
                      phone: '123',
                    ),
                  ),
                );
                return cubit;
              },
            ),
            BlocProvider<AuthGateCubit>(
              create: (context) => AuthGateCubit(
                repository: context.read<AuthRepository>(),
                storage: MemoryAuthStorage(),
              ),
            ),
          ],
          child: MaterialApp(
            home: const BaigalaaProfilePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Profile'), findsOneWidget);
    expect(find.textContaining('Хуваарьт'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('GOOGLE'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('GOOGLE'), findsOneWidget);
    expect(find.text('POLICY & PRIVACY'), findsOneWidget);
    expect(find.text('Link Google account'), findsOneWidget);
    expect(
      find.byIcon(Icons.logout_rounded, skipOffstage: false),
      findsOneWidget,
    );
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

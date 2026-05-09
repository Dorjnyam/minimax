import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/auth/bloc/auth_cubit.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';
import 'package:minimax/features/auth/data/auth_storage.dart';
import 'package:minimax/features/auth/presentation/auth_page.dart';

void main() {
  testWidgets('OTP verify success shows profile and enter app action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var entered = false;
    final repository = AuthRepository(
      client: HackathonApiClient(
        send: (method, uri, headers, body) async {
          if (uri.path.endsWith('/otp/verify')) {
            return _json({'access': 'a1', 'refresh': 'r1'});
          }
          return _json({
            'email': 'themargad@gmail.com',
            'full_name': 'User',
            'phone': '80197747',
          });
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              AuthCubit(repository: repository, storage: MemoryAuthStorage()),
          child: AuthPage(onEnterApp: () => entered = true),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'themargad@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), '111111');
    await tester.tap(find.text('НЭВТРЭХ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Профайл бэлэн'), findsOneWidget);
    expect(find.text('themargad@gmail.com'), findsOneWidget);
    expect(find.text('АПП НЭЭХ'), findsOneWidget);

    await tester.ensureVisible(find.text('АПП НЭЭХ'));
    await tester.tap(find.text('АПП НЭЭХ'));
    expect(entered, isTrue);
  });
}

http.Response _json(Map<String, Object?> data) {
  return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
}

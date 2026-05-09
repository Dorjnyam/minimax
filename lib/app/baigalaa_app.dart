import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_storage.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/assistant/data/assistant_repository.dart';
import '../features/chat/data/chat_audio_playback_service.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/chat/data/chat_voice_socket_service.dart';
import '../features/transit/data/google_routes_transit_repository.dart';
import '../features/transit/data/transit_repository.dart';
import '../shared/services/maps_launcher_service.dart';
import '../shared/widgets/fixed_text_scale.dart';

class BaigalaaApp extends StatelessWidget {
  const BaigalaaApp({
    super.key,
    this.authRepository,
    this.authStorage,
  });

  final AuthRepository? authRepository;
  final AuthStorage? authStorage;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AssistantRepository>(
          create: (_) => const MockAssistantRepository(),
        ),
        RepositoryProvider<MapsLauncherService>(
          create: (_) => const MapsLauncherService(),
        ),
        RepositoryProvider<TransitRepository>(
          create: (_) => const GoogleRoutesTransitRepository(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (_) => authRepository ?? const AuthRepository(),
        ),
        RepositoryProvider<AuthStorage>(
          create: (_) => authStorage ?? const SecureAuthStorage(),
        ),
        RepositoryProvider<ChatRepository>(
          create: (_) => const ChatRepository(),
        ),
        RepositoryProvider<ChatVoiceSocketService>(
          create: (_) => const ChatVoiceSocketService(),
        ),
        RepositoryProvider<ChatAudioPlaybackService>(
          create: (_) => ChatAudioPlaybackService(),
        ),
      ],
      child: MaterialApp(
        title: 'Baigalaa',
        debugShowCheckedModeBanner: false,
        builder: FixedTextScale.builder,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007C89),
            primary: const Color(0xFF007C89),
            secondary: const Color(0xFF4E6E5D),
            surface: const Color(0xFFF7F9FB),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F9FB),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              side: BorderSide(color: Color(0xFFE0E7EB)),
            ),
          ),
        ),
        home: AuthGate(storage: authStorage ?? const SecureAuthStorage()),
      ),
    );
  }
}

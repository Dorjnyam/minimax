import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../features/auth/data/auth_storage.dart';
import '../features/auth/data/session_refresh_service.dart';
import '../features/assistant/bloc/assistant_cubit.dart';
import '../features/assistant/data/assistant_repository.dart';
import '../features/assistant/presentation/assistant_page.dart';
import '../features/chat/data/chat_audio_playback_service.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/chat/data/chat_voice_socket_service.dart';
import '../features/labs/presentation/labs_page.dart';
import '../features/setup/presentation/baigalaa_setup_page.dart';
import '../features/transit/bloc/transit_cubit.dart';
import '../features/transit/data/transit_repository.dart';
import '../features/transit/presentation/transit_page.dart';
import '../shared/services/maps_launcher_service.dart';
import '../shared/theme/baigalaa_mesh_background.dart';

class BaigalaaShell extends StatelessWidget {
  const BaigalaaShell({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: BaigalaaMeshBackground(
        child: PageView(
          children: [
            BlocProvider(
              create: (context) => AssistantCubit(
                repository: context.read<AssistantRepository>(),
                mapsLauncher: context.read<MapsLauncherService>(),
                authStorage: context.read<AuthStorage>(),
                accessTokenProvider: context.read<SessionRefreshService>(),
                chatRepository: context.read<ChatRepository>(),
                chatVoiceSocket: context.read<ChatVoiceSocketService>(),
                chatAudioPlayback: context.read<ChatAudioPlaybackService>(),
              ),
              child: const AssistantPage(),
            ),
            const Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _SetupAppBar(),
              body: BaigalaaSetupPage(),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: const _LabsAppBar(),
              body: LabsPage(mapsLauncher: context.read<MapsLauncherService>()),
            ),
            BlocProvider(
              create: (context) =>
                  TransitCubit(repository: context.read<TransitRepository>()),
              child: const Scaffold(
                backgroundColor: Colors.transparent,
                appBar: _TransitAppBar(),
                body: TransitPage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SetupAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Baigalaa Setup'), centerTitle: false);
  }
}

class _LabsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LabsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Baigalaa Labs'), centerTitle: false);
  }
}

class _TransitAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TransitAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Bus Options'), centerTitle: false);
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../features/assistant/bloc/assistant_cubit.dart';
import '../features/assistant/data/assistant_repository.dart';
import '../features/assistant/presentation/assistant_page.dart';
import '../features/assistant/services/assistant_chat_service.dart';
import '../features/auth/data/auth_storage.dart';
import '../features/auth/data/session_refresh_service.dart';
import '../features/chat/data/chat_audio_playback_service.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/chat/data/chat_voice_socket_service.dart';
import '../features/profile/presentation/baigalaa_profile_page.dart';
import '../features/reminders/data/reminder_pause_storage.dart';
import '../features/reminders/data/reminders_repository.dart';
import '../features/reminders/presentation/cubit/reminders_cubit.dart';
import '../features/reminders/presentation/reminders_page.dart';
import '../features/reminders/services/reminder_notification_service.dart';
import '../shared/services/assistant_follow_up_launcher.dart';
import '../shared/services/maps_launcher_service.dart';
import 'shell_navigation_scope.dart';

class BaigalaaShell extends StatefulWidget {
  const BaigalaaShell({super.key});

  @override
  State<BaigalaaShell> createState() => _BaigalaaShellState();
}

class _BaigalaaShellState extends State<BaigalaaShell> {
  late final PageController _pageController;
  bool _scheduledReminderBootstrap = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _scheduleReminderBootstrap(BuildContext context) {
    if (_scheduledReminderBootstrap) return;
    _scheduledReminderBootstrap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cubit = context.read<RemindersCubit>();
      if (!kIsWeb) {
        final svc = context.read<ReminderNotificationService>();
        await svc.ensureInitialized(onTapPayload: cubit.playAlertFor);
      }
      await cubit.bootstrap();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AssistantCubit(
            repository: context.read<AssistantRepository>(),
            mapsLauncher: context.read<MapsLauncherService>(),
            followUpLauncher: context.read<AssistantFollowUpLauncher>(),
            authStorage: context.read<AuthStorage>(),
            accessTokenProvider: context.read<SessionRefreshService>(),
            chatRepository: context.read<ChatRepository>(),
            chatVoiceSocket: context.read<ChatVoiceSocketService>(),
            chatAudioPlayback: context.read<ChatAudioPlaybackService>(),
            chatService: context.read<AssistantChatService>(),
          ),
        ),
        BlocProvider(
          create: (context) => RemindersCubit(
            repository: context.read<RemindersRepository>(),
            pauseStorage: context.read<ReminderPauseStorage>(),
            notificationService: context.read<ReminderNotificationService>(),
            chatService: context.read<AssistantChatService>(),
            audioPlayback: context.read<ChatAudioPlaybackService>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          _scheduleReminderBootstrap(context);
          return WithForegroundTask(
            child: ShellNavigationScope(
              goToPage: (i) => _pageController.jumpToPage(i),
              child: PageView(
                controller: _pageController,
                children: const [
                  AssistantPage(),
                  BaigalaaProfilePage(),
                  RemindersPage(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../assistant/services/assistant_chat_service.dart';
import '../../../chat/data/chat_audio_playback_service.dart';
import '../../data/reminder_pause_storage.dart';
import '../../data/reminders_repository.dart';
import '../../domain/reminder.dart';
import '../../services/reminder_notification_service.dart';
import '../reminders_strings.dart';
import 'reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required RemindersRepository repository,
    required ReminderPauseStorage pauseStorage,
    required ReminderNotificationService notificationService,
    required AssistantChatService chatService,
    required ChatAudioPlaybackService audioPlayback,
  }) : _repository = repository,
       _pauseStorage = pauseStorage,
       _notifications = notificationService,
       _chat = chatService,
       _audio = audioPlayback,
       super(const RemindersState());

  final RemindersRepository _repository;
  final ReminderPauseStorage _pauseStorage;
  final ReminderNotificationService _notifications;
  final AssistantChatService _chat;
  final ChatAudioPlaybackService _audio;

  Future<void> initializePausedIds() async {
    final ids = await _pauseStorage.loadPausedIds();
    emit(state.copyWith(pausedIds: ids));
  }

  Future<void> bootstrap() async {
    await initializePausedIds();
    await load();
  }

  Future<void> load({String? filterStatus}) async {
    final status = filterStatus ?? state.filterStatus;
    emit(
      state.copyWith(
        loading: true,
        filterStatus: status,
        clearError: true,
      ),
    );
    try {
      final list = await _repository.listReminders(status: status);
      emit(state.copyWith(reminders: list, loading: false));
      if (status == 'open') {
        await _notifications.rescheduleAll(
          reminders: list,
          pausedIds: state.pausedIds,
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: '${RemindersStrings.loadError} ($e)',
        ),
      );
    }
  }

  Future<void> setFilter(String status) async {
    await load(filterStatus: status);
  }

  Future<void> toggleLocalPause(Reminder r) async {
    final id = r.id;
    final wasPaused = state.pausedIds.contains(id);
    late final String socketContent;
    if (wasPaused) {
      await _pauseStorage.resume(id);
      emit(
        state.copyWith(pausedIds: Set<String>.from(state.pausedIds)..remove(id)),
      );
      socketContent = RemindersStrings.resumeSocketMessage(id);
    } else {
      await _pauseStorage.pause(id);
      emit(
        state.copyWith(pausedIds: Set<String>.from(state.pausedIds)..add(id)),
      );
      await _notifications.cancelReminder(id);
      socketContent = RemindersStrings.pauseSocketMessage(id);
    }
    try {
      final ctx = await _chat.prepare('');
      await _chat.sendUserText(context: ctx, content: socketContent);
    } catch (_) {}

    if (state.filterStatus == 'open') {
      await _notifications.rescheduleAll(
        reminders: state.reminders,
        pausedIds: state.pausedIds,
      );
    }
  }

  /// Natural-language task line from the reminders composer (same socket as assistant typing).
  Future<void> sendQuickTaskMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;
    emit(state.copyWith(creating: true, clearError: true));
    try {
      final ctx = await _chat.prepare('');
      final content = RemindersStrings.wrapQuickTask(text);
      await _chat.sendUserText(context: ctx, content: content);
      await load();
    } catch (e) {
      emit(
        state.copyWith(
          creating: false,
          errorMessage: '${RemindersStrings.sendError} ($e)',
        ),
      );
      return;
    }
    emit(state.copyWith(creating: false));
  }

  Future<void> createFromText({
    required String title,
    required String notes,
    String scheduleHint = '',
  }) async {
    if (title.trim().isEmpty) return;
    emit(state.copyWith(creating: true, clearError: true));
    try {
      final ctx = await _chat.prepare('');
      final prompt = RemindersStrings.buildCreationPrompt(
        title: title,
        notes: notes,
        scheduleHint: scheduleHint,
      );
      await _chat.sendUserText(context: ctx, content: prompt);
      await load();
    } catch (e) {
      emit(
        state.copyWith(
          creating: false,
          errorMessage: '${RemindersStrings.sendError} ($e)',
        ),
      );
      return;
    }
    emit(state.copyWith(creating: false));
  }

  /// When user taps a scheduled notification (payload = reminder id).
  Future<void> playAlertFor(String reminderId) async {
    Reminder? match;
    for (final r in state.reminders) {
      if (r.id == reminderId) {
        match = r;
        break;
      }
    }
    match ??= await _fetchOne(reminderId);

    if (match == null) return;

    try {
      final ctx = await _chat.prepare('');
      await _audio.downloadTtsAndPlay(
        baseUrl: ctx.baseUrl,
        token: ctx.token,
        text: match.alertText,
      );
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: RemindersStrings.ttsError,
        ),
      );
    }
  }

  Future<Reminder?> _fetchOne(String id) async {
    try {
      await load(filterStatus: 'open');
      for (final r in state.reminders) {
        if (r.id == id) return r;
      }
      await load(filterStatus: 'closed');
      for (final r in state.reminders) {
        if (r.id == id) return r;
      }
    } catch (_) {}
    return null;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/shell_navigation_scope.dart';
import '../../../shared/theme/baigalaa_assistant_shell.dart';
import '../domain/reminder.dart';
import 'cubit/reminders_cubit.dart';
import 'cubit/reminders_state.dart';
import 'reminders_strings.dart';
import 'widgets/reminder_create_sheet.dart';

/// Tasks / reminders — assistant shell + automation-style rows (icon • title • subtitle • switch).
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: BaigalaaAssistantShell.boxDecoration,
          child: Material(
            color: Colors.transparent,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Буцах',
                            onPressed: () =>
                                ShellNavigationScope.of(context).goToPage(0),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  RemindersStrings.pageTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  RemindersStrings.subtitle,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.62),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: RemindersStrings.createTitle,
                            onPressed: state.creating
                                ? null
                                : () async {
                                    await showModalBottomSheet<void>(
                                      context: context,
                                      useSafeArea: true,
                                      isScrollControlled: true,
                                      backgroundColor: const Color(0xFF1A2438),
                                      builder: (ctx) => ReminderCreateSheet(
                                        loading: state.creating,
                                        onSubmit:
                                            (title, notes, schedule) async {
                                          await context
                                              .read<RemindersCubit>()
                                              .createFromText(
                                                title: title,
                                                notes: notes,
                                                scheduleHint: schedule,
                                              );
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                      ),
                                    );
                                  },
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            tooltip: RemindersStrings.goAssistantVoice,
                            onPressed: () =>
                                ShellNavigationScope.of(context).goToPage(0),
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'open',
                            label: Text(RemindersStrings.tabOpen),
                          ),
                          ButtonSegment(
                            value: 'closed',
                            label: Text(RemindersStrings.tabClosed),
                          ),
                        ],
                        selected: {state.filterStatus},
                        onSelectionChanged: (s) {
                          context.read<RemindersCubit>().setFilter(s.first);
                        },
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: BaigalaaAssistantShell.errorText,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: state.loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: BaigalaaAssistantShell.progressIndicator,
                              ),
                            )
                          : _ReminderList(state: state),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                      child: Text(
                        RemindersStrings.pausedExplain,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.42),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: state.creating
                    ? null
                    : () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          useSafeArea: true,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF1A2438),
                          builder: (ctx) => ReminderCreateSheet(
                            loading: state.creating,
                            onSubmit: (title, notes, schedule) async {
                              await context.read<RemindersCubit>().createFromText(
                                    title: title,
                                    notes: notes,
                                    scheduleHint: schedule,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                backgroundColor: const Color(0xFF007C89),
                foregroundColor: Colors.white,
                icon: state.creating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  RemindersStrings.createTitle,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.state});

  final RemindersState state;

  @override
  Widget build(BuildContext context) {
    if (state.reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.filterStatus == 'open'
                ? RemindersStrings.emptyOpen
                : RemindersStrings.emptyClosed,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 96),
      itemCount: state.reminders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = state.reminders[i];
        final paused = state.isLocallyPaused(r.id);
        return _TaskAutomationRow(
          index: i,
          reminder: r,
          locallyPaused: paused,
        );
      },
    );
  }
}

/// Reference-style row: colored glyph tile, title + schedule line, trailing switch.
class _TaskAutomationRow extends StatelessWidget {
  const _TaskAutomationRow({
    required this.index,
    required this.reminder,
    required this.locallyPaused,
  });

  final int index;
  final Reminder reminder;
  final bool locallyPaused;

  static const List<IconData> _glyphs = [
    Icons.schedule_rounded,
    Icons.notifications_active_rounded,
    Icons.repeat_rounded,
    Icons.mail_outline_rounded,
    Icons.wb_sunny_outlined,
  ];

  /// Baigalaa palette (teal / purple / rose / mist accents — distinct from the cyan demo image).
  static const List<Color> _glyphBg = [
    Color(0xFF007C89),
    Color(0xFF5855B0),
    Color(0xFFE491C9),
    Color(0xFF4E6E5D),
    Color(0xFF6B8CAE),
  ];

  String get _title =>
      reminder.title.isNotEmpty ? reminder.title : reminder.notes;

  String _subtitleLine() {
    final time = reminder.scheduleTime?.trim();
    final rec = reminder.recurrence.trim();
    final recCaps = rec.isEmpty ? '' : rec.toUpperCase();
    if (time != null && time.isNotEmpty && recCaps.isNotEmpty) {
      return '$time • $recCaps';
    }
    if (time != null && time.isNotEmpty) return time;
    if (recCaps.isNotEmpty) return recCaps;
    if (reminder.nextRunAt != null) {
      final d = reminder.nextRunAt!.toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    return '—';
  }

  bool get _canToggle =>
      reminder.status == 'open' && !reminder.completed;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final bg = _glyphBg[index % _glyphBg.length];
    final icon = _glyphs[index % _glyphs.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: bg.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BaigalaaAssistantShell.accentText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _subtitleLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reminder.notes.isNotEmpty &&
                    reminder.title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_canToggle)
            Switch.adaptive(
              value: !locallyPaused,
              activeThumbColor: const Color(0xFF54C7FF),
              activeTrackColor:
                  const Color(0xFF007C89).withValues(alpha: 0.55),
              onChanged: (_) =>
                  unawaited(cubit.toggleLocalPause(reminder)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white.withValues(alpha: 0.35),
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}

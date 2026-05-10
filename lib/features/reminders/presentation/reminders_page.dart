import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/shell_navigation_scope.dart';
import '../../profile/presentation/baigalaa_profile_page.dart';
import '../domain/reminder.dart';
import 'cubit/reminders_cubit.dart';
import 'cubit/reminders_state.dart';
import 'reminders_strings.dart';
import 'widgets/reminder_create_sheet.dart';

/// Tasks / reminders list (Mongolian UI).
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: BaigalaaProfilePage.shellGradient,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Буцах',
                          onPressed: () =>
                              ShellNavigationScope.of(context).goToPage(0),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                RemindersStrings.pageTitle,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                RemindersStrings.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: RemindersStrings.goAssistantVoice,
                          onPressed: () =>
                              ShellNavigationScope.of(context).goToPage(0),
                          icon: const Icon(
                            Icons.mic_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
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
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Color(0xFFFFB8B8)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: state.loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5855B0),
                            ),
                          )
                        : _ReminderList(state: state),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Text(
                      RemindersStrings.pausedExplain,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
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
                        backgroundColor: const Color(0xFF10182B),
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
              backgroundColor: const Color(0xFF5855B0),
              icon: state.creating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                RemindersStrings.createTitle,
                style: const TextStyle(color: Colors.white),
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
        child: Text(
          state.filterStatus == 'open'
              ? RemindersStrings.emptyOpen
              : RemindersStrings.emptyClosed,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 15,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 88),
      itemCount: state.reminders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = state.reminders[i];
        final paused = state.isLocallyPaused(r.id);
        return _ReminderCard(reminder: r, locallyPaused: paused);
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.locallyPaused});

  final Reminder reminder;
  final bool locallyPaused;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final scheduleLine = reminder.scheduleTime ?? '—';
    final recurrence = reminder.recurrence.isEmpty ? '—' : reminder.recurrence;
    final next = reminder.nextRunAt != null
        ? '${reminder.nextRunAt!.toLocal()}'
        : '—';

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      reminder.title.isEmpty ? reminder.notes : reminder.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (reminder.status == 'open')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locallyPaused
                              ? RemindersStrings.pausedChip
                              : RemindersStrings.activeChip,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                        Switch.adaptive(
                          value: locallyPaused,
                          activeThumbColor: Colors.orangeAccent,
                          onChanged: (_) =>
                              unawaited(cubit.toggleLocalPause(reminder)),
                        ),
                      ],
                    ),
                ],
              ),
              if (reminder.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reminder.notes,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetaChip(icon: Icons.schedule, label: scheduleLine),
                  _MetaChip(icon: Icons.repeat, label: recurrence),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${RemindersStrings.nextRun}: $next',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

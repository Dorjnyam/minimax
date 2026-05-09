import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/assistant_cubit.dart';
import 'widgets/assistant_chips.dart';
import 'widgets/assistant_controls.dart';
import 'widgets/assistant_orb.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantCubit, AssistantState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14233D), Color(0xFF5855B0), Color(0xFF191C32)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AssistantStatusBar(),
                    const SizedBox(height: 18),
                    AssistantChips(
                      onSelected: (suggestion) => unawaited(
                        context.read<AssistantCubit>().runSuggestion(
                          suggestion,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Hi, Baigalaa',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.68),
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isListening ? 'LISTENING' : 'SAY SOMETHING',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    Center(child: AssistantOrb(active: state.isListening)),
                    const Spacer(),
                    _AssistantTranscriptPanel(state: state),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFFB8B8),
                        ),
                      ),
                    ],
                    const Spacer(),
                    AssistantMicControls(
                      isListening: state.isListening,
                      onMicPressed: () =>
                          unawaited(context.read<AssistantCubit>().listen()),
                      onClosePressed: () => unawaited(
                        context.read<AssistantCubit>().submitText(''),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AssistantTranscriptPanel extends StatelessWidget {
  const _AssistantTranscriptPanel({required this.state});

  final AssistantState state;

  @override
  Widget build(BuildContext context) {
    final hasTranscript = state.transcript.trim().isNotEmpty;
    return Column(
      children: [
        if (hasTranscript) ...[
          Text(
            'You said',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.56),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.transcript,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFEDEBFF),
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          state.response,
          textAlign: TextAlign.center,
          maxLines: hasTranscript ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: hasTranscript
                ? Colors.white.withValues(alpha: 0.68)
                : const Color(0xFFEDEBFF),
            height: 1.5,
            letterSpacing: 0,
          ),
        ),
        if (state.recordingPath.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Saved m4a: ${_compactPath(state.recordingPath)}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }

  String _compactPath(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
  }
}

class _AssistantStatusBar extends StatelessWidget {
  const _AssistantStatusBar();

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return Row(
      children: [
        Text(
          '$hour:$minute',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 17),
        const SizedBox(width: 4),
        Icon(Icons.wifi, color: Colors.white, size: 17),
        const SizedBox(width: 4),
        Icon(Icons.battery_full, color: Colors.white, size: 20),
      ],
    );
  }
}

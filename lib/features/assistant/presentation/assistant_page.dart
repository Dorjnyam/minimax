import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/assistant_cubit.dart';
import 'widgets/assistant_chips.dart';
import 'widgets/assistant_controls.dart';
import 'widgets/assistant_messages.dart';
import 'widgets/assistant_orb.dart';

double _orbSize(BuildContext context) {
  final h = MediaQuery.sizeOf(context).height;
  if (h < 620) return 130;
  if (h < 700) return 150;
  return 230;
}

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantCubit, AssistantState>(
      builder: (context, state) {
        return Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Center(
                            child: _InteractiveOrb(
                              active: state.isListening,
                              size: _orbSize(context),
                              onTap: () => unawaited(
                                context.read<AssistantCubit>().listen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AssistantChips(
                                onSelected: (suggestion) => unawaited(
                                  context.read<AssistantCubit>().runSuggestion(
                                    suggestion,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _AssistantTranscriptPanel(state: state),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  child: AssistantMicControls(
                    isListening: state.isListening,
                    onMicPressed: () =>
                        unawaited(context.read<AssistantCubit>().listen()),
                    onClosePressed: () => unawaited(
                      context.read<AssistantCubit>().submitText(''),
                    ),
                    onMessagesPressed: () =>
                        unawaited(showAssistantMessagesSheet(context)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tap target with ripple; starts listening like the main mic control.
class _InteractiveOrb extends StatelessWidget {
  const _InteractiveOrb({
    required this.active,
    required this.size,
    required this.onTap,
  });

  final bool active;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Colors.white.withValues(alpha: 0.14),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: AssistantOrb(active: active, size: size),
      ),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../chat/domain/chat_models.dart';
import '../../bloc/assistant_cubit.dart';

class AssistantMessagePreview extends StatelessWidget {
  const AssistantMessagePreview({super.key, required this.state});

  final AssistantState state;

  @override
  Widget build(BuildContext context) {
    final latest = state.messages.isEmpty ? null : state.messages.last;
    final label = latest == null
        ? 'Messages'
        : latest.isUser
        ? 'You'
        : 'Baigalaa';
    final text = latest?.content ?? 'Tap to view your conversation history';
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        unawaited(context.read<AssistantCubit>().loadMessages());
        showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF10182B),
          builder: (_) => BlocProvider.value(
            value: context.read<AssistantCubit>(),
            child: const AssistantMessagesSheet(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.forum_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_less, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

class AssistantMessagesSheet extends StatelessWidget {
  const AssistantMessagesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantCubit, AssistantState>(
      builder: (context, state) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        itemCount: state.messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _MessageBubble(message: state.messages[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF6D5DFB) : const Color(0xFF26314F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.content.isEmpty ? '-' : message.content,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ),
      ),
    );
  }
}

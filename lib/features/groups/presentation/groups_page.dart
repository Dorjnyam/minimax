import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/baigalaa_assistant_shell.dart';
import '../data/groups_repository.dart';
import '../domain/group_models.dart';
import 'group_locations_page.dart';

/// Family groups: list, join by invite code, open member locations.
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  Future<List<GroupSummary>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    setState(() {
      _future = context.read<GroupsRepository>().listGroups();
    });
  }

  Future<void> _pullRefresh() async {
    final repo = context.read<GroupsRepository>();
    final f = repo.listGroups();
    setState(() => _future = f);
    await f;
  }

  Future<void> _showJoinDialog() async {
    final codeController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2438),
          title: const Text(
            'Бүлэгт нэгдэх',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: codeController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Урилгын код',
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Color(0xFF007C89)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Болих',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007C89),
              ),
              child: const Text('Нэгдэх'),
            ),
          ],
        );
      },
    );
    final code = codeController.text.trim();
    codeController.dispose();
    if (ok != true || !mounted) return;
    if (code.isEmpty) return;

    try {
      await context.read<GroupsRepository>().joinGroup(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Амжилттай нэгдлээ.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyInvite(GroupSummary g) {
    if (g.inviteCode.isEmpty) return;
    unawaited(Clipboard.setData(ClipboardData(text: g.inviteCode)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Хуулагдлаа: ${g.inviteCode}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openLocations(GroupSummary g) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GroupLocationsPage(
          groupId: g.id,
          groupName: g.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        );
    return DecoratedBox(
      decoration: BaigalaaAssistantShell.boxDecoration,
      child: Material(
        color: Colors.transparent,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showJoinDialog,
            backgroundColor: const Color(0xFF007C89),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Нэгдэх'),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: Text('Бүлэг', style: titleStyle),
            actions: [
              IconButton(
                tooltip: 'Сэргээх',
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: _future == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: BaigalaaAssistantShell.progressIndicator,
                    ),
                  )
                : FutureBuilder<List<GroupSummary>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: BaigalaaAssistantShell.progressIndicator,
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return _ErrorBody(
                          message: '${snap.error}',
                          onRetry: _reload,
                        );
                      }
                      final groups = snap.data ?? [];
                      if (groups.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups_2_outlined,
                                  size: 56,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Танд одоогоор бүлэг алга.\nДоорх «Нэгдэх» товчоор урилгын кодоор ороорой.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 15,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        color: const Color(0xFF007C89),
                        onRefresh: _pullRefresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 88),
                          itemCount: groups.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final g = groups[i];
                            return _GroupCard(
                              group: g,
                              onOpen: () => _openLocations(g),
                              onCopyCode: () => _copyInvite(g),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onOpen,
    required this.onCopyCode,
  });

  final GroupSummary group;
  final VoidCallback onOpen;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name.isNotEmpty ? group.name : 'Бүлэг',
                      style: const TextStyle(
                        color: BaigalaaAssistantShell.accentText,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.key_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              group.inviteCode.isNotEmpty
                                  ? group.inviteCode
                                  : '—',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Хуулах',
                    onPressed: onCopyCode,
                    icon: Icon(
                      Icons.copy_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Гишүүдийн байршлыг харахын тулд дарна уу.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BaigalaaAssistantShell.errorText,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007C89),
              ),
              child: const Text('Дахин оролдох'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/services/maps_launcher_service.dart';
import '../../../shared/theme/baigalaa_assistant_shell.dart';
import '../../assistant/domain/maps_command.dart';
import '../data/groups_repository.dart';
import '../domain/group_models.dart';

String _nameInitial(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  final r = t.runes;
  if (r.isEmpty) return '?';
  return String.fromCharCode(r.first);
}

/// Member locations for one family group (GET `/api/v1/groups/{id}/locations`).
class GroupLocationsPage extends StatefulWidget {
  const GroupLocationsPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupLocationsPage> createState() => _GroupLocationsPageState();
}

class _GroupLocationsPageState extends State<GroupLocationsPage> {
  Future<List<GroupMemberLocation>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    setState(() {
      _future = context.read<GroupsRepository>().groupLocations(widget.groupId);
    });
  }

  Future<void> _pullRefresh() async {
    final repo = context.read<GroupsRepository>();
    final f = repo.groupLocations(widget.groupId);
    setState(() => _future = f);
    await f;
  }

  Future<void> _openOnMap(GroupMemberLocation row) async {
    if (!row.hasCoords) return;
    final q = (row.address != null && row.address!.trim().isNotEmpty)
        ? row.address!.trim()
        : '${row.lat},${row.lng}';
    try {
      await context.read<MapsLauncherService>().launch(MapsCommand.search(q));
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: Text(
              widget.groupName.isNotEmpty ? widget.groupName : 'Байршил',
              style: titleStyle,
            ),
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
                : FutureBuilder<List<GroupMemberLocation>>(
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
                      final rows = snap.data ?? [];
                      if (rows.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Text(
                              'Гишүүдийн байршил одоогоор байхгүй.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        color: const Color(0xFF007C89),
                        onRefresh: _pullRefresh,
                        child: ListView.separated(
                          padding: BaigalaaAssistantShell.pagePadding,
                          itemCount: rows.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final row = rows[i];
                            return _MemberTile(
                              row: row,
                              onMapTap: row.hasCoords
                                  ? () => unawaited(_openOnMap(row))
                                  : null,
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

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.row,
    this.onMapTap,
  });

  final GroupMemberLocation row;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    final addr = row.address?.trim();
    final updated = row.updatedAt;
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onMapTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF007C89).withValues(alpha: 0.35),
                child: Text(
                  row.fullName.isNotEmpty ? _nameInitial(row.fullName) : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.fullName.isNotEmpty ? row.fullName : '—',
                      style: const TextStyle(
                        color: BaigalaaAssistantShell.accentText,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!row.shareLocation)
                      Text(
                        'Байршил хуваалцаагүй',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                        ),
                      )
                    else if (row.shareLocation &&
                        !row.hasCoords &&
                        (addr == null || addr.isEmpty))
                      Text(
                        'Байршил одоогоор байхгүй',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                        ),
                      )
                    else if (addr != null && addr.isNotEmpty) ...[
                      Text(
                        addr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ] else if (row.hasCoords)
                      Text(
                        '${row.lat!.toStringAsFixed(5)}, ${row.lng!.toStringAsFixed(5)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    if (updated != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Шинэчилсэн: ${_formatMn(updated)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onMapTap != null)
                IconButton(
                  tooltip: 'Газрын зураг',
                  onPressed: onMapTap,
                  icon: Icon(
                    Icons.map_outlined,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMn(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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

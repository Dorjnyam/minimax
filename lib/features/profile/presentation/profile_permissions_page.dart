import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permission status (microphone, location, notifications).
class ProfilePermissionsPage extends StatefulWidget {
  const ProfilePermissionsPage({super.key});

  @override
  State<ProfilePermissionsPage> createState() => _ProfilePermissionsPageState();
}

class _ProfilePermissionsPageState extends State<ProfilePermissionsPage>
    with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _status = {};

  static const List<_PermissionItem> _items = [
    _PermissionItem(
      permission: Permission.microphone,
      labelMn: 'Микрофон',
      hintMn: 'Дуу таних, ярих туслах',
      icon: Icons.mic_none_rounded,
    ),
    _PermissionItem(
      permission: Permission.location,
      labelMn: 'Байршил',
      hintMn: 'Чат, чиглэл, газрын зураг',
      icon: Icons.location_on_outlined,
    ),
    _PermissionItem(
      permission: Permission.notification,
      labelMn: 'Мэдэгдэл',
      hintMn: 'Сануулагч, системийн мэдэгдэл',
      icon: Icons.notifications_none_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.microtask(_refresh);
    }
  }

  Future<void> _refresh() async {
    final next = <Permission, PermissionStatus>{};
    for (final item in _items) {
      next[item.permission] = await item.permission.status;
    }
    if (mounted) {
      setState(() => _status = next);
    }
  }

  String _summaryMn() {
    var allowed = 0;
    var notAllowed = 0;
    for (final item in _items) {
      final s = _status[item.permission];
      if (s == null) continue;
      if (_isAllowed(s)) {
        allowed++;
      } else {
        notAllowed++;
      }
    }
    final total = _items.length;
    return 'Нийт $total зөвшөөрөл · Зөвшөөрөгдсөн $allowed · Зөвшөөрөгдөөгүй $notAllowed';
  }

  static bool _isAllowed(PermissionStatus s) {
    return s == PermissionStatus.granted || s == PermissionStatus.limited;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14233D), Color(0xFF5855B0), Color(0xFF191C32)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text(
            'Зөвшөөрлүүд',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          actions: [
            IconButton(
              tooltip: 'Шинэчлэх',
              onPressed: () => Future.microtask(_refresh),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              Text(
                _status.isEmpty ? 'Шинэчилж байна…' : _summaryMn(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      _PermissionRow(
                        item: _items[i],
                        status: _status[_items[i].permission],
                        onOpenSettings: () {
                          openAppSettings();
                        },
                      ),
                      if (i < _items.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 56,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Тодотгол: Зөвшөөрлийг төхөөрөмжийн тохиргооноос өөрчилнө. '
                '«Хязгаарлагдсан» нь зарим функцэд л зөвшөөрөгдсөн гэсэн үг байж болно.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem {
  const _PermissionItem({
    required this.permission,
    required this.labelMn,
    required this.hintMn,
    required this.icon,
  });

  final Permission permission;
  final String labelMn;
  final String hintMn;
  final IconData icon;
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.item,
    required this.status,
    required this.onOpenSettings,
  });

  final _PermissionItem item;
  final PermissionStatus? status;
  final VoidCallback onOpenSettings;

  static String _statusMn(PermissionStatus? s) {
    if (s == null) return '…';
    return switch (s) {
      PermissionStatus.granted => 'Зөвшөөрөгдсөн',
      PermissionStatus.limited => 'Хязгаарлагдсан',
      PermissionStatus.denied => 'Зөвшөөрөгдөөгүй',
      PermissionStatus.permanentlyDenied => 'Түрүүнд татгалзсан',
      PermissionStatus.restricted => 'Хязгаарласан',
      PermissionStatus.provisional => 'Түр зөвшөөрөл',
    };
  }

  static Color _statusColor(PermissionStatus? s) {
    if (s == null) return Colors.white54;
    if (s == PermissionStatus.granted || s == PermissionStatus.limited) {
      return const Color(0xFF8EFFD0);
    }
    return const Color(0xFFFFC9C9);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: Colors.white.withValues(alpha: 0.88), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.labelMn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.hintMn,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Text(
                        _statusMn(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onOpenSettings,
                      child: Text(
                        'Тохиргоо',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

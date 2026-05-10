import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/bloc/auth_cubit.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/google_integration_models.dart';
import '../../auth/gate/auth_gate_cubit.dart';
import '../../../shared/constants/baigalaa_constants.dart';
import '../../../shared/theme/baigalaa_assistant_shell.dart';
import '../../groups/presentation/groups_page.dart';
import 'policy_document_page.dart';
import 'profile_legal_content.dart';
import 'profile_permissions_page.dart';

/// Profile: signed-in user, hubs (tasks, connections, SOS, tools), Google, policies.
class BaigalaaProfilePage extends StatefulWidget {
  const BaigalaaProfilePage({super.key});

  static const BoxDecoration shellGradient =
      BaigalaaAssistantShell.boxDecoration;

  @override
  State<BaigalaaProfilePage> createState() => _BaigalaaProfilePageState();
}

class _BaigalaaProfilePageState extends State<BaigalaaProfilePage> {
  GoogleIntegrationStatus? _googleStatus;
  String? _googleError;
  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshGoogleStatus());
    });
  }

  Future<void> _refreshGoogleStatus() async {
    final auth = context.read<AuthCubit>();
    final token = auth.state.session.accessToken.trim();
    if (token.isEmpty) return;

    setState(() {
      _googleLoading = true;
      _googleError = null;
    });
    try {
      final base = _resolvedBaseUrl(auth.state.baseUrl);
      final status = await context
          .read<AuthRepository>()
          .googleIntegrationStatus(baseUrl: base, accessToken: token);
      if (mounted) {
        setState(() {
          _googleStatus = status;
          _googleLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _googleError = '$e';
          _googleLoading = false;
        });
      }
    }
  }

  Future<void> _connectGoogle() async {
    if (_googleLoading) return;
    final auth = context.read<AuthCubit>();
    final token = auth.state.session.accessToken.trim();
    if (token.isEmpty) return;

    setState(() => _googleError = null);
    try {
      final base = _resolvedBaseUrl(auth.state.baseUrl);
      final uri = await context.read<AuthRepository>().googleConnectUri(
        baseUrl: base,
        accessToken: token,
      );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        setState(() => _googleError = 'Could not open browser.');
        return;
      }
      if (mounted) await _refreshGoogleStatus();
    } catch (e) {
      if (mounted) setState(() => _googleError = '$e');
    }
  }

  String _resolvedBaseUrl(String stored) {
    final t = stored.trim();
    return t.isNotEmpty ? t : defaultApiBaseUrl;
  }

  void _openPolicy() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PolicyDocumentPage(
          title: ProfileLegalContent.privacyPolicyTitle,
          bodyText: ProfileLegalContent.privacyPolicyBody,
        ),
      ),
    );
  }

  void _openTerms() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PolicyDocumentPage(
          title: ProfileLegalContent.termsOfServiceTitle,
          bodyText: ProfileLegalContent.termsOfServiceBody,
        ),
      ),
    );
  }

  void _openPermissions() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfilePermissionsPage()),
    );
  }

  Future<void> _dialEmergency(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openEmergencySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2438),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Яаралтай дугаарууд',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _EmergencyTile(
                  icon: Icons.local_police_outlined,
                  label: 'Цагдаа',
                  number: '102',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    unawaited(_dialEmergency('102'));
                  },
                ),
                _EmergencyTile(
                  icon: Icons.fire_truck_outlined,
                  label: 'Гал түймэр',
                  number: '101',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    unawaited(_dialEmergency('101'));
                  },
                ),
                _EmergencyTile(
                  icon: Icons.medical_services_outlined,
                  label: 'Түргэн тусламж',
                  number: '103',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    unawaited(_dialEmergency('103'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Opens the same floating overlay engine as the wake-word path (Android).
  Future<void> _openFloatingAssistantOverlay() async {
    if (kIsWeb) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Вэб дээр идэвхгүй.')));
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Зөвхөн Android дээр ажиллана.')),
      );
      return;
    }
    try {
      var granted = await FlutterOverlayWindow.isPermissionGranted();
      if (!granted) {
        await FlutterOverlayWindow.requestPermission();
        granted = await FlutterOverlayWindow.isPermissionGranted();
      }
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Дэлгэц дээр зурах зөвшөөрөл хэрэгтэй.'),
          ),
        );
        return;
      }
      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.showOverlay(
          width: WindowSize.matchParent,
          height: overlayHeight,
          alignment: OverlayAlignment.bottomCenter,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPrivate,
          overlayTitle: 'Байгалаа туслах',
          overlayContent: 'Дуу хүлээн авч байна',
          enableDrag: false,
          positionGravity: PositionGravity.none,
        );
      }
      await FlutterOverlayWindow.shareData({
        'event': eventWake,
        'keywordIndex': -1,
        'startedAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      final overlayActive = await FlutterOverlayWindow.isActive();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            overlayActive
                ? 'Туслахын цонх нээгдлээ.'
                : 'Туслахын цонхыг шалгана уу.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
          ),
          backgroundColor: const Color(0xFF2D3A55),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('Цонх нээхэд алдаа: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shell uses PageView without Scaffold; SnackBars need a Scaffold descendant.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BaigalaaProfilePage.shellGradient,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, auth) {
                final user = auth.user;
                return GestureDetector(
                  onLongPress: () => unawaited(_openFloatingAssistantOverlay()),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: const Color(0xFFEDEBFF),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 18),
                      _MeCard(
                        fullName: user.fullName.isNotEmpty
                            ? user.fullName
                            : '—',
                        email: user.email.isNotEmpty ? user.email : '—',
                        phone: user.phone.isNotEmpty ? user.phone : '—',
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Таск',
                        children: [
                          _ProfileTile(
                            icon: Icons.event_note_outlined,
                            label: 'Хуваарьт таск',
                            subtitle:
                                'Төлөвлөлт, сануулга — зүүн тал руу шудрахад туслах нээгдэнэ.',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Туслах руу шудран «Маргаашийн хурал сануулаарай» гэж хэлээрэй.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF2D3A55),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Холбоо',
                        children: [
                          _ProfileTile(
                            icon: Icons.people_outline_rounded,
                            label: 'Бүлэг',
                            subtitle:
                                'Гэр бүлийн бүлэг, урилгаар нэгдэж, гишүүдийн байршлыг харах.',
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const GroupsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Тусламж',
                        children: [
                          _ProfileTile(
                            icon: Icons.sos_rounded,
                            label: 'Яаралтай тусламж (SOS)',
                            subtitle:
                                'Цагдаа, гал, эмнэлгийн яаралтай дугаарууд.',
                            onTap: _openEmergencySheet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Google',
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _GoogleGlyph(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _googleLoading
                                            ? 'Checking…'
                                            : (_googleStatus?.connected == true
                                                  ? 'Connected'
                                                  : 'Not connected'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (_googleStatus != null &&
                                          _googleStatus!.connected &&
                                          _googleStatus!.email.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _googleStatus!.email,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.68,
                                            ),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                      if (_googleError != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _googleError!,
                                          style: const TextStyle(
                                            color: Color(0xFFFFB8B8),
                                            fontSize: 12,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Refresh status',
                                  onPressed: _googleLoading
                                      ? null
                                      : _refreshGoogleStatus,
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ProfileTile(
                            icon: Icons.link_rounded,
                            label: 'Link Google account',
                            subtitle:
                                'Open Google to connect Gmail and calendar.',
                            onTap: _connectGoogle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Policy & privacy',
                        children: [
                          _ProfileTile(
                            icon: Icons.shield_outlined,
                            label: 'Нууцлалын бодлого',
                            onTap: _openPolicy,
                          ),
                          _ProfileTile(
                            icon: Icons.description_outlined,
                            label: 'Үйлчилгээний нөхцөл',
                            onTap: _openTerms,
                          ),
                          _ProfileTile(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'Зөвшөөрлүүд',
                            subtitle:
                                'Микрофон, байршил, мэдэгдэл — аль нь зөвшөөрөгдсөнийг харах',
                            onTap: _openPermissions,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.read<AuthGateCubit>().signOut(),
                          icon: Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade200,
                            size: 20,
                          ),
                          label: Text(
                            'Гарах',
                            style: TextStyle(
                              color: Colors.red.shade100,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade100,
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _EmergencyTile extends StatelessWidget {
  const _EmergencyTile({
    required this.icon,
    required this.label,
    required this.number,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.85),
        size: 26,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        number,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _MeCard extends StatelessWidget {
  const _MeCard({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String fullName;
  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullName,
              style: const TextStyle(
                color: Color(0xFFEDEBFF),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            _meLine(Icons.mail_outline_rounded, email),
            const SizedBox(height: 6),
            _meLine(Icons.phone_outlined, phone),
          ],
        ),
      ),
    );
  }

  Widget _meLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.05,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withDividers(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i < tiles.length - 1) {
        out.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 52,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        );
      }
    }
    return out;
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: subtitle != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.88), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

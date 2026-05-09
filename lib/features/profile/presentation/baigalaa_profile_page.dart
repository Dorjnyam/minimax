import 'package:flutter/material.dart';

import 'policy_document_page.dart';
import 'profile_legal_content.dart';
import 'profile_permissions_page.dart';

/// Hub for profile, social, policy, permissions, and scheduled tasks (Baigalaa shell).
class BaigalaaProfilePage extends StatelessWidget {
  const BaigalaaProfilePage({super.key});

  static const BoxDecoration _shellGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF14233D), Color(0xFF5855B0), Color(0xFF191C32)],
    ),
  );

  void _openPolicy(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PolicyDocumentPage(
          title: ProfileLegalContent.privacyPolicyTitle,
          bodyText: ProfileLegalContent.privacyPolicyBody,
        ),
      ),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PolicyDocumentPage(
          title: ProfileLegalContent.termsOfServiceTitle,
          bodyText: ProfileLegalContent.termsOfServiceBody,
        ),
      ),
    );
  }

  void _openPermissions(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ProfilePermissionsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _shellGradient,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            children: [
              Text(
                'Profile & settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFEDEBFF),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage account, people, and policies',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              _SectionCard(
                title: 'Profile',
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit profile',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.language_rounded,
                    label: 'Language & region',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Connections',
                children: [
                  _ProfileTile(
                    icon: Icons.link_rounded,
                    label: 'Linked accounts',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.person_add_outlined,
                    label: 'Invite contacts',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.sync_alt_rounded,
                    label: 'Sync preferences',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Groups & friends',
                children: [
                  _ProfileTile(
                    icon: Icons.groups_outlined,
                    label: 'Your groups',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Friends',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Group chats',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Хуваарьт даалгавар',
                children: [
                  _ProfileTile(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Өглөөний цаг агаар (жишээ)',
                    subtitle:
                        'TODO: Backend — өдөр бүр 08:00-д серверээс өнөөдрийн цаг агаарын '
                        'мэдээлэл аваад хэрэглэгчид харуулах (жишээ: «Өнөөдөр салхитай, +18°C»).',
                    showChevron: false,
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.schedule_rounded,
                    label: 'Хуваарьт текст → backend',
                    subtitle:
                        'TODO: Тодорхой цаг хугацаанд (жишээ нь 8 цагт) текст илгээж, '
                        'backend-ээс хариу авч дэлгэцэнд гаргах (програмчилсан даалгавар).',
                    showChevron: false,
                    onTap: () {},
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
                    onTap: () => _openPolicy(context),
                  ),
                  _ProfileTile(
                    icon: Icons.description_outlined,
                    label: 'Үйлчилгээний нөхцөл',
                    onTap: () => _openTerms(context),
                  ),
                  _ProfileTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Зөвшөөрлүүд',
                    subtitle:
                        'Микрофон, байршил, мэдэгдэл — аль нь зөвшөөрөгдсөнийг харах',
                    onTap: () => _openPermissions(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

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
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final bool showChevron;

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
              if (showChevron)
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

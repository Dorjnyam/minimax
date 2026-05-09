import 'package:flutter/material.dart';

/// Hub for profile, social, and policy — same gradient shell as [AssistantPage].
/// Placeholder rows until backend wiring; visuals can be swapped later.
class BaigalaaProfilePage extends StatelessWidget {
  const BaigalaaProfilePage({super.key});

  static const BoxDecoration _shellGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF14233D), Color(0xFF5855B0), Color(0xFF191C32)],
    ),
  );

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
                  _tile(context, Icons.person_outline_rounded, 'Edit profile'),
                  _tile(context, Icons.notifications_none_rounded, 'Notifications'),
                  _tile(context, Icons.language_rounded, 'Language & region'),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Connections',
                children: [
                  _tile(context, Icons.link_rounded, 'Linked accounts'),
                  _tile(context, Icons.person_add_outlined, 'Invite contacts'),
                  _tile(context, Icons.sync_alt_rounded, 'Sync preferences'),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Groups & friends',
                children: [
                  _tile(context, Icons.groups_outlined, 'Your groups'),
                  _tile(context, Icons.people_outline_rounded, 'Friends'),
                  _tile(context, Icons.chat_bubble_outline_rounded, 'Group chats'),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Policy & privacy',
                children: [
                  _tile(context, Icons.shield_outlined, 'Privacy policy'),
                  _tile(context, Icons.description_outlined, 'Terms of service'),
                  _tile(context, Icons.cookie_outlined, 'Cookies & data'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label) {
    return _ProfileTile(icon: icon, label: label, onTap: () {});
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.88), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
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

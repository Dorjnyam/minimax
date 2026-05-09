import 'package:flutter/material.dart';

class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _EntryGradient(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LogoMark(icon: Icons.graphic_eq),
            SizedBox(height: 24),
            Text(
              'Baigalaa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Voice assistant for everyday actions',
              style: TextStyle(color: Color(0xFFC8D7FF), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class EntryGradient extends StatelessWidget {
  const EntryGradient({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _EntryGradient(child: child);
  }
}

class EntryLogoMark extends StatelessWidget {
  const EntryLogoMark({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _LogoMark(icon: icon);
  }
}

class _EntryGradient extends StatelessWidget {
  const _EntryGradient({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111A2E), Color(0xFF20255A), Color(0xFF5639A6)],
        ),
      ),
      child: SafeArea(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6EE7F9), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
            blurRadius: 34,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 46),
    );
  }
}

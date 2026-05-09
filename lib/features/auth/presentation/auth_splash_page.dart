import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../../../shared/theme/baigalaa_mesh_background.dart';
import 'auth_theme.dart';
import 'widgets/auth_hero_lottie.dart';

class AuthSplashPage extends StatefulWidget {
  const AuthSplashPage({super.key});

  @override
  State<AuthSplashPage> createState() => _AuthSplashPageState();
}

class _AuthSplashPageState extends State<AuthSplashPage> {
  var _warming = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_warming) {
      _warming = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_preloadHeroLottie());
      });
    }
  }

  /// Warms asset cache early so splash hero does not blink when other startup
  /// I/O walks `assets/wake_words/` (e.g. Porcupine .ppn).
  Future<void> _preloadHeroLottie() async {
    try {
      await AssetLottie(orbLottieAsset).load(context: context);
    } catch (_) {
      /* [AuthHeroLottie] fallback still applies */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _EntryGradient(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuthHeroLottie(fallback: EntryLogoMark(icon: Icons.graphic_eq)),
            const SizedBox(height: 24),
            const Text(
              'Baigalaa',
              style: TextStyle(
                color: AuthTheme.primary,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Voice assistant for everyday actions',
              style: TextStyle(
                color: AuthTheme.onSurfaceVariant,
                fontSize: 15,
              ),
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
    return BaigalaaMeshBackground(
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

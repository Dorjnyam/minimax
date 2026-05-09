import 'package:flutter/material.dart';

import 'auth_splash_page.dart';

class AuthOnboardingPage extends StatelessWidget {
  const AuthOnboardingPage({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EntryGradient(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Align(
              alignment: Alignment.centerLeft,
              child: EntryLogoMark(icon: Icons.mic_none),
            ),
            const SizedBox(height: 28),
            const Text(
              'Talk to Baigalaa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                height: 1.08,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Sign in once, then use voice, maps, transit, and assistant tools from one place.',
              style: TextStyle(
                color: Color(0xFFD7DEFF),
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onGetStarted,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Get Started'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF20255A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

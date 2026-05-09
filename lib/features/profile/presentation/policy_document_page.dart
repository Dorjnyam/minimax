import 'package:flutter/material.dart';

/// Full-screen reader for privacy policy or terms (Mongolian body text).
class PolicyDocumentPage extends StatelessWidget {
  const PolicyDocumentPage({
    super.key,
    required this.title,
    required this.bodyText,
  });

  final String title;
  final String bodyText;

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
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: SelectableText(
                  bodyText.trim(),
                  style: const TextStyle(
                    color: Color(0xFFEDEBFF),
                    height: 1.55,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

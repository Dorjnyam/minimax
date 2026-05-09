import 'package:flutter/material.dart';

class ApiSection extends StatelessWidget {
  const ApiSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ApiTextField extends StatelessWidget {
  const ApiTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.minLines = 1,
    this.maxLines = 1,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final int minLines;
  final int maxLines;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }
}

class ApiButtonGrid extends StatelessWidget {
  const ApiButtonGrid({super.key, required this.isBusy, required this.buttons});

  final bool isBusy;
  final List<ApiActionButton> buttons;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons.map((button) {
        return FilledButton.tonalIcon(
          onPressed: isBusy ? null : button.onPressed,
          icon: Icon(button.icon, size: 18),
          label: Text(button.label),
        );
      }).toList(),
    );
  }
}

class ApiActionButton {
  const ApiActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class ApiOutputCard extends StatelessWidget {
  const ApiOutputCard({
    super.key,
    required this.title,
    required this.body,
    required this.statusCode,
    required this.isBusy,
  });

  final String title;
  final String body;
  final int? statusCode;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final status = statusCode == null ? '' : 'HTTP $statusCode';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isBusy)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (status.isNotEmpty)
                  Text(status),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              body,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

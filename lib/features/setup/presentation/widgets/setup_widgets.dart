import 'package:flutter/material.dart';

class SetupHeader extends StatelessWidget {
  const SetupHeader({super.key, required this.serviceRunning});

  final bool serviceRunning;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF007C89),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.graphic_eq, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Baigalaa Setup',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              Text(
                serviceRunning ? 'Wake listener active' : 'Wake listener off',
                style: const TextStyle(color: Color(0xFF52616B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SetupStatusPanel extends StatelessWidget {
  const SetupStatusPanel({
    super.key,
    required this.statusMessage,
    required this.isAndroid,
    required this.microphoneGranted,
    required this.notificationGranted,
    required this.overlayGranted,
    required this.wakeAssetCount,
  });

  final String statusMessage;
  final bool isAndroid;
  final bool microphoneGranted;
  final bool notificationGranted;
  final bool overlayGranted;
  final int wakeAssetCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SetupStatusChip(
                  label: isAndroid ? 'Android' : 'Android only',
                  passed: isAndroid,
                ),
                SetupStatusChip(label: 'Mic', passed: microphoneGranted),
                SetupStatusChip(
                  label: 'Notification',
                  passed: notificationGranted,
                ),
                SetupStatusChip(label: 'Overlay', passed: overlayGranted),
                SetupStatusChip(
                  label: '$wakeAssetCount wake assets',
                  passed: wakeAssetCount > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SetupStatusChip extends StatelessWidget {
  const SetupStatusChip({super.key, required this.label, required this.passed});

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final color = passed ? const Color(0xFF007C89) : const Color(0xFF9A3A3A);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.check_circle : Icons.error,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class AccessKeyPanel extends StatefulWidget {
  const AccessKeyPanel({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<AccessKeyPanel> createState() => _AccessKeyPanelState();
}

class _AccessKeyPanelState extends State<AccessKeyPanel> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: widget.controller,
          obscureText: _obscure,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: 'Picovoice AccessKey',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show key' : 'Hide key',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupActionPanel extends StatelessWidget {
  const SetupActionPanel({
    super.key,
    required this.isBusy,
    required this.serviceRunning,
    required this.canStart,
    required this.onRequestPermissions,
    required this.onStart,
    required this.onStop,
    required this.onTestOverlay,
    required this.onRefresh,
  });

  final bool isBusy;
  final bool serviceRunning;
  final bool canStart;
  final VoidCallback onRequestPermissions;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onTestOverlay;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: isBusy || serviceRunning || !canStart ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Listening'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isBusy || !serviceRunning ? null : onStop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Listening'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onTestOverlay,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Test Overlay'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onRequestPermissions,
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Permissions'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onRefresh,
                    icon: const Icon(Icons.sync),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WakeAssetNotice extends StatelessWidget {
  const WakeAssetNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_open, color: Color(0xFF8A6D1D)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add Android Porcupine .ppn files in assets/wake_words/. The app will load any .ppn file in that folder.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskLogPanel extends StatelessWidget {
  const TaskLogPanel({super.key, required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent events',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(entry),
              ),
          ],
        ),
      ),
    );
  }
}

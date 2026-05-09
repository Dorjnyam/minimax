import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../assistant/domain/maps_command.dart';
import '../../../shared/services/maps_launcher_service.dart';
import 'widgets/maps_lab_card.dart';

class LabsPage extends StatefulWidget {
  const LabsPage({super.key, required this.mapsLauncher});

  final MapsLauncherService mapsLauncher;

  @override
  State<LabsPage> createState() => _LabsPageState();
}

class _LabsPageState extends State<LabsPage> {
  final _tts = FlutterTts();
  final _textController = TextEditingController(
    text:
        '\u0421\u0430\u0439\u043d \u0443\u0443. '
        '\u0411\u0438 \u0411\u0430\u0439\u0433\u0430\u043b\u0430\u0430 '
        '\u0431\u0430\u0439\u043d\u0430.',
  );

  List<Map<String, String>> _mongolianVoices = const [];
  Map<String, String>? _selectedVoice;
  String _status = 'Ready';
  double _rate = 0.42;
  double _pitch = 1.0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVoices());
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _tts.getVoices;
      final items = <Map<String, String>>[];
      if (voices is List) {
        for (final voice in voices) {
          if (voice is Map) {
            final name = '${voice['name'] ?? ''}';
            final locale = '${voice['locale'] ?? ''}';
            if (locale.toLowerCase().startsWith('mn')) {
              items.add({'name': name, 'locale': locale});
            }
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _mongolianVoices = items;
        _selectedVoice = items.isEmpty ? null : items.first;
        _status = items.isEmpty
            ? 'No mn-MN voice found. Trying language fallback.'
            : 'Found ${items.length} Mongolian voice(s).';
      });
    } catch (error) {
      _setStatus('Could not load voices: $error');
    }
  }

  Future<void> _speak() async {
    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(false);
      await _tts.setLanguage('mn-MN');
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(1);
      final voice = _selectedVoice;
      if (voice != null) {
        await _tts.setVoice(voice);
      }
      await _tts.speak(_textController.text.trim());
      _setStatus('Speaking with ${voice?['name'] ?? 'mn-MN fallback'}.');
    } catch (error) {
      _setStatus('TTS failed: $error');
    }
  }

  Future<void> _launchMap(MapsCommand command) async {
    try {
      await widget.mapsLauncher.launch(command);
      _setStatus(command.confirmation);
    } catch (error) {
      _setStatus('Maps failed: $error');
    }
  }

  void _setStatus(String value) {
    if (!mounted) {
      return;
    }
    setState(() => _status = value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Labs',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(_status, style: const TextStyle(color: Color(0xFF52616B))),
          const SizedBox(height: 16),
          _TtsCard(
            textController: _textController,
            voices: _mongolianVoices,
            selectedVoice: _selectedVoice,
            rate: _rate,
            pitch: _pitch,
            onVoiceChanged: (voice) => setState(() => _selectedVoice = voice),
            onRateChanged: (value) => setState(() => _rate = value),
            onPitchChanged: (value) => setState(() => _pitch = value),
            onSpeak: _speak,
            onReloadVoices: _loadVoices,
          ),
          const SizedBox(height: 16),
          MapsLabCard(onLaunch: (command) => unawaited(_launchMap(command))),
        ],
      ),
    );
  }
}

class _TtsCard extends StatelessWidget {
  const _TtsCard({
    required this.textController,
    required this.voices,
    required this.selectedVoice,
    required this.rate,
    required this.pitch,
    required this.onVoiceChanged,
    required this.onRateChanged,
    required this.onPitchChanged,
    required this.onSpeak,
    required this.onReloadVoices,
  });

  final TextEditingController textController;
  final List<Map<String, String>> voices;
  final Map<String, String>? selectedVoice;
  final double rate;
  final double pitch;
  final ValueChanged<Map<String, String>?> onVoiceChanged;
  final ValueChanged<double> onRateChanged;
  final ValueChanged<double> onPitchChanged;
  final VoidCallback onSpeak;
  final VoidCallback onReloadVoices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mongolian TTS',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Text'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Map<String, String>>(
              initialValue: selectedVoice,
              items: voices
                  .map(
                    (voice) => DropdownMenuItem(
                      value: voice,
                      child: Text('${voice['name']} (${voice['locale']})'),
                    ),
                  )
                  .toList(),
              onChanged: onVoiceChanged,
              decoration: const InputDecoration(labelText: 'mn-MN voice'),
              hint: const Text('Use mn-MN language fallback'),
            ),
            _SliderRow(
              label: 'Rate',
              value: rate,
              min: 0.25,
              max: 0.65,
              onChanged: onRateChanged,
            ),
            _SliderRow(
              label: 'Pitch',
              value: pitch,
              min: 0.75,
              max: 1.25,
              onChanged: onPitchChanged,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReloadVoices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Voices'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSpeak,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Speak'),
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

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(width: 42, child: Text(value.toStringAsFixed(2))),
      ],
    );
  }
}

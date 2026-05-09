import 'package:flutter/material.dart';

import '../../bloc/assistant_cubit.dart';

class AssistantChips extends StatelessWidget {
  const AssistantChips({super.key, required this.onSelected});

  final ValueChanged<AssistantSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ChipButton(
            label: 'Turn off the light',
            suggestion: AssistantSuggestion.lights,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Turn on the air conditioner',
            suggestion: AssistantSuggestion.airConditioner,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'My location',
            suggestion: AssistantSuggestion.myLocation,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Directions',
            suggestion: AssistantSuggestion.directions,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Coffee near me',
            suggestion: AssistantSuggestion.coffeeNearMe,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.suggestion,
    required this.onSelected,
  });

  final String label;
  final AssistantSuggestion suggestion;
  final ValueChanged<AssistantSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        onPressed: () => onSelected(suggestion),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        labelStyle: const TextStyle(color: Color(0xFFE9EDFF)),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

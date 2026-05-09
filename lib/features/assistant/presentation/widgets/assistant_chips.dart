import 'package:flutter/material.dart';

import '../../bloc/assistant_cubit.dart';

class AssistantChips extends StatelessWidget {
  const AssistantChips({super.key, required this.onSelected});

  final ValueChanged<AssistantSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(suggestion),
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withValues(alpha: 0.12),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

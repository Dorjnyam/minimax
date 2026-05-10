import 'package:flutter/material.dart';

import '../../bloc/assistant_cubit.dart';

/// Quick actions — short Mongolian labels (maps + chat intents).
class AssistantChips extends StatelessWidget {
  const AssistantChips({super.key, required this.onSelected});

  final ValueChanged<AssistantSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _ChipButton(
            label: 'Ойролцоо',
            suggestion: AssistantSuggestion.nearbyPlaces,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Байршил',
            suggestion: AssistantSuggestion.myLocation,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Чиглэл',
            suggestion: AssistantSuggestion.directions,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Бүлэг',
            suggestion: AssistantSuggestion.groupLocations,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Утас',
            suggestion: AssistantSuggestion.callSomeone,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'Мэйл',
            suggestion: AssistantSuggestion.sendMail,
            onSelected: onSelected,
          ),
          _ChipButton(
            label: 'SOS',
            suggestion: AssistantSuggestion.sos,
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
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(suggestion),
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withValues(alpha: 0.12),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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

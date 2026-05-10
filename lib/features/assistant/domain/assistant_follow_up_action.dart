import 'package:equatable/equatable.dart';

import 'maps_command.dart';

/// External step after assistant TTS (Maps, dialer, mail, browser).
abstract class AssistantFollowUp extends Equatable {
  const AssistantFollowUp();

  /// Short status line for UI while launching (optional).
  String? get confirmation;

  @override
  List<Object?> get props => [];
}

class AssistantFollowUpMaps extends AssistantFollowUp {
  const AssistantFollowUpMaps({required this.command});

  final MapsCommand command;

  @override
  String? get confirmation => command.confirmation;

  @override
  List<Object?> get props => [command];
}

class AssistantFollowUpOpenUri extends AssistantFollowUp {
  const AssistantFollowUpOpenUri({
    required this.uri,
    this.confirmationMessage,
  });

  final Uri uri;
  final String? confirmationMessage;

  @override
  String? get confirmation => confirmationMessage;

  @override
  List<Object?> get props => [uri, confirmationMessage];
}

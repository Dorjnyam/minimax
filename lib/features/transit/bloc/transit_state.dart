import 'package:equatable/equatable.dart';

import '../domain/transit_models.dart';

enum TransitStatus { initial, loading, loaded, failure }

class TransitState extends Equatable {
  const TransitState({
    this.status = TransitStatus.initial,
    this.origin = 'State Department Store Ulaanbaatar',
    this.destination = 'Sukhbaatar Square Ulaanbaatar',
    this.options = const [],
    this.errorMessage = '',
    this.sourceLabel = 'Mock data',
  });

  final TransitStatus status;
  final String origin;
  final String destination;
  final List<TransitRouteOption> options;
  final String errorMessage;
  final String sourceLabel;

  TransitState copyWith({
    TransitStatus? status,
    String? origin,
    String? destination,
    List<TransitRouteOption>? options,
    String? errorMessage,
    String? sourceLabel,
  }) {
    return TransitState(
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      options: options ?? this.options,
      errorMessage: errorMessage ?? this.errorMessage,
      sourceLabel: sourceLabel ?? this.sourceLabel,
    );
  }

  @override
  List<Object?> get props => [
    status,
    origin,
    destination,
    options,
    errorMessage,
    sourceLabel,
  ];
}

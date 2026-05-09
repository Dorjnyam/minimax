import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/transit_repository.dart';
import 'transit_state.dart';

class TransitCubit extends Cubit<TransitState> {
  TransitCubit({required TransitRepository repository})
    : _repository = repository,
      super(const TransitState());

  final TransitRepository _repository;

  Future<void> findRoutes({
    required String origin,
    required String destination,
    String? apiKey,
  }) async {
    final cleanOrigin = origin.trim().isEmpty
        ? 'State Department Store Ulaanbaatar'
        : origin;
    final cleanDestination = destination.trim().isEmpty
        ? 'Sukhbaatar Square Ulaanbaatar'
        : destination;
    final hasApiKey = apiKey != null && apiKey.trim().isNotEmpty;

    emit(
      state.copyWith(
        status: TransitStatus.loading,
        origin: cleanOrigin,
        destination: cleanDestination,
        errorMessage: '',
        sourceLabel: hasApiKey ? 'Google Routes API' : 'Mock data',
      ),
    );

    try {
      final options = await _repository.findBusOptions(
        origin: cleanOrigin,
        destination: cleanDestination,
        apiKey: apiKey,
      );
      emit(
        state.copyWith(
          status: TransitStatus.loaded,
          options: options,
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TransitStatus.failure,
          options: const [],
          errorMessage: '$error',
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../bloc/transit_cubit.dart';
import '../bloc/transit_state.dart';
import 'widgets/transit_route_card.dart';

class TransitPage extends StatefulWidget {
  const TransitPage({super.key});

  @override
  State<TransitPage> createState() => _TransitPageState();
}

class _TransitPageState extends State<TransitPage> {
  static const _secureStorage = FlutterSecureStorage();

  final _originController = TextEditingController(
    text: 'State Department Store Ulaanbaatar',
  );
  final _destinationController = TextEditingController(
    text: 'Sukhbaatar Square Ulaanbaatar',
  );
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadApiKey();
      await _search();
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    String? key;
    try {
      key = await _secureStorage.read(key: routesApiKeyStorageKey);
    } catch (_) {}
    if (!mounted || key == null) {
      return;
    }
    _apiKeyController.text = key;
  }

  Future<void> _search() async {
    try {
      await _secureStorage.write(
        key: routesApiKeyStorageKey,
        value: _apiKeyController.text.trim(),
      );
    } catch (_) {}
    if (!mounted) {
      return;
    }
    await context.read<TransitCubit>().findRoutes(
      origin: _originController.text,
      destination: _destinationController.text,
      apiKey: _apiKeyController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<TransitCubit, TransitState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Bus Options',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Live with Google Routes API key',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 16),
              _TransitSearchPanel(
                originController: _originController,
                destinationController: _destinationController,
                apiKeyController: _apiKeyController,
                isLoading: state.status == TransitStatus.loading,
                onSearch: () => _search(),
              ),
              const SizedBox(height: 16),
              _TransitResults(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _TransitSearchPanel extends StatelessWidget {
  const _TransitSearchPanel({
    required this.originController,
    required this.destinationController,
    required this.apiKeyController,
    required this.isLoading,
    required this.onSearch,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;
  final TextEditingController apiKeyController;
  final bool isLoading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: originController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'From',
                prefixIcon: Icon(Icons.trip_origin),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: destinationController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                labelText: 'To',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: apiKeyController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Google Routes API key',
                hintText: 'Leave empty to use mock data',
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onSearch,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.directions_bus),
              label: const Text('Find Bus Options'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransitResults extends StatelessWidget {
  const _TransitResults({required this.state});

  final TransitState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == TransitStatus.failure) {
      return const SizedBox.shrink();
    }
    if (state.status == TransitStatus.loading && state.options.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.options.isEmpty) {
      return const _MessageCard(message: 'No bus options yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${state.options.length} routes from ${state.origin} to ${state.destination}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          state.sourceLabel,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 10),
        for (final option in state.options) ...[
          TransitRouteCard(option: option),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

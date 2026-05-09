import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/api_console_cubit.dart';
import '../bloc/api_console_state.dart';
import 'widgets/api_console_widgets.dart';

class ApiConsolePage extends StatefulWidget {
  const ApiConsolePage({super.key});

  @override
  State<ApiConsolePage> createState() => _ApiConsolePageState();
}

class _ApiConsolePageState extends State<ApiConsolePage> {
  final _baseUrl = TextEditingController(text: 'http://192.168.0.153:8000');
  final _email = TextEditingController(text: 'test@test.com');
  final _fullName = TextEditingController(text: 'Test User');
  final _phone = TextEditingController(text: '99001122');
  final _otp = TextEditingController(text: '111111');
  final _agentId = TextEditingController();
  final _agentInput = TextEditingController(text: 'Сайн уу');
  final _conversationTitle = TextEditingController(text: 'Шинэ яриа');
  final _conversationId = TextEditingController();
  final _groupName = TextEditingController(text: 'Манай гэр бүл');
  final _groupId = TextEditingController();
  final _lat = TextEditingController(text: '47.9184676');
  final _lng = TextEditingController(text: '106.9177016');
  final _address = TextEditingController(text: 'Ulaanbaatar');
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<ApiConsoleCubit>().load());
  }

  @override
  void dispose() {
    for (final controller in [
      _baseUrl,
      _email,
      _fullName,
      _phone,
      _otp,
      _agentId,
      _agentInput,
      _conversationTitle,
      _conversationId,
      _groupName,
      _groupId,
      _lat,
      _lng,
      _address,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _sync(ApiConsoleState state) {
    if (_hydrated) {
      return;
    }
    _set(_baseUrl, state.baseUrl);
    _set(_agentId, state.agentId);
    _set(_conversationId, state.conversationId);
    _set(_groupId, state.groupId);
    _hydrated = true;
  }

  void _set(TextEditingController controller, String value) {
    if (value.isNotEmpty && controller.text != value) {
      controller.text = value;
    }
  }

  ApiConsoleCubit get _cubit => context.read<ApiConsoleCubit>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApiConsoleCubit, ApiConsoleState>(
      listener: (_, state) => _sync(state),
      builder: (context, state) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Header(hasToken: state.hasToken),
              const SizedBox(height: 16),
              _connection(state),
              const SizedBox(height: 16),
              _auth(state),
              const SizedBox(height: 16),
              _agent(state),
              const SizedBox(height: 16),
              _chat(state),
              const SizedBox(height: 16),
              _groups(state),
              const SizedBox(height: 16),
              ApiOutputCard(
                title: state.lastTitle,
                body: state.lastBody,
                statusCode: state.lastStatusCode,
                isBusy: state.isBusy,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _connection(ApiConsoleState state) {
    return ApiSection(
      title: 'Connection',
      children: [
        ApiTextField(controller: _baseUrl, label: 'Base URL', icon: Icons.link),
        Text(
          'For a real phone, 192.168.0.153 must be your computer LAN IP.',
          style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 10),
        ApiButtonGrid(
          isBusy: state.isBusy,
          buttons: [
            ApiActionButton(
              label: 'Save',
              icon: Icons.save,
              onPressed: () => unawaited(_cubit.saveBaseUrl(_baseUrl.text)),
            ),
            ApiActionButton(
              label: 'Health',
              icon: Icons.health_and_safety,
              onPressed: () => unawaited(_cubit.health(_baseUrl.text)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _auth(ApiConsoleState state) {
    return ApiSection(
      title: 'Auth',
      children: [
        ApiTextField(controller: _email, label: 'Email', icon: Icons.email),
        ApiTextField(
          controller: _fullName,
          label: 'Full name',
          icon: Icons.person,
        ),
        ApiTextField(controller: _phone, label: 'Phone', icon: Icons.phone),
        ApiTextField(controller: _otp, label: 'OTP', icon: Icons.password),
        ApiButtonGrid(
          isBusy: state.isBusy,
          buttons: [
            ApiActionButton(
              label: 'Sign Up',
              icon: Icons.person_add,
              onPressed: () => unawaited(
                _cubit.signUp(
                  baseUrl: _baseUrl.text,
                  email: _email.text,
                  fullName: _fullName.text,
                  phone: _phone.text,
                ),
              ),
            ),
            ApiActionButton(
              label: 'Send OTP',
              icon: Icons.sms,
              onPressed: () =>
                  unawaited(_cubit.sendOtp(_baseUrl.text, _email.text)),
            ),
            ApiActionButton(
              label: 'Verify',
              icon: Icons.verified,
              onPressed: () => unawaited(
                _cubit.verifyOtp(
                  baseUrl: _baseUrl.text,
                  email: _email.text,
                  otp: _otp.text,
                ),
              ),
            ),
            ApiActionButton(
              label: 'Me',
              icon: Icons.account_circle,
              onPressed: () => unawaited(_cubit.me(_baseUrl.text)),
            ),
            ApiActionButton(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: () => unawaited(_cubit.refresh(_baseUrl.text)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _agent(ApiConsoleState state) {
    return ApiSection(
      title: 'Agent',
      children: [
        ApiTextField(
          controller: _agentId,
          label: 'Agent ID',
          icon: Icons.smart_toy,
        ),
        ApiTextField(
          controller: _agentInput,
          label: 'Agent input',
          icon: Icons.keyboard,
          minLines: 2,
          maxLines: 4,
        ),
        ApiButtonGrid(
          isBusy: state.isBusy,
          buttons: [
            ApiActionButton(
              label: 'My Agent',
              icon: Icons.person_search,
              onPressed: () => unawaited(_cubit.myAgent(_baseUrl.text)),
            ),
            ApiActionButton(
              label: 'Create',
              icon: Icons.add_circle,
              onPressed: () => unawaited(_cubit.createAgent(_baseUrl.text)),
            ),
            ApiActionButton(
              label: 'Run',
              icon: Icons.play_arrow,
              onPressed: () => unawaited(
                _cubit.runAgent(_baseUrl.text, _agentId.text, _agentInput.text),
              ),
            ),
            ApiActionButton(
              label: 'Tools',
              icon: Icons.handyman,
              onPressed: () => unawaited(_cubit.tools(_baseUrl.text)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chat(ApiConsoleState state) {
    return ApiSection(
      title: 'Chat',
      children: [
        ApiTextField(
          controller: _conversationTitle,
          label: 'Conversation title',
          icon: Icons.title,
        ),
        ApiTextField(
          controller: _conversationId,
          label: 'Conversation ID',
          icon: Icons.forum,
        ),
        ApiButtonGrid(
          isBusy: state.isBusy,
          buttons: [
            ApiActionButton(
              label: 'Create',
              icon: Icons.add_comment,
              onPressed: () => unawaited(
                _cubit.createConversation(
                  _baseUrl.text,
                  _conversationTitle.text,
                ),
              ),
            ),
            ApiActionButton(
              label: 'List',
              icon: Icons.list,
              onPressed: () => unawaited(_cubit.conversations(_baseUrl.text)),
            ),
            ApiActionButton(
              label: 'Messages',
              icon: Icons.message,
              onPressed: () => unawaited(
                _cubit.messages(_baseUrl.text, _conversationId.text),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _groups(ApiConsoleState state) {
    return ApiSection(
      title: 'Groups and Location',
      children: [
        ApiTextField(
          controller: _groupName,
          label: 'Group name',
          icon: Icons.group,
        ),
        ApiTextField(controller: _groupId, label: 'Group ID', icon: Icons.tag),
        ApiTextField(
          controller: _lat,
          label: 'Latitude',
          icon: Icons.my_location,
        ),
        ApiTextField(
          controller: _lng,
          label: 'Longitude',
          icon: Icons.my_location,
        ),
        ApiTextField(controller: _address, label: 'Address', icon: Icons.place),
        ApiButtonGrid(
          isBusy: state.isBusy,
          buttons: [
            ApiActionButton(
              label: 'Create Group',
              icon: Icons.group_add,
              onPressed: () =>
                  unawaited(_cubit.createGroup(_baseUrl.text, _groupName.text)),
            ),
            ApiActionButton(
              label: 'List Groups',
              icon: Icons.groups,
              onPressed: () => unawaited(_cubit.groups(_baseUrl.text)),
            ),
            ApiActionButton(
              label: 'Update Location',
              icon: Icons.location_on,
              onPressed: () => unawaited(
                _cubit.updateLocation(
                  baseUrl: _baseUrl.text,
                  lat: _lat.text,
                  lng: _lng.text,
                  address: _address.text,
                ),
              ),
            ),
            ApiActionButton(
              label: 'Locations',
              icon: Icons.map,
              onPressed: () => unawaited(
                _cubit.groupLocations(_baseUrl.text, _groupId.text),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.hasToken});

  final bool hasToken;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'API Console',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        Chip(
          avatar: Icon(hasToken ? Icons.lock_open : Icons.lock, size: 16),
          label: Text(hasToken ? 'Token saved' : 'No token'),
        ),
      ],
    );
  }
}

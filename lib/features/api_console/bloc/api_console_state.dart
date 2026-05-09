import 'package:equatable/equatable.dart';

import '../../../shared/constants/baigalaa_constants.dart';

enum ApiConsoleStatus { initial, loading, success, failure }

class ApiConsoleState extends Equatable {
  const ApiConsoleState({
    this.status = ApiConsoleStatus.initial,
    this.baseUrl = defaultApiBaseUrl,
    this.accessToken = '',
    this.refreshToken = '',
    this.agentId = '',
    this.conversationId = '',
    this.groupId = '',
    this.lastTitle = 'Ready',
    this.lastStatusCode,
    this.lastBody = '{}',
  });

  final ApiConsoleStatus status;
  final String baseUrl;
  final String accessToken;
  final String refreshToken;
  final String agentId;
  final String conversationId;
  final String groupId;
  final String lastTitle;
  final int? lastStatusCode;
  final String lastBody;

  bool get isBusy => status == ApiConsoleStatus.loading;
  bool get hasToken => accessToken.trim().isNotEmpty;

  ApiConsoleState copyWith({
    ApiConsoleStatus? status,
    String? baseUrl,
    String? accessToken,
    String? refreshToken,
    String? agentId,
    String? conversationId,
    String? groupId,
    String? lastTitle,
    int? lastStatusCode,
    bool clearStatusCode = false,
    String? lastBody,
  }) {
    return ApiConsoleState(
      status: status ?? this.status,
      baseUrl: baseUrl ?? this.baseUrl,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      agentId: agentId ?? this.agentId,
      conversationId: conversationId ?? this.conversationId,
      groupId: groupId ?? this.groupId,
      lastTitle: lastTitle ?? this.lastTitle,
      lastStatusCode: clearStatusCode
          ? null
          : lastStatusCode ?? this.lastStatusCode,
      lastBody: lastBody ?? this.lastBody,
    );
  }

  @override
  List<Object?> get props => [
    status,
    baseUrl,
    accessToken,
    refreshToken,
    agentId,
    conversationId,
    groupId,
    lastTitle,
    lastStatusCode,
    lastBody,
  ];
}

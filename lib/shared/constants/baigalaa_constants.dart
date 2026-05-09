import 'package:flutter/foundation.dart' show kIsWeb;

const accessKeyStorageKey = 'picovoice_access_key';
const routesApiKeyStorageKey = 'google_routes_api_key';

/// Backend on LAN (Android/iOS physical device, emulator with host IP, etc.).
const defaultApiBaseUrlLan = 'http://192.168.0.153:8778';

/// Backend on same machine as Flutter **web** (`flutter run -d chrome`).
const defaultApiBaseUrlLocalhost = 'http://192.168.0.153:8778';

/// Default API origin: **web** uses localhost; native uses LAN (see above).
String get defaultApiBaseUrl =>
    kIsWeb ? defaultApiBaseUrlLocalhost : defaultApiBaseUrlLan;

/// Fallback bearer token when secure storage has no session (e.g. hackathon demo).
/// Prefer OTP login; this is used by assistant/chat when no stored token exists.
const defaultHackathonAccessToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJoYWNrYXRob24tYXBpIiwiYXVkIjoiaGFja2F0aG9uLW1vYmlsZSIsInN1YiI6IjY5ZmYyNjhiNDNiMTA2Y2ZkZjBmMjRjNyIsImlhdCI6MTc3ODM2MDA0OSwianRpIjoiYjU5ODE0YjA0YWI2NDY0NzgzZGQ4N2Y1NDJhNzVmYTUiLCJyb2xlcyI6W10sInR5cGUiOiJhY2Nlc3MiLCJleHAiOjE3Nzg0NDY0NDl9.iORMGdOe8UYgmKoqzcrmvRFAJHOxxg-P8DFMXyrS5ek';

/// Default chat thread when none is stored (assistant loads this conversation).
const defaultHackathonConversationId = '69ff9ef1ac7626f19bd199c9';

const apiBaseUrlStorageKey = 'hackathon_api_base_url';
const apiAccessTokenStorageKey = 'hackathon_api_access_token';
const apiRefreshTokenStorageKey = 'hackathon_api_refresh_token';
const apiAgentIdStorageKey = 'hackathon_api_agent_id';
const apiConversationIdStorageKey = 'hackathon_api_conversation_id';
const apiGroupIdStorageKey = 'hackathon_api_group_id';
const authLastEmailStorageKey = 'auth_last_email';
const authProfileEmailStorageKey = 'auth_profile_email';
const authProfileFullNameStorageKey = 'auth_profile_full_name';
const authProfilePhoneStorageKey = 'auth_profile_phone';
const authOnboardingCompletedStorageKey = 'auth_onboarding_completed';
const taskAccessKeyKey = 'picovoice_access_key';
const taskKeywordPathsKey = 'keyword_paths_json';

const wakeWordAssetDirectory = 'assets/wake_words/';

/// Lottie orb: assistant UI when mic is active.
/// Registered in pubspec as [orb.json] at project root (correct Flutter web URL).
const orbLottieAsset = 'orb.json';

/// Lottie hero on auth screens (login / sign-up under [AuthPage]).
const authHeroLottieAsset = '${wakeWordAssetDirectory}tata_neu_AI_Assist.json';

const cmdPause = 'pause';
const cmdResume = 'resume';
const cmdShowOverlay = 'showOverlay';

const eventStatus = 'status';
const eventWake = 'wake';
const eventError = 'error';

const overlayHeight = 720;

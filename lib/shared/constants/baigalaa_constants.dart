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

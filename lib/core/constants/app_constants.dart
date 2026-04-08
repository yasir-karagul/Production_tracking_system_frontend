import 'package:flutter/foundation.dart';

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Maia Porselen';
  static const String appVersion = '1.0.0';

  // PC/LAN host
  static const String lanHost = '10.0.2.2';

  // API
  static const String _defaultLanBaseUrl = 'http://$lanHost:8000/api/v1';
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static String _activeBaseUrl = _resolveInitialBaseUrl();
  static String get baseUrl => _activeBaseUrl;

  static void setActiveBaseUrl(String value) {
    final normalized = _normalizeBaseUrl(value);
    if (normalized.isEmpty) return;
    _activeBaseUrl = normalized;
  }

  static List<String> get apiBaseUrlCandidates {
    final rawCandidates = <String>[
      if (_apiBaseUrlOverride.trim().isNotEmpty) _apiBaseUrlOverride.trim(),
      _defaultLanBaseUrl,
      ..._platformBaseUrlCandidates(),
    ];

    final unique = <String>{};
    final normalized = <String>[];
    for (final raw in rawCandidates) {
      final value = _normalizeBaseUrl(raw);
      if (value.isEmpty || !unique.add(value)) continue;
      normalized.add(value);
    }
    return normalized;
  }

  static List<String> _platformBaseUrlCandidates() {
    if (kIsWeb) {
      return const [
        'http://127.0.0.1:8000/api/v1',
        'http://localhost:8000/api/v1',
      ];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const [
          'http://10.0.2.2:8000/api/v1',
        ];
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return const [
          'http://127.0.0.1:8000/api/v1',
          'http://localhost:8000/api/v1',
        ];
      case TargetPlatform.fuchsia:
        return const ['http://127.0.0.1:8000/api/v1'];
    }
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static String _resolveInitialBaseUrl() {
    final candidates = apiBaseUrlCandidates;
    if (candidates.isNotEmpty) return candidates.first;
    return _defaultLanBaseUrl;
  }

  static const Duration connectionTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String deferredLogoutForSyncKey = 'deferred_logout_for_sync';

  // Hive boxes
  static const String productionBox = 'productions_offline';
  static const String syncQueueBox = 'sync_queue';
  static const String cacheBox = 'cache';

  // Production stages (ordered)
  static const List<String> stages = [
    'Eskilandirma',
    'Press',
    'Torna',
    'Dek Press',
    'Run Press',
    'Sirlama',
    'Dijital',
    'Firin',
    'Kalite Kontrol',
    'Paketleme',
    'Sevkiyat',
  ];

  // Machines per stage
  static const Map<String, List<String>> machinesPerStage = {
    'Eskilandirma': [
      'Eskilandirma-1',
      'Eskilandirma-2',
      'Eskilandirma-3',
      'Eskilandirma-4'
    ],
    'Press': ['Press-1'],
    'Torna': ['Torna-1'],
    'Dek Press': ['Dek Press-1'],
    'Run Press': ['Run Press-1'],
    'Sirlama': ['Sirlama-1', 'Sirlama-2', 'Sirlama-3', 'Sirlama-4'],
    'Dijital': ['Dijital-1'],
    'Firin': ['Firin-1'],
    'Kalite Kontrol': [],
    'Paketleme': [],
    'Sevkiyat': ['Sevkiyat'],
  };

  // Shifts
  static const List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

  // Roles
  static const List<String> roles = ['worker', 'supervisor', 'admin'];
}

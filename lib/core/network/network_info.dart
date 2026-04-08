import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Network connectivity checker.
class NetworkInfo {
  final Connectivity _connectivity;
  final Dio _dio;

  NetworkInfo({
    Connectivity? connectivity,
    Dio? dio,
  })  : _connectivity = connectivity ?? Connectivity(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 2),
                receiveTimeout: const Duration(seconds: 3),
                sendTimeout: const Duration(seconds: 2),
                followRedirects: false,
                validateStatus: (status) =>
                    status != null && status > 0 && status < 500,
              ),
            );

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) return false;
    return _hasInternetAccess();
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Stream<bool> get onConnectionStatusChanged =>
      _connectivity.onConnectivityChanged
          .asyncMap((_) => isConnected)
          .distinct();

  Future<bool> _hasInternetAccess() async {
    final apiProbes = _apiProbeUris();
    if (apiProbes.isNotEmpty) {
      return _probeUris(apiProbes);
    }

    final probes = <Uri>[
      Uri.parse('https://www.gstatic.com/generate_204'),
      Uri.parse('https://www.msftconnecttest.com/connecttest.txt'),
      Uri.parse('https://clients3.google.com/generate_204'),
    ];

    return _probeUris(probes);
  }

  Future<bool> _probeUris(List<Uri> probes) async {
    for (final uri in probes) {
      try {
        final response = await _dio.getUri<dynamic>(
          uri,
          options: Options(
            headers: const {
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          ),
        );

        final status = response.statusCode ?? 0;
        if (status >= 200 && status < 400) {
          return true;
        }
      } on DioException {
        // Try next probe.
      } catch (_) {
        // Try next probe.
      }
    }

    return false;
  }

  List<Uri> _apiProbeUris() {
    final probes = <Uri>[];
    final unique = <String>{};
    final orderedCandidates = <String>[
      AppConstants.baseUrl,
      ...AppConstants.apiBaseUrlCandidates,
    ];

    for (final candidate in orderedCandidates) {
      final baseUri = Uri.tryParse(candidate);
      if (baseUri == null || baseUri.host.isEmpty) continue;
      final probe =
          baseUri.replace(path: '/api/health', query: null, fragment: null);
      final key = probe.toString();
      if (!unique.add(key)) continue;
      probes.add(probe);
      if (probes.length >= 3) break;
    }

    return probes;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Configured Dio HTTP client with JWT interceptors.
class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        followRedirects: true,
        maxRedirects: 5,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_BaseUrlFailoverInterceptor(dio));
    dio.interceptors.add(_RedirectInterceptor(dio));
    dio.interceptors.add(_AuthInterceptor(_storage, dio));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );
  }
}

/// Interceptor that retries failed relative-path requests against
/// alternate API base URLs (emulator, localhost, LAN) and sticks to
/// the first working one.
class _BaseUrlFailoverInterceptor extends Interceptor {
  final Dio _dio;

  _BaseUrlFailoverInterceptor(this._dio);

  bool _isConnectionIssue(DioException err) {
    if (err.response != null) return false;
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.unknown;
  }

  bool _isAbsoluteUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (!_isConnectionIssue(err) ||
        request.extra['_skipBaseUrlFailover'] == true ||
        _isAbsoluteUrl(request.path)) {
      handler.next(err);
      return;
    }

    final alreadyTried = <String>{
      request.baseUrl,
      _dio.options.baseUrl,
      ...(request.extra['_triedBaseUrls'] as List?)?.whereType<String>() ??
          const <String>[],
    };

    for (final candidate in AppConstants.apiBaseUrlCandidates) {
      if (candidate.isEmpty || alreadyTried.contains(candidate)) continue;

      final retry = request.copyWith(
        baseUrl: candidate,
        extra: {
          ...request.extra,
          '_skipBaseUrlFailover': true,
          '_triedBaseUrls': [...alreadyTried, candidate],
        },
      );

      try {
        final response = await _dio.fetch(retry);
        _dio.options.baseUrl = candidate;
        handler.resolve(response);
        return;
      } on DioException catch (retryErr) {
        if (!_isConnectionIssue(retryErr)) {
          handler.reject(retryErr);
          return;
        }
      }
    }

    handler.next(err);
  }
}

/// Interceptor that re-sends POST/PUT/DELETE on 307/308 redirects
/// because Dio's built-in redirect handling is mainly for GET.
class _RedirectInterceptor extends Interceptor {
  final Dio _dio;

  _RedirectInterceptor(this._dio);

  bool _isRedirect(int? statusCode) => statusCode == 307 || statusCode == 308;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final locationHeader = response.headers['location'];

    if (_isRedirect(response.statusCode) && locationHeader != null) {
      final location = locationHeader.first;
      final options = response.requestOptions;

      options.path = location;
      options.extra['_redirected'] = true;

      _dio.fetch(options).then(
            handler.resolve,
            onError: (e) => handler.reject(
              e is DioException
                  ? e
                  : DioException(
                      requestOptions: options,
                      error: e,
                    ),
            ),
          );
      return;
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final locationHeader = response?.headers['location'];

    if (err.requestOptions.extra['_redirected'] == true) {
      handler.next(err);
      return;
    }

    if (response != null &&
        _isRedirect(response.statusCode) &&
        locationHeader != null) {
      final location = locationHeader.first;
      final options = err.requestOptions;

      options.path = location;
      options.extra['_redirected'] = true;

      _dio.fetch(options).then(
            handler.resolve,
            onError: (e) => handler.reject(
              e is DioException
                  ? e
                  : DioException(
                      requestOptions: options,
                      error: e,
                    ),
            ),
          );
      return;
    }

    handler.next(err);
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  bool _isRefreshing = false;

  _AuthInterceptor(this._storage, this._dio);

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') || path.contains('/auth/refresh');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;

    if (!skipAuth) {
      final accessToken = await _storage.read(
        key: AppConstants.accessTokenKey,
      );

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;
    final path = requestOptions.path;

    if (statusCode != 401) {
      handler.next(err);
      return;
    }

    // Never try to refresh for auth endpoints themselves.
    if (_isAuthEndpoint(path)) {
      handler.next(err);
      return;
    }

    // Prevent retry loops for the same request.
    if (requestOptions.extra['_retried'] == true) {
      handler.next(err);
      return;
    }

    // Prevent parallel refresh storms.
    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(
        key: AppConstants.refreshTokenKey,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearTokens();
        handler.next(err);
        return;
      }

      // Use a dedicated Dio instance without interceptors.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          followRedirects: true,
          maxRedirects: 5,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final refreshResponse = await refreshDio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );

      final newAccessToken = refreshResponse.data['access_token'] as String?;
      final newRefreshToken = refreshResponse.data['refresh_token'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw Exception('Missing access token in refresh response');
      }

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: newAccessToken,
      );

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: newRefreshToken,
        );
      }

      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra['_retried'] = true;

      final retryResponse = await _dio.fetch(requestOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await _clearTokens();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.deferredLogoutForSyncKey);
  }
}

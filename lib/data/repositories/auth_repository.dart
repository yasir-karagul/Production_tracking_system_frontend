import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _storage;

  AuthRepository(this._remoteDataSource, this._storage);

  Future<Either<Failure, UserModel>> login(
      String username, String loginCode) async {
    try {
      final response = await _remoteDataSource.login(username, loginCode);

      // Store tokens securely
      await _storage.delete(key: AppConstants.deferredLogoutForSyncKey);
      await _storage.write(
          key: AppConstants.accessTokenKey, value: response.accessToken);
      await _storage.write(
          key: AppConstants.refreshTokenKey, value: response.refreshToken);

      final user = UserModel.fromJson(response.user);
      await _storage.write(
        key: AppConstants.userDataKey,
        value: jsonEncode(user.toJson()),
      );
      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(AuthFailure(
            message: 'Kullanıcı adı veya personel kodu hatalı',
            statusCode: 401));
      }
      if (e.response?.statusCode == 403) {
        return Left(AuthFailure(
          message: e.response?.data?['detail'] ??
              e.response?.data?['error'] ??
              'Atanmış vardiya saati dışında giriş yapılamaz',
          statusCode: 403,
        ));
      }
      if (_isConnectivityIssue(e)) {
        return Left(_mapConnectivityFailure(e));
      }
      return Left(ServerFailure(
        message: e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Sunucu hatası',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, UserModel>> getMe() async {
    try {
      final user = await _remoteDataSource.getMe();
      await _storage.write(
        key: AppConstants.userDataKey,
        value: jsonEncode(user.toJson()),
      );
      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(
            AuthFailure(message: 'Oturum süresi doldu', statusCode: 401));
      }
      if (_isConnectivityIssue(e)) {
        return Left(_mapConnectivityFailure(e));
      }
      return Left(ServerFailure(
          message: e.response?.data?['error'] ?? 'Sunucu hatası'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<UserModel?> getCachedUser() async {
    final raw = await _storage.read(key: AppConstants.userDataKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout({bool preserveTokensForPendingSync = false}) async {
    await _storage.delete(key: AppConstants.userDataKey);
    if (preserveTokensForPendingSync) {
      await _storage.write(
        key: AppConstants.deferredLogoutForSyncKey,
        value: '1',
      );
      return;
    }
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.deferredLogoutForSyncKey);
  }

  Future<bool> isDeferredLogoutForSync() async {
    final value =
        await _storage.read(key: AppConstants.deferredLogoutForSyncKey);
    return value == '1';
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  bool _isConnectivityIssue(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  Failure _mapConnectivityFailure(DioException e) {
    final raw = '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();

    if (raw.contains('cleartext')) {
      return const ServerFailure(
        message:
            'HTTP bağlantısı Android tarafından engellendi (cleartext). Geliştirme için uygulamada cleartext izni açılmalı veya HTTPS kullanılmalı.',
      );
    }

    if (raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection reset') ||
        raw.contains('timed out')) {
      return NetworkFailure(
        message:
            'Sunucuya ulaşılamıyor. Telefon ve backend aynı ağda mı? Base URL: ${AppConstants.baseUrl}',
      );
    }

    return const NetworkFailure(
      message:
          'Bağlantı kurulamadı. Wi-Fi, backend IP/port ve Docker servislerini kontrol edin.',
    );
  }
}

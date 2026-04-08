import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../datasources/local/production_local_datasource.dart';
import '../datasources/remote/production_remote_datasource.dart';
import '../models/api_response.dart';
import '../models/production_model.dart';

class ProductionRepository {
  final ProductionRemoteDataSource _remoteDataSource;
  final ProductionLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ProductionRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, PaginatedResponse<ProductionModel>>> getProductions({
    String? shift,
    String? stage,
    String? date,
    String? startAt,
    String? endAt,
    int page = 1,
    int limit = 50,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final result = await _remoteDataSource.getProductions(
          shift: shift,
          stage: stage,
          date: date,
          startAt: startAt,
          endAt: endAt,
          page: page,
          limit: limit,
        );

        // Cache remote records for offline/hybrid history use.
        await _localDataSource.cacheProductions(result.data);

        return Right(result);
      } on DioException catch (e) {
        return Left(ServerFailure(
          message: e.response?.data?['error'] ?? 'Failed to fetch productions',
          statusCode: e.response?.statusCode,
        ));
      }
    } else {
      // Return cached data when offline
      final cached = await _localDataSource.getCachedProductions();
      return Right(PaginatedResponse(
        data: cached,
        page: 1,
        limit: cached.length,
        total: cached.length,
        pages: 1,
      ));
    }
  }

  Future<Either<Failure, ProductionModel>> createProduction(
      Map<String, dynamic> data) async {
    if (await _networkInfo.isConnected) {
      try {
        final result = await _remoteDataSource.createProduction(data);
        return Right(result);
      } on DioException catch (e) {
        if (e.response?.statusCode == 403) {
          final body = e.response?.data;
          if (body != null && body['assignedShift'] != null) {
            return Left(ShiftFailure(
              message: body['error'] ?? 'Shift restriction',
              assignedShift: body['assignedShift'],
              currentShift: body['currentShift'],
            ));
          }
          return Left(ServerFailure(
              message: body?['error'] ?? 'Access denied', statusCode: 403));
        }
        return Left(ServerFailure(
          message: e.response?.data?['error'] ??
              e.response?.data?['detail'] ??
              'Failed to create production',
          statusCode: e.response?.statusCode,
        ));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      // Queue for later sync
      await _localDataSource.addToSyncQueue(data);
      return Right(ProductionModel(
        operationId: (data['operation_id'] ?? data['operationId'])?.toString(),
        productName: data['product_name'] ?? '',
        productCode: data['product_code'] ?? '',
        designCode:
            (data['design_code'] ?? data['pattern_code'] ?? '').toString(),
        stage: data['stage'] ?? '',
        machine: data['machine'],
        quantity: data['quantity'] ?? 0,
        shift: data['shift'] ?? '',
        userId: data['user_id'] ?? '',
        quality: data['quality'] is num
            ? (data['quality'] as num).toInt()
            : int.tryParse((data['quality'] ?? '').toString()),
        notes: data['notes'],
        localSyncStatus: 'pending',
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<Either<Failure, ProductionModel>> updateProduction(
      String id, Map<String, dynamic> data) async {
    try {
      final result = await _remoteDataSource.updateProduction(id, data);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to update',
        statusCode: e.response?.statusCode,
      ));
    }
  }

  Future<Either<Failure, void>> cancelProduction(String id) async {
    try {
      await _remoteDataSource.cancelProduction(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to cancel',
        statusCode: e.response?.statusCode,
      ));
    }
  }

  /// Sync all queued offline records to the server.
  Future<int> syncPendingRecords() async {
    if (!await _networkInfo.isConnected) return 0;

    final pending = await _localDataSource.getPendingSyncItems();
    int synced = 0;

    for (final item in pending) {
      try {
        final localId = item.remove('_localId') as String?;
        await _remoteDataSource.createProduction(item);
        if (localId != null) {
          await _localDataSource.removeSyncItem(localId);
        }
        synced++;
      } catch (_) {
        // Skip failed items, they'll retry next sync
      }
    }

    return synced;
  }

  Future<int> get pendingSyncCount => _localDataSource.pendingSyncCount;

  Future<Either<Failure, PaginatedResponse<ProductionModel>>> getMyHistory({
    String? date,
    int page = 1,
    int limit = 100,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final result = await _remoteDataSource.getMyHistory(
          date: date,
          page: page,
          limit: limit,
        );
        await _localDataSource.cacheProductions(result.data);
        return Right(result);
      } on DioException catch (e) {
        return Left(ServerFailure(
          message: e.response?.data?['error'] ?? 'Failed to fetch history',
          statusCode: e.response?.statusCode,
        ));
      }
    } else {
      final cached = await _localDataSource.getCachedProductions();
      return Right(PaginatedResponse(
        data: cached,
        page: 1,
        limit: cached.length,
        total: cached.length,
        pages: 1,
      ));
    }
  }
}

import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/report_remote_datasource.dart';
import '../models/api_response.dart';

class ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepository(this._remoteDataSource);

  Future<Either<Failure, DashboardResponse>> getDashboard({
    String? date,
    String? shift,
    String? startAt,
    String? endAt,
  }) async {
    try {
      final result = await _remoteDataSource.getDashboard(
        date: date,
        shift: shift,
        startAt: startAt,
        endAt: endAt,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['error'] ?? 'Failed to load dashboard',
        statusCode: e.response?.statusCode,
      ));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getStageSummary({
    required String startDate,
    required String endDate,
    String? shift,
    String? startAt,
    String? endAt,
  }) async {
    try {
      final result = await _remoteDataSource.getStageSummary(
        startDate: startDate,
        endDate: endDate,
        shift: shift,
        startAt: startAt,
        endAt: endAt,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['error'] ?? 'Failed to load report',
        statusCode: e.response?.statusCode,
      ));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getUserPerformance({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final result = await _remoteDataSource.getUserPerformance(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message:
            e.response?.data?['error'] ?? 'Failed to load user performance',
        statusCode: e.response?.statusCode,
      ));
    }
  }

  Future<Either<Failure, Uint8List>> exportExcel({
    String entryType = 'production',
    String reportMode = 'detailed',
    String? startDate,
    String? endDate,
    String? startAt,
    String? endAt,
    String? shift,
    String? stage,
    String? machine,
    String? productName,
    String? designCode,
    String? quality,
  }) async {
    try {
      final result = await _remoteDataSource.exportExcel(
        entryType: entryType,
        reportMode: reportMode,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        shift: shift,
        stage: stage,
        machine: machine,
        productName: productName,
        designCode: designCode,
        quality: quality,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['error'] ?? 'Failed to export Excel',
        statusCode: e.response?.statusCode,
      ));
    }
  }
}

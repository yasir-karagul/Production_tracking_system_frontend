import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../models/api_response.dart';

class ReportRemoteDataSource {
  final ApiClient _apiClient;

  ReportRemoteDataSource(this._apiClient);

  Future<DashboardResponse> getDashboard({
    String? date,
    String? shift,
    String? startAt,
    String? endAt,
  }) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    if (shift != null) params['shift'] = shift;
    if (startAt != null) params['start_at'] = startAt;
    if (endAt != null) params['end_at'] = endAt;

    final response =
        await _apiClient.dio.get('/reports/dashboard', queryParameters: params);
    return DashboardResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getStageSummary({
    required String startDate,
    required String endDate,
    String? shift,
    String? startAt,
    String? endAt,
  }) async {
    final params = <String, dynamic>{
      'start_date': startDate,
      'end_date': endDate,
    };
    if (shift != null) params['shift'] = shift;
    if (startAt != null) params['start_at'] = startAt;
    if (endAt != null) params['end_at'] = endAt;

    final response = await _apiClient.dio
        .get('/reports/stage-summary', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getUserPerformance({
    required String startDate,
    required String endDate,
  }) async {
    final response =
        await _apiClient.dio.get('/reports/user-performance', queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    });
    return response.data;
  }

  Future<Uint8List> exportExcel({
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
    final params = <String, dynamic>{
      'entry_type': entryType,
      'report_mode': reportMode,
    };
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (startAt != null) params['start_at'] = startAt;
    if (endAt != null) params['end_at'] = endAt;
    if (shift != null) params['shift'] = shift;
    if (stage != null) params['stage'] = stage;
    if (machine != null) params['machine'] = machine;
    if (productName != null) params['product_name'] = productName;
    if (designCode != null) params['design_code'] = designCode;
    if (quality != null) params['quality'] = quality;

    final response = await _apiClient.dio.get(
      '/excel/export',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}

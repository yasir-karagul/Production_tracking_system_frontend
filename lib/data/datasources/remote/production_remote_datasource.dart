import '../../../core/network/api_client.dart';
import '../../models/production_model.dart';
import '../../models/api_response.dart';

class ProductionRemoteDataSource {
  final ApiClient _apiClient;

  ProductionRemoteDataSource(this._apiClient);

  Future<PaginatedResponse<ProductionModel>> getProductions({
    String? shift,
    String? stage,
    String? date,
    String? startAt,
    String? endAt,
    int page = 1,
    int limit = 50,
  }) async {
    final safeLimit = limit < 1 ? 1 : (limit > 200 ? 200 : limit);
    final params = <String, dynamic>{'page': page, 'limit': safeLimit};
    if (shift != null) params['shift'] = shift;
    if (stage != null) params['stage'] = stage;
    if (date != null) params['date'] = date;
    if (startAt != null) params['start_at'] = startAt;
    if (endAt != null) params['end_at'] = endAt;

    final response = await _apiClient.dio
        .get('/production-entries/', queryParameters: params);
    final data = response.data;

    final productions = (data['data'] as List)
        .map((json) => ProductionModel.fromJson(json))
        .toList();

    return PaginatedResponse(
      data: productions,
      page: data['pagination']['page'],
      limit: data['pagination']['limit'],
      total: data['pagination']['total'],
      pages: data['pagination']['pages'],
    );
  }

  Future<ProductionModel> getProductionById(String id) async {
    final response = await _apiClient.dio.get('/production-entries/$id');
    return ProductionModel.fromJson(response.data);
  }

  Future<ProductionModel> createProduction(Map<String, dynamic> data) async {
    final response =
        await _apiClient.dio.post('/production-entries/', data: data);
    return ProductionModel.fromJson(response.data);
  }

  Future<ProductionModel> updateProduction(
      String id, Map<String, dynamic> data) async {
    final response =
        await _apiClient.dio.put('/production-entries/$id', data: data);
    return ProductionModel.fromJson(response.data);
  }

  Future<void> cancelProduction(String id) async {
    await _apiClient.dio.delete('/production-entries/$id');
  }

  Future<PaginatedResponse<ProductionModel>> getMyHistory({
    String? date,
    int page = 1,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (date != null) params['date'] = date;

    final response = await _apiClient.dio
        .get('/production-entries/my-history', queryParameters: params);
    final data = response.data;

    final productions = (data['data'] as List)
        .map((json) => ProductionModel.fromJson(json))
        .toList();

    return PaginatedResponse(
      data: productions,
      page: data['pagination']['page'],
      limit: data['pagination']['limit'],
      total: data['pagination']['total'],
      pages: data['pagination']['pages'],
    );
  }
}

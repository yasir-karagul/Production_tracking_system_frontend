import '../../../core/network/api_client.dart';
import 'package:flutter/foundation.dart';

class ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSource(this._apiClient);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[CATALOG_DS] $message');
    }
  }

  Future<List<Map<String, dynamic>>> getProducts(
      {String? search, int limit = 200}) async {
    final params = <String, dynamic>{'limit': limit};
    if (search != null) params['search'] = search;

    _log('GET /products/ -> start (params=$params)');
    final response =
        await _apiClient.dio.get('/products/', queryParameters: params);
    final items = _extractItems(response.data);
    _log('GET /products/ -> parsed ${items.length} item(s)');
    return items;
  }

  Future<List<Map<String, dynamic>>> getPatterns({int limit = 200}) async {
    _log('GET /patterns/ -> start (limit=$limit)');
    final response = await _apiClient.dio
        .get('/patterns/', queryParameters: {'limit': limit});
    final items = _extractItems(response.data);
    _log('GET /patterns/ -> parsed ${items.length} item(s)');
    return items;
  }

  Future<List<Map<String, dynamic>>> getMachines({String? stage}) async {
    final params = <String, dynamic>{};
    if (stage != null) params['stage'] = stage;

    _log('GET /machines/ -> start (params=$params)');
    final response =
        await _apiClient.dio.get('/machines/', queryParameters: params);
    final items = _extractItems(response.data);
    _log('GET /machines/ -> parsed ${items.length} item(s)');
    return items;
  }

  Future<List<Map<String, dynamic>>> getStages({
    bool includeDeleted = false,
  }) async {
    final params = <String, dynamic>{};
    if (includeDeleted) params['include_deleted'] = true;

    _log('GET /machines/stages -> start (params=$params)');
    final response = await _apiClient.dio.get(
      '/machines/stages',
      queryParameters: params,
    );
    final items = _extractItems(response.data);
    _log('GET /machines/stages -> parsed ${items.length} item(s)');
    return items;
  }

  List<Map<String, dynamic>> _extractItems(dynamic payload) {
    dynamic rawList;
    if (payload is List) {
      rawList = payload;
    } else if (payload is Map<String, dynamic>) {
      rawList = payload['data'] ?? payload['items'] ?? payload['results'];
    } else if (payload is Map) {
      rawList = payload['data'] ?? payload['items'] ?? payload['results'];
    }

    if (rawList is! List) {
      _log(
          'extractItems -> payload list not found (type=${payload.runtimeType})');
      return const [];
    }
    final items = rawList
        .whereType<Map>()
        .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
    return items;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../data/database/app_database.dart';

const _uuid = Uuid();

class CatalogMutationResult {
  final bool queuedOffline;

  const CatalogMutationResult({required this.queuedOffline});
}

class CatalogImportResult extends CatalogMutationResult {
  final int imported;
  final int updated;

  const CatalogImportResult({
    required super.queuedOffline,
    this.imported = 0,
    this.updated = 0,
  });
}

class CatalogService {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  CatalogService(
    this._db, {
    ApiClient? apiClient,
    NetworkInfo? networkInfo,
  })  : _apiClient = apiClient ?? ApiClient(),
        _networkInfo = networkInfo ?? NetworkInfo();

  Future<CatalogMutationResult> createProduct({
    required String name,
    required String code,
  }) async {
    final normalizedName = name.trim();
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedName.isEmpty || normalizedCode.isEmpty) {
      throw ArgumentError('Name and code are required');
    }

    final existing = await _db.getProductByCode(normalizedCode);
    if (existing != null) {
      throw StateError('Bu urun kodu zaten var');
    }

    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        final response = await _apiClient.dio.post('/products/', data: {
          'name': normalizedName,
          'code': normalizedCode,
        });
        final data = _toMap(response.data);
        await _db.upsertProduct(
          ProductsCompanion.insert(
            id: _idFromResponse(data),
            productCode:
                _stringOrFallback(data['code'], normalizedCode).toUpperCase(),
            productName: _stringOrFallback(data['name'], normalizedName),
            isActive: Value(_boolOrFallback(data['is_active'], true)),
          ),
        );
        return const CatalogMutationResult(queuedOffline: false);
      } on DioException catch (e) {
        if (!_isOfflineDioError(e)) rethrow;
      }
    }

    final operationId = _uuid.v4();
    final now = DateTime.now();
    await _db.upsertProduct(
      ProductsCompanion.insert(
        id: operationId,
        productCode: normalizedCode,
        productName: normalizedName,
        isActive: const Value(true),
        cachedAt: Value(now),
      ),
    );

    await _db.addToSyncQueue(
      SyncQueueCompanion.insert(
        operationId: operationId,
        entryType: 'product',
        action: 'create',
        payload: jsonEncode({
          'name': normalizedName,
          'code': normalizedCode,
        }),
        createdAt: Value(now),
      ),
    );

    return const CatalogMutationResult(queuedOffline: true);
  }

  Future<CatalogMutationResult> createPattern({
    required String name,
    required String code,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final normalizedName = name.trim();
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedName.isEmpty || normalizedCode.isEmpty) {
      throw ArgumentError('Name and code are required');
    }

    final existing = await _db.getPatternByCode(normalizedCode);
    if (existing != null) {
      throw StateError('Bu desen kodu zaten var');
    }

    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        String? imageUrl;
        if (imageBytes != null &&
            imageBytes.isNotEmpty &&
            imageName != null &&
            imageName.trim().isNotEmpty) {
          final uploadResponse = await _apiClient.dio.post(
            '/patterns/upload-image',
            data: FormData.fromMap({
              'file': MultipartFile.fromBytes(imageBytes,
                  filename: imageName.trim()),
            }),
          );
          imageUrl = _toMap(uploadResponse.data)['image_url']?.toString();
        }

        final response = await _apiClient.dio.post('/patterns/', data: {
          'name': normalizedName,
          'code': normalizedCode,
          if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        });

        final data = _toMap(response.data);
        await _db.upsertPattern(
          PatternsCompanion.insert(
            id: _idFromResponse(data),
            patternCode:
                _stringOrFallback(data['code'], normalizedCode).toUpperCase(),
            patternName: _stringOrFallback(data['name'], normalizedName),
            thumbnailUrl: Value(_firstNonEmptyString([
              data['thumbnail_url'],
              data['image_url'],
              imageUrl,
            ])),
            isActive: Value(_boolOrFallback(data['is_active'], true)),
          ),
        );
        return const CatalogMutationResult(queuedOffline: false);
      } on DioException catch (e) {
        if (!_isOfflineDioError(e)) rethrow;
      }
    }

    final operationId = _uuid.v4();
    final now = DateTime.now();
    String? localImagePath;
    if (imageBytes != null &&
        imageBytes.isNotEmpty &&
        imageName != null &&
        imageName.trim().isNotEmpty) {
      localImagePath = await _cacheLocalPatternImage(
        operationId: operationId,
        imageBytes: imageBytes,
        imageName: imageName,
      );
    }

    await _db.upsertPattern(
      PatternsCompanion.insert(
        id: operationId,
        patternCode: normalizedCode,
        patternName: normalizedName,
        thumbnailUrl: Value(localImagePath),
        isActive: const Value(true),
        cachedAt: Value(now),
      ),
    );

    final payload = <String, dynamic>{
      'name': normalizedName,
      'code': normalizedCode,
      if (localImagePath != null && localImagePath.isNotEmpty)
        'local_image_path': localImagePath,
      if (imageBytes != null &&
          imageBytes.isNotEmpty &&
          imageName != null &&
          imageName.trim().isNotEmpty) ...{
        'image_name': imageName.trim(),
        'image_bytes_base64': base64Encode(imageBytes),
      },
    };

    await _db.addToSyncQueue(
      SyncQueueCompanion.insert(
        operationId: operationId,
        entryType: 'pattern',
        action: 'create',
        payload: jsonEncode(payload),
        createdAt: Value(now),
      ),
    );

    return const CatalogMutationResult(queuedOffline: true);
  }

  Future<CatalogMutationResult> updateProduct({
    required String id,
    required String name,
    required String code,
  }) async {
    final normalizedId = id.trim();
    final normalizedName = name.trim();
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedId.isEmpty || normalizedName.isEmpty || normalizedCode.isEmpty) {
      throw ArgumentError('Product id, name, and code are required');
    }

    final online = await _networkInfo.isConnected;
    if (!online) {
      throw StateError('Urun guncellemek icin internet baglantisi gereklidir');
    }

    final response = await _apiClient.dio.put('/products/$normalizedId', data: {
      'name': normalizedName,
      'code': normalizedCode,
    });
    final data = _toMap(response.data);
    await _db.upsertProduct(
      ProductsCompanion.insert(
        id: _idFromResponse(data, fallback: normalizedId),
        productCode: _stringOrFallback(data['code'], normalizedCode).toUpperCase(),
        productName: _stringOrFallback(data['name'], normalizedName),
        isActive: Value(_boolOrFallback(data['is_active'], true)),
      ),
    );

    return const CatalogMutationResult(queuedOffline: false);
  }

  Future<CatalogMutationResult> updatePattern({
    required String id,
    required String name,
    required String code,
  }) async {
    final normalizedId = id.trim();
    final normalizedName = name.trim();
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedId.isEmpty || normalizedName.isEmpty || normalizedCode.isEmpty) {
      throw ArgumentError('Pattern id, name, and code are required');
    }

    final online = await _networkInfo.isConnected;
    if (!online) {
      throw StateError('Desen guncellemek icin internet baglantisi gereklidir');
    }

    final response = await _apiClient.dio.put('/patterns/$normalizedId', data: {
      'name': normalizedName,
      'code': normalizedCode,
    });
    final data = _toMap(response.data);
    await _db.upsertPattern(
      PatternsCompanion.insert(
        id: _idFromResponse(data, fallback: normalizedId),
        patternCode: _stringOrFallback(data['code'], normalizedCode).toUpperCase(),
        patternName: _stringOrFallback(data['name'], normalizedName),
        thumbnailUrl: Value(_firstNonEmptyString([
          data['thumbnail_url'],
          data['image_url'],
        ])),
        isActive: Value(_boolOrFallback(data['is_active'], true)),
      ),
    );

    return const CatalogMutationResult(queuedOffline: false);
  }

  Future<CatalogMutationResult> deleteProduct({
    required String id,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError('Product id is required');
    }

    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        await _apiClient.dio.delete('/products/$normalizedId');
        await _db.markProductInactiveById(normalizedId);
        return const CatalogMutationResult(queuedOffline: false);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          await _db.markProductInactiveById(normalizedId);
          return const CatalogMutationResult(queuedOffline: false);
        }
        if (!_isOfflineDioError(e)) rethrow;
      }
    }

    final now = DateTime.now();
    await _db.markProductInactiveById(normalizedId);
    await _db.addToSyncQueue(
      SyncQueueCompanion.insert(
        operationId: normalizedId,
        entryType: 'product',
        action: 'delete',
        payload: jsonEncode({'id': normalizedId}),
        createdAt: Value(now),
      ),
    );

    return const CatalogMutationResult(queuedOffline: true);
  }

  Future<CatalogMutationResult> deletePattern({
    required String id,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError('Pattern id is required');
    }

    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        await _apiClient.dio.delete('/patterns/$normalizedId');
        await _db.markPatternInactiveById(normalizedId);
        return const CatalogMutationResult(queuedOffline: false);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          await _db.markPatternInactiveById(normalizedId);
          return const CatalogMutationResult(queuedOffline: false);
        }
        if (!_isOfflineDioError(e)) rethrow;
      }
    }

    final now = DateTime.now();
    await _db.markPatternInactiveById(normalizedId);
    await _db.addToSyncQueue(
      SyncQueueCompanion.insert(
        operationId: normalizedId,
        entryType: 'pattern',
        action: 'delete',
        payload: jsonEncode({'id': normalizedId}),
        createdAt: Value(now),
      ),
    );

    return const CatalogMutationResult(queuedOffline: true);
  }

  Future<CatalogImportResult> importProductsExcel({
    required Uint8List bytes,
    required String filename,
  }) async {
    return _importExcel(
      bytes: bytes,
      filename: filename,
      endpoint: '/products/import-excel',
      queueEntryType: 'products_excel_import',
    );
  }

  Future<CatalogImportResult> importPatternsExcel({
    required Uint8List bytes,
    required String filename,
  }) async {
    return _importExcel(
      bytes: bytes,
      filename: filename,
      endpoint: '/patterns/import-excel',
      queueEntryType: 'patterns_excel_import',
    );
  }

  Future<CatalogImportResult> _importExcel({
    required Uint8List bytes,
    required String filename,
    required String endpoint,
    required String queueEntryType,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Excel file is empty');
    }

    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        final response = await _apiClient.dio.post(
          endpoint,
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(bytes, filename: filename),
          }),
        );
        final data = _toMap(response.data);
        return CatalogImportResult(
          queuedOffline: false,
          imported: _intOrZero(data['imported']),
          updated: _intOrZero(data['updated']),
        );
      } on DioException catch (e) {
        if (!_isOfflineDioError(e)) rethrow;
      }
    }

    final now = DateTime.now();
    await _db.addToSyncQueue(
      SyncQueueCompanion.insert(
        operationId: _uuid.v4(),
        entryType: queueEntryType,
        action: 'import',
        payload: jsonEncode({
          'file_name': filename,
          'file_bytes_base64': base64Encode(bytes),
        }),
        createdAt: Value(now),
      ),
    );

    return const CatalogImportResult(queuedOffline: true);
  }

  Future<String?> _cacheLocalPatternImage({
    required String operationId,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDir.path, 'pattern_images'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final ext = _safeImageExtension(imageName);
    final file = File(p.join(cacheDir.path, 'offline_$operationId$ext'));
    await file.writeAsBytes(imageBytes, flush: true);
    return Uri.file(file.path).toString();
  }

  bool _isOfflineDioError(DioException e) {
    if (e.response != null) return false;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
  }

  String _safeImageExtension(String imageName) {
    final ext = p.extension(imageName).toLowerCase();
    if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp') {
      return ext;
    }
    return '.jpg';
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  String _idFromResponse(Map<String, dynamic> data, {String? fallback}) {
    final id = _firstNonEmptyString([data['id'], data['_id']]);
    if (id != null) return id;
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }
    return _uuid.v4();
  }

  String _stringOrFallback(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  bool _boolOrFallback(dynamic value, bool fallback) {
    if (value is bool) return value;
    return fallback;
  }

  int _intOrZero(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

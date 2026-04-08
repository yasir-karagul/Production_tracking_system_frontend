import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../data/database/app_database.dart';

const syncTaskName = 'com.maiaporselen.sync';
const syncTaskUniqueName = 'maia_sync_periodic';
const syncTaskImmediateUniqueName = 'maia_sync_immediate';
const _maxRetries = 5;
const _batchSize = 50;

/// Initialize Workmanager and register periodic sync.
/// Only works on Android/iOS and skips on desktop platforms.
Future<void> initWorkmanager() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return;
  }
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    syncTaskUniqueName,
    syncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  await scheduleImmediateSyncTask();
}

Future<void> scheduleImmediateSyncTask() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return;
  }
  try {
    await Workmanager().registerOneOffTask(
      syncTaskImmediateUniqueName,
      syncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: const Duration(seconds: 2),
    );
  } catch (_) {
    // Best effort scheduling.
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == syncTaskName) {
      try {
        final service = SyncService(AppDatabase.instance);
        await service.syncAll();
      } catch (_) {
        return false;
      }
    }
    return true;
  });
}

/// Calculates exponential backoff delay: min(2^retryCount * 5s, 5min).
Duration _backoffDelay(int retryCount) {
  final seconds = min(pow(2, retryCount).toInt() * 5, 300);
  return Duration(seconds: seconds);
}

/// Maps entry_type string to the backend collection name.
String _toCollection(String entryType) {
  switch (entryType) {
    case 'production':
      return 'production_entries';
    case 'quality':
      return 'quality_entries';
    case 'packaging':
      return 'packaging_entries';
    case 'shipment':
      return 'shipment_entries';
    default:
      return entryType;
  }
}

bool _isBatchSyncType(String entryType) {
  switch (entryType) {
    case 'production':
    case 'quality':
    case 'packaging':
    case 'shipment':
      return true;
    default:
      return false;
  }
}

bool _isCatalogDirectType(String entryType) {
  switch (entryType) {
    case 'product':
    case 'pattern':
    case 'products_excel_import':
    case 'patterns_excel_import':
      return true;
    default:
      return false;
  }
}

class SyncService {
  final AppDatabase _db;
  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SyncService(this._db) : _api = ApiClient();

  /// Sync all pending items.
  /// Entry records use /sync/batch, catalog records use direct endpoints.
  Future<SyncResult> syncAll() async {
    final networkInfo = NetworkInfo();
    if (!await networkInfo.isConnected) {
      return SyncResult(synced: 0, failed: 0, total: 0);
    }

    final pending = await _db.getPendingSyncItems();
    if (pending.isEmpty) {
      return SyncResult(synced: 0, failed: 0, total: 0);
    }

    int totalSynced = 0;
    int totalFailed = 0;

    for (var i = 0; i < pending.length; i += _batchSize) {
      final chunk = pending.sublist(i, min(i + _batchSize, pending.length));
      final batchItems =
          chunk.where((item) => _isBatchSyncType(item.entryType)).toList();
      final directItems =
          chunk.where((item) => !_isBatchSyncType(item.entryType)).toList();

      for (final item in chunk) {
        await _db.updateSyncItem(
          item.id,
          SyncQueueCompanion(
            status: const Value('syncing'),
            lastAttempt: Value(DateTime.now()),
          ),
        );
      }

      if (batchItems.isNotEmpty) {
        try {
          final operations = batchItems.map((item) {
            final payload = _decodePayloadMap(item.payload);
            return {
              'operation_id': item.operationId,
              'type': item.action, // create | update | delete
              'collection': _toCollection(item.entryType),
              'data': payload,
            };
          }).toList();

          final response = await _api.dio.post(
            '/sync/batch',
            data: {
              'device_id': 'flutter_app',
              'operations': operations,
            },
          );

          final body = _toMap(response.data);
          final syncedItems = (body['synced'] as List?) ?? const [];
          final failedItems = (body['failed'] as List?) ?? const [];

          final syncedMap = <String, Map<String, dynamic>>{};
          for (final item in syncedItems) {
            final map = _toMap(item);
            final operationId = _stringOrNull(map['operation_id']);
            if (operationId != null) {
              syncedMap[operationId] = map;
            }
          }

          final failedMap = <String, Map<String, dynamic>>{};
          for (final item in failedItems) {
            final map = _toMap(item);
            final operationId = _stringOrNull(map['operation_id']);
            if (operationId != null) {
              failedMap[operationId] = map;
            }
          }

          for (final item in batchItems) {
            if (syncedMap.containsKey(item.operationId)) {
              final result = syncedMap[item.operationId]!;
              final serverId = _stringOrNull(result['server_id']);
              if (item.action == 'create') {
                await _db.markEntrySynced(
                    item.entryType, item.operationId, serverId);
              } else if (item.action == 'update' || item.action == 'delete') {
                await _db.markEntrySynced(item.entryType, item.operationId);
              }
              await _db.removeSyncItem(item.id);
              totalSynced++;
            } else if (failedMap.containsKey(item.operationId)) {
              final error =
                  _stringOrNull(failedMap[item.operationId]!['error']);
              await _markItemFailed(item, error);
              totalFailed++;
            } else {
              await _markItemFailed(item, 'No response from server');
              totalFailed++;
            }
          }
        } on DioException catch (e) {
          for (final item in batchItems) {
            await _markItemFailed(item, e.message ?? 'Network error');
          }
          totalFailed += batchItems.length;
          for (final item in directItems) {
            await _markItemFailed(item, e.message ?? 'Network error');
          }
          totalFailed += directItems.length;
          break;
        } on FormatException catch (e) {
          for (final item in batchItems) {
            await _markItemFailed(item, e.message);
          }
          totalFailed += batchItems.length;
        }
      }

      var shouldStop = false;
      for (final item in directItems) {
        if (!_isCatalogDirectType(item.entryType)) {
          await _markItemFailed(
            item,
            'Unsupported sync entry type: ${item.entryType}',
          );
          totalFailed++;
          continue;
        }

        try {
          await _syncDirectItem(item);
          await _db.removeSyncItem(item.id);
          totalSynced++;
        } on DioException catch (e) {
          await _markItemFailed(item, _extractDirectErrorMessage(e));
          totalFailed++;
          if (_isConnectivityDioError(e)) {
            shouldStop = true;
            break;
          }
        } on FormatException catch (e) {
          await _markItemFailed(item, e.message);
          totalFailed++;
        } catch (e) {
          await _markItemFailed(item, e.toString());
          totalFailed++;
        }
      }

      if (shouldStop) {
        break;
      }
    }

    final result = SyncResult(
      synced: totalSynced,
      failed: totalFailed,
      total: pending.length,
    );

    await _finalizeDeferredLogoutIfQueueDrained();

    return result;
  }

  Future<void> _syncDirectItem(SyncQueueData item) async {
    switch (item.entryType) {
      case 'product':
        if (item.action == 'delete') {
          await _syncProductDelete(item);
        } else {
          await _syncProductCreate(item);
        }
        return;
      case 'pattern':
        if (item.action == 'delete') {
          await _syncPatternDelete(item);
        } else {
          await _syncPatternCreate(item);
        }
        return;
      case 'products_excel_import':
      case 'patterns_excel_import':
        await _syncExcelImport(item);
        return;
      default:
        throw StateError('Unsupported direct sync type: ${item.entryType}');
    }
  }

  Future<void> _syncProductCreate(SyncQueueData item) async {
    final payload = _decodePayloadMap(item.payload);
    final name = _requiredString(payload, 'name');
    final code = _requiredString(payload, 'code').toUpperCase();

    final response = await _api.dio.post('/products/', data: {
      'name': name,
      'code': code,
    });

    final responseMap = _toMap(response.data);
    final serverId =
        _stringOrNull(responseMap['id']) ?? _stringOrNull(responseMap['_id']);
    await _db.reconcileCatalogCreate(
      entryType: 'product',
      operationId: item.operationId,
      serverId: serverId,
      payload: {
        'name': name,
        'code': code,
      },
    );
  }

  Future<void> _syncProductDelete(SyncQueueData item) async {
    try {
      await _api.dio
          .delete('/products/${Uri.encodeComponent(item.operationId)}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> _syncPatternCreate(SyncQueueData item) async {
    final payload = _decodePayloadMap(item.payload);
    final name = _requiredString(payload, 'name');
    final code = _requiredString(payload, 'code').toUpperCase();

    var imageUrl = _stringOrNull(payload['image_url']);
    final imageName = _stringOrNull(payload['image_name']);
    final imageBase64 = _stringOrNull(payload['image_bytes_base64']);

    if ((imageUrl == null || imageUrl.isEmpty) &&
        imageBase64 != null &&
        imageBase64.isNotEmpty) {
      final imageBytes = base64Decode(imageBase64);
      final uploadResponse = await _api.dio.post(
        '/patterns/upload-image',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            imageBytes,
            filename: (imageName != null && imageName.isNotEmpty)
                ? imageName
                : 'pattern.jpg',
          ),
        }),
      );
      imageUrl = _stringOrNull(_toMap(uploadResponse.data)['image_url']);
    }

    final createPayload = <String, dynamic>{
      'name': name,
      'code': code,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    };
    final response = await _api.dio.post('/patterns/', data: createPayload);
    final responseMap = _toMap(response.data);
    final serverId =
        _stringOrNull(responseMap['id']) ?? _stringOrNull(responseMap['_id']);

    await _db.reconcileCatalogCreate(
      entryType: 'pattern',
      operationId: item.operationId,
      serverId: serverId,
      payload: {
        'name': name,
        'code': code,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (payload['local_image_path'] != null)
          'local_image_path': payload['local_image_path'],
      },
    );
  }

  Future<void> _syncPatternDelete(SyncQueueData item) async {
    try {
      await _api.dio
          .delete('/patterns/${Uri.encodeComponent(item.operationId)}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> _syncExcelImport(SyncQueueData item) async {
    final payload = _decodePayloadMap(item.payload);
    final fileName = _requiredString(payload, 'file_name');
    final encodedBytes = _requiredString(payload, 'file_bytes_base64');
    final fileBytes = base64Decode(encodedBytes);

    final endpoint = item.entryType == 'products_excel_import'
        ? '/products/import-excel'
        : '/patterns/import-excel';

    await _api.dio.post(
      endpoint,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      }),
    );
  }

  Map<String, dynamic> _decodePayloadMap(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const FormatException('Invalid sync payload format');
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  String _requiredString(Map<String, dynamic> payload, String key) {
    final value = _stringOrNull(payload[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required field: $key');
    }
    return value;
  }

  String? _stringOrNull(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value != null) {
      final asString = value.toString().trim();
      return asString.isEmpty ? null : asString;
    }
    return null;
  }

  bool _isConnectivityDioError(DioException e) {
    if (e.response != null) return false;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown;
  }

  String _extractDirectErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        return detail.join(', ');
      }
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return e.message ?? 'Sync error';
  }

  /// Mark a queue item as failed with exponential backoff scheduling.
  Future<void> _markItemFailed(SyncQueueData item, String? error) async {
    final newRetryCount = item.retryCount + 1;
    final nextRetry = DateTime.now().add(_backoffDelay(newRetryCount));

    if (newRetryCount >= _maxRetries) {
      await _db.updateSyncItem(
        item.id,
        SyncQueueCompanion(
          status: const Value('dead'),
          retryCount: Value(newRetryCount),
          errorMessage: Value(error),
          lastAttempt: Value(DateTime.now()),
        ),
      );
      await _db.markEntryFailed(item.entryType, item.operationId);
    } else {
      await _db.updateSyncItem(
        item.id,
        SyncQueueCompanion(
          status: const Value('failed'),
          retryCount: Value(newRetryCount),
          errorMessage: Value(error),
          lastAttempt: Value(DateTime.now()),
          nextRetryAt: Value(nextRetry),
        ),
      );
    }
  }

  Future<void> _finalizeDeferredLogoutIfQueueDrained() async {
    final deferredLogout = await _storage.read(
      key: AppConstants.deferredLogoutForSyncKey,
    );
    if (deferredLogout != '1') return;

    final pendingCount = await _db.getPendingSyncCount();
    if (pendingCount > 0) return;

    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.deferredLogoutForSyncKey);
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final int total;

  SyncResult({required this.synced, required this.failed, required this.total});

  bool get hasFailures => failed > 0;
  bool get allSynced => synced == total && total > 0;
}

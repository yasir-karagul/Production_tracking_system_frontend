import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/database/app_database.dart';
import 'sync_service.dart';

// Re-implement locally to avoid import issues with top-level function
String _getCurrentShift() {
  final hour = DateTime.now().hour;
  if (hour >= 1 && hour < 9) return 'Shift 1';
  if (hour >= 9 && hour < 17) return 'Shift 2';
  return 'Shift 3';
}

const _uuid = Uuid();

/// Service responsible for creating and updating local entry records
/// and enqueueing them for background sync.
class EntryService {
  final AppDatabase _db;

  EntryService(this._db);

  // ── Production ──

  Future<String> createProductionEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    String? machine,
    required int quantity,
    required String stage,
    required String userId,
    String? userName,
    int? quality,
    String? notes,
  }) async {
    final operationId = _uuid.v4();
    final now = DateTime.now();
    final shift = _getCurrentShift();
    final cleanNotes = notes?.trim();
    final safeNotes = cleanNotes ?? '';

    await _db.insertProductionEntry(ProductionEntriesCompanion.insert(
      operationId: operationId,
      productCode: productCode,
      productName: productName,
      patternCode: Value(patternCode),
      machine: Value(machine),
      quantity: quantity,
      stage: stage,
      shift: shift,
      userId: userId,
      userName: Value(userName),
      quality: Value(quality),
      notes: Value(cleanNotes),
      createdAt: Value(now),
    ));

    // Enqueue for sync
    final payload = {
      'product_code': productCode,
      'product_name': productName,
      'pattern_code': patternCode,
      'machine': machine,
      'quantity': quantity,
      if (quality != null) 'quality': quality,
      'stage': stage,
      'shift': shift,
      'notes': safeNotes,
      'created_at': now.toUtc().toIso8601String(),
    };

    await _db.addToSyncQueue(SyncQueueCompanion.insert(
      operationId: operationId,
      entryType: 'production',
      action: 'create',
      payload: jsonEncode(payload),
      createdAt: Value(now),
    ));
    await scheduleImmediateSyncTask();

    return operationId;
  }

  Future<void> updateProductionEntry({
    required String operationId,
    int? quantity,
    int? quality,
    String? notes,
    String? machine,
  }) async {
    final entry = await _db.getProductionEntry(operationId);
    if (entry == null) return;

    await _db.updateProductionEntry(
      operationId,
      ProductionEntriesCompanion(
        quantity: quantity != null ? Value(quantity) : const Value.absent(),
        quality: quality != null ? Value(quality) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        machine: machine != null ? Value(machine) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );

    final payload = {
      if (quantity != null) 'quantity': quantity,
      if (quality != null) 'quality': quality,
      if (notes != null) 'notes': notes,
      if (machine != null) 'machine': machine,
    };

    await _db.addToSyncQueue(SyncQueueCompanion.insert(
      operationId: operationId,
      entryType: 'production',
      action: 'update',
      payload: jsonEncode(payload),
      createdAt: Value(DateTime.now()),
    ));
    await scheduleImmediateSyncTask();
  }

  // ── Quality ──

  Future<String> createQualityEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    String? machine,
    required int quantity,
    String qualityGrade = 'A',
    String? defectNotes,
    required String userId,
    String? userName,
  }) async {
    final operationId = _uuid.v4();
    final now = DateTime.now();
    final shift = _getCurrentShift();
    final safeDefectNotes = defectNotes ?? '';

    await _db.insertQualityEntry(QualityEntriesCompanion.insert(
      operationId: operationId,
      productCode: productCode,
      productName: productName,
      patternCode: Value(patternCode),
      machine: Value(machine),
      quantity: quantity,
      shift: shift,
      userId: userId,
      userName: Value(userName),
      defectNotes: Value(defectNotes),
      createdAt: Value(now),
    ));

    final payload = {
      'product_code': productCode,
      'product_name': productName,
      'pattern_code': patternCode,
      'machine': machine,
      'quantity': quantity,
      'quality_grade': qualityGrade,
      'defect_notes': safeDefectNotes,
      'shift': shift,
      'created_at': now.toUtc().toIso8601String(),
    };

    await _db.addToSyncQueue(SyncQueueCompanion.insert(
      operationId: operationId,
      entryType: 'quality',
      action: 'create',
      payload: jsonEncode(payload),
      createdAt: Value(now),
    ));
    await scheduleImmediateSyncTask();

    return operationId;
  }

  // ── Packaging ──

  Future<String> createPackagingEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    String? machine,
    required int quantity,
    required String packagingType,
    required String userId,
    String? userName,
  }) async {
    final operationId = _uuid.v4();
    final now = DateTime.now();
    final shift = _getCurrentShift();

    await _db.insertPackagingEntry(PackagingEntriesCompanion.insert(
      operationId: operationId,
      productCode: productCode,
      productName: productName,
      patternCode: Value(patternCode),
      machine: Value(machine),
      quantity: quantity,
      packagingType: Value(packagingType),
      shift: shift,
      userId: userId,
      userName: Value(userName),
      createdAt: Value(now),
    ));

    final payload = {
      'product_code': productCode,
      'product_name': productName,
      'pattern_code': patternCode,
      'machine': machine,
      'quantity': quantity,
      'packaging_type': packagingType,
      'shift': shift,
      'created_at': now.toUtc().toIso8601String(),
    };

    await _db.addToSyncQueue(SyncQueueCompanion.insert(
      operationId: operationId,
      entryType: 'packaging',
      action: 'create',
      payload: jsonEncode(payload),
      createdAt: Value(now),
    ));
    await scheduleImmediateSyncTask();

    return operationId;
  }

  // ── Shipment ──

  Future<String> createShipmentEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    required int quantity,
    required String destination,
    required String userId,
    String? userName,
  }) async {
    final operationId = _uuid.v4();
    final now = DateTime.now();
    final shift = _getCurrentShift();

    await _db.insertShipmentEntry(ShipmentEntriesCompanion.insert(
      operationId: operationId,
      productCode: productCode,
      productName: productName,
      patternCode: Value(patternCode),
      quantity: quantity,
      destination: Value(destination),
      shift: shift,
      userId: userId,
      userName: Value(userName),
      createdAt: Value(now),
    ));

    final payload = {
      'product_code': productCode,
      'product_name': productName,
      'pattern_code': patternCode,
      'quantity': quantity,
      'destination': destination,
      'shift': shift,
      'created_at': now.toUtc().toIso8601String(),
    };

    await _db.addToSyncQueue(SyncQueueCompanion.insert(
      operationId: operationId,
      entryType: 'shipment',
      action: 'create',
      payload: jsonEncode(payload),
      createdAt: Value(now),
    ));
    await scheduleImmediateSyncTask();

    return operationId;
  }
}

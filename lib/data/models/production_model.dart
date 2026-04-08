import '../../domain/entities/production_entity.dart';

DateTime? _parseApiDateTime(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  final hasExplicitOffset = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(raw);
  if (parsed.isUtc || hasExplicitOffset) {
    return parsed.toLocal();
  }

  // Mongo may return UTC datetimes without timezone info. Treat them as UTC.
  final assumedUtc = DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
  return assumedUtc.toLocal();
}

int? _parseQualityValue(dynamic value) {
  if (value == null) return null;

  if (value is num) {
    final level = value.toInt();
    if (level >= 1 && level <= 4) return level;
    return null;
  }

  final normalized = value.toString().trim().toLowerCase();
  if (normalized.isEmpty) return null;

  final numeric = int.tryParse(normalized);
  if (numeric != null && numeric >= 1 && numeric <= 4) return numeric;

  if (normalized.contains('1.kalite') ||
      normalized.contains('1. kalite') ||
      normalized.contains('birinci kalite')) {
    return 1;
  }
  if (normalized.contains('2.kalite') ||
      normalized.contains('2. kalite') ||
      normalized.contains('ikinci kalite')) {
    return 2;
  }
  if (normalized.contains('3.kalite') ||
      normalized.contains('3. kalite') ||
      normalized.contains('\u00fc\u00e7\u00fcnc\u00fc kalite') ||
      normalized.contains('ucuncu kalite')) {
    return 3;
  }
  if (normalized.contains('end\u00fcstriyel') ||
      normalized.contains('endustriyel') ||
      normalized.contains('industrial')) {
    return 4;
  }

  final match = RegExp(r'\b([123])\s*\.?\s*kalite\b').firstMatch(normalized);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }

  return null;
}

class ProductionModel extends Production {
  const ProductionModel({
    super.id,
    super.operationId,
    required super.productName,
    required super.productCode,
    required super.designCode,
    required super.stage,
    super.machine,
    required super.quantity,
    required super.shift,
    required super.userId,
    super.userName,
    super.personnelNo,
    super.quality,
    super.notes,
    super.status,
    super.localSyncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory ProductionModel.fromJson(Map<String, dynamic> json) {
    // Handle populated user_id
    String userId = '';
    String? userName;
    if (json['user_id'] is Map) {
      userId = json['user_id']['_id'] ?? '';
      userName = json['user_id']['name'];
    } else {
      userId = json['user_id'] ?? '';
    }
    // Also check for user_name field from backend
    userName ??= json['user_name'];

    return ProductionModel(
      id: json['_id'] ?? json['id'],
      operationId: json['operation_id'] ?? json['operationId'],
      productName: json['product_name'] ?? '',
      productCode: json['product_code'] ?? '',
      designCode:
          (json['design_code'] ?? json['pattern_code'] ?? '').toString(),
      stage: json['stage'] ?? '',
      machine: json['machine'],
      quantity: json['quantity'] ?? 0,
      shift: json['shift'] ?? '',
      userId: userId,
      userName: userName,
      personnelNo:
          (json['user_personnel_no'] ?? json['personnelNo'])?.toString(),
      quality: _parseQualityValue(json['quality']),
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'active',
      localSyncStatus: json['local_sync_status'] ?? json['localSyncStatus'],
      createdAt: _parseApiDateTime(json['created_at']),
      updatedAt: _parseApiDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (operationId != null) 'operation_id': operationId,
      'product_name': productName,
      'product_code': productCode,
      'design_code': designCode,
      'pattern_code': designCode,
      'stage': stage,
      'machine': machine,
      'quantity': quantity,
      if (quality != null) 'quality': quality,
      'notes': notes,
    };
  }
}

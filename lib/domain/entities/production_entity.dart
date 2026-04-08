import 'package:equatable/equatable.dart';

class Production extends Equatable {
  final String? id;
  final String? operationId;
  final String productName;
  final String productCode;
  final String designCode;
  final String stage;
  final String? machine;
  final int quantity;
  final String shift;
  final String userId;
  final String? userName;
  final String? personnelNo;
  final int? quality;
  final String? notes;
  final String status;
  final String? localSyncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Production({
    this.id,
    this.operationId,
    required this.productName,
    required this.productCode,
    required this.designCode,
    required this.stage,
    this.machine,
    required this.quantity,
    required this.shift,
    required this.userId,
    this.userName,
    this.personnelNo,
    this.quality,
    this.notes,
    this.status = 'active',
    this.localSyncStatus,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        operationId,
        productCode,
        stage,
        quantity,
        shift,
        userId,
        localSyncStatus,
        createdAt
      ];
}

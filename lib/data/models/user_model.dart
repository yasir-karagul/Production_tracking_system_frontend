import '../../domain/entities/user_entity.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    super.personnelNo,
    required super.role,
    required super.assignedShift,
    super.assignedStage,
    super.assignedStages,
    super.assignedMachines,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final assignedStagesRaw =
        json['assigned_stages'] ?? json['assignedStages'] ?? const [];
    final assignedStages = assignedStagesRaw is List
        ? assignedStagesRaw
            .map((stage) => stage?.toString().trim() ?? '')
            .where((stage) => stage.isNotEmpty)
            .toList()
        : <String>[];

    final assignedStage =
        (json['assigned_stage'] ?? json['assignedStage'])?.toString();
    if (assignedStage != null &&
        assignedStage.trim().isNotEmpty &&
        !assignedStages.contains(assignedStage.trim())) {
      assignedStages.insert(0, assignedStage.trim());
    }

    final assignedMachinesRaw =
        json['assigned_machines'] ?? json['assignedMachines'] ?? const [];
    final assignedMachines = assignedMachinesRaw is List
        ? assignedMachinesRaw
            .map((machine) => machine?.toString().trim() ?? '')
            .where((machine) => machine.isNotEmpty)
            .toSet()
            .toList()
        : <String>[];

    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      personnelNo: (json['personnel_no'] ?? json['personnelNo'])?.toString(),
      role: json['role'] ?? 'worker',
      assignedShift:
          (json['assigned_shift'] ?? json['assignedShift'] ?? '').toString(),
      assignedStage: assignedStages.isNotEmpty ? assignedStages.first : null,
      assignedStages: assignedStages,
      assignedMachines: assignedMachines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'personnelNo': personnelNo,
      'role': role,
      'assignedShift': assignedShift,
      'assignedStage': assignedStage,
      'assignedStages': assignedStages,
      'assignedMachines': assignedMachines,
    };
  }
}

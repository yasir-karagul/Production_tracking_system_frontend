import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String username;
  final String? personnelNo;
  final String role;
  final String assignedShift;
  final String? assignedStage;
  final List<String> assignedStages;
  final List<String> assignedMachines;

  const User({
    required this.id,
    required this.name,
    required this.username,
    this.personnelNo,
    required this.role,
    required this.assignedShift,
    this.assignedStage,
    this.assignedStages = const [],
    this.assignedMachines = const [],
  });

  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
  bool get isWorker => role == 'worker';
  bool get canDelete => role == 'supervisor' || role == 'admin';
  bool get canAudit => role == 'supervisor' || role == 'admin';

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        personnelNo,
        role,
        assignedShift,
        assignedStage,
        assignedStages,
        assignedMachines,
      ];
}

import 'package:equatable/equatable.dart';

/// Base failure class for clean error handling.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

class ValidationFailure extends Failure {
  final List<String> details;
  const ValidationFailure({required super.message, this.details = const []});
}

class ShiftFailure extends Failure {
  final String assignedShift;
  final String currentShift;
  const ShiftFailure({
    required super.message,
    required this.assignedShift,
    required this.currentShift,
  });
}

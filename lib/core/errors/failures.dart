/// Base class for all failures in the application
abstract class Failure {
  const Failure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.statusCode,
  });
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.statusCode,
  });
}

/// Authorization failures
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required super.message,
    super.statusCode,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.statusCode,
  });
}

/// Business rule failures
class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({
    required super.message,
    super.statusCode,
  });
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.statusCode,
  });
}

/// Backup/Restore failures
class BackupFailure extends Failure {
  const BackupFailure({
    required super.message,
    super.statusCode,
  });
}

/// File operation failures
class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    super.statusCode,
  });
}

/// Unknown/Unexpected failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.statusCode,
  });
}

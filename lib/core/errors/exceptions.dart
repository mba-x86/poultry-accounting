/// Base exception class
class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.statusCode,
  });
}

/// Authentication exceptions
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.statusCode,
  });
}

/// Authorization exceptions
class AuthorizationException extends AppException {
  const AuthorizationException({
    required super.message,
    super.statusCode,
  });
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode,
  });
}

/// Business rule violations
class BusinessRuleException extends AppException {
  const BusinessRuleException({
    required super.message,
    super.statusCode,
  });
}

/// Not found exceptions
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.statusCode,
  });
}

/// Backup/Restore exceptions
class BackupException extends AppException {
  const BackupException({
    required super.message,
    super.statusCode,
  });
}

/// File operation exceptions
class FileException extends AppException {
  const FileException({
    required super.message,
    super.statusCode,
  });
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
  });
}

/// Server exceptions
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

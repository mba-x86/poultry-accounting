import 'package:poultry_accounting/domain/entities/user.dart';

/// User Repository Interface
abstract class UserRepository {
  /// Get all users
  Future<List<User>> getAllUsers();

  /// Get user by ID
  Future<User?> getUserById(int id);

  /// Get user by username
  Future<User?> getUserByUsername(String username);

  /// Get active users only
  Future<List<User>> getActiveUsers();

  /// Create new user
  Future<int> createUser(User user);

  /// Update existing user
  Future<void> updateUser(User user);

  /// Soft delete user
  Future<void> deleteUser(int id);

  /// Authenticate user
  Future<User?> authenticate(String username, String password);

  /// Change user password
  Future<void> changePassword(int userId, String newPasswordHash);

  /// Activate/deactivate user
  Future<void> toggleUserStatus(int userId, bool isActive);
}

// Base Failure Class
abstract class Failure {
  final String message;
  const Failure(this.message,);
}

// Server Failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Authentication Failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Invalid email or password',
  ]);
}

class UserNotAuthenticatedFailure extends Failure {
  const UserNotAuthenticatedFailure([
    super.message = 'User is not authenticated',
  ]);
}

class TokenExpiredFailure extends Failure {
  const TokenExpiredFailure([
    super.message = 'Authentication token has expired',
  ]);
}

class AccountDisabledFailure extends Failure {
  const AccountDisabledFailure([super.message = 'Account has been disabled']);
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = "No internet connection"]);
}

class NoInternetFailure extends Failure {
  const NoInternetFailure([super.message = 'No internet connection available']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure([super.message = 'Failed to connect to server']);
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class CacheNotFoundFailure extends Failure {
  const CacheNotFoundFailure([super.message = 'Cached data not found']);
}

// Database Failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class DataNotFoundFailure extends Failure {
  const DataNotFoundFailure([super.message = 'Requested data not found']);
}

class DuplicateDataFailure extends Failure {
  const DuplicateDataFailure([super.message = 'Data already exists']);
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure(super.message);
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure([super.message = 'Invalid email format']);
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure([super.message = 'Password is too weak']);
}

// File/Storage Failures
class FileFailure extends Failure {
  const FileFailure(super.message);
}

class FileUploadFailure extends Failure {
  const FileUploadFailure([super.message = 'Failed to upload file']);
}

class FileDownloadFailure extends Failure {
  const FileDownloadFailure([super.message = 'Failed to download file']);
}

class FileSizeExceededFailure extends Failure {
  const FileSizeExceededFailure([super.message = 'File size exceeds limit']);
}

class UnsupportedFileTypeFailure extends Failure {
  const UnsupportedFileTypeFailure([super.message = 'File type not supported']);
}

// Chat/Messaging Failures
class MessageFailure extends Failure {
  const MessageFailure(super.message);
}

class MessageSendFailure extends Failure {
  const MessageSendFailure([super.message = 'Failed to send message']);
}

class MessageDeleteFailure extends Failure {
  const MessageDeleteFailure([super.message = 'Failed to delete message']);
}

class ChatNotFoundFailure extends Failure {
  const ChatNotFoundFailure([super.message = 'Chat not found']);
}

// User Failures
class UserFailure extends Failure {
  const UserFailure(super.message);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([super.message = 'User not found']);
}

class UserAlreadyExistsFailure extends Failure {
  const UserAlreadyExistsFailure([super.message = 'User already exists']);
}

class UserBlockedFailure extends Failure {
  const UserBlockedFailure([super.message = 'User is blocked']);
}

// Permission Failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([super.message = 'Permission denied']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized access']);
}

// Rate Limiting Failures
class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Too many requests. Please try again later',
  ]);
}

// Firebase Failures
class FirebaseFailure extends Failure {
  const FirebaseFailure(super.message);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

// Unknown/Unexpected Failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred']);
}

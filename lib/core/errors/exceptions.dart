// Server Exceptions
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

// Authentication Exceptions
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class InvalidCredentialsException implements Exception {
  final String message;
  InvalidCredentialsException([this.message = 'Invalid email or password']);
}

class UserNotAuthenticatedException implements Exception {
  final String message;
  UserNotAuthenticatedException([this.message = 'User is not authenticated']);
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([this.message = 'Authentication token has expired']);
}

class AccountDisabledException implements Exception {
  final String message;
  AccountDisabledException([this.message = 'Account has been disabled']);
}

// Network Exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'No internet connection available']);
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'Request timed out']);
}

class ConnectionException implements Exception {
  final String message;
  ConnectionException([this.message = 'Failed to connect to server']);
}

// Cache Exceptions
class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class CacheNotFoundException implements Exception {
  final String message;
  CacheNotFoundException([this.message = 'Cached data not found']);
}

// Database Exceptions
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
}

class DataNotFoundException implements Exception {
  final String message;
  DataNotFoundException([this.message = 'Requested data not found']);
}

class DuplicateDataException implements Exception {
  final String message;
  DuplicateDataException([this.message = 'Data already exists']);
}

// Validation Exceptions
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class InvalidInputException implements Exception {
  final String message;
  InvalidInputException(this.message);
}

class InvalidEmailException implements Exception {
  final String message;
  InvalidEmailException([this.message = 'Invalid email format']);
}

class WeakPasswordException implements Exception {
  final String message;
  WeakPasswordException([this.message = 'Password is too weak']);
}

// File/Storage Exceptions
class FileException implements Exception {
  final String message;
  FileException(this.message);
}

class FileUploadException implements Exception {
  final String message;
  FileUploadException([this.message = 'Failed to upload file']);
}

class FileDownloadException implements Exception {
  final String message;
  FileDownloadException([this.message = 'Failed to download file']);
}

class FileSizeExceededException implements Exception {
  final String message;
  FileSizeExceededException([this.message = 'File size exceeds limit']);
}

class UnsupportedFileTypeException implements Exception {
  final String message;
  UnsupportedFileTypeException([this.message = 'File type not supported']);
}

// Chat/Messaging Exceptions
class MessageException implements Exception {
  final String message;
  MessageException(this.message);
}

class MessageSendException implements Exception {
  final String message;
  MessageSendException([this.message = 'Failed to send message']);
}

class MessageDeleteException implements Exception {
  final String message;
  MessageDeleteException([this.message = 'Failed to delete message']);
}

class ChatNotFoundException implements Exception {
  final String message;
  ChatNotFoundException([this.message = 'Chat not found']);
}

// User Exceptions
class UserException implements Exception {
  final String message;
  UserException(this.message);
}

class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException([this.message = 'User not found']);
}

class UserAlreadyExistsException implements Exception {
  final String message;
  UserAlreadyExistsException([this.message = 'User already exists']);
}

class UserBlockedException implements Exception {
  final String message;
  UserBlockedException([this.message = 'User is blocked']);
}

// Permission Exceptions
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException([this.message = 'Permission denied']);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized access']);
}

// Rate Limiting Exceptions
class RateLimitException implements Exception {
  final String message;
  RateLimitException([
    this.message = 'Too many requests. Please try again later',
  ]);
}

// Firebase Exceptions
class FirebaseException implements Exception {
  final String message;
  FirebaseException(this.message);
}

class FirestoreException implements Exception {
  final String message;
  FirestoreException(this.message);
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
}

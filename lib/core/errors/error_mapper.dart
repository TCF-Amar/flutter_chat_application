import 'package:chat_kare/core/errors/exceptions.dart';
import 'package:chat_kare/core/errors/failure.dart';

/// Maps exceptions to failures for use in the domain/application layer
Failure mapExceptionToFailure(Exception exception) {
  // Server Exceptions
  if (exception is ServerException) {
    return ServerFailure(exception.message);
  }

  // Authentication Exceptions
  if (exception is AuthException) {
    return AuthFailure(exception.message);
  }
  if (exception is InvalidCredentialsException) {
    return InvalidCredentialsFailure(exception.message);
  }
  if (exception is UserNotAuthenticatedException) {
    return UserNotAuthenticatedFailure(exception.message);
  }
  if (exception is TokenExpiredException) {
    return TokenExpiredFailure(exception.message);
  }
  if (exception is AccountDisabledException) {
    return AccountDisabledFailure(exception.message);
  }

  // Network Exceptions
  if (exception is NetworkException) {
    return NetworkFailure(exception.message);
  }
  if (exception is NoInternetException) {
    return NoInternetFailure(exception.message);
  }
  if (exception is TimeoutException) {
    return TimeoutFailure(exception.message);
  }
  if (exception is ConnectionException) {
    return ConnectionFailure(exception.message);
  }

  // Cache Exceptions
  if (exception is CacheException) {
    return CacheFailure(exception.message);
  }
  if (exception is CacheNotFoundException) {
    return CacheNotFoundFailure(exception.message);
  }

  // Database Exceptions
  if (exception is DatabaseException) {
    return DatabaseFailure(exception.message);
  }
  if (exception is DataNotFoundException) {
    return DataNotFoundFailure(exception.message);
  }
  if (exception is DuplicateDataException) {
    return DuplicateDataFailure(exception.message);
  }

  // Validation Exceptions
  if (exception is ValidationException) {
    return ValidationFailure(exception.message);
  }
  if (exception is InvalidInputException) {
    return InvalidInputFailure(exception.message);
  }
  if (exception is InvalidEmailException) {
    return InvalidEmailFailure(exception.message);
  }
  if (exception is WeakPasswordException) {
    return WeakPasswordFailure(exception.message);
  }

  // File/Storage Exceptions
  if (exception is FileException) {
    return FileFailure(exception.message);
  }
  if (exception is FileUploadException) {
    return FileUploadFailure(exception.message);
  }
  if (exception is FileDownloadException) {
    return FileDownloadFailure(exception.message);
  }
  if (exception is FileSizeExceededException) {
    return FileSizeExceededFailure(exception.message);
  }
  if (exception is UnsupportedFileTypeException) {
    return UnsupportedFileTypeFailure(exception.message);
  }

  // Chat/Messaging Exceptions
  if (exception is MessageException) {
    return MessageFailure(exception.message);
  }
  if (exception is MessageSendException) {
    return MessageSendFailure(exception.message);
  }
  if (exception is MessageDeleteException) {
    return MessageDeleteFailure(exception.message);
  }
  if (exception is ChatNotFoundException) {
    return ChatNotFoundFailure(exception.message);
  }

  // User Exceptions
  if (exception is UserException) {
    return UserFailure(exception.message);
  }
  if (exception is UserNotFoundException) {
    return UserNotFoundFailure(exception.message);
  }
  if (exception is UserAlreadyExistsException) {
    return UserAlreadyExistsFailure(exception.message);
  }
  if (exception is UserBlockedException) {
    return UserBlockedFailure(exception.message);
  }

  // Permission Exceptions
  if (exception is PermissionException) {
    return PermissionFailure(exception.message);
  }
  if (exception is PermissionDeniedException) {
    return PermissionDeniedFailure(exception.message);
  }
  if (exception is UnauthorizedException) {
    return UnauthorizedFailure(exception.message);
  }

  // Rate Limiting Exceptions
  if (exception is RateLimitException) {
    return RateLimitFailure(exception.message);
  }

  // Firebase Exceptions
  if (exception is FirebaseException) {
    return FirebaseFailure(exception.message);
  }
  if (exception is FirestoreException) {
    return FirestoreFailure(exception.message);
  }
  if (exception is StorageException) {
    return StorageFailure(exception.message);
  }

  // Default fallback for unknown exceptions
  return UnexpectedFailure(
    'An unexpected error occurred: ${exception.toString()}',
  );
}

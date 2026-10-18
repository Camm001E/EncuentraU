import '../constants/app_strings.dart';
import '../errors/api_exception.dart';

String apiMessage(Object error) {
  if (error is! ApiException) return AppStrings.unexpectedError;
  return switch (error.failure) {
    ApiFailure.permissionDenied => AppStrings.permissionDenied,
    ApiFailure.workflowConflict => AppStrings.workflowConflict,
    ApiFailure.invalidData => AppStrings.apiInvalidData,
    ApiFailure.unauthorized => AppStrings.sessionExpired,
    ApiFailure.forbidden => AppStrings.inactiveAccount,
    ApiFailure.notFound => AppStrings.apiNotFound,
    ApiFailure.conflict => AppStrings.apiConflict,
    ApiFailure.server => AppStrings.authServerError,
    ApiFailure.connection => AppStrings.authConnectionError,
    ApiFailure.timeout => AppStrings.apiTimeout,
    ApiFailure.invalidResponse => AppStrings.apiInvalidResponse,
    ApiFailure.storage => AppStrings.secureStorageError,
    ApiFailure.imageTooLarge => AppStrings.reportPhotoTooLarge,
    ApiFailure.unsupportedImage => AppStrings.reportPhotoUnsupported,
  };
}

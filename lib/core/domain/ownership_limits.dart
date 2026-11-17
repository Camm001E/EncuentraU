/// Shared client validation limits. FastAPI remains the authoritative validator.
abstract final class OwnershipLimits {
  static const minimumEvidenceLength = 10;
  static const maximumEvidenceLength = 4000;
  static const maximumNoteLength = 2000;
  static const minimumRejectionLength = 3;
  static const maximumMessageLength = 2000;
  static const messagesPageSize = 50;
}

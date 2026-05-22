class TransferPrecheckEntity {
  final bool isValid;
  final String? recipientName;
  final String? errorCode;
  final String? message;

  const TransferPrecheckEntity({
    required this.isValid,
    this.recipientName,
    this.errorCode,
    this.message,
  });
}
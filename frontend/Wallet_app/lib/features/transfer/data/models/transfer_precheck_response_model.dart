class TransferPrecheckResponseModel {
  final bool isValid;
  final String? recipientName;
  final String? errorCode;
  final String? message;

  const TransferPrecheckResponseModel({
    required this.isValid,
    this.recipientName,
    this.errorCode,
    this.message,
  });

  factory TransferPrecheckResponseModel.fromJson(Map<String, dynamic> json) {
    return TransferPrecheckResponseModel(
      isValid: json['is_valid'] == true,
      recipientName: json['recipient_name'] as String?,
      errorCode: json['error_code'] as String?,
      message: json['message'] as String?,
    );
  }
}
class ExecuteExchangeRequestModel {
  final int fromAccountId;
  final int toAccountId;
  final double fromAmount;
  final String notes;

  const ExecuteExchangeRequestModel({
    required this.fromAccountId,
    required this.toAccountId,
    required this.fromAmount,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'from_amount': fromAmount,
      if (notes.trim().isNotEmpty) 'notes': notes,
    };
  }
}

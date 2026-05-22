class ExecuteTransferRequestModel {
  final int fromAccountId;
  final String toWalletNumber;
  final double amount;
  final String notes;

  const ExecuteTransferRequestModel({
    required this.fromAccountId,
    required this.toWalletNumber,
    required this.amount,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'from_account_id': fromAccountId,
      'to_wallet_number': toWalletNumber,
      'amount': amount,
      if (notes.trim().isNotEmpty) 'notes': notes,
    };
  }
}

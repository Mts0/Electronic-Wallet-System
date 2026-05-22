class ExchangeQuoteResponseModel {
  final String baseCurrency;
  final String targetCurrency;
  final double rateValue;
  final String? updatedAtIso;

  const ExchangeQuoteResponseModel({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rateValue,
    this.updatedAtIso,
  });

  factory ExchangeQuoteResponseModel.fromJson(Map<String, dynamic> json) {
    return ExchangeQuoteResponseModel(
      baseCurrency: (json['base_currency'] ?? '').toString().trim().toUpperCase(),
      targetCurrency: (json['target_currency'] ?? '').toString().trim().toUpperCase(),
      rateValue: double.tryParse((json['rate_value'] ?? '0').toString()) ?? 0,
      updatedAtIso: (json['updated_at'] ?? '').toString().trim().isEmpty
          ? null
          : (json['updated_at'] ?? '').toString().trim(),
    );
  }
}

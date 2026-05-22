class ExchangeQuoteEntity {
  final String baseCurrency;
  final String targetCurrency;
  final double rateValue;
  final DateTime? updatedAt;

  const ExchangeQuoteEntity({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rateValue,
    this.updatedAt,
  });

  double estimateReceived(double fromAmount) {
    return fromAmount * rateValue;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_quote_entity.dart';
import 'package:y_wallet/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:y_wallet/features/exchange/presentation/providers/exchange_providers.dart';
import 'package:y_wallet/features/exchange/presentation/utils/exchange_error_mapper.dart';

class ExchangeQuoteState {
  final bool isLoading;
  final ExchangeQuoteEntity? quote;
  final String? inlineErrorMessage;
  final bool requiresLogin;

  const ExchangeQuoteState({
    this.isLoading = false,
    this.quote,
    this.inlineErrorMessage,
    this.requiresLogin = false,
  });

  ExchangeQuoteState copyWith({
    bool? isLoading,
    ExchangeQuoteEntity? quote,
    bool clearQuote = false,
    String? inlineErrorMessage,
    bool clearInlineError = false,
    bool? requiresLogin,
  }) {
    return ExchangeQuoteState(
      isLoading: isLoading ?? this.isLoading,
      quote: clearQuote ? null : (quote ?? this.quote),
      inlineErrorMessage:
          clearInlineError ? null : (inlineErrorMessage ?? this.inlineErrorMessage),
      requiresLogin: requiresLogin ?? this.requiresLogin,
    );
  }
}

final exchangeQuoteProvider =
    StateNotifierProvider<ExchangeQuoteController, ExchangeQuoteState>((ref) {
  final repository = ref.watch(exchangeRepositoryProvider);
  return ExchangeQuoteController(repository);
});

class ExchangeQuoteController extends StateNotifier<ExchangeQuoteState> {
  ExchangeQuoteController(this._repository) : super(const ExchangeQuoteState());

  final ExchangeRepository _repository;

  void clearQuoteState() {
    state = const ExchangeQuoteState();
  }

  Future<bool> loadQuote({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    if (baseCurrency.trim().toUpperCase() == targetCurrency.trim().toUpperCase()) {
      state = const ExchangeQuoteState(
        inlineErrorMessage: 'لا يمكن المصارفة بين نفس العملة',
      );
      return false;
    }

    state = const ExchangeQuoteState(isLoading: true);

    try {
      final quote = await _repository.getPairRate(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
      );

      state = ExchangeQuoteState(
        isLoading: false,
        quote: quote,
        inlineErrorMessage: null,
        requiresLogin: false,
      );
      return true;
    } catch (error) {
      final mapped = ExchangeErrorMapper.map(error);
      state = ExchangeQuoteState(
        isLoading: false,
        quote: null,
        inlineErrorMessage: mapped.message,
        requiresLogin: mapped.shouldLogout,
      );
      return false;
    }
  }
}
